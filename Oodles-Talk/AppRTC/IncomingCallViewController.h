//
//  IncomingCallViewController.h
//  MSCRTC
//
//  Created by Maneesh Madan on 05/05/17.
//  Copyright © 2017 ISBX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ARDAppClient.h"
#import <AVFoundation/AVFoundation.h>

@interface IncomingCallViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *callerName;
@property (weak, nonatomic) IBOutlet UIImageView *callerImage;
@property (weak, nonatomic) IBOutlet UIButton *declineButton;
@property (weak, nonatomic) IBOutlet UIButton *acceptButton;


- (IBAction)buttonTapped:(id)sender;


@property (weak, nonatomic) NSString *name;
@property (weak, nonatomic) UIImage *image;

@property (strong, nonatomic) ARDAppClient *client;
@property(strong, nonatomic) AVAudioPlayer *player;

@end
