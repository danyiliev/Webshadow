//
//  ViewController.m
//  InternetMonitoringApp
//
//  Created by Stanimir on 3/23/15.
//  Copyright (c) 2015 mendy. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "MainLoginViewController.h"

@interface ViewController() <UITextFieldDelegate>{
    IBOutlet CustomPlaceHolderTextColorTextField *emailTxtField, *passTxtField;
    IBOutlet UIButton *nextButton;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated{
    [self setupInitUI];
    [self setupNavigationBar];
}

#pragma mark - Segue control methods
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"Login"]) {
   
    }
}

#pragma mark - UI methods
- (void)setupInitUI{
    emailTxtField.text = @"";
    passTxtField.text = @"";
}

- (void)setupNavigationBar{
    [self.navigationController setNavigationBarHidden:NO];

    // color
    [self.navigationController.navigationBar setAlpha:1.0];
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorPrimary]];

    // back button
    self.navigationController.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStyleDone target:self action:@selector(goBack)];
    
    // title
    [self.navigationController.navigationBar.topItem setTitle:@"LOG IN"];
    [self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObject:[UIFont systemFontOfSize:18.0] forKey:UITextAttributeFont]];
    [self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:UITextAttributeTextColor]];

    // remove back button title
//    self.navigationItem.backBarButtonItem.title = @"";
}

#pragma mark - IBAction methods
- (IBAction)goBack{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)Hint:(id)sender{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://webshadow.org/accounts/password/new"]];
}

- (IBAction)Login:(id)sender{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [[AppDelegate sharedInstance] postResource:@"" andMethod:@"GET" andWithParams:@{@"accountName": emailTxtField.text,
                                                                                     @"accountPassword": passTxtField.text} andLink:ParentLoginAPI AndCallback:^(id result, NSError *error) {
         [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
         NSLog(@"%@", result);

         if (result != NULL) {
             if ([result isKindOfClass:[NSDictionary class]] && [[result allKeys] count] > 1) {
                 [AppDelegate sharedInstance].accountInfo = [NSMutableDictionary dictionaryWithDictionary:result];
                 [AppDelegate sharedInstance].mainPass = passTxtField.text;
                 
                 // eliminate null or empty field value to avoid crash
                 NSMutableDictionary *tempDict1 = [NSMutableDictionary dictionaryWithDictionary:[AppDelegate sharedInstance].accountInfo[@"account"]];
                 if (tempDict1[@"time_zone"] == [NSNull null] || [tempDict1[@"time_zone"] isEqualToString:@""]) {
                     tempDict1[@"time_zone"] = @"";
                     [AppDelegate sharedInstance].accountInfo[@"account"] = tempDict1;
                 }
                 
                 // saving process
                 NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                 [defaults setBool:YES forKey:@"rootLoginStatus"];
                 [defaults setObject:[AppDelegate sharedInstance].accountInfo forKey:@"accountInfo"];
                 [defaults setObject:[AppDelegate sharedInstance].mainPass forKey:@"accountPass"];
                 [defaults synchronize];
                 
                 // push action
                 [self performSegueWithIdentifier:@"Login" sender:self];
             }else{
                 [[AppDelegate sharedInstance] showAlertMessage:@"" message:@"Please check your password and try again"];
             }
         }else {
             [[AppDelegate sharedInstance] showAlertMessage:@"" message:@"Please check your password and try again"];
         }
     }];
}

#pragma mark - UITextField delegates
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [emailTxtField resignFirstResponder];
    [passTxtField resignFirstResponder];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField{
    textField.text = @"";
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
