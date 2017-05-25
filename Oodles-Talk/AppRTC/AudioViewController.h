//
//  AudioViewController.h
//  Oodles Talk
//
//  Created by Aditya Sharma on 28/04/17.
//  Copyright © 2017 ISBX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ARDAppClient.h"


@interface AudioViewController : UIViewController  <RTCEAGLVideoViewDelegate>

//Views, Labels, and Buttons

@property (strong, nonatomic) IBOutlet UIView *footerView;
@property (strong, nonatomic) IBOutlet UILabel *urlLabel;
@property (strong, nonatomic) IBOutlet UIView *buttonContainerView;
@property (strong, nonatomic) IBOutlet UIButton *audioButton;
@property (strong, nonatomic) IBOutlet UIButton *videoButton;
@property (strong, nonatomic) IBOutlet UIButton *hangupButton;
@property (strong, nonatomic) IBOutlet RTCEAGLVideoView *remoteView;
@property (strong, nonatomic) IBOutlet RTCEAGLVideoView *localView;
@property (strong, nonatomic) IBOutlet RTCEAGLVideoView *screenView;
@property (strong, nonatomic) ARDAppClient *client;
@property (strong, nonatomic) NSString *clientName;
@property (strong, nonatomic) UIImage *image;
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;

//Auto Layout Constraints used for animations
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *remoteViewTopConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *remoteViewRightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *remoteViewLeftConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *remoteViewBottomConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *footerViewBottomConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *buttonContainerViewLeftConstraint;

@property (weak, nonatomic) IBOutlet UILabel *timerLabel;
@property (strong, nonatomic) IBOutlet UIImageView *dataImageView;

@property (assign, nonatomic) CGSize localVideoSize;
@property (assign, nonatomic) CGSize remoteVideoSize;
@property (assign, nonatomic) CGSize screenVideoSize;
@property (assign, nonatomic) BOOL isZoom; //used for double tap remote view

//togle button parameter
@property (assign, nonatomic) BOOL isAudioMute;
@property (assign, nonatomic) BOOL isVideoMute;
@property (assign, nonatomic) BOOL isBackCamera;

//Activity Indicator
@property (assign, nonatomic) UIActivityIndicatorView *activityIndicator;

//Action
- (IBAction)audioButtonPressed:(id)sender;
- (IBAction)hangupButtonPressed:(id)sender;

@property(strong, nonatomic) AVAudioPlayer *player;
@property (nonatomic, assign) BOOL connectedCall;

@end
