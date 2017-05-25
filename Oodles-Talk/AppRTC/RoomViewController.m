//
//  RoomViewController.m
//  Oodles Talk
//
//  Created by Aditya Sharma on 12/04/17.
//  Copyright © 2017 ISBX. All rights reserved.
//

#import "AppDelegate.h"
#import "RoomViewController.h"
#import "VideoChatViewController.h"
#import "AudioViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "MBProgressHUD.h"
#import "LoginViewController.h"

@implementation RoomViewController  {
    SystemSoundID soundID;
}

double delayInSeconds = 20.0;


- (void)viewDidLoad {
    [super viewDidLoad];
    
    _userListTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(serverFoundOffline:)
                                                 name:@"ServerFoundOffline"
                                               object:nil];
    
    NSURL *url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/0063.wav", [[NSBundle mainBundle] resourcePath]]];
    NSError *error;
    _player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    _player.numberOfLoops = -1;
    NSLog(@"NAME: %@", [[NSUserDefaults standardUserDefaults] valueForKey:@"MY_USERNAME"]);
    
    self.definesPresentationContext = YES;
    self.searchResults = [NSMutableArray arrayWithCapacity:[self.registeredUsers count]];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[self navigationController] setNavigationBarHidden:NO animated:YES];
    
    //Connect to the room
    if(self.client == nil){
        self.client = [[ARDAppClient alloc] initWithDelegate:self];
        [self.client connectToWebsocket : false];
    }
    
    //    if ([_userListTableView numberOfRowsInSection:0] < 1) {
    [self updateTableList];
    //    }
    
    self.client.registeredUserdelegate = self;
    
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ServerFoundOffline" object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void) serverOfflineView {
    UIView *bacView = [[UIView alloc] initWithFrame: _userListTableView.backgroundView.bounds];
    [_userListTableView.backgroundView addSubview: bacView];
    
    UIImageView *offlineImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, _userListTableView.frame.size.width, 250)];
    offlineImageView.contentMode = UIViewContentModeScaleAspectFit;
    offlineImageView.image = [UIImage imageNamed:@"Server_offline"];
    [bacView addSubview:offlineImageView];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, offlineImageView.frame.origin.y - 40, _userListTableView.frame.size.width, 40)];
    label.text = @"Oops! Server is not working. Please try after some time!";
    [bacView addSubview:label];
    
}
- (void)serverFoundOffline:(NSNotification *)notification{
    [self alertView: @"Oops! Server is not working. Please try after some time!" from:@"offline"];
    
}

- (void)alertView:(NSString *)message from:(NSString *)from {
    NSLog(@"Server Offline");
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Note" message:message preferredStyle:UIAlertControllerStyleAlert];
    if ([from isEqualToString:@"offline"]) {
        UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler: nil];
        [alert addAction:yesButton];
    }else {
        UIAlertAction* cancelButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
            
        }];
        
        UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"Open Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        }];
        
        [alert addAction:cancelButton];
        [alert addAction:yesButton];
    }
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Search

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    [self.searchResults removeAllObjects];
    
    NSPredicate *namePredicate = [NSPredicate predicateWithFormat:@"fullName contains[c] %@",searchText];
    
    self.searchResults = [NSMutableArray arrayWithArray: [self.registeredUsers filteredArrayUsingPredicate:namePredicate]];
    
    [_userListTableView reloadData];
    
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    [self filterContentForSearchText:searchString scope:[[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    _userListTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [_searchResults count];
    } else {
        return [self.registeredUsers count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"cell";
    
    RoomTableViewCell *cell = [self.userListTableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    [cell.voiceCall addTarget: self action: @selector(voiceCallButtonTapped:) forControlEvents: UIControlEventTouchUpInside];
    [cell.videoCall addTarget: self action: @selector(videoCallButtonTapped:) forControlEvents: UIControlEventTouchUpInside];
    
    AudioViewController *viewController = [[AudioViewController alloc] init];
    viewController.image = self.registeredUsers[indexPath.row][@"userImage"];
    
    VideoChatViewController *videoViewController = [[VideoChatViewController alloc] init];
    videoViewController.connectedCall = NO;
    
    NSString *value = self.registeredUsers[indexPath.row][@"fullName"];
    NSCharacterSet *set = [NSCharacterSet whitespaceCharacterSet];
    
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        
        if (![value stringByTrimmingCharactersInSet: set].length) {
            cell.chatNameLabel.text = _searchResults[indexPath.row][@"PhoneNumbers"];
        }else {
            cell.chatNameLabel.text = _searchResults[indexPath.row][@"fullName"];
        }
        
        cell.chatPersonImageView.image = _searchResults[indexPath.row][@"userImage"];
        if ( [self.onlineUsers containsObject:_searchResults[indexPath.row][@"PhoneNumbers"]] ) {
            cell.statusImageView.image = [UIImage imageNamed:@"online"];
        }else {
            cell.statusImageView.image = [UIImage imageNamed:@"offline"];
        }
    } else {
        if (![value stringByTrimmingCharactersInSet: set].length) {
            cell.chatNameLabel.text = self.registeredUsers[indexPath.row][@"PhoneNumbers"];
        }else {
            cell.chatNameLabel.text = self.registeredUsers[indexPath.row][@"fullName"];
        }
        
        cell.chatPersonImageView.image = self.registeredUsers[indexPath.row][@"userImage"];
        if ( [self.onlineUsers containsObject:self.registeredUsers[indexPath.row][@"PhoneNumbers"]] ){
            cell.statusImageView.image = [UIImage imageNamed:@"online"];
        }else {
            cell.statusImageView.image = [UIImage imageNamed:@"offline"];
        }
    }
    
    _userListTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [cell setNeedsLayout];
    
    return cell;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80;
}

- (void)updateTable:(NSArray *)registeringUser{
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        self.onlineUsers =  [[NSMutableArray alloc] init];
        self.onlineUsers = [registeringUser mutableCopy];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.userListTableView reloadData];
        });
    });
}

