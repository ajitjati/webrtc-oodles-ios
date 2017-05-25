//
//  RoomTableViewCell.m
//  Oodles Talk
//
//  Created by Aditya Sharma on 13/04/17.
//  Copyright © 2017 ISBX. All rights reserved.
//

#import "RoomTableViewCell.h"

@implementation RoomTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    _backView.layer.cornerRadius = 4.0;
    _chatPersonImageView.layer.cornerRadius = _chatPersonImageView.frame.size.width/2.0;
    _chatPersonImageView.clipsToBounds = YES;
    
    _backView.layer.shadowOffset = CGSizeMake(.5f,1.5f);
    _backView.layer.shadowRadius = 1.5f;
    _backView.layer.shadowOpacity = .7f;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
