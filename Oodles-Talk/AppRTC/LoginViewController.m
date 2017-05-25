//
//  LoginViewController.m
//  Oodles Talk
//
//  Created by Aditya Sharma on 12/04/17.
//  Copyright © 2017 ISBX. All rights reserved.
//

#import "AppDelegate.h"
#import "LoginViewController.h"
#import "MBProgressHUD.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _userNameTextField.text = @"9899923127";
    _passwordTextField.text = @"oodles";
    _userNameTextField.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5f].CGColor;
    _passwordTextField.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5f].CGColor;

    self.gradient = [CAGradientLayer layer];
    self.gradient.frame = self.view.bounds;
    self.gradient.colors = @[(id)[UIColor purpleColor].CGColor,
                             (id)[UIColor redColor].CGColor];
    
    [self.view.layer insertSublayer:self.gradient atIndex:0];
    
    [self animateLayer];
}

-(void)animateLayer {
    
    NSArray *fromColors = self.gradient.colors;
    NSArray *toColors = @[(id)[UIColor colorWithRed:0.0/255.0 green:128.0/255.0 blue:171.0/255.0 alpha:1.0].CGColor,//blueColor].CGColor,
                          (id)[UIColor colorWithRed:0.0/255.0 green:91.0/255.0 blue:255.0/255.0 alpha:1.0].CGColor];
    
    [self.gradient setColors:toColors];
    _gradient.startPoint = CGPointMake(1.0f, 0.0f);
    _gradient.endPoint = CGPointMake(0.0f, 1.0f);
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"colors"];
    
    animation.fromValue             = fromColors;
    animation.toValue               = toColors;
    animation.duration              = 3.00;
    animation.removedOnCompletion   = YES;
    animation.fillMode              = kCAFillModeForwards;
    animation.timingFunction        = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    animation.delegate              = self;
    
    // Add the animation to our layer
    
    [self.gradient addAnimation:animation forKey:@"animateGradient"];
}
- (void)viewDidLayoutSubviews {
    [self updateUI];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) updateUI {
    _loginButton.layer.cornerRadius = 4;
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField == _userNameTextField) {
        NSAttributedString *str = [[NSAttributedString alloc] initWithString:@"Username" attributes:@{ NSForegroundColorAttributeName : [UIColor whiteColor] }];
        _userNameTextField.attributedPlaceholder = str;
    }else if (textField == _passwordTextField) {
        NSAttributedString *str = [[NSAttributedString alloc] initWithString:@"Password" attributes:@{ NSForegroundColorAttributeName : [UIColor whiteColor] }];
        _passwordTextField.attributedPlaceholder = str;
    }
}

- (void)loginCheck {
    
    [self isTextFieldEmpty:_userNameTextField];
    [self isTextFieldEmpty:_passwordTextField];
    
//    if (![_userNameTextField.text isEqualToString:@"9899923127"]) {
//        _userNameTextField.floatingLabel.text = @"Incorrect Username";
//        _userNameTextField.floatingLabel.textColor = [UIColor redColor];
//        [self shakeView:_loginButton];
//    }else
        if (![_passwordTextField.text isEqualToString:@"oodles"]) {
        _passwordTextField.floatingLabel.text = @"Incorrect Password";
        _passwordTextField.floatingLabel.textColor = [UIColor redColor];
        [self shakeView:_passwordTextField];
    }else if (/*[_userNameTextField.text isEqualToString:@"9899923127"] && */[_passwordTextField.text isEqualToString:@"oodles"]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setValue:_userNameTextField.text forKey:@"MY_USERNAME"];
        [defaults setValue:@"https://180.151.230.12:9443/jWebrtc/" forKey:@"SERVER_HOST_URL"];
        
        [defaults synchronize];
        
        AppDelegate* appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate fetchContactsandAuthorization];
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.label.text = @"Loading";
        
        double delayInSeconds = 2.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"loginSuccessful"];
            [self performSegueWithIdentifier:@"loginToChatViewControllerSegue" sender:self];
        });
        
    }
    
}

- (void)isTextFieldEmpty:(UITextField *)textField {
    if (![textField hasText]) {
        [self shakeView:textField];
        
        NSAttributedString *str = [[NSAttributedString alloc] initWithString:@"Empty" attributes:@{ NSForegroundColorAttributeName : [UIColor redColor] }];
        textField.attributedPlaceholder = str;
        return;
    }
}

-(void)shakeView:(UIButton *)button{
    
    CABasicAnimation *shake = [CABasicAnimation animationWithKeyPath:@"position"];
    [shake setDuration:0.1];
    [shake setRepeatCount:2];
    [shake setAutoreverses:YES];
    [shake setFromValue:[NSValue valueWithCGPoint:
                         CGPointMake(button.center.x - 5,button.center.y)]];
    [shake setToValue:[NSValue valueWithCGPoint:
                       CGPointMake(button.center.x + 5, button.center.y)]];
    [button.layer addAnimation:shake forKey:@"position"];
}

- (IBAction)loginButtonPressed:(id)sender {
    _loginButton.transform =CGAffineTransformScale(CGAffineTransformIdentity, 0.001, 0.001);
    
    [UIView animateWithDuration:0.3/1.5 animations:^{
        _loginButton.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.1, 1.1);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3/2 animations:^{
            _loginButton.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.9, 0.9);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3/2 animations:^{
                _loginButton.transform = CGAffineTransformIdentity;
            }];
        }];
    }];
    
    [self loginCheck];
}

-(IBAction)prepareForUnwind:(UIStoryboardSegue *)segue {
    NSLog(@"##################");
    NSLog(@"LOGOUT SUCCESSFUL");
}
@end
