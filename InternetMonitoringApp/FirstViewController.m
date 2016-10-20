//
//  FirstViewController.m
//  InternetMonitoringApp
//
//  Created by Stanimir on 12/19/15.
//  Copyright © 2015 mendy. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "AppDelegate.h"

#import "FirstViewController.h"
#import "MainLoginViewController.h"
#import "ViewController.h"
#import "BrowserViewController.h"
#import "DeviceViewController.h"

@interface FirstViewController ()

@property (nonatomic, strong) AVPlayer *avplayer;
@property (strong, nonatomic) IBOutlet UIView *movieView;
@property (strong, nonatomic) IBOutlet UIButton *loginButton;

@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
  
    // disasble affection of background music playing
    NSError *sessionError = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:&sessionError];
    [[AVAudioSession sharedInstance] setActive:YES error:&sessionError];

    // set up media player
    NSURL *movieURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Intro640x1680" ofType:@"mp4"]];
    AVAsset *avAsset = [AVAsset assetWithURL:movieURL];
    
    AVPlayerItem *avPlayerItem =[[AVPlayerItem alloc]initWithAsset:avAsset];
    self.avplayer = [[AVPlayer alloc]initWithPlayerItem:avPlayerItem];
    
    AVPlayerLayer *avPlayerLayer =[AVPlayerLayer playerLayerWithPlayer:self.avplayer];
    [avPlayerLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [avPlayerLayer setFrame:[self.movieView bounds]];
    [self.movieView.layer addSublayer:avPlayerLayer];
    
    // config player
    [self.avplayer seekToTime:kCMTimeZero];
    [self.avplayer setVolume:0.0f];
    [self.avplayer setActionAtItemEnd:AVPlayerActionAtItemEndNone];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:[self.avplayer currentItem]];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerStartPlaying)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];

}

- (void)viewWillAppear:(BOOL)animated{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // UI initial setting
    [self setupNavigationBar];

    // judge primary logged-in status
    if ([defaults boolForKey:@"rootLoginStatus"]) {
        [AppDelegate sharedInstance].accountInfo = [defaults objectForKey:@"accountInfo"];

        // check second logged-in status
        if ([defaults boolForKey:@"mainLoginStatus"]) {
            [AppDelegate sharedInstance].parentInfo = [defaults objectForKey:@"parentInfo"];
            [AppDelegate sharedInstance].userChildInfo = [defaults objectForKey:@"childInfo"];
            [AppDelegate sharedInstance].bParent = [defaults boolForKey:@"IsParent"];
            
            BrowserViewController *dest = [self.storyboard instantiateViewControllerWithIdentifier:@"BrowserViewController"];
            [self.navigationController pushViewController:dest animated:NO];
        }else if ([defaults objectForKey:@"deviceInfo"]) {
            MainLoginViewController *dest = [self.storyboard instantiateViewControllerWithIdentifier:@"MainLoginViewController"];
            [self.navigationController pushViewController:dest animated:NO];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.avplayer pause];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.avplayer play];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - video related methods
- (void)playerItemDidReachEnd:(NSNotification *)notification {
    AVPlayerItem *p = [notification object];
    [p seekToTime:kCMTimeZero];
}

- (void)playerStartPlaying{
    [self.avplayer play];
}

#pragma mark - UI methods
- (void)setupNavigationBar{
    [self.navigationController setNavigationBarHidden:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


#pragma mark - IBAction methods
- (IBAction)Signup:(id)sender{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://webshadow.org/accounts/sign_up"]];
}

- (IBAction)Login:(id)sender{
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // judge primary logged-in status
    if ([defaults boolForKey:@"rootLoginStatus"]) {
        [AppDelegate sharedInstance].accountInfo = [defaults objectForKey:@"accountInfo"];
        
        // check second logged-in status
        if ([defaults boolForKey:@"mainLoginStatus"]) {
            [AppDelegate sharedInstance].parentInfo = [defaults objectForKey:@"parentInfo"];
            [AppDelegate sharedInstance].userChildInfo = [defaults objectForKey:@"childInfo"];
            [AppDelegate sharedInstance].bParent = [defaults boolForKey:@"IsParent"];
            
            BrowserViewController *dest = [self.storyboard instantiateViewControllerWithIdentifier:@"BrowserViewController"];
            [self.navigationController pushViewController:dest animated:NO];
        }else{
            if ([defaults objectForKey:@"deviceInfo"]) {
                MainLoginViewController *dest = [self.storyboard instantiateViewControllerWithIdentifier:@"MainLoginViewController"];
                [self.navigationController pushViewController:dest animated:NO];
            }else{
                [AppDelegate sharedInstance].deviceInfo = [defaults objectForKey:@"deviceInfo"];
                [AppDelegate sharedInstance].mainPass = [defaults objectForKey:@"accountPass"];
                
                DeviceViewController *dest = [self.storyboard instantiateViewControllerWithIdentifier:@"DeviceViewController"];
                [self.navigationController pushViewController:dest animated:NO];
            }
        }
    }else{
        ViewController *dest = [self.storyboard instantiateViewControllerWithIdentifier:@"ViewController"];
        [self.navigationController pushViewController:dest animated:YES];
    }
    
    NSLog(@"%@", [AppDelegate sharedInstance].parentInfo);
    NSLog(@"%d", [AppDelegate sharedInstance].bParent);
}

@end
