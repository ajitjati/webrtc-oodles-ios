/*
 * libjingle
 * Copyright 2014, Google Inc.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *  1. Redistributions of source code must retain the above copyright notice,
 *     this list of conditions and the following disclaimer.
 *  2. Redistributions in binary form must reproduce the above copyright notice,
 *     this list of conditions and the following disclaimer in the documentation
 *     and/or other materials provided with the distribution.
 *  3. The name of the author may not be used to endorse or promote products
 *     derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "ARDAppClient.h"

#import <AVFoundation/AVFoundation.h>

#import "ARDMessageResponse.h"
#import "ARDRegisterResponse.h"
#import "ARDSignalingMessage.h"
#import "ARDUtilities.h"
#import "ARDWebSocketChannel.h"
#import <WebRTC/WebRTC.h>
#import "NBMWebRTCPeer.h"
#import "NBMPeerConnection.h"
#import "NBMMediaConfiguration.h"
#import <WebRTC/RTCPeerConnection.h>

static NSString *kARDDefaultSTUNServerUrl = @"stun:stun.l.google.com:19302";

static NSString *kARDAppClientErrorDomain = @"ARDAppClient";
static NSInteger kARDAppClientErrorCreateSDP = -3;
static NSInteger kARDAppClientErrorSetSDP = -4;

//ICECandidateConstants
NSString const *kRTCICECandidateTypeKey = @"id";
NSString const *kRTCICECandidateTypeValue = @"onIceCandidate";
NSString const *kRTCICECandidateMidKey = @"sdpMid";
NSString const *kRTCICECandidateMLineIndexKey = @"sdpMLineIndex";
NSString const *kRTCICECandidateSdpKey = @"candidate";
NSString const *kARDSignalingCandidate = @"candidate";

@interface ARDAppClient (){
   // NSMutableArray * arrayCondidates;
}

@property(nonatomic, strong) ARDWebSocketChannel *channel;
@property(nonatomic, strong) RTCPeerConnection *peerConnection;
@property(nonatomic, strong) RTCPeerConnectionFactory *factory;
@property(nonatomic, strong) NSMutableArray *messageQueue;

@property(nonatomic, assign) BOOL hasReceivedSdp;
@property(nonatomic, assign) BOOL hasReceivedScreenSdp;
@property(nonatomic, readonly) BOOL isRegisteredWithWebsocketServer;
@property(nonatomic, assign) BOOL isSpeakerEnabled;
@property(nonatomic, strong) NSMutableArray *iceServers;
@property(nonatomic, strong) NSURL *webSocketURL;
@property(nonatomic, strong) RTCAudioTrack *defaultAudioTrack;
@property(nonatomic, strong) RTCVideoTrack *defaultVideoTrack;
@property(nonatomic, strong) RTCVideoTrack *defaultScreenTrack;

@property (nonatomic, strong) NBMWebRTCPeer *webRTCPeer;
@end

@implementation ARDAppClient

@synthesize delegate = _delegate;
@synthesize state = _state;
@synthesize serverHostUrl = _serverHostUrl;
@synthesize channel = _channel;
@synthesize isCallbackMode = _isCallbackMode;
@synthesize peerConnection = _peerConnection;
@synthesize factory = _factory;
@synthesize messageQueue = _messageQueue;
@synthesize hasReceivedSdp  = _hasReceivedSdp;
@synthesize hasReceivedScreenSdp  = _hasReceivedScreenSdp;

@synthesize isRegisteredWithWebsocketServer  = _isRegisteredWithWebsocketServer;
@synthesize from = _from;
@synthesize to = _to;
@synthesize isInitiator = _isInitiator;
@synthesize isSpeakerEnabled = _isSpeakerEnabled;
@synthesize iceServers = _iceServers;
@synthesize webSocketURL = _websocketURL;

@synthesize localVideoTrack = _localVideoTrack;
@synthesize remoteVideoTrack = _remoteVideoTrack;
@synthesize screenVideoTrack = _screenVideoTrack;

@synthesize localVideoSize = _localVideoSize;
@synthesize remoteVideoSize = _remoteVideoSize;
@synthesize screenVideoSize = _screenVideoSize;

@synthesize remoteView = _remoteView;
@synthesize localView = _localView;
@synthesize screenView = _screenView;

@synthesize viewWrapper = _viewWrapper;
@synthesize isPotrait = _isPotrait;

@synthesize localViewWidthConstraint = _localViewWidthConstraint;
@synthesize localViewHeightConstraint = _localViewHeightConstraint;
@synthesize localViewRightConstraint = _localViewRightConstraint;
@synthesize localViewBottomConstraint = _localViewBottomConstraint;
@synthesize footerViewBottomConstraint = _footerViewBottomConstraint;

- (instancetype)initWithDelegate:(id<ARDAppClientDelegate>)delegate {
  if (self = [super init]) {
    _delegate = delegate;
    _factory = [[RTCPeerConnectionFactory alloc] init];
    _messageQueue = [NSMutableArray array];
    _iceServers = [NSMutableArray arrayWithObject:[self defaultSTUNServer]];
    _isSpeakerEnabled = YES;
      
    [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(orientationChanged:)
                                                   name:@"UIDeviceOrientationDidChangeNotification"
                                                 object:nil];
      
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(connectToWebsocket:)
                                                   name:@"UIApplicationDidBecomeActiveNotification"
                                                 object:nil];
      
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(disconnect)
                                                   name:@"UIApplicationDidEnterBackgroundNotification"
                                                 object:nil];
    //get default orientation and store it so it cannot be overwritten by other orientations
      
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if (UIDeviceOrientationIsLandscape(orientation)){
          _isPotrait = false;
    }
    else{
          _isPotrait = true;
    }
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    
  [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIApplicationDidBecomeActiveNotification" object:nil];
    [self disconnect : false useCallback: false];
}

- (void)connectToWebsocket : (BOOL) reconnect {
    
    if (_channel != nil && !reconnect) {  //disconnect from call not from colider
        NSLog(@"don't connect again because channel is not nil");
        return;
    }
    _websocketURL = [NSURL URLWithString: [[NSUserDefaults standardUserDefaults] stringForKey:@"SERVER_HOST_URL"]];
    _from = [[NSUserDefaults standardUserDefaults] stringForKey:@"MY_USERNAME"];
    
    NSLog(@"called connectToWebsocket to %@ with user: %@",_websocketURL,_from);
//    NSParameterAssert(_state == kARDAppClientStateDisconnected);
    self.state = kARDAppClientStateConnecting;
    
    __weak ARDAppClient *weakSelf = self;
    ARDAppClient *strongSelf = weakSelf;
    [strongSelf registerWithColliderIfReady];
    
    [_channel getAppConfig];
    
}

- (void)disconnect{
    [self disconnect:true useCallback:false];
    _channel = nil;
}


- (void)call:(NSString *)from : (NSString *)to{
    self.to = to;
    self.from = from;
    
    [self startSignalingIfReady];
}

- (void)startSignalingIfReady {
    
    if (!self.isRegisteredWithWebsocketServer) {
        return;
    }
    
    self.state = kARDAppClientStateConnected;
    
    // Create peer connection.
    RTCMediaConstraints *constraints = [self offerConstraints];
    
    RTCConfiguration *config = [[RTCConfiguration alloc] init];
    [config setIceServers:_iceServers];
    _peerConnection = [_factory peerConnectionWithConfiguration:config
                                                    constraints:constraints
                                                       delegate:(id)self];
    
    if(self.startLocalMedia){
        [_peerConnection addStream:self.localStream];
        [self sendOffer];
    }
    
}

- (void)startSignalingScreensharing{
    [self sendOfferScreensharing];
}


- (void)sendOffer {
    [_peerConnection offerForConstraints:[self offerConstraints] completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
        
        [self peerConnection:_peerConnection didCreateSessionDescription:sdp error:error];
        
    }];
}

- (void)sendOfferScreensharing {
        
    NBMMediaConfiguration *defaultConfig = [NBMMediaConfiguration defaultConfiguration];
    NBMWebRTCPeer *webRTCManager = [[NBMWebRTCPeer alloc] initWithDelegate:(id) self configuration:defaultConfig];
    
    if (!webRTCManager) {
        /*    NSError *retryError = [NSError errorWithDomain:@"it.nubomedia.NBMRoomManager"
         code:0
         userInfo:@{NSLocalizedDescriptionKey: @"Impossible to setup local media stream, check AUDIO & VIDEO permission"}];*/
        //  [self.delegate roomManager:self didFailWithError:retryError];
        return;
    }
   
    self.webRTCPeer = webRTCManager;
    self.webRTCPeer.iceServers = self.iceServers;
    [self.webRTCPeer generateOffer:@"screensharing"];  //we use 'screensharing' as connectionId since we are not using more then one right now. (no conferences!)
}




