//
//  IncomingCallViewController.m
//  MSCRTC
//
//  Created by Maneesh Madan on 05/05/17.
//  Copyright © 2017 ISBX. All rights reserved.
//

#import "IncomingCallViewController.h"
#import "RoomViewController.h"


@implementation IncomingCallViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if (self.name != nil) {
        self.callerName.text = self.name;
    }
    if (self.image != nil) {
        self.callerImage.image = self.image;
    }
    
    NSURL *url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/0063.wav", [[NSBundle mainBundle] resourcePath]]];
    NSError *error;
    _player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    _player.numberOfLoops = -1;
}

-(void)viewDidLayoutSubviews {
    _acceptButton.layer.cornerRadius = _acceptButton.frame.size.width/2;
    _declineButton.layer.cornerRadius = _declineButton.frame.size.width/2;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidAppear {
    if (_player != nil)
        [_player play];
    
    [NSTimer scheduledTimerWithTimeInterval:20.0
                                     target:self
                                   selector:@selector(doSomethingWhenTimeIsUp:)
                                   userInfo:nil
                                    repeats:NO];
}

- (void) doSomethingWhenTimeIsUp:(NSTimer*)t {
    
    // YES! Do something here!!
    ARDIncomingCallResponseMessage *message = [[ARDIncomingCallResponseMessage alloc] init];
    message.from = self.client.to;
    [self.client sendSignalingMessageToCollider: message];
    
    [self dismissViewControllerAnimated:YES completion: nil];
    
}

- (IBAction)buttonTapped:(id)sender {
    [_player stop];
    
    if (sender == _acceptButton) {
        NSLog(@"Accept");
        self.client.isInitiator = FALSE;
        
        [self performSegueWithIdentifier:@"incomingScreenToVideoSegue" sender:self.client];

    }else {
        NSLog(@"Decline");
        ARDIncomingCallResponseMessage *message = [[ARDIncomingCallResponseMessage alloc] init];
        message.from = self.client.to;
        [self.client sendSignalingMessageToCollider: message];
        
        [self dismissViewControllerAnimated:YES completion: nil];
    }
}
@end
