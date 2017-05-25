//
//  AppDelegate.h
//  AppRTC
//
//  Created by Aditya Sharma on 3/7/15.
//  Copyright (c) 2017 ISBX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PushKit/PushKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, PKPushRegistryDelegate>

@property (strong, nonatomic) UIWindow *window;
@property(nonatomic,retain) NSMutableArray *arrayTableData;

@property (strong, nonatomic) UIStoryboard *storyboard;

-(void)fetchContactsandAuthorization;
@end

