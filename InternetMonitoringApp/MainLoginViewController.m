//
//  MainLoginViewController.m
//  InternetMonitoringApp
//
//  Created by Vanguard on 3/23/15.
//  Copyright (c) 2015 mendy. All rights reserved.
//

#import "AppDelegate.h"

#import "MainLoginViewController.h"
#import "BrowserViewController.h"
#import "UIColor+CustomColors.h"

@interface MainLoginViewController() <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource>{
    IBOutlet UITextField *passTxtField;
    IBOutlet UITableView *userPicker;
    IBOutlet UIButton *nextButton;
    IBOutlet UILabel *userLabel;
    IBOutlet UIView *passView;
    
    NSIndexPath *selectedIndex;
    NSMutableArray *childList;
    NSMutableDictionary *chosenOne;
}

@end

@implementation MainLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self getChildren];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated{
    // loading the saved information
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [AppDelegate sharedInstance].accountInfo = [defaults objectForKey:@"accountInfo"];
    [AppDelegate sharedInstance].deviceInfo = [defaults objectForKey:@"deviceInfo"];
    [AppDelegate sharedInstance].bNewDevice = [defaults boolForKey:@"deviceNewStatus"];
    
    NSLog(@"%@", [defaults objectForKey:@"deviceInfo"]);
    // UI initial setting
    [self setupInitUI];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:YES];
    [self hideViews];
}

#pragma mark - UI methods
- (void)setupInitUI{
    passTxtField.text = @"";
    selectedIndex = nil;
    
    // navigation
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
    // extra views
    [self hideViews];
    nextButton.frame = CGRectMake(nextButton.frame.origin.x, nextButton.frame.origin.y, self.view.frame.size.width, nextButton.frame.size.height);
    
    // table view
    self.edgesForExtendedLayout = UIRectEdgeNone;
    userPicker.tableHeaderView = [[UIView alloc] initWithFrame:CGRectZero];
    userPicker.tintColor = [UIColor whiteColor];
    userPicker.layoutMargins = UIEdgeInsetsZero;
    [userPicker reloadData];
}

- (void)hideViews{
    [passView setHidden:YES];
    [userLabel setHidden:YES];
    [nextButton setHidden:YES];
}

- (void)showViews{
    [passView setHidden:NO];
    [userLabel setHidden:NO];
    [nextButton setHidden:NO];
}

#pragma mark - Segue control methods

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@""]) {
    }
}

#pragma mark - Web service methods
- (void)getChildren{
    NSString *accountToken = [AppDelegate sharedInstance].accountInfo[@"account"][@"token"];
    NSString *urlString = [NSString stringWithFormat:@"%@/surfers/%@", GetChildrenAPI, accountToken];
    
    [[AppDelegate sharedInstance] postResource:@"" andMethod:@"GET" andWithParams:@{} andLink:urlString AndCallback:^(id result, NSError *error) {
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        
        NSLog(@"%@", result);
        if (result != NULL) {
            if ([result isKindOfClass:[NSDictionary class]] && [[result allKeys] count] > 1) {
                [AppDelegate sharedInstance].childrenInfo = result;
                childList = [AppDelegate sharedInstance].childrenInfo[@"Surfers"];
                [userPicker reloadData];
            }else{
                [[AppDelegate sharedInstance] showAlertMessage:@"" message:@"please try again"];
            }
        }else {
            [[AppDelegate sharedInstance] showAlertMessage:@"" message:@"please try again"];
        }
    }];
}

#pragma mark - IBAction methods
- (IBAction)Hint:(id)sender{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://webshadow.org/accounts/password/new"]];
}

- (IBAction)SigninAs:(id)sender{
    [passTxtField resignFirstResponder];
    [self keyboardWillHide];
}

