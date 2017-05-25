//
//  GradientAnimationView.h
//  MSCRTC
//
//  Created by Maneesh Madan on 09/05/17.
//  Copyright © 2017 ISBX. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GradientAnimationView : UIView

- (id)initWithFrame:(CGRect)frame;

+ (Class)layerClass;

- (void)animateColors;

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag;

@end
