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

#import <Foundation/Foundation.h>
#import <WebRTC/WebRTC.h>
#import "ARDSignalingMessage.h"

typedef NS_ENUM(NSInteger, ARDAppClientState) {
  // Disconnected from servers.
  kARDAppClientStateDisconnected,
  // Connecting to servers.
  kARDAppClientStateConnecting,
  // Connected to servers.
  kARDAppClientStateConnected
  //Ice finished
  //kARDAppClientIceFinished
};

@class ARDAppClient;
@protocol ARDAppClientDelegate <NSObject>

- (void)appClient:(ARDAppClient *)client
    didChangeState:(ARDAppClientState)state;

- (void)appClient:(ARDAppClient *)client
   incomingCallRequest:(NSString *)from;


@end

@protocol ARDAppClientUpdateUserTableDelegate <NSObject>

- (void)updateTable:(NSArray *)registeredUser;

@end

// Handles connections to the AppRTC server 
@interface ARDAppClient : NSObject

@property(nonatomic, readonly) ARDAppClientState state;
@property(nonatomic, weak) id<ARDAppClientDelegate> delegate;
@property(nonatomic, weak) id<ARDAppClientUpdateUserTableDelegate> registeredUserdelegate;
@property(nonatomic, strong) NSString *serverHostUrl;
@property(nonatomic, strong) NSString *from;
@property(nonatomic, strong) NSString *to;
@property(nonatomic, assign) BOOL isInitiator;
@property (nonatomic, strong) RTCVideoTrack *localVideoTrack;
@property (nonatomic, strong) RTCVideoTrack *remoteVideoTrack;
@property (nonatomic, strong) RTCMediaStream *localStream;
@property (nonatomic, strong) RTCEAGLVideoView *remoteView;
@property (nonatomic, strong) RTCEAGLVideoView *localView;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *localViewWidthConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *localViewHeightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *localViewRightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *localViewBottomConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *footerViewBottomConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *remoteViewTopConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *remoteViewRightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *remoteViewLeftConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *remoteViewBottomConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *buttonContainerViewLeftConstraint;

@property(nonatomic, assign)  BOOL isPotrait;
@property (nonatomic, strong) UIView *viewWrapper;
@property (assign, nonatomic) CGSize localVideoSize;
@property (assign, nonatomic) CGSize remoteVideoSize;
@property (assign, nonatomic) BOOL isZoom; //used for double tap remote view

- (instancetype)initWithDelegate:(id<ARDAppClientDelegate>)delegate;
- (void)videoView:(RTCEAGLVideoView *)videoView didChangeVideoSize:(CGSize)size;
- (void)connectToWebsocket:(NSString *)url : (NSString *)from;
- (void)startSignalingIfReady;
- (void)sendSignalingMessageToCollider: (ARDSignalingMessage *)message;

- (RTCMediaConstraints *)connectionConstraints;
- (NSDictionary *)mandatoryConstraints;
- (NSDictionary *)optionalConstraints;
- (void)call:(NSString *)from : (NSString *)to;

// Mute and unmute Audio-In
- (void)muteAudioIn;
- (void)unmuteAudioIn;

// Mute and unmute Video-In
- (void)muteVideoIn;
- (void)unmuteVideoIn;

// Enabling / Disabling Speakerphone
- (void)enableSpeaker;
- (void)disableSpeaker;

// Swap camera functionality
- (void)swapCameraToFront;
- (void)swapCameraToBack;

// Disconnects from the AppRTC servers and any connected clients.
- (void)disconnect: (BOOL) ownDisconnect;

@end
