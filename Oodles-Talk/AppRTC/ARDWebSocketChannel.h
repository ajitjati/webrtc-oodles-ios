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

#import "ARDSignalingMessage.h"

typedef NS_ENUM(NSInteger, ARDWebSocketChannelState) {
  // State when disconnected.
  kARDWebSocketChannelStateClosed,
  // State when connection is established but not ready for use.
  kARDWebSocketChannelStateOpen,
  // State when connection is established and registered.
  kARDWebSocketChannelStateRegistered,
  // State when connection encounters a fatal error.
  kARDWebSocketChannelStateError
};

@class ARDWebSocketChannel;
@protocol ARDWebSocketChannelDelegate <NSObject>

- (void)channel:(ARDWebSocketChannel *)channel
    didChangeState:(ARDWebSocketChannelState)state;

- (void)channel:(ARDWebSocketChannel *)channel
    didReceiveMessage:(ARDSignalingMessage *)message;

- (void)channel:(ARDWebSocketChannel *)channel
    setTurnServer:(NSArray *)turnservers;

@end

// Wraps a WebSocket connection to the AppRTC WebSocket server.
@interface ARDWebSocketChannel : NSObject

@property(nonatomic, assign)   NSArray *pcConfig;
@property(nonatomic, readonly) NSString *to;
@property(nonatomic, readonly) NSString *from;
@property(nonatomic, readonly) ARDWebSocketChannelState state;
@property(nonatomic, weak) id<ARDWebSocketChannelDelegate> delegate;

- (instancetype)initWithURL:(NSURL *)url
                   delegate:(id<ARDWebSocketChannelDelegate>)delegate;


- (void)getAppConfig;
- (void)registerFrom:(NSString *)name;
- (void)call:(NSString *)from : (NSString *)to : (RTCSessionDescription *) description;
- (void)incomingCallResponse:(NSString *)from : (RTCSessionDescription *) description;
- (void)incomingScreenCallResponse:(NSString *)from : (RTCSessionDescription *) description;

- (void)sendData:(NSData *)data;

@end