- (void)setState:(ARDAppClientState)state {
    if (_state == state) {
        return;
    }
    NSLog(@"changed state ");
    _state = state;
    [_delegate appClient:self didChangeState:_state];
}


- (void)orientationChanged:(NSNotification *)notification {
    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    
    //if device is not yet connected don't do any peerConnection stream actions
    if(_state == kARDAppClientStateDisconnected || _state == kARDAppClientStateConnecting){
        NSLog(@"orientation changed ");
        return;
    }
    
    //if orientation is the same don't do anything
    if(!UIDeviceOrientationIsLandscape(orientation) && !UIDeviceOrientationIsPortrait(orientation)) return;
    
    if(_isPotrait == true  && !UIDeviceOrientationIsLandscape(orientation)) return;
    if(_isPotrait == false && !UIDeviceOrientationIsPortrait(orientation)) return;
    
    if (UIDeviceOrientationIsLandscape(orientation)){
        _isPotrait = false;
    }
    else{
        _isPotrait = true;
    }
}

- (void)disconnectScreen: (BOOL) ownDisconnect {
    
    if(self.webRTCPeer){
        [self.remoteVideoTrack removeRenderer:self.screenView];
        self.screenView.layer.hidden = true;   // [self.screenView renderFrame:nil];
        [self.screenVideoTrack removeRenderer:self.remoteView];
        self.screenVideoTrack = nil;

        [self.remoteVideoTrack addRenderer:self.remoteView];
    
        [UIView animateWithDuration:0.4f animations:^{
        
            [UIApplication sharedApplication].idleTimerDisabled = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"UIDeviceOrientationDidChangeNotification" object:self];
        
        }];
    
   
        [self.webRTCPeer closeConnectionWithConnectionId: @"screensharing"];
        self.webRTCPeer = nil;
    }
}

