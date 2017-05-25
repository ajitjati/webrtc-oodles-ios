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

#import "ARDWebSocketChannel.h"
#import "ARDMessageResponse.h"
#import "ARDRegisterResponse.h"
#import "RTCICEServer+JSON.h"
#import "ARDUtilities.h"
#import "SRWebSocket.h"
#include "ARDAppClient.h"

// TODO(tkchin): move these to a configuration object.
static NSString const *kARDWSSMessageErrorKey = @"error";
static NSString const *kARDWSSMessagePayloadKey = @"id";
static NSString const *kARDWSSMessageResultKey = @"result";
static NSString const *kARDWSSMessageParamsKey = @"params";
static NSString const *kARDWSSMessageIceServersKey = @"iceServers";

@interface ARDWebSocketChannel () <SRWebSocketDelegate>
@end

@implementation ARDWebSocketChannel {
  NSURL *_url;
  SRWebSocket *_socket;
}

@synthesize delegate = _delegate;
@synthesize state = _state;
@synthesize to = _to;
@synthesize from = _from;

- (instancetype)initWithURL:(NSURL *)url
                   delegate:(id<ARDWebSocketChannelDelegate>)delegate {
  if (self = [super init]) {
    _url = url;
    _delegate = delegate;
    _socket = [[SRWebSocket alloc] initWithURL:url];
    _socket.delegate = self;
    NSLog(@"Opening WebSocket.");
    [_socket open];
  }
  return self;
}

- (void)dealloc {
  [self disconnect];
}

- (void)setState:(ARDWebSocketChannelState)state {
  if (_state == state) {
    return;
  }
  _state = state;
  [_delegate channel:self didChangeState:_state];
}

- (void)getAppConfig {
   if (_state == kARDWebSocketChannelStateOpen) {
       
        NSDictionary *appConfigMessage = @{
                                            @"id": @"appConfig"
                                          };
       
        NSData *message = [NSJSONSerialization dataWithJSONObject:appConfigMessage
                                            options:NSJSONWritingPrettyPrinted
                                          error:nil];
        
        [self sendData: message];
    }
}

- (void)registerFrom:(NSString *)name {
    if (_state == kARDWebSocketChannelStateOpen) {

        NSDictionary *appConfigMessage = @{ @"id": @"register", @"name": name };
        
        NSData *message = [NSJSONSerialization dataWithJSONObject:appConfigMessage
                                                          options:NSJSONWritingPrettyPrinted
                                                            error:nil];
        
        [self sendData: message];
    }
}
- (void)call:(NSString *)from : (NSString *)to : (RTCSessionDescription *) description{
    if (_state == kARDWebSocketChannelStateOpen) {
        
        NSDictionary *callMessage = @{ @"id": @"call",
                                       @"to": to,
                                       @"from": from,
                                       @"sdpOffer": description.description };
        
        NSData *message = [NSJSONSerialization dataWithJSONObject:callMessage
                                                          options:NSJSONWritingPrettyPrinted
                                                            error:nil];
        
        [self sendData: message];
    }
}


- (void)incomingCallResponse:(NSString *)from : (RTCSessionDescription *) description{
    
    if (_state == kARDWebSocketChannelStateOpen) {
        
        NSDictionary *callMessage = @{ @"id": @"incomingCallResponse",
                                       @"from": from,
                                       @"callResponse": @"accept",
                                       @"sdpOffer": description.description };
        

        NSData *message = [NSJSONSerialization dataWithJSONObject:callMessage
                                                          options:NSJSONWritingPrettyPrinted
                                                            error:nil];
        
        [self sendData: message];
    }
}





- (void)sendData:(NSData *)data {
    NSString *payload =
        [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSString *messageString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"C->WSS: %@", messageString);
    [_socket send:messageString];
}

- (void)disconnect {
  if (_state == kARDWebSocketChannelStateClosed ||
      _state == kARDWebSocketChannelStateError) {
    return;
  }
  //[_socket close];
 // NSLog(@"we are not closing the websocket here anymore!:%@", _to, _from);
}

#pragma mark - SRWebSocketDelegate

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
  NSLog(@"WebSocket connection opened.");
  self.state = kARDWebSocketChannelStateOpen;
  [self getAppConfig];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    
    NSString *messageString = message;
    NSData *messageData = [messageString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSLog(@"message: %@",message);
    id jsonObject = [NSJSONSerialization JSONObjectWithData:messageData
                                                  options:0
                                                    error:nil];
  
    if (![jsonObject isKindOfClass:[NSDictionary class]]) {
      NSLog(@"Unexpected message: %@", jsonObject);
      return;
    }
    
    NSDictionary *wssMessage = jsonObject;
    NSString *errorString = wssMessage[kARDWSSMessageErrorKey];
  
    if (errorString.length) {
        NSLog(@"WSS error: %@", errorString);
        return;
    }
    
    NSString *payload = wssMessage[kARDWSSMessagePayloadKey];
     NSLog(@"WSS->C: %@", payload);
    if(wssMessage[kARDWSSMessageResultKey]!=NULL){
       payload = wssMessage[kARDWSSMessageParamsKey];
       
        //read appconfig here
        ARDRegisterResponse *response = [ARDRegisterResponse responseFromJSONData:messageData];
        
        //get iceServers from appConfig
        NSDictionary *dict = response.pcConfig[@"iceServers"];
       // NSDictionary *turnServers = [RTCIceServer serversFromCEODJSONDictionary:dict[kARDWSSMessageIceServersKey]];
        
        [_delegate channel:self setTurnServer:dict];
        
        [self registerFrom: ((ARDAppClient *) _delegate).from];
    }
    else{
        
        ARDSignalingMessage *signalingMessage = [ARDSignalingMessage messageFromJSONString:messageString];
    
        [_delegate channel:self didReceiveMessage:signalingMessage];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
  NSLog(@"WebSocket error: %@", error);
  self.state = kARDWebSocketChannelStateError;
}

- (void)webSocket:(SRWebSocket *)webSocket
    didCloseWithCode:(NSInteger)code
              reason:(NSString *)reason
            wasClean:(BOOL)wasClean {
    
  NSLog(@"WebSocket closed with code: %ld reason:%@ wasClean:%d", (long)code, reason, wasClean);
  NSParameterAssert(_state != kARDWebSocketChannelStateError);
  self.state = kARDWebSocketChannelStateClosed;
}

#pragma mark - Private

- (void)registerWithCollider {
  
    if (_state == kARDWebSocketChannelStateRegistered) {
        return;
    }
    
  NSParameterAssert(_to.length);
  NSParameterAssert(_from.length);
    
  NSDictionary *registerMessage = @{
    @"id": @"register",
    @"name" : _to
  };
    
  NSData *message =
      [NSJSONSerialization dataWithJSONObject:registerMessage
                                      options:NSJSONWritingPrettyPrinted
                                        error:nil];
  NSString *messageString =
      [[NSString alloc] initWithData:message encoding:NSUTF8StringEncoding];
    
  NSLog(@"Registering on WSS for from:%@ to:%@", _from, _to);
  // Registration can fail if server rejects it. For example, if the room is
  // full.
  [_socket send:messageString];
  self.state = kARDWebSocketChannelStateRegistered;
}

@end
