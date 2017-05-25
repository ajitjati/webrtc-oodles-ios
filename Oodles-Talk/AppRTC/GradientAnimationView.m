//
//  GradientAnimationView.m
//  MSCRTC
//
//  Created by Maneesh Madan on 09/05/17.
//  Copyright © 2017 ISBX. All rights reserved.
//

#import "GradientAnimationView.h"


@implementation GradientAnimationView {
    NSArray *_colorsFirst;
    NSArray *_colorsSecond;
    NSArray *_currentColor;
}

+ (Class)layerClass {
    return [CAGradientLayer class];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        CAGradientLayer *layer = (CAGradientLayer *)[self layer];
        _colorsFirst = @[(__bridge id)[[UIColor blueColor] CGColor], (__bridge id)[[UIColor greenColor] CGColor]];
        _colorsSecond = @[(__bridge id)[[UIColor redColor] CGColor], (__bridge id)[[UIColor yellowColor] CGColor]];
        _currentColor = _colorsFirst;
        [layer setColors:_colorsFirst];
    }
    return self;
}

- (void)animateColors {
    if (_currentColor == _colorsSecond) {
        _currentColor = _colorsFirst;
    } else {
        _currentColor = _colorsSecond;
    }
    
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"colors"];
    anim.fromValue = [[self layer] valueForKey:@"colors"];
    anim.toValue = _currentColor;
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    anim.duration = 0.4;
    anim.delegate = self;
    
    [self.layer addAnimation:anim forKey:@"colors"];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self animateColors];
}

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag {
    CAGradientLayer *layer = (CAGradientLayer *)[self layer];
    [layer setColors:_currentColor];
}

@end