- (void)disconnect: (BOOL) ownDisconnect  useCallback: (BOOL) sendCallback {
    
    NSLog(@"ownDisconnect %s ",ownDisconnect ? "true" : "false");
    
    if (_state == kARDAppClientStateDisconnected) {  //disconnect from call not from colider
        NSLog(@"kARDAppClientStateDisconnected");
        return;
    }
    
    self.isCallbackMode = sendCallback;
    
    if (_channel && ownDisconnect) {  //check if this disconnect was issued by ourselfs - if so send our peer a message
          // Tell the other client we're hanging up.
          NSLog(@"Tell the other client we're hanging up.");
         
          ARDByeMessage *byeMessage = [[ARDByeMessage alloc] init];
          NSData *byeData = [byeMessage JSONData];
          [_channel sendData:byeData];
    }

    _hasReceivedSdp = NO;
    _messageQueue = [NSMutableArray array];
    _peerConnection = nil;
    
    if(self.webRTCPeer)  [self disconnectScreen: false];
    self.state = kARDAppClientStateDisconnected;

    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

#pragma mark - NBMWebRTCPeerDelegate

- (void)webRTCPeer:(NBMWebRTCPeer *)peer didGenerateOffer:(RTCSessionDescription *)sdpOffer forConnection:(NBMPeerConnection *)connection {
    NSLog(@"offer generated after incoming %@ connection",[connection connectionId]);
    [_channel incomingScreenCallResponse: _to:  sdpOffer];
}

- (void)webRTCPeer:(NBMWebRTCPeer *)peer hasICECandidate:(RTCIceCandidate *)candidate forConnection:(NBMPeerConnection *)connection{
    NSLog(@"hasICECandidate after incoming %@ connection",[connection connectionId]);
    ARDICECandidateMessage *message =  [[ARDICECandidateMessage alloc] initWithCandidate:candidate];
    
    [self sendSignalingMessage:message];
    
}

- (void)webrtcPeer:(NBMWebRTCPeer *)peer iceStatusChanged:(RTCIceConnectionState)state ofConnection:(NBMPeerConnection *)connection{
    
    if(state == RTCIceGatheringStateNew) NSLog(@"screensharing RTCIceGatheringStateNew");
    else if(state == RTCIceConnectionStateChecking) NSLog(@"screensharing RTCIceConnectionStateChecking");
    else if(state == RTCIceConnectionStateCompleted) NSLog(@"screensharing RTCIceConnectionStateCompleted");
    else if(state == RTCIceConnectionStateConnected) {
        
        self.screenView.layer.zPosition = MAXFLOAT;
        self.screenView.layer.hidden = false;
        NSLog(@"screensharing RTCIceConnectionStateConnected");
    }
    else if(state == RTCIceConnectionStateFailed){
            [self disconnectScreen:false];
            NSLog(@"screensharing RTCIceConnectionStateDisconnected ");
    }
    else if(state == RTCIceConnectionStateDisconnected) {
        [self disconnectScreen:false];
        NSLog(@"screensharing RTCIceConnectionStateDisconnected ");
    }
    else if(state == RTCIceConnectionStateClosed) NSLog(@"screensharing RTCIceConnectionStateClosed ");
    else if(state == RTCIceConnectionStateCount) NSLog(@"screensharing RTCIceConnectionStateCount ");
    else if(state == RTCIceGatheringStateNew) NSLog(@"screensharing RTCIceGatheringStateNew");
    else if(state == RTCIceGatheringStateComplete) NSLog(@"screensharing RTCIceGatheringStateComplete");
    else if(state == RTCIceGatheringStateGathering) NSLog(@"screensharing RTCIceGatheringStateGathering");
    else  NSLog(@"iceStatusChanged after incoming %@ connection to: %li",[connection connectionId], (long)state);

}

- (void)webRTCPeer:(NBMWebRTCPeer *)peer didAddStream:(RTCMediaStream *)remoteStream ofConnection:(NBMPeerConnection *)connection{
    self.screenStream = remoteStream;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"Received %lu video tracks and %lu audio tracks",
              (unsigned long)remoteStream.videoTracks.count,
              (unsigned long)remoteStream.audioTracks.count);
        
     if(self.screenStream){
         if (self.screenStream.videoTracks.count) {
             RTCVideoTrack *videoTrack = self.screenStream.videoTracks[0];
             [self didReceiveScreenVideoTrack:videoTrack];
         }
     }
    });
}

- (void)webRTCPeer:(NBMWebRTCPeer *)peer didRemoveStream:(RTCMediaStream *)remoteStream ofConnection:(NBMPeerConnection *)connection{
    NSLog(@"didRemoveStream in %@ connection", connection);
    
    self.screenStream = nil;
}

#pragma mark - ARDWebSocketChannelDelegate

- (void)channel:(ARDWebSocketChannel *)channel
    setTurnServer:(NSMutableArray *)turnServers {
    _iceServers = turnServers;
}

