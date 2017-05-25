//
//  DashboardNavigationViewController.m
//  Oodles Talk
//
//  Created by Aditya Sharma on 03/05/17.
//  Copyright © 2017 ISBX. All rights reserved.
//

#import "DashboardNavigationViewController.h"

@interface DashboardNavigationViewController ()

@end

@implementation DashboardNavigationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(UIViewController *)viewControllerForUnwindSegueAction:(SEL)action fromViewController:(UIViewController *)fromViewController withSender:(id)sender
{
    return [self.presentedViewController viewControllerForUnwindSegueAction:action fromViewController:fromViewController withSender:sender];
}

@end
