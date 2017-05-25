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
#import "RTCICECandidate+JSON.h"
#import "RTCSessionDescription+JSON.h"

static NSString const *kARDSignalingMessageIdKey = @"id";
static NSString const *kARDSignalingMessageMessageKey = @"message";

static NSString const *kARDSignalingMessageResponseKey = @"response";
static NSString const *kARDSignalingMessageFromKey = @"from";
static NSString const *kARDSignalingCallResponseKey = @"callResponse";

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
  if ([typeString isEqualToString:@"iceCandidate"]) {
        RTCIceCandidate *candidate = [RTCIceCandidate candidateFromJSONDictionary:values];
        message = [[ARDICECandidateMessage alloc] initWithCandidate:candidate];
  }
  else if ([typeString isEqualToString:@"registerResponse"]) {
      
      [[ARDRegisterResponseMessage alloc] initWithString: values[kARDSignalingMessageResponseKey]];
      NSLog(@"Received RegisterResponse: (%@) %@", values[kARDSignalingMessageResponseKey],
            values[kARDSignalingMessageMessageKey]);
  }
  
  else if ([typeString isEqualToString:@"callResponse"]) {
        if([values[@"response"]  isEqualToString:@"accepted"]){
                RTCSessionDescription *description = [RTCSessionDescription descriptionFromJSONDictionary:values];
                message = [[ARDSessionDescriptionMessage alloc] initWithDescription:description];
                NSLog(@"Received callResponse: (%@) %@", values[kARDSignalingMessageResponseKey],
                values[kARDSignalingMessageMessageKey]);
        }
  }
            
  else if ([typeString isEqualToString:@"incomingCall"]) {
    
      message = [[ARDIncomingCallMessage alloc] initWithString: values[@"from"]];
      NSLog(@"incomingCall incomingCall from: %@", values[@"from"]);
      
  }
    
  else if ([typeString isEqualToString:@"startCommunication"]) {
      NSLog(@"Received callResponse: %@", values);
      RTCSessionDescription *description =  [[RTCSessionDescription alloc] initWithType: @"answer" sdp:values[@"sdpAnswer"]];
      message = [[ARDStartCommunicationMessage alloc] initWithDescription: description];
     // RTCSessionDescription *description = [RTCSessionDescription descriptionFromJSONDictionary:values];
     // message = [[ARDSessionDescriptionMessage alloc] initWithDescription:description];
    
  }
  else if ([typeString isEqualToString:@"registeredUsers"]) {
    
     NSData* data = [values[@"response"] dataUsingEncoding:NSUTF8StringEncoding];
     NSError *e;
     NSArray *array = [NSJSONSerialization JSONObjectWithData:data options:nil error:&e];
    
      message = [[ARDRegisteredUserMessage alloc] initWithArray: array];
      NSLog(@"Received registeredUsers: (%@) ",array);
      
  } else if ([typeString isEqualToString:@"stopCommunication"]) {
    message = [[ARDByeMessage alloc] init];
  } else {
    NSLog(@"Unexpected type: %@ (which is not a problem!)", typeString);
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
    return [_candidate JSONData];
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

//@synthesize response = _response;
@synthesize from = _from;
- (instancetype)initWithString:(NSString *) response {
    if (self = [super initWithType: kARDSignalingMessageIncomingCall]) {
       // _response = response;
         _from = response;
    }
    return self;
}

//- (NSData *)JSONData {
//  return [_response JSONData];
//}

@end

@implementation ARDStartCommunicationMessage

//@synthesize response = _response;
@synthesize sessionDescription = _sessionDescription;
- (instancetype)initWithDescription:(RTCSessionDescription *)description {
//- (instancetype)initWithString:(NSString *) response {
    if (self = [super initWithType: kARDSignalingMessageStartCommunication]) {
//         _response = response;
        _sessionDescription = description;
    }
    return self;
}

//- (NSData *)JSONData {
//  return [_response JSONData];
//}

@end

@implementation ARDSessionDescriptionMessage

@synthesize sessionDescription = _sessionDescription;

- (instancetype)initWithDescription:(RTCSessionDescription *)description {
  ARDSignalingMessageType type = kARDSignalingMessageTypeOffer;
 
    
  //[description stringForType:description.type]
  //  if([description.type == (RTCSessionDescription *) RTCSdpType.RTCSdpTypeOffer]){
        
    //}
      
    /*NSString *typeString = description.type;
    
  if ([typeString isEqualToString:@"offer"]) {
    type = kARDSignalingMessageTypeOffer;
  } else if ([typeString isEqualToString:@"answer"]) {
    type = kARDSignalingMessageTypeAnswer;
  } else {
    NSAssert(NO, @"Unexpected type: %@", typeString);
  }
    */
  if (self = [super initWithType:description.type]) {
    _sessionDescription = description;
  }
  return self;
}

- (NSData *)JSONData {
  return [_sessionDescription JSONData];
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

@implementation ARDByeMessage

- (instancetype)init {
  return [super initWithType:kARDSignalingMessageTypeBye];
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
