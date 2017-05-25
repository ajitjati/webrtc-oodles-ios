//
//  LoginViewController.h
//  Oodles Talk
//
//  Created by Aditya Sharma on 12/04/17.
//  Copyright © 2017 ISBX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JVFloatLabeledTextView.h"
#import "JVFloatLabeledTextField.h"

@interface LoginViewController : UIViewController

@property (weak, nonatomic) IBOutlet JVFloatLabeledTextField *userNameTextField;
@property (weak, nonatomic) IBOutlet JVFloatLabeledTextField *passwordTextField;

@property (weak, nonatomic) IBOutlet UIButton *loginButton;

- (IBAction)loginButtonPressed:(id)sender;

- (IBAction)prepareForUnwind:(UIStoryboardSegue *)segue;

@property (strong, nonatomic) CAGradientLayer *gradient;

@end