- (void)channel:(ARDWebSocketChannel *)channel
    didReceiveMessage:(ARDSignalingMessage *)message {
  switch (message.type) {
    case kARDSignalingMessageTypeRegisteredUsers:
          [_registeredUserdelegate updateTable:((ARDRegisteredUserMessage *)message).registeredUsers];
          [_registeredUserdelegate removeRegisteredUser:_from];
          break;
    case kARDSignalingMessageTypeRegister:
         
          break;
    case kARDSignalingMessageTypeRegisterResponse:
          // [_registeredUserdelegate updateTable:((ARDRegisteredUserMessage *)message).registeredUsers];
          break;
    case kARDSignalingMessageTypeResponse:
          //what should have been happening here?
          break;
    case kARDSignalingMessageIncomingCall:
          _isInitiator = FALSE;
          _to = ((ARDIncomingCallMessage *)message).from; //the guy who is calling is "from" but its the new "to"!
          _hasReceivedSdp = YES;
          [_delegate appClient:self incomingCallRequest: ((ARDIncomingCallMessage *)message).from: ((ARDIncomingCallMessage *)message).activeCall];
          break;
    case kARDSignalingMessageIncomingScreenCall:
          _hasReceivedScreenSdp = YES;
          [_delegate appClient:self incomingScreenCallRequest: ((ARDIncomingScreenCallMessage *)message).from];
          break;
    case kARDSignalingMessageTypeCallback:
          
          break;
    case kARDSignalingMessageIncomingResponseCall:
          NSLog(@"Incoming Response Calll ====================");
    case kARDSignalingMessageIncomingScreenResponseCall:
           //what should have been happening here?
           [_messageQueue addObject:message];
          break;
    case kARDSignalingMessageStartCommunication:
    case kARDSignalingMessageStartScreenCommunication:
          _hasReceivedSdp = YES;
          [_messageQueue insertObject:message atIndex:0];
          break;
    case kARDSignalingMessageTypeOffer:
    case kARDSignalingMessageTypeAnswer:
      _hasReceivedSdp = YES;
      [_messageQueue insertObject:message atIndex:0];
      break;
    case kARDSignalingMessageTypeCandidate:
    case kARDSignalingMessageTypeScreenCandidate:
      [_messageQueue addObject:message];
      break;
    case kARDSignalingMessageTypeBye:
    case kARDSignalingMessageTypeScreenBye:
        [_messageQueue insertObject:message atIndex:0];
        break;
    case kARDSignalingMessageTypePing:   
         [self sendSignalingMessage: [[ARDPingMessage alloc] init]];
         break;
      return;
  }
  [self drainMessageQueueIfReady];
}

- (void)channel:(ARDWebSocketChannel *)channel didChangeState:(ARDWebSocketChannelState)state {
  switch (state) {
    case kARDWebSocketChannelStateOpen:
      break;
    case kARDWebSocketChannelStateRegistered:
      break;
    case kARDWebSocketChannelStateClosed:
    case kARDWebSocketChannelStateError:
            NSLog(@"kARDWebSocketChannelStateError");
          [self disconnect : false useCallback: false];
          [[NSNotificationCenter defaultCenter] postNotificationName:@"ServerFoundOffline" object:NULL];

      break;
  }
}

#pragma mark - RTCPeerConnectionDelegate

- (void)peerConnection:(RTCPeerConnection *)peerConnection signalingStateChanged:(RTCSignalingState)stateChanged {
    NSLog(@"Signaling state changed: %ld", (long)stateChanged);
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
        removedStream:(RTCMediaStream *)stream {
    NSLog(@"Stream was removed.");
}

- (void)peerConnectionOnRenegotiationNeeded:
    (RTCPeerConnection *)peerConnection {
    NSLog(@"WARNING: Renegotiation needed but unimplemented.");
}
    
    
#pragma mark - RTCPeerConnectionDelegate
    
- (void)peerConnection:(RTCPeerConnection *)peerConnection didChangeSignalingState:(RTCSignalingState)stateChanged {
      NSLog(@"didChangeSignalingState");
}
    
- (void)peerConnection:(RTCPeerConnection *)peerConnection didAddStream:(RTCMediaStream *)stream {
    NSLog(@"didAddStream");

    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSLog(@"Received %lu video tracks and %lu audio tracks",
              (unsigned long)stream.videoTracks.count,
              (unsigned long)stream.audioTracks.count);
        
        if(!self.remoteStream){
            self.remoteStream=stream;
        }
        
        if (stream.videoTracks.count) {
                    RTCVideoTrack *videoTrack = stream.videoTracks[0];
                    [self didReceiveRemoteVideoTrack:videoTrack];
                   if (_isSpeakerEnabled) [self enableSpeaker]; //Use the "handsfree" speaker instead of the ear speaker.
        }
    });
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didRemoveStream:(RTCMediaStream *)stream {
    NSLog(@"didRemoveStream");
}
    
- (void)peerConnectionShouldNegotiate:(RTCPeerConnection *)peerConnection {
    NSLog(@"peerConnectionShouldNegotiate");
}
    
- (void)peerConnection:(RTCPeerConnection *)peerConnection didChangeIceConnectionState:(RTCIceConnectionState)newState {
    NSLog(@"didChangeIceConnectionState %@", [self stringForConnectionState: newState]);
}
    