- (IBAction)Signin:(id)sender{   
    NSString *devToken;
    NSString *accountToken = [AppDelegate sharedInstance].accountInfo[@"account"][@"token"];
    NSString *accountName = [AppDelegate sharedInstance].accountInfo[@"account"][@"name"];

    // get device token
    if ([AppDelegate sharedInstance].bNewDevice) {
        devToken = [AppDelegate sharedInstance].deviceInfo[@"Tokens"][1][@"Content"];
    }else{
        devToken = [AppDelegate sharedInstance].deviceInfo[@"Token"];
    }
    
    NSString *urlString = [NSString stringWithFormat:@"%@/%@/%@", ChildLoginAPI, accountToken, devToken];
    NSLog(@"%@ - %@", devToken, urlString);
    
    if (devToken) {
        if ([AppDelegate sharedInstance].bParent) { // parent login
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            [[AppDelegate sharedInstance] postResource:@"" andMethod:@"GET" andWithParams:@{@"accountName": accountName,
                                                                                            @"accountPassword": passTxtField.text} andLink:ParentLoginAPI AndCallback:^(id result, NSError *error) {
                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                NSLog(@"result = %@", result);
                if (result != NULL) {
                    
                    if (!result[@"error_code"] && !result[@"error"]) {
//                        [AppDelegate sharedInstance].accountInfo = [NSMutableDictionary dictionaryWithDictionary:result];
                        [AppDelegate sharedInstance].parentInfo = [NSMutableDictionary dictionaryWithDictionary:result];
                        [AppDelegate sharedInstance].mainPass = passTxtField.text;

                        // eliminate null or empty field value to avoid crash
                        NSMutableDictionary *tempDict1 = [NSMutableDictionary dictionaryWithDictionary:[AppDelegate sharedInstance].accountInfo[@"account"]];
                        if (tempDict1[@"time_zone"] == [NSNull null] || [tempDict1[@"time_zone"] isEqualToString:@""]) {
                            tempDict1[@"time_zone"] = @"";
                            [AppDelegate sharedInstance].parentInfo[@"account"] = tempDict1;
                        }
                        NSLog(@"%@", [AppDelegate sharedInstance].parentInfo);
                        
                        // saving process
                        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                        [defaults setBool:YES forKey:@"mainLoginStatus"];
                        [defaults setObject:[AppDelegate sharedInstance].parentInfo forKey:@"parentInfo"];
                        [defaults synchronize];
                        
                        // push action
                        BrowserViewController *dest = [self.storyboard instantiateViewControllerWithIdentifier:@"BrowserViewController"];
                        [self.navigationController pushViewController:dest animated:YES];
                    }else{ // exception handler
                        if (result[@"status"]) {
                            [[AppDelegate sharedInstance] showAlertMessage:@"" message:WRONG_CREDENTIAL];
                        }else if (result[@"error"]){
                            [[AppDelegate sharedInstance] showAlertMessage:@"" message:WRONG_CREDENTIAL];
                        }
                    }
                }else {
                    [[AppDelegate sharedInstance] showAlertMessage:@"" message:WRONG_CREDENTIAL];
                }
            }];
        }else{
            if (chosenOne){ // child login
                [[AppDelegate sharedInstance] postResource:@"" andMethod:@"GET" andWithParams:@{@"surferName": chosenOne[@"Name"], @"surferPassword": passTxtField.text} andLink:urlString AndCallback:^(id result, NSError *error) {
                    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                    
                    NSLog(@"%@", result);
                    if (result != NULL) {
                        if (!result[@"error_code"] && !result[@"error"]) {
                            [AppDelegate sharedInstance].userChildInfo = chosenOne;
                            NSLog(@"%@", [AppDelegate sharedInstance].userChildInfo[@"Token"]);
                            
                            // saving process
                            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                            [defaults setBool:YES forKey:@"mainLoginStatus"];
                            [defaults setObject:[AppDelegate sharedInstance].userChildInfo forKey:@"childInfo"];
                            [defaults synchronize];
                            
                            // push action
                            BrowserViewController *dest = [self.storyboard instantiateViewControllerWithIdentifier:@"BrowserViewController"];
                            [self.navigationController pushViewController:dest animated:YES];
                        }else{  // exception handler
                            if (result[@"status"]) {
                                [[AppDelegate sharedInstance] showAlertMessage:@"" message:WRONG_CREDENTIAL];
                            }else if (result[@"error"]){
                                [[AppDelegate sharedInstance] showAlertMessage:@"" message:WRONG_CREDENTIAL];
                            }
                        }
                    }else { // exception handler
                        [[AppDelegate sharedInstance] showAlertMessage:@"" message:WRONG_CREDENTIAL];
                    }
                }];
            }else{
                [[AppDelegate sharedInstance] showAlertMessage:@"Warning" message:@"You have to select parent or child."];
            }
        }
    }
    
    [passTxtField resignFirstResponder];
}