- (void) removeRegisteredUser:(NSString *)username{
    if ([self.registeredUsers containsObject:username]) {
        // NSMutableArray *newArray = [NSMutableArray arrayWithArray: self.registeredUsers ];
        // [self.registeredUsers removeObject: @"support"];
        // self.registeredUsers = newArray;
    }
}

- (void) updateTableList {
    self.registeredUsers =  [[NSMutableArray alloc] init];
    AppDelegate* appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.registeredUsers = appDelegate.arrayTableData;
    
    [self.userListTableView reloadData];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    //    RoomTableViewCell *cell = (RoomTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    //
    //    [self toTextInputViewCell:cell shouldVideoCallUser:self.registeredUsers[indexPath.row][@"PhoneNumbers"]];
    //    _clientName = self.registeredUsers[indexPath.row][@"fullName"];
    //    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)disconnect {
    if (self.client) {
        if (self.client.localVideoTrack) [self.client.localVideoTrack removeRenderer:self.client.localView];
        if (self.client.remoteVideoTrack) [self.client.remoteVideoTrack removeRenderer:self.client.remoteView];
        self.client.localVideoTrack = nil;
        [self.client.localView renderFrame:nil];
        self.client.remoteVideoTrack = nil;
        [self.client.remoteView renderFrame:nil];
        [self.client disconnect:true useCallback:false];
    }
}


- (void)toTextInputViewCell:(UITableViewCell *)cell shouldVideoCallUser:(NSString *)to {
    NSLog(@"To******** : %@", to);
    
    self.client.to = to;
    self.client.isInitiator = TRUE;
    [self performSegueWithIdentifier:@"RoomViewToVideoChatViewControllerSegue" sender:self.client];
}

- (void)toTextInputViewCell:(UITableViewCell *)cell shouldAudioCallUser:(NSString *)to {
    NSLog(@"To******** : %@", to);
    
    self.client.to = to;
    self.client.isInitiator = TRUE;
    [self performSegueWithIdentifier:@"RoomViewToAudioChatViewControllerSegue" sender:self.client];
}


#pragma mark - UITextFieldDelegate Methods

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    BOOL isBackspace = [string isEqualToString:@""] && range.length == 1;
    NSString *text = [NSString stringWithFormat:@"%@%@", textField.text, string];
    if (isBackspace && text.length > 1) {
        text = [text substringWithRange:NSMakeRange(0, text.length-2)];
    }
    if (text.length >= 5) {
        [UIView animateWithDuration:0.3f animations:^{
            [self.errorLabelHeightConstraint setConstant:0.0f];
            //  [self.textFieldBorderView setBackgroundColor:[UIColor colorWithRed:66.0f/255.0f green:133.0f/255.0f blue:244.0f/255.0f alpha:1.0f]];
            [self.joinButton setBackgroundColor:[UIColor colorWithRed:66.0f/255.0f green:133.0f/255.0f blue:244.0f/255.0f alpha:1.0f]];
            [self.joinButton setEnabled:YES];
            [self.view layoutIfNeeded];
        }];
    } else {
        [UIView animateWithDuration:0.3f animations:^{
            [self.errorLabelHeightConstraint setConstant:40.0f];
            //  [self.textFieldBorderView setBackgroundColor:[UIColor colorWithRed:244.0f/255.0f green:67.0f/255.0f blue:54.0f/255.0f alpha:1.0f]];
            [self.joinButton setBackgroundColor:[UIColor colorWithWhite:100.0f/255.0f alpha:1.0f]];
            [self.joinButton setEnabled:NO];
            [self.view layoutIfNeeded];
        }];
    }
    return YES;
}

