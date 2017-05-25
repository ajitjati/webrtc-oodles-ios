//
//  RegistrationViewController.h
//  Oodles Talk
//
//  Created by Aditya Sharma on 19/04/17.
//  Copyright © 2017 ISBX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JVFloatLabeledTextField.h"

@interface RegistrationViewController : UIViewController

@property (weak, nonatomic) IBOutlet JVFloatLabeledTextField *registrationIDTextField;
- (IBAction)nextButtonTapped:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;

@end
