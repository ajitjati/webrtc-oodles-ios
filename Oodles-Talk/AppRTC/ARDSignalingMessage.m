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

#import "ARDSignalingMessage.h"

#import "ARDUtilities.h"

static NSString const *kARDSignalingMessageIdKey = @"id";
static NSString const *kARDSignalingMessageMessageKey = @"message";

static NSString const *kARDSignalingMessageResponseKey = @"response";
static NSString const *kARDSignalingMessageFromKey = @"from";
static NSString const *kARDSignalingCallResponseKey = @"callResponse";

static NSString const *kRTCICECandidateTypeKey = @"id";
static NSString const *kRTCICECandidateTypeValue = @"onIceCandidate";
static NSString const *kRTCICECandidateMidKey = @"sdpMid";
static NSString const *kRTCICECandidateMLineIndexKey = @"sdpMLineIndex";
static NSString const *kRTCICECandidateSdpKey = @"candidate";
static NSString const *kARDSignalingCandidate = @"candidate";

@implementation ARDSignalingMessage

@synthesize type = _type;

- (instancetype)initWithType:(ARDSignalingMessageType)type {
  if (self = [super init]) {
    _type = type;
  }
  return self;
}

- (NSString *)description {
  return [[NSString alloc] initWithData:[self JSONData]
                               encoding:NSUTF8StringEncoding];
}

+ (ARDSignalingMessage *)messageFromJSONString:(NSString *)jsonString {
    
  NSDictionary *values = [NSDictionary dictionaryWithJSONString:jsonString];
  if (!values) {
      NSLog(@"Error parsing signaling message JSON. %@", jsonString);
    return nil;
  }

  NSString *typeString = values[kARDSignalingMessageIdKey];
 
  ARDSignalingMessage *message = nil;
  
  if ([typeString isEqualToString:@"registerResponse"]) {
      
      NSLog(@"Received RegisterResponse: (%@) %@", values[kARDSignalingMessageResponseKey],values[kARDSignalingMessageMessageKey]);
      
  }
    
  else if ([typeString isEqualToString:@"registeredUsers"]) {
      NSString *jsonUsers = values[@"response"];
      NSData *data =  [jsonUsers dataUsingEncoding:NSUTF8StringEncoding];
      
      NSError *e;
      NSArray *users = [NSJSONSerialization JSONObjectWithData:data options:0 error:&e];
     
      NSLog(@"Received registeredUsers: (%@) ",users);
      message = [[ARDRegisteredUserMessage alloc] initWithArray: users];
      
      
  }
  else if ([typeString isEqualToString:@"incomingCall"]) {
      
      NSLog(@"incomingCall incomingCall from: %@", values[@"from"]);
      bool activeCall = [values[@"screensharing"] length] != 0;
      message = [[ARDIncomingCallMessage alloc] initWithFromAndType: values[@"from"] setActiveCall: activeCall ];
      
  }
  else if ([typeString isEqualToString:@"incomingScreenCall"]) {
      
      NSLog(@"incomingScreenCall from: %@ ", values[@"from"]);
      message = [[ARDIncomingScreenCallMessage alloc] initWithString: values[@"from"]];
      
  }
  else if ([typeString isEqualToString:@"callResponse"]) {
      
      if([values[@"response"]  isEqualToString:@"accepted"]){
          
         RTCSessionDescription *description =  [[RTCSessionDescription alloc]
                                                 initWithType: RTCSdpTypeAnswer
                                                 sdp:values[@"sdpAnswer"]];
          
          
         message = [[ARDSessionDescriptionMessage alloc] initWithDescription:description];
          
      }else{ //otherwise this was a reject (should be equals to a bye message)
          message = [[ARDByeMessage alloc] init];
      }
      NSLog(@"Received callResponse: (%@) %@", values[kARDSignalingMessageResponseKey],values[kARDSignalingMessageMessageKey]);
      [[NSNotificationCenter defaultCenter] postNotificationName:@"UserNotRegistered" object:values[kARDSignalingMessageResponseKey]];
  }
  else if ([typeString isEqualToString:@"iceCandidate"]) {
    
      NSDictionary *dictionary = values[kARDSignalingCandidate];
      NSDictionary *subdict = dictionary;
      
      if([subdict[kARDSignalingCandidate] isKindOfClass:[NSDictionary class]]){
          subdict = dictionary[kARDSignalingCandidate];
      }
      
      NSString *mid = subdict[kRTCICECandidateMidKey];
      NSString *sdp = subdict[kRTCICECandidateSdpKey];
      NSNumber *num = subdict[kRTCICECandidateMLineIndexKey];
      
      RTCIceCandidate *candidate = [[RTCIceCandidate alloc] initWithSdp:sdp sdpMLineIndex:(int)[num integerValue] sdpMid:mid];
      message = [[ARDICECandidateMessage alloc] initWithCandidate:candidate];
      
  }
  else if ([typeString isEqualToString:@"iceCandidateScreen"]) {
      
      NSDictionary *dictionary = values[kARDSignalingCandidate];
      NSDictionary *subdict = dictionary;
      
      if([subdict[kARDSignalingCandidate] isKindOfClass:[NSDictionary class]]){
          subdict = dictionary[kARDSignalingCandidate];
      }
      
      NSString *mid = subdict[kRTCICECandidateMidKey];
      NSString *sdp = subdict[kRTCICECandidateSdpKey];
      NSNumber *num = subdict[kRTCICECandidateMLineIndexKey];
      
      RTCIceCandidate *candidate = [[RTCIceCandidate alloc] initWithSdp:sdp sdpMLineIndex:(int)[num integerValue] sdpMid:mid];
      message = [[ARDICEScreenCandidateMessage alloc] initWithCandidate:candidate];
      
  }
  else if ([typeString isEqualToString:@"startCommunication"]) {
      
      NSLog(@"Received callResponse: %@", values);
      RTCSessionDescription *description =  [[RTCSessionDescription alloc]
                                             initWithType: RTCSdpTypeAnswer
                                             sdp:values[@"sdpAnswer"]];
      
      message = [[ARDStartCommunicationMessage alloc] initWithDescription: description];
  }
  else if ([typeString isEqualToString:@"startScreenCommunication"]) {
      
      NSLog(@"Received callResponse: %@", values);
      RTCSessionDescription *description =  [[RTCSessionDescription alloc]
                                             initWithType: RTCSdpTypeAnswer
                                             sdp:values[@"sdpAnswer"]];
      
      message = [[ARDStartScreenCommunicationMessage alloc] initWithDescription: description];
  }
  else if ([typeString isEqualToString:@"stopCommunication"]) {
      bool callback = ([values[@"callback"] length] != 0);
      message = [[ARDByeMessage alloc] initWithCallback:callback];
  }
  else if ([typeString isEqualToString:@"stopScreenCommunication"]) {
      message = [[ARDScreenByeMessage alloc] init];
  }
  else if ([typeString isEqualToString:@"ping"]) {
      message = [[ARDPingMessage alloc] init];
  }
  else {
    NSLog(@"Received type: %@ and did nothing so far here", typeString);
  }
    
  return message;
}