#pragma mark - ARDAppClientDelegate
- (void) appClient:(ARDAppClient *)client didChangeSignalingState:(ARDAppClientState)state {
    NSLog(@"Signalling state: %ld", (long)state);
}

- (void)appClient:(ARDAppClient *)client didChangeState:(ARDAppClientState)state {
    switch (state) {
            case kARDAppClientStateConnected:
            NSLog(@"Client connected.");
            break;
            case kARDAppClientStateConnecting:
            NSLog(@"Client connecting.");
            break;
            case kARDAppClientStateDisconnected:
            NSLog(@"Client disconnected.");
            [self.navigationController popToRootViewControllerAnimated:YES];
            break;
            case kARDAppClientIceFinished:
            NSLog(@"Client connecting.");
            break;
    }
}

- (void)appClient:(ARDAppClient *)client incomingCallRequest:(NSString *)from : (BOOL) activeCall{
    NSLog(@" incoming call from %@",from);
    _connectedCall = NO;
    int i;
    NSString *callerName;
    for (i = 0; i < self.registeredUsers.count; i++) {
        if ([from isEqual: self.registeredUsers[i][@"PhoneNumbers"]]){
            callerName = self.registeredUsers[i][@"fullName"];
            break;
        }else {
            callerName = from;
        }
    }
    
    NSString *message =  [NSString stringWithFormat:@"incoming call from '%@'", callerName];
    
    //    AudioServicesPlaySystemSoundWithCompletion(1151,  ^{
    //        AudioServicesPlaySystemSound(1151);
    //    });
    
    if (_player != nil)
    [_player play];
    
    
    self.client.to = from;
    self.client.from = [[NSUserDefaults standardUserDefaults] stringForKey:@"MY_USERNAME"];
    if(!activeCall){
        
        
        
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Incoming call..."
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:@"Hangup"
                                              otherButtonTitles:@"Answer call",nil];
        [alert show];
        
        dispatch_queue_t myCustomQueue;
        myCustomQueue = dispatch_queue_create("com.example.MyQueue", NULL);
        
        dispatch_async(myCustomQueue, ^ {
            [NSThread sleepForTimeInterval:20];
        });
        
        dispatch_async(myCustomQueue, ^ {
            NSLog(@"Task1");
            if (_connectedCall == NO) {
                [alert dismissWithClickedButtonIndex:0 animated:YES];
            }
        });
        
        
        //        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        //
        //        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        //            NSLog(@"Do some work");
        //
        //        });
        
    }
    else{
        self.client.isInitiator = FALSE;
        
        VideoChatViewController *videoViewController = [[VideoChatViewController alloc] init];
        videoViewController.connectedCall = YES;
        [self performSegueWithIdentifier:@"RoomViewToVideoChatViewControllerSegue" sender:self.client];
        //        [self performSegueWithIdentifier:@"RoomViewToAudioChatViewControllerSegue" sender:self.client];
        
    }
    
}

- (void)appClient:(ARDAppClient *)client incomingScreenCallRequest:(NSString *)from {
    NSLog(@" incoming screencall from %@",from);
    
    self.client.to = from;
    self.client.from = [[NSUserDefaults standardUserDefaults] stringForKey:@"MY_USERNAME"];
    
    [self.client startSignalingScreensharing];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    //    AudioServicesDisposeSystemSoundID(soundID);
    if (_player != nil)
    [_player stop];
    _connectedCall = YES;
    if (buttonIndex == 0) {
        NSLog(@"Cancel Tapped.");
        
        ARDIncomingCallResponseMessage *message = [[ARDIncomingCallResponseMessage alloc] init];
        message.from = self.client.to;
        [self.client sendSignalingMessageToCollider: message];
        
    }else if (buttonIndex == 1) {
        self.client.isInitiator = FALSE;
        
        [self performSegueWithIdentifier:@"RoomViewToVideoChatViewControllerSegue" sender:self.client];
    }
}