- (NSString *)stringForConnectionState:(RTCIceConnectionState)state {
        switch (state) {
            case RTCIceConnectionStateNew:
            return @"New";
            break;
            case RTCIceConnectionStateChecking:
            return @"Checking";
            break;
            case RTCIceConnectionStateConnected:
            return @"Connected";
            break;
            case RTCIceConnectionStateCompleted:
            return @"Completed";
            break;
            case RTCIceConnectionStateFailed:
            return @"Failed";
            break;
            case RTCIceConnectionStateDisconnected:
            return @"Disconnected";
            break;
            case RTCIceConnectionStateClosed:
            return @"Closed";
            break;
            default:
            return @"Other state";
            break;
        }
}

- (NSString *)stringForGatheringState:(RTCIceGatheringState)state
    {
    switch (state) {
    case RTCIceGatheringStateNew:
    return @"New";
    break;
    case RTCIceGatheringStateGathering:
    return @"Gathering";
    break;
    case RTCIceGatheringStateComplete:
    return @"Complete";
    break;
    default:
    return @"Other state";
    break;
    }
}

    
- (void)peerConnection:(RTCPeerConnection *)peerConnection didGenerateIceCandidate:(RTCIceCandidate *)candidate {
    NSLog(@"didGenerateIceCandidate %@", candidate.sdp);
    
    ARDICECandidateMessage *message =  [[ARDICECandidateMessage alloc] initWithCandidate:candidate];
    [self sendSignalingMessage:message];
}
    
