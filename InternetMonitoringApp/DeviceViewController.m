//
//  DeviceViewController.m
//  InternetMonitoringApp
//
//  Created by Stanimir on 3/23/15.
//  Copyright (c) 2015 mendy. All rights reserved.
//

#import "AppDelegate.h"
#import "DeviceViewController.h"

@interface DeviceViewController() <UITextFieldDelegate>{
    IBOutlet CustomPlaceHolderTextColorTextField *devNameTxtField;
    IBOutlet UILabel *toplabel, *bottomLabel;
}

@end

@implementation DeviceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
    // Do any additional setup after loading the view.
    [self setupNavigationBar];
    
    if ([AppDelegate sharedInstance].g_bPhone4) {
        toplabel.font = [UIFont boldSystemFontOfSize:22];
        bottomLabel.font = [UIFont systemFontOfSize:14];
    }else{
        toplabel.font = [UIFont systemFontOfSize:22];
        bottomLabel.font = [UIFont systemFontOfSize:17];
    }

    // setting initial device name according to device type
    NSString *deviceType = [UIDevice currentDevice].model;
    if([deviceType hasPrefix:@"iPhone"]){
        devNameTxtField.text = @"KID's IPHONE";
    }
    if([deviceType hasPrefix:@"iPad"]){
        devNameTxtField.text = @"KID's IPAD";
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UI methods
- (void)setupNavigationBar{
    // color
    [self.navigationController.navigationBar setAlpha:1.0];
    [self.navigationController.navigationBar setTintColor:[UIColor colorPrimary]];
    [self.navigationController setNavigationBarHidden:YES];
    
    // title
    [self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObject:[UIFont systemFontOfSize:18.0] forKey:UITextAttributeFont]];
    [self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:UITextAttributeTextColor]];
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorPrimary]];
}

#pragma mark - Segue control methods
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"SetDevice"]){
    
    }
}

#pragma mark - Web service methods
- (void)GetDeviceToken{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [AppDelegate sharedInstance].accountInfo = [defaults objectForKey:@"accountInfo"];
    
    NSString *accountToken = [AppDelegate sharedInstance].accountInfo[@"account"][@"token"];
    NSString *urlString = [NSString stringWithFormat:@"%@/%@", GetDeviceAPI, accountToken];
    
    [[AppDelegate sharedInstance] postResource:@"" andMethod:@"GET" andWithParams:@{} andLink:urlString AndCallback:^(id result, NSError *error) {
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        NSLog(@"%@", result);
        
        if (result != NULL) {
            NSMutableArray *devList = [result objectForKey:@"Devices"];
            for (int i=0; i<devList.count; i++) {
                NSMutableDictionary *devInfo = devList[i];

                if ([devInfo[@"Name"] isEqualToString:devNameTxtField.text]) {
                    [AppDelegate sharedInstance].bNewDevice = NO;
                    [AppDelegate sharedInstance].deviceInfo = devInfo;
                    
                    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                    [defaults setObject:devInfo forKey:@"deviceInfo"];
                    [defaults setBool:[AppDelegate sharedInstance].bNewDevice forKey:@"deviceNewStatus"];                    
                    [defaults synchronize];
                }
            }
            
            [self performSegueWithIdentifier:@"SetDevice" sender:self];
        }else {
            [[AppDelegate sharedInstance] showAlertMessage:@"" message:@"No devices"];
        }
    }];
}

#pragma mark - IBAction methods
- (IBAction)Continue:(id)sender{
    [self.view setAlpha:1];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    NSString *accountName = [AppDelegate sharedInstance].accountInfo[@"account"][@"name"];
    NSString *passString = [AppDelegate sharedInstance].mainPass;
    NSString *uuidString = [[AppDelegate sharedInstance] UDID];
    
    [[AppDelegate sharedInstance] postResource:@"" andMethod:@"POST" andWithParams:@{@"accountName": accountName, @"accountPassword": passString,
                                                                                    @"deviceName": devNameTxtField.text, @"deviceSpecifier": uuidString,
                                                                                    @"osInfo": @"iOS", @"reason": @"NEWINSTALL"} andLink:SetDeviceNameAPI AndCallback:^(id result, NSError *error) {
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        NSLog(@"%@", result);

        if (result != NULL) {
            if ([result isKindOfClass:[NSDictionary class]] && [[result allKeys] count] > 1) {
                // new device
                [AppDelegate sharedInstance].deviceInfo = result;
                [AppDelegate sharedInstance].bNewDevice = YES;
                
                // saving process
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setObject:result forKey:@"deviceInfo"];
                [defaults setBool:[AppDelegate sharedInstance].bNewDevice forKey:@"deviceNewStatus"];
                [defaults synchronize];
                
                // push action
                [self performSegueWithIdentifier:@"SetDevice" sender:self];
            }else if ([[result objectForKey:@"status"] isEqualToString:@"device_name_not_unique"]){
                // check in existing devices
                [self GetDeviceToken];
            }
        }
    }];
}

#pragma mark - UITextField delegates
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [devNameTxtField resignFirstResponder];
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    [textField resignFirstResponder];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if ([string isEqualToString:@"\n"]) {
        [textField resignFirstResponder];
    }
    return YES;
}

@end
