//
//  RoomViewController.h
//  Oodles Talk
//
//  Created by Aditya Sharma on 12/04/17.
//  Copyright © 2017 ISBX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RoomTableViewCell.h"
#import "ARDAppClient.h"
#import "MBProgressHUD.h"

@interface RoomViewController : UIViewController <ARDAppClientDelegate,ARDAppClientUpdateUserTableDelegate,UITableViewDataSource,UITableViewDelegate,UISearchDisplayDelegate, UISearchControllerDelegate,UISearchBarDelegate>

@property (strong, nonatomic) NSString *to;
@property (strong, nonatomic) ARDAppClient *client;
@property (strong, nonatomic) NSIndexPath *selectedIndexPath;

@property (strong, nonatomic) NSMutableArray *registeredUsers;
@property (nonatomic, strong) NSMutableArray *searchResults;

@property (strong, nonatomic) NSMutableArray *onlineUsers;
@property (strong, nonatomic) IBOutlet UIButton *joinButton;
@property (strong, nonatomic) IBOutlet UILabel *errorLabel;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *errorLabelHeightConstraint; //used for animating
@property (strong, nonatomic) IBOutlet UITableView *userListTableView;
@property (strong, nonatomic) IBOutlet UIView *optionView;
- (IBAction)logOutTapped:(id)sender;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@property (strong, nonatomic) UISearchController *searchController;


@property(strong, nonatomic) AVAudioPlayer *player;
@property (strong, nonatomic) NSString *clientName;
@property (nonatomic, assign) BOOL connectedCall;

- (void)toTextInputViewCell:(UITableViewCell *)cell shouldVideoCallUser:(NSString *)to;
- (void)toTextInputViewCell:(UITableViewCell *)cell shouldAudioCallUser:(NSString *)to;

- (void)reloadData:(BOOL)animated;

@end