#pragma mark - UITableView delegate & datasource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [childList count] + 1;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    cell.preservesSuperviewLayoutMargins = NO;

    // Remove seperator inset
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    // Prevent the cell from inheriting the Table View's margin settings
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
    
    // Explictly set your cell's layout margins
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    // cell identifier
    NSString *cellID = @"orgCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];

    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    
    cell.backgroundColor = [UIColor colorWithRed:54/255.0 green:143/255.0 blue:165/255.0 alpha:1.0];
    
    // font setting
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:14.0];

    // imageview setting
    if (childList.count > 0) {
        cell.imageView.image = [UIImage imageNamed:@"parent"];
        
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Parent";
        }else{
            NSMutableDictionary *tempDict = [childList objectAtIndex:indexPath.row - 1];
            cell.textLabel.text = tempDict[@"Name"];
        }
    }
    
    // check box setting
    if (selectedIndex){
        if (indexPath == selectedIndex)
            [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        else
            [cell setAccessoryType:UITableViewCellAccessoryNone];
    }else {
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 0){    // select parent
        [AppDelegate sharedInstance].bParent = YES;
        
        [userLabel setText:@"Sign in as Parent:"];
        passTxtField.placeholder = @"Parent Account Password";
    }else{  // select child
        [AppDelegate sharedInstance].bParent = NO;
        
        // get child information
        NSMutableDictionary *tempDict = [childList objectAtIndex:indexPath.row - 1];
        chosenOne = tempDict;
        
        [userLabel setText:[NSString stringWithFormat:@"Sign in as %@:", tempDict[@"Name"]]];
        passTxtField.placeholder = @"Child Account Password";        
    }
    
    // save parnt/child flag
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:[AppDelegate sharedInstance].bParent forKey:@"IsParent"];
    [defaults synchronize];
    
    // display password field
    [self showViews];

    selectedIndex = indexPath;
    [tableView reloadData];
}

#pragma mark - UITextField & Keyboard Delegates
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [passTxtField resignFirstResponder];
    [self keyboardWillHide];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField{
    [self keyboardWillShow];
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    [self keyboardWillHide];
    [textField resignFirstResponder];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if ([string isEqualToString:@"\n"]) {
        [self keyboardWillHide];
        [textField resignFirstResponder];
    }
    return YES;
}

- (void)keyboardWillShow {
    // Animate the current view out of the way
    if (self.view.frame.origin.y >= 0){
        [self setViewMovedUp:YES];
    }
    else if (self.view.frame.origin.y < 0){
        //        [self setViewMovedUp:NO];
    }
}

- (void)keyboardWillHide {
    if (self.view.frame.origin.y >= 0){
        //        [self setViewMovedUp:YES];
    }
    else if (self.view.frame.origin.y < 0){
        [self setViewMovedUp:NO];
    }
}

//method to move the view up/down whenever the keyboard is shown/dismissed
- (void)setViewMovedUp:(BOOL)movedUp{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3]; // if you want to slide up the view
    
    CGRect rect = self.view.frame;
   
    if (movedUp){
        // 1. move the view's origin up so that the text field that will be hidden come above the keyboard
        // 2. increase the size of the view so that the area behind the keyboard is covered up.
        rect.origin.y -= 150;
    }
    else{
        // revert back to the normal state.
        rect.origin.y += 150;
    }
    self.view.frame = rect;
    
    [UIView commitAnimations];
}

@end
