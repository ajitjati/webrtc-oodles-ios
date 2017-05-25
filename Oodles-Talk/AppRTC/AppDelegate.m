//
//  AppDelegate.m
//  AppRTC
//
//  Created by Aditya Sharma on 3/7/15.
//  Copyright (c) 2017 ISBX. All rights reserved.
//

#import "AppDelegate.h"
#import <WebRTC/RTCPeerConnectionFactory.h>
#import <Contacts/Contacts.h>
#import "RoomViewController.h"
#import "LoginViewController.h"
#import "DashboardNavigationViewController.h"

@implementation AppDelegate

@synthesize arrayTableData = _arrayTableData;



- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    [self setNotificationDefaults: launchOptions];
    [RTCPeerConnectionFactory initialize];
    _arrayTableData = [[NSMutableArray alloc] init];
    [self isLogin];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    NSLog(@"applicationWillResignActive");
    
    // [[NSNotificationCenter defaultCenter]
    //  postNotificationName:@"UIApplicationDidEnterBackgroundNotification" object:nil];
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    NSLog(@"applicationDidEnterBackground");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UIApplicationDidEnterBackgroundNotification" object:nil];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    NSLog(@"applicationWillEnterForeground");
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    NSLog(@"UIApplicationDidBecomeActiveNotification");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UIApplicationDidBecomeActiveNotification" object:nil];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    // [RTCPeerConnectionFactory dealloc];
    
}

- (void)handleLocalNotification:(UILocalNotification *)notification {
//    if (notification) {
//        id<SINNotificationResult> result = [self.client relayLocalNotification:notification];
//        if ([result isCall] && [[result callResult] isTimedOut]) {
//            UIAlertView *alert = [[UIAlertView alloc]
//                                  initWithTitle:@"Missed call"
//                                  message:[NSString stringWithFormat:@"Missed call from %@", [[result callResult] remoteUserId]]
//                                  delegate:nil
//                                  cancelButtonTitle:nil
//                                  otherButtonTitles:@"OK", nil];
//            [alert show];
//        }
//    }
}

#pragma mark - PushKit

-(void) setNotificationDefaults:(NSDictionary *)launchOptions {
    UIUserNotificationSettings* notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
    
    [self handleLocalNotification:[launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey]];
}

-(void)voipRegistration
{
    PKPushRegistry* voipRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
    voipRegistry.delegate = self;
    voipRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
}

-(void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(NSString *)type
{
//    [_client registerPushNotificationData:credentials.token];
}

-(void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(NSString *)type
{
    //notify
    NSDictionary* dic = payload.dictionaryPayload;
    NSString* sinchinfo = [dic objectForKey:@"sin"];
    UILocalNotification* notif = [[UILocalNotification alloc] init];
    notif.alertBody = @"incoming call";
    [[UIApplication sharedApplication] presentLocalNotificationNow:notif];
    if (sinchinfo == nil)
    return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
//        [_client relayRemotePushNotificationPayload:sinchinfo];
    });
    
}

#pragma mark - Login check
-(void) isLogin {
    BOOL isLogin = [[NSUserDefaults standardUserDefaults]boolForKey:@"loginSuccessful"];
    NSLog(@"Login Status %hhd",isLogin);

    if (isLogin == NO)
    {
        LoginViewController *loginViewController = (LoginViewController*)[self.storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
        self.window.rootViewController = loginViewController;
    }
    else
    {
        [self fetchContactsandAuthorization];
        DashboardNavigationViewController *homeView = [self.storyboard instantiateViewControllerWithIdentifier:@"DashboardNavigationViewController"];
        self.window.rootViewController = homeView;
    }
}

#pragma mark - Fetch Contacts

//This method is for fetching contacts from iPhone.Also It asks authorization permission.
-(void)fetchContactsandAuthorization
{
    
    [_arrayTableData removeAllObjects];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // Request authorization to Contacts
        CNContactStore *store = [[CNContactStore alloc] init];
        [store requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if (granted == YES)
            {
                //keys with fetching properties
                NSArray *keys = @[CNContactFamilyNameKey, CNContactGivenNameKey, CNContactPhoneNumbersKey, CNContactImageDataKey];
                NSString *containerId = store.defaultContainerIdentifier;
                NSPredicate *predicate = [CNContact predicateForContactsInContainerWithIdentifier:containerId];
                NSError *error;
                NSArray *cnContacts = [store unifiedContactsMatchingPredicate:predicate keysToFetch:keys error:&error];
                if (error)
                {
                    NSLog(@"error fetching contacts %@", error);
                }
                else
                {
                    NSString *phone;
                    NSString *cleanedPhoneNumber;
                    NSString *fullName;
                    NSString *firstName;
                    NSString *lastName;
                    UIImage *profileImage;
                    NSMutableArray *contactNumbersArray = [[NSMutableArray alloc]init];
                    for (CNContact *contact in cnContacts) {
                        // copy data to my custom Contacts class.
                        firstName = contact.givenName;
                        lastName = contact.familyName;
                        if (lastName == nil) {
                            fullName=[NSString stringWithFormat:@"%@",firstName];
                        }else if (firstName == nil){
                            fullName=[NSString stringWithFormat:@"%@",lastName];
                        }
                        else{
                            fullName=[NSString stringWithFormat:@"%@ %@",firstName,lastName];
                            if ([fullName length] == 0) {
                                fullName=@"--";
                            }
                        }
                        UIImage *image = [UIImage imageWithData:contact.imageData];
                        if (image != nil) {
                            profileImage = image;
                        }else{
                            profileImage = [UIImage imageNamed: @"User"];
                        }
                        for (CNLabeledValue *label in contact.phoneNumbers) {
                            phone = [label.value stringValue];
                            cleanedPhoneNumber = [[phone componentsSeparatedByCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet]] componentsJoinedByString:@""];
                            
                            if ([phone length] > 0) {
                                [contactNumbersArray addObject:cleanedPhoneNumber];
                            }
                        }
                        NSString* from = [[NSUserDefaults standardUserDefaults] stringForKey:@"MY_USERNAME"];
                        
                        if (![from isEqualToString: cleanedPhoneNumber]) {
                            NSDictionary* personDict = [[NSDictionary alloc] initWithObjectsAndKeys: fullName,@"fullName",profileImage,@"userImage",cleanedPhoneNumber,@"PhoneNumbers", nil];
                            [_arrayTableData addObject:personDict];
                        }
                        
                        phone = @"";
                        cleanedPhoneNumber = @"";
                        fullName = @"";
                        firstName = @"";
                        lastName = @"";
                    }
                    
                    NSLog(@"The contactsArray are - %@",_arrayTableData);
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSLog(@"Synced Contacts");
                        RoomViewController *roomViewController = [[RoomViewController alloc] init];
                        [roomViewController reloadData:YES];
                        
                    });
                }
            }else {
                NSLog(@"Contact not allowed");
            }
        }];
    });
}

+(NSString *)filterString:(NSString *)subject filter:(NSString *)filter {
    NSString *cleanedString = [[subject componentsSeparatedByCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:filter] invertedSet]] componentsJoinedByString:@""];
    return cleanedString;
}

@end