- (NSData *)JSONData {
  return nil;
}

@end

@implementation ARDICECandidateMessage

@synthesize candidate = _candidate;

- (instancetype)initWithCandidate:(RTCIceCandidate *)candidate {
    if (self = [super initWithType:kARDSignalingMessageTypeCandidate]) {
        _candidate = candidate;
    }
    return self;
}

- (NSData *)JSONData {
    NSDictionary *json = @{
                           kRTCICECandidateTypeKey : kRTCICECandidateTypeValue,
                           kRTCICECandidateMLineIndexKey : @(_candidate.sdpMLineIndex),
                           kRTCICECandidateMidKey : _candidate.sdpMid,
                           kRTCICECandidateSdpKey : _candidate.sdp
                           };
    NSError *error = nil;
    NSData *data =  [NSJSONSerialization dataWithJSONObject:json
                                    options:NSJSONWritingPrettyPrinted
                                      error:&error];
    if (error) {
        NSLog(@"Error serializing JSON: %@", error);
        return nil;
    }
    return data;
}
@end

@implementation ARDICEScreenCandidateMessage

@synthesize candidate = _candidate;

- (instancetype)initWithCandidate:(RTCIceCandidate *)candidate {
    if (self = [super initWithType:kARDSignalingMessageTypeScreenCandidate]) {
        _candidate = candidate;
    }
    return self;
}

- (NSData *)JSONData {
    NSDictionary *json = @{
                           kRTCICECandidateTypeKey : kRTCICECandidateTypeValue,
                           kRTCICECandidateMLineIndexKey : @(_candidate.sdpMLineIndex),
                           kRTCICECandidateMidKey : _candidate.sdpMid,
                           kRTCICECandidateSdpKey : _candidate.sdp
                           };
    NSError *error = nil;
    NSData *data =  [NSJSONSerialization dataWithJSONObject:json
                                                    options:NSJSONWritingPrettyPrinted
                                                      error:&error];
    if (error) {
        NSLog(@"Error serializing JSON: %@", error);
        return nil;
    }
    return data;
}
@end

