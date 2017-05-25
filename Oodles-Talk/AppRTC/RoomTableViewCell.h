//
//  RoomTableViewCell.h
//  Oodles Talk
//
//  Created by Aditya Sharma on 13/04/17.
//  Copyright © 2017 ISBX. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RoomTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *statusImageView;

@property (weak, nonatomic) IBOutlet UILabel *chatNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *chatPersonImageView;
@property (weak, nonatomic) IBOutlet UIView *backView;
@property (weak, nonatomic) IBOutlet UIButton *voiceCall;
@property (weak, nonatomic) IBOutlet UIButton *videoCall;



@end
