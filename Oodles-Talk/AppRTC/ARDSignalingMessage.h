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
#import <WebRTC/RTCIceCandidate.h>
#import <WebRTC/RTCSessionDescription.h>




typedef enum {
  kARDSignalingMessageTypeRegister,
  kARDSignalingMessageTypeRegisteredUsers,
  kARDSignalingMessageTypeRegisterResponse,
  kARDSignalingMessageTypeResponse,
  kARDSignalingMessageIncomingCall,
  kARDSignalingMessageIncomingScreenCall,
  kARDSignalingMessageStartCommunication,
  kARDSignalingMessageStartScreenCommunication,
  kARDSignalingMessageIncomingResponseCall,
  kARDSignalingMessageIncomingScreenResponseCall,
  kARDSignalingMessageTypeCandidate,
  kARDSignalingMessageTypeScreenCandidate,
  kARDSignalingMessageTypeOffer,
  kARDSignalingMessageTypeAnswer,
  kARDSignalingMessageTypeBye,
  kARDSignalingMessageTypeScreenBye,
  kARDSignalingMessageTypeCallback,
  kARDSignalingMessageTypePing,
  kARDSignalingMessageTypePong,
} ARDSignalingMessageType;

@interface ARDSignalingMessage : NSObject
//@interface YourViewController : UIViewController<UIAlertViewDelegate>

@property(nonatomic, readonly) ARDSignalingMessageType type;

+ (ARDSignalingMessage *)messageFromJSONString:(NSString *)jsonString;
- (NSData *)JSONData;

@end

@interface ARDRegisterResponseMessage : ARDSignalingMessage

@property(nonatomic, readonly) NSString *response;

- (instancetype)initWithString:(NSString *)response;
@end


@interface ARDStartCommunicationMessage : ARDSignalingMessage
@property(nonatomic, readonly) RTCSessionDescription *sessionDescription;
- (instancetype)initWithDescription:(RTCSessionDescription *)description;
@end

@interface ARDStartScreenCommunicationMessage : ARDSignalingMessage
@property(nonatomic, readonly) RTCSessionDescription *sessionDescription;
- (instancetype)initWithDescription:(RTCSessionDescription *)description;
@end

@interface ARDIncomingCallMessage : ARDSignalingMessage
@property(nonatomic, readonly) NSString *from;
@property(nonatomic, readonly) bool activeCall;
- (instancetype)initWithFromAndType:(NSString *) callFrom setActiveCall: (bool) activeCall;
@end

@interface ARDIncomingScreenCallMessage : ARDSignalingMessage
@property(nonatomic, readonly) NSString *from;
- (instancetype)initWithString:(NSString *)from;
@end

@interface ARDRegisteredUserMessage : ARDSignalingMessage
@property(nonatomic, readonly) NSArray *registeredUsers;
- (instancetype)initWithArray:(NSArray *) registeredUsers;
@end

@interface ARDICECandidateMessage : ARDSignalingMessage
@property(nonatomic, readonly) RTCIceCandidate *candidate;
- (instancetype)initWithCandidate:(RTCIceCandidate *)candidate;
@end
@interface ARDICEScreenCandidateMessage : ARDSignalingMessage
@property(nonatomic, readonly) RTCIceCandidate *candidate;
- (instancetype)initWithCandidate:(RTCIceCandidate *)candidate;
@end

@interface ARDSessionDescriptionMessage : ARDSignalingMessage

@property(nonatomic, readonly) RTCSessionDescription *sessionDescription;

- (instancetype)initWithDescription:(RTCSessionDescription *)description;

@end

@interface ARDIncomingCallResponseMessage : ARDSignalingMessage
@property(nonatomic, readwrite) NSString *from;
@end

@interface ARDIncomingScreenCallResponseMessage : ARDSignalingMessage
@property(nonatomic, readwrite) NSString *from;
@property(nonatomic, readwrite) NSString *to;
@end

@interface ARDByeMessage : ARDSignalingMessage
@property(nonatomic, readonly) bool callback;
- (instancetype)initWithCallback:(bool) callback;
@end

@interface ARDCallbackMessage : ARDSignalingMessage
- (instancetype)init;
@end

@interface ARDPingMessage : ARDSignalingMessage
- (instancetype)init;
@end

@interface ARDScreenByeMessage : ARDSignalingMessage
@end
