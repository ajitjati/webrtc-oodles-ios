//
//  RegistrationViewController.m
//  Oodles Talk
//
//  Created by Aditya Sharma on 19/04/17.
//  Copyright © 2017 ISBX. All rights reserved.
//

#import "AppDelegate.h"
#import "RegistrationViewController.h"
#import <Contacts/Contacts.h>

@interface RegistrationViewController ()

@end

@implementation RegistrationViewController

//

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _registrationIDTextField.textAlignment = NSTextAlignmentCenter;
    _registrationIDTextField.floatingLabel.textAlignment = NSTextAlignmentCenter;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)alertView:(NSString *)message {
    NSLog(@"Not Registered");
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Note" message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* cancelButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
    
    }];
    
    UIAlertAction* yesButton = [UIAlertAction actionWithTitle:@"Open Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }];
    
    [alert addAction:cancelButton];
    [alert addAction:yesButton];

    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)nextButtonTapped:(id)sender {
    
    CNContactStore *store = [[CNContactStore alloc] init];
    [store requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            if (granted == YES)
            {
                if (![_registrationIDTextField hasText]) {
                    [self shakeView:_nextButton];
                    
                    NSAttributedString *str = [[NSAttributedString alloc] initWithString:@"Empty" attributes:@{ NSForegroundColorAttributeName : [UIColor redColor] }];
                    _registrationIDTextField.attributedPlaceholder = str;
                }else {
                    
                    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                    NSDictionary *appDefaults = [NSDictionary dictionaryWithObject:_registrationIDTextField.text forKey:@"MY_USERNAME"];
                    NSDictionary *appDefaults2 = [NSDictionary dictionaryWithObject:@"https://180.151.230.12:9443/jWebrtc/" forKey:@"SERVER_HOST_URL"];
                    
                    [defaults registerDefaults:appDefaults];
                    [defaults registerDefaults:appDefaults2];
                    [defaults synchronize];
                    
                    //        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
                    //        dispatch_async(queue, ^{
                    //            AppDelegate* appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                    //
                    //            [appDelegate fetchContactsandAuthorization];
                    //
                    //            dispatch_sync(dispatch_get_main_queue(), ^{
                    //                // Update UI
                    //                // Example:
                    //                // self.myLabel.text = result;
                    //            });
                    //        });
                    
                    
                    [self performSegueWithIdentifier:@"registerToChatControllerSegue" sender:self];
                }
                
            }else {
                [self alertView:@"Please allow to access contacts before moving forward."];
            }
        });
    }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField == _registrationIDTextField) {
        NSAttributedString *str = [[NSAttributedString alloc] initWithString:@"Phone number" attributes:@{ NSForegroundColorAttributeName : [UIColor lightGrayColor] }];
        _registrationIDTextField.attributedPlaceholder = str;
    }
}

- (BOOL)isTextFieldEmpty:(UITextField *)textField {
    if (![textField hasText]) {
        [self shakeView:_nextButton];
        
        NSAttributedString *str = [[NSAttributedString alloc] initWithString:@"Empty" attributes:@{ NSForegroundColorAttributeName : [UIColor redColor] }];
        textField.attributedPlaceholder = str;
        return YES;
    }
    return NO;
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

@end