@implementation ARDRegisterResponseMessage

@synthesize response = _response;

- (instancetype)initWithString:(NSString *) response {
  if (self = [super initWithType:kARDSignalingMessageTypeRegisterResponse]) {
    _response = response;
  }
  return self;
}

@end

@implementation ARDRegisteredUserMessage

@synthesize registeredUsers = _registeredUsers;
- (instancetype)initWithArray:(NSArray *) registeredUsers{
    if (self = [super initWithType:kARDSignalingMessageTypeRegisteredUsers]) {
        _registeredUsers = registeredUsers;
    }
    return self;
}

@end


@implementation ARDIncomingCallMessage
@synthesize from = _from;
@synthesize activeCall = _activeCall;
- (instancetype)initWithFromAndType:(NSString *) callFrom setActiveCall: (bool) activeCall{
    if (self = [super initWithType: kARDSignalingMessageIncomingCall]) {
        _from = callFrom;
        _activeCall = activeCall;
    }
    return self;
}
@end

@implementation ARDIncomingScreenCallMessage
@synthesize from = _from;
- (instancetype)initWithString:(NSString *) from  {
    if (self = [super initWithType: kARDSignalingMessageIncomingScreenCall]) {
        _from = from;
    }
    return self;
}
@end

@implementation ARDStartCommunicationMessage
@synthesize sessionDescription = _sessionDescription;
- (instancetype)initWithDescription:(RTCSessionDescription *)description {

    if (self = [super initWithType: kARDSignalingMessageStartCommunication]) {
        _sessionDescription = description;
    }
    return self;
}
@end

@implementation ARDStartScreenCommunicationMessage
@synthesize sessionDescription = _sessionDescription;
- (instancetype)initWithDescription:(RTCSessionDescription *)description {
    
    if (self = [super initWithType: kARDSignalingMessageStartScreenCommunication]) {
        _sessionDescription = description;
    }
    return self;
}
@end

@implementation ARDSessionDescriptionMessage

@synthesize sessionDescription = _sessionDescription;

- (instancetype)initWithDescription:(RTCSessionDescription *)description {

  if (self = [super initWithType:kARDSignalingMessageTypeAnswer]) {
    _sessionDescription = description;
  }
  return self;
}

- (NSData *)JSONData {
    return nil;
}

@end

@implementation ARDIncomingCallResponseMessage
@synthesize from = _from;

- (instancetype)init {
    return [super initWithType:kARDSignalingMessageIncomingResponseCall];
}

- (NSData *)JSONData {
    NSDictionary *message = @{
                              @"id": @"incomingCallResponse",
                              @"from": _from,
                              @"callResponse": @"reject",
                              @"message": @"bussy"
                             };
    
    return [NSJSONSerialization dataWithJSONObject:message
                                           options:NSJSONWritingPrettyPrinted
                                             error:NULL];
}
@end

@implementation ARDCallbackMessage
- (instancetype)init {
    return [super initWithType:kARDSignalingMessageTypeCallback];
}
- (NSData *)JSONData {
    NSDictionary *message = @{
                              @"id": @"callback"
                              };
    return [NSJSONSerialization dataWithJSONObject:message
                                           options:NSJSONWritingPrettyPrinted
                                             error:NULL];
}
@end

@implementation ARDByeMessage
@synthesize callback = _callback;
- (instancetype)initWithCallback:(bool) callback {
  
    if (self = [super initWithType:kARDSignalingMessageTypeBye]) {
          _callback = callback;
    }
    
    return self;
}

- (NSData *)JSONData {
    
  NSDictionary *message = @{
        @"id": @"stop"
  };
    
  return [NSJSONSerialization dataWithJSONObject:message
                                         options:NSJSONWritingPrettyPrinted
                                           error:NULL];
}
@end

@implementation ARDScreenByeMessage
- (instancetype)init {
    return [super initWithType:kARDSignalingMessageTypeScreenBye];
}

- (NSData *)JSONData {
    NSDictionary *message = @{
                              @"id": @"stopScreen"
                              };
    return [NSJSONSerialization dataWithJSONObject:message
                                           options:NSJSONWritingPrettyPrinted
                                             error:NULL];
}
@end

@implementation ARDPingMessage
- (instancetype)init {
    return [super initWithType:kARDSignalingMessageTypePing];
}

- (NSData *)JSONData {
    NSDictionary *message = @{
                              @"id": @"pong"
                              };
    return [NSJSONSerialization dataWithJSONObject:message
                                           options:NSJSONWritingPrettyPrinted
                                             error:NULL];
}
@end