- (void)reloadData:(BOOL)animated
{
    NSLog(@"Reloading");
    self.registeredUsers =  [[NSMutableArray alloc] init];
    [self.registeredUsers removeAllObjects];
    AppDelegate* appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.registeredUsers = appDelegate.arrayTableData;
    
    NSLog(@"%@", self.registeredUsers);
    
    
    [self.userListTableView reloadData];
    NSRange range = NSMakeRange(0, 0);
    NSIndexSet *section = [NSIndexSet indexSetWithIndexesInRange:range];
    [self.userListTableView reloadSections:section withRowAnimation: UITableViewRowAnimationLeft];
    
    //    if (animated) {
    //
    //        CATransition *animation = [CATransition animation];
    //        [animation setType:kCATransitionPush];
    //        [animation setSubtype:kCATransitionFromBottom];
    //        [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    //        [animation setFillMode:kCAFillModeBoth];
    //        [animation setDuration:.3];
    //        [[self.userListTableView layer] addAnimation:animation forKey:@"UITableViewReloadDataAnimationKey"];
    //    }
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)param {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    if ([segue.identifier  isEqual: @"RoomViewToVideoChatViewControllerSegue"]) {
        VideoChatViewController *viewController = (VideoChatViewController *)[segue destinationViewController];
        viewController.connectedCall = _connectedCall;
        [viewController setClient: param];
    }else if ([segue.identifier  isEqual: @"RoomViewToAudioChatViewControllerSegue"]) {
        AudioViewController *viewController = (AudioViewController *)[segue destinationViewController];
        viewController.connectedCall = _connectedCall;
        [viewController setClient: param];
    }
}

- (IBAction)voiceCallButtonTapped:(id)sender {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = @"Loading...";
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
                if (granted) {
                    NSLog(@"Permission granted");
                    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView: _userListTableView];
                    NSIndexPath *indexPath = [_userListTableView indexPathForRowAtPoint:buttonPosition];
                    
                    NSLog(@"Selected Index: %ld", (long)indexPath.row);
                    
                    RoomTableViewCell *cell = (RoomTableViewCell *)[_userListTableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath: indexPath];
                    
                    if ([self.searchDisplayController isActive]) {
                        [self toTextInputViewCell:cell shouldAudioCallUser:self.searchResults[ indexPath.row][@"PhoneNumbers"]];
                        _clientName = self.searchResults[ indexPath.row][@"fullName"];
                    }else{
                        [self toTextInputViewCell:cell shouldAudioCallUser:self.registeredUsers[ indexPath.row][@"PhoneNumbers"]];
                        _clientName = self.registeredUsers[ indexPath.row][@"fullName"];
                    }
                    [_userListTableView deselectRowAtIndexPath: indexPath animated:YES];
                }
                else {
                    NSLog(@"Permission denied");
                    [self alertView:@"Please allow to access microphone." from:@"permission"];
                }
            }];
        });
    });
}

- (IBAction)videoCallButtonTapped:(id)sender {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = @"Loading...";
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if ([AVCaptureDevice respondsToSelector:@selector(requestAccessForMediaType: completionHandler:)]) {
                [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                    if (granted) {
                        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
                            if (granted) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    
                                    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView: _userListTableView];
                                    NSIndexPath *indexPath = [_userListTableView indexPathForRowAtPoint:buttonPosition];
                                    NSLog(@"Selected Index: %ld", (long)indexPath.row);
                                    
                                    RoomTableViewCell *cell = (RoomTableViewCell *)[_userListTableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath: indexPath];
                                    
                                    if ([self.searchDisplayController isActive]) {
                                        [self toTextInputViewCell:cell shouldVideoCallUser:self.searchResults[ indexPath.row][@"PhoneNumbers"]];
                                        _clientName = self.searchResults[ indexPath.row][@"fullName"];
                                    }else {
                                        [self toTextInputViewCell:cell shouldVideoCallUser:self.registeredUsers[ indexPath.row][@"PhoneNumbers"]];
                                        _clientName = self.registeredUsers[ indexPath.row][@"fullName"];
                                    }
                                    
                                    [_userListTableView deselectRowAtIndexPath: indexPath animated:YES];
                                });
                            } else {
                                NSLog(@"Permission denied");
                                [self alertView:@"Please allow to access microphone." from:@"permission"];
                            }
                        }];
                    }else {
                        NSLog(@"Permission denied");
                        [self alertView:@"Please allow to access camera for Video call." from:@"permission"];
                    }
                }];
            }
        });
    });
}

- (IBAction)logOutTapped:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"loginSuccessful"];
    //    [self dismissViewControllerAnimated:YES completion: nil];
    
    //    [self performSegueWithIdentifier:@"unwindToLogin" sender:self];
    
    UIViewController *rootController =(UIViewController*)[[(AppDelegate*)[[UIApplication sharedApplication]delegate] window] rootViewController];
    
    NSLog(@"%@", rootController);
    LoginViewController *loginViewController = (LoginViewController*)[self.storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
    
    if (rootController == loginViewController){
        [self performSegueWithIdentifier:@"logoutSegue" sender:self];
        
    }else {
        [self performSegueWithIdentifier:@"logoutSegue" sender:self];
        
    }
    
}
@end