- (void)peerConnection:(RTCPeerConnection *)peerConnection
    didOpenDataChannel:(RTCDataChannel *)dataChannel {
    NSLog(@"didOpenDataChannel");
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection  didChangeIceGatheringState:(RTCIceGatheringState)newState {
         NSLog(@"didChangeIceGatheringState %@", [self stringForGatheringState:newState]);
         switch (newState) {
            case RTCIceGatheringStateNew:
                 break;
             case RTCIceGatheringStateGathering:
                 break;
             case RTCIceGatheringStateComplete:
                       /* for (ARDICECandidateMessage *message in arrayCondidates) {
                                [self sendSignalingMessage:message];
                        }*/
                    break;
       }
}


#pragma mark - RTCSessionDescription
- (void)peerConnection:(RTCPeerConnection *)peerConnection didCreateSessionDescription:(RTCSessionDescription *)sdp
                          error:(NSError *)error {
  dispatch_async(dispatch_get_main_queue(), ^{
      
    if (error) {
      NSLog(@"Failed to create session description. Error: %@", error);
        [self disconnect : false useCallback: false];
      NSDictionary *userInfo = @{
        NSLocalizedDescriptionKey: @"Failed to create session description.",
      };
      NSError *sdpError =
          [[NSError alloc] initWithDomain:kARDAppClientErrorDomain
                                     code:kARDAppClientErrorCreateSDP
                                 userInfo:userInfo];

        [self didError:sdpError];
      return;
    }
    
    [peerConnection setLocalDescription:sdp completionHandler:^(NSError * _Nullable error) {
          
          if(!self.isInitiator){
              [_channel incomingCallResponse: _to:  sdp];
          }else{
              [_channel call: _from: _to : sdp];
          }
    }];
      

  });
}


- (void)peerConnection:(RTCPeerConnection *)peerConnection didSetSessionDescriptionWithError:(NSError *)error {
  dispatch_async(dispatch_get_main_queue(), ^{
    if (error) {
      NSLog(@"Failed to set session description. Error: %@", error);
        [self disconnect : false useCallback: false];
      NSDictionary *userInfo = @{
        NSLocalizedDescriptionKey: @"Failed to set session description.",
      };
      NSError *sdpError = [[NSError alloc] initWithDomain:kARDAppClientErrorDomain
                                     code:kARDAppClientErrorSetSDP
                                 userInfo:userInfo];
        [self didError:sdpError];
      return;
    }
      
  });
}

#pragma mark - Private

- (BOOL)isRegisteredWithWebsocketServer {
    return _channel.state == kARDWebSocketChannelStateOpen || _channel.state == kARDWebSocketChannelStateRegistered;
}

- (BOOL)startLocalMedia
{
    RTCMediaStream *localMediaStream = [_factory mediaStreamWithStreamId:[self localStreamLabel]];
    self.localStream = localMediaStream;
    
    //Audio setup
    BOOL audioEnabled = NO;
    AVAuthorizationStatus audioAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (audioAuthStatus == AVAuthorizationStatusAuthorized || audioAuthStatus == AVAuthorizationStatusNotDetermined) {
        audioEnabled = YES;
        [self setupLocalAudio];
    }
    
    //Video setup
    BOOL videoEnabled = NO;
    // The iOS simulator doesn't provide any sort of camera capture
    // support or emulation (http://goo.gl/rHAnC1) so don't bother
    // trying to open a local video track.
#if !TARGET_IPHONE_SIMULATOR
    AVAuthorizationStatus videoAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (videoAuthStatus == AVAuthorizationStatusAuthorized || videoAuthStatus == AVAuthorizationStatusNotDetermined) {
        videoEnabled = YES;
        [self setupLocalVideo];
    }
    
#endif
    
    return audioEnabled && videoEnabled;
}


- (void)waitForAnswer {
  [self drainMessageQueueIfReady];
}

- (void)drainMessageQueueIfReady {
  if (!_peerConnection || !_hasReceivedSdp) {
    return;
  }
    
  for (ARDSignalingMessage *message in _messageQueue) {
      [self processSignalingMessage:message];
  }
  [_messageQueue removeAllObjects];
}

- (void)processSignalingMessage:(ARDSignalingMessage *)message {
  
    if (_peerConnection == NULL) {
        return;
    }
    NSParameterAssert(_peerConnection || message.type == kARDSignalingMessageTypeBye);
    
    switch (message.type) {
      
        case kARDSignalingMessageTypeRegister:
        case kARDSignalingMessageTypeRegisterResponse:
        case kARDSignalingMessageIncomingCall:
        case kARDSignalingMessageIncomingScreenCall:
        case kARDSignalingMessageIncomingResponseCall:
        case kARDSignalingMessageIncomingScreenResponseCall:
        case kARDSignalingMessageTypeResponse:
        case kARDSignalingMessageTypeOffer:
        case kARDSignalingMessageTypeCallback:
        case kARDSignalingMessageTypeRegisteredUsers:
            break;
            
       case kARDSignalingMessageTypeAnswer:
                case kARDSignalingMessageStartCommunication:{
                ARDStartCommunicationMessage *sdpMessage = (ARDStartCommunicationMessage *) message;
                [_peerConnection setRemoteDescription:sdpMessage.sessionDescription completionHandler:^(NSError * _Nullable error) {
                  // some code when remote description was set (was a delegate before - see below)
            }];
            break;
        }
        case kARDSignalingMessageStartScreenCommunication:{
            ARDStartScreenCommunicationMessage *sdpMessage = (ARDStartScreenCommunicationMessage *) message;
            
            [self.webRTCPeer processAnswer:sdpMessage.sessionDescription connectionId:@"screensharing"];
            break;
        }
        case kARDSignalingMessageTypeCandidate: {

          ARDICECandidateMessage *candidateMessage =  (ARDICECandidateMessage *)message;
          [_peerConnection addIceCandidate: candidateMessage.candidate];
        
          break;
        }
        case kARDSignalingMessageTypeScreenCandidate: {
            
            ARDICEScreenCandidateMessage *candidateMessage =  (ARDICEScreenCandidateMessage *)message;
            [self.webRTCPeer addICECandidate:candidateMessage.candidate connectionId:@"screensharing"];
            
            break;
        }
        case kARDSignalingMessageTypeBye:{
         
          ARDByeMessage *byeMessage = (ARDByeMessage *) message;
           
          [self disconnect : false useCallback: byeMessage.callback];
          break;
        }
        case kARDSignalingMessageTypeScreenBye: {
            
            // Other client disconnected.
            [self disconnectScreen : false];
            
            break;
        }
    }
}

- (void)sendSignalingMessage:(ARDSignalingMessage *)message {
    [self sendSignalingMessageToCollider:message];
}


- (void)setupLocalMediaWithVideoConstraints:(RTCMediaConstraints *)videoConstraints
{
    RTCMediaStream *localMediaStream = [_factory mediaStreamWithStreamId:[self localStreamLabel]];
    self.localStream = localMediaStream;
    
    //Audio setup
    [self setupLocalAudio];
    
    // The iOS simulator doesn't provide any sort of camera capture
    // support or emulation (http://goo.gl/rHAnC1) so don't bother
    // trying to open a local video track.
#if !TARGET_IPHONE_SIMULATOR
    //Video setup
    [self setupLocalVideo];
    
#endif
}

- (NSString *)localStreamLabel {
    return @"ARDAMS";
}

- (NSString *)audioTrackId {
    return [[self localStreamLabel] stringByAppendingString:@"a0"];
}

- (NSString *)videoTrackId {
    return [[self localStreamLabel] stringByAppendingString:@"v0"];
}

- (void)setupLocalAudio {
    RTCAudioTrack *audioTrack = [self.factory audioTrackWithTrackId:[self audioTrackId]];
    if (self.localStream && audioTrack) {
        [self.localStream addAudioTrack:audioTrack];
    }
}

- (void)setupLocalVideo {
    [self setupLocalVideoWithConstraints:nil];
}

- (void)setupLocalVideoWithConstraints:(RTCMediaConstraints *)videoConstraints {
    RTCVideoTrack *videoTrack = [self localVideoTrackWithConstraints:videoConstraints];
    if (self.localStream && videoTrack) {
        RTCVideoTrack *oldVideoTrack = [self.localStream.videoTracks firstObject];
        if (oldVideoTrack) {
            [self.localStream removeVideoTrack:oldVideoTrack];
        }
        [self.localStream addVideoTrack:videoTrack];
        [self didReceiveLocalVideoTrack:videoTrack]; //connect track with videoUI
    }
}

- (RTCVideoTrack *)localVideoTrackWithConstraints:(RTCMediaConstraints *)videoConstraints {
   /// NSString *cameraId = [self cameraDevice:self.cameraPosition];
    
   // NSAssert(cameraId, @"Unable to get camera id");
    //TODO: checkout Camera checnage
    RTCAVFoundationVideoSource* videoSource = [self.factory avFoundationVideoSourceWithConstraints:videoConstraints];
    //if (self.cameraPosition == AVCaptureDevicePositionBack) {
      //  [videoSource setUseBackCamera:YES];
    //}
    
    RTCVideoTrack *videoTrack = [self.factory videoTrackWithSource:videoSource trackId:[self videoTrackId]];
    
    return videoTrack;
}

- (NSString *)cameraDevice{
    NSString *cameraID = nil;
    for (AVCaptureDevice *captureDevice in
         [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if (captureDevice.position == AVCaptureDevicePositionFront) {
            cameraID = [captureDevice localizedName];
            break;
        }
    }
    NSAssert(cameraID, @"Unable to get the front camera id");
  /*  for (AVCaptureDevice* captureDevice in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if (captureDevice.position == (AVCaptureDevicePosition)cameraPosition) {
            cameraID = [captureDevice localizedName];
            break;
        }
    }*/
    
    return cameraID;
}

- (void) didReceiveLocalVideoTrack:(RTCVideoTrack *)localVideoTrack {
    
     if(self.localVideoTrack) {
        [self.localVideoTrack removeRenderer:self.localView];
        self.localVideoTrack = nil;
        [self.localView renderFrame:nil];
     }
    
     self.localVideoTrack = localVideoTrack;
     [self.localVideoTrack addRenderer:self.localView];
}

- (void)didReceiveRemoteVideoTrack:(RTCVideoTrack *)remoteVideoTrack {
    
    if(self.remoteVideoTrack) {
        [self.remoteVideoTrack removeRenderer:self.remoteView];
        self.remoteVideoTrack = nil;
        [self.remoteView renderFrame:nil];
    }

    self.remoteVideoTrack = remoteVideoTrack;
    [self.remoteVideoTrack addRenderer:self.remoteView];
   
     [UIView animateWithDuration:0.4f animations:^{
         
         [UIApplication sharedApplication].idleTimerDisabled = YES;
         
         [[NSNotificationCenter defaultCenter] postNotificationName:@"UIDeviceOrientationDidChangeNotification" object:self];
     }];
}

- (void)didReceiveScreenVideoTrack:(RTCVideoTrack *)screenVideoTrack {
    
    self.screenVideoTrack = screenVideoTrack;
    
     [self.remoteVideoTrack removeRenderer:self.remoteView];
     [self.remoteView renderFrame:nil];
     [self.screenVideoTrack addRenderer:self.remoteView];
     [self.remoteVideoTrack addRenderer:self.screenView];
    
    
    [UIView animateWithDuration:0.4f animations:^{
        
        [UIApplication sharedApplication].idleTimerDisabled = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UIDeviceOrientationDidChangeNotification" object:self];
        
    }];
}

- (void)didError:(NSError *)error {
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:nil
                                                        message:[NSString stringWithFormat:@"%@", error]
                                                                                          delegate:nil
                                                                                 cancelButtonTitle:@"OK"
                                                                                 otherButtonTitles:nil];
    [alertView show];
    [self disconnect : false useCallback: false];
}

#pragma mark - Websocket methods

- (void)registerWithColliderIfReady {
    _websocketURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",_websocketURL, @"/ws"]];
    _channel =  [[ARDWebSocketChannel alloc] initWithURL:_websocketURL delegate:(id) self];
}

- (void)sendSignalingMessageToCollider:(ARDSignalingMessage *)message {
  NSData *data = [message JSONData];
  [_channel sendData:data];
}


#pragma mark - Defaults

- (RTCMediaConstraints *)offerConstraints {
    return [self offerConstraintsRestartIce:NO];
}

- (RTCMediaConstraints *)offerScreensharingConstraints {
    return [self offerConstraintsRestartScreenIce:NO];
}

- (RTCMediaConstraints *)offerConstraintsRestartIce:(BOOL)restartICE;
{
    // In the AppRTC example optional offer contraints are nil
    NSMutableDictionary *optional = [NSMutableDictionary dictionaryWithDictionary:[self optionalConstraints]];
    
    if (restartICE) {
        [optional setObject:@"true" forKey:@"IceRestart"];
    }
    
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc]
                                        initWithMandatoryConstraints:[self mandatoryConstraints] optionalConstraints:optional];
    
    return constraints;
}

- (RTCMediaConstraints *)offerConstraintsRestartScreenIce:(BOOL)restartICE;
{
    // In the AppRTC example optional offer contraints are nil
    NSMutableDictionary *optional = [NSMutableDictionary dictionaryWithDictionary:[self optionalConstraints]];
    
    if (restartICE) {
        [optional setObject:@"true" forKey:@"IceRestart"];
    }
    
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc]
                                        initWithMandatoryConstraints:[self mandatoryConstraintsScreen] optionalConstraints:optional];
    
    return constraints;
}
    
- (NSDictionary *)mandatoryConstraints
    {   
        return @{
                 @"OfferToReceiveAudio": @"true",
                 @"OfferToReceiveVideo": @"true",
                 @"maxWidth":@"320",
                 @"maxHeight":@"240",
                 @"maxFrameRate":@"15"
                 };
      
    }

- (NSDictionary *)mandatoryConstraintsScreen
{
    return @{
             @"OfferToReceiveAudio": @"false",
             @"OfferToReceiveVideo": @"true",
             @"maxWidth":@"320",
             @"maxHeight":@"240",
             @"maxFrameRate":@"15"
             };
    
}

- (NSDictionary *)optionalConstraints{
        //     @"internalSctpDataChannels": @"true", (we don't need DataChannels at the momet right?)
        return @{
            
                 @"DtlsSrtpKeyAgreement": @"true"
                 };
}

- (RTCMediaConstraints *)videoConstraints {
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:nil optionalConstraints:nil];
    return constraints;
}


#pragma mark - Private
- (RTCIceServer *)defaultSTUNServer {
  
    return [[RTCIceServer alloc] initWithURLStrings:@[kARDDefaultSTUNServerUrl]
                                           username:@""
                                         credential:@""];
}

#pragma mark - Audio mute/unmute
- (void)muteAudioIn {
    NSLog(@"audio muted");
    RTCMediaStream *localStream = _peerConnection.localStreams[0];
    self.defaultAudioTrack = localStream.audioTracks[0];
    [localStream removeAudioTrack:localStream.audioTracks[0]];
    [_peerConnection removeStream:localStream];
    [_peerConnection addStream:localStream];
}
- (void)unmuteAudioIn {
    NSLog(@"audio unmuted");
    RTCMediaStream* localStream = _peerConnection.localStreams[0];
    [localStream addAudioTrack:self.defaultAudioTrack];
    [_peerConnection removeStream:localStream];
    [_peerConnection addStream:localStream];
    if (_isSpeakerEnabled) [self enableSpeaker];
}

#pragma mark - Video mute/unmute
- (void)muteVideoIn {
    NSLog(@"video muted");
//    if (_peerConnection.localStreams.count > 0) {
        RTCMediaStream *localStream = _peerConnection.localStreams[0];
        self.defaultVideoTrack = localStream.videoTracks[0];
        [localStream removeVideoTrack:localStream.videoTracks[0]];
//    }
}
- (void)unmuteVideoIn {
    NSLog(@"video unmuted");
//    if (_peerConnection.localStreams.count > 0) {
        RTCMediaStream* localStream = _peerConnection.localStreams[0];
        [localStream addVideoTrack:self.defaultVideoTrack];
//    }
}

#pragma mark - swap camera

- (RTCVideoTrack *)createLocalVideoTrackBackCamera {
    

    RTCVideoTrack *videoTrack = nil;
#if !TARGET_IPHONE_SIMULATOR && TARGET_OS_IPHONE
    //AVCaptureDevicePositionFront
  /*  NSString *cameraID = nil;
    for (AVCaptureDevice *captureDevice in
         [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if (captureDevice.position == AVCaptureDevicePositionBack) {
            cameraID = [captureDevice localizedName];
            break;
        }
    }
    NSAssert(cameraID, @"Unable to get the back camera id");*/
    
   // RTCVideoCapturer *capturer = [RTCVideoCapturer capturerWithDeviceName:cameraID];
  //  RTCMediaConstraints *mediaConstraints = [self defaultMediaStreamConstraints];
  //  RTCVideoSource *videoSource = [_factory videoSourceWithCapturer:capturer constraints:mediaConstraints];
     //localVideoTrack = [_factory videoTrackWithID:@"ARDAMSv0" source:videoSource];
    
    RTCAVFoundationVideoSource* videoSource = [self.factory avFoundationVideoSourceWithConstraints:[self videoConstraints]];
    
    [videoSource setUseBackCamera:YES];
    //if (self.cameraPosition == AVCaptureDevicePositionBack) {
   
    // [videoSource set]
    //}
    
    videoTrack = [self.factory videoTrackWithSource:videoSource trackId:[self videoTrackId]];
    
    //videoTrack = [self localVideoTrackWithConstraints: [self videoConstraints]];
#endif
    return videoTrack;
}
- (void)swapCameraToFront{
    RTCMediaStream *localStream = _peerConnection.localStreams[0];
    [localStream removeVideoTrack:localStream.videoTracks[0]];
    
    RTCVideoTrack *localVideoTrack = [self localVideoTrackWithConstraints: [self videoConstraints]];
    if (localVideoTrack) {
        [localStream addVideoTrack:localVideoTrack];
        [self didReceiveLocalVideoTrack:localVideoTrack];
    }
}
- (void)swapCameraToBack{
    RTCMediaStream *localStream = _peerConnection.localStreams[0];
    [localStream removeVideoTrack:localStream.videoTracks[0]];
    
    RTCVideoTrack *localVideoTrack = [self createLocalVideoTrackBackCamera];
    if (localVideoTrack) {
        [localStream addVideoTrack:localVideoTrack];
        [self didReceiveLocalVideoTrack:localVideoTrack];
    }
}

#pragma mark - enable/disable speaker

- (void)enableSpeaker {
  //    [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
  // _isSpeakerEnabled = YES;
}

- (void)disableSpeaker {
    [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
    _isSpeakerEnabled = NO;
}

@end
