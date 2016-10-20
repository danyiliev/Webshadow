//
//  BrowserViewController.m
//  InternetMonitoringApp
//
//  Created by Vanguard on 4/7/15.
//  Copyright (c) 2015 mendy. All rights reserved.
//

#import "BrowserViewController.h"

@interface BrowserViewController ()

@end

@implementation BrowserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)loadWebPage{
    NSString *urlString = [NSString stringWithFormat:@"http://www.%@", urlTxtField.text];
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [webView setScalesPageToFit:YES];
    [webView loadRequest:request];
}

#pragma mark - IBAction methods
- (IBAction)Go:(id)sender{
    [self loadWebPage];
}

#pragma mark - UITextField delegate
- (void)textFieldDidEndEditing:(UITextField *)textField{
    [self loadWebPage];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if ([string isEqualToString:@"\n"]) {
        [textField resignFirstResponder];
    }
    
    return YES;
}

#pragma mark - WebView delegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    NSLog(@"1");
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView{
    NSLog(@"2");
}

- (void)webViewDidFinishLoad:(UIWebView *)webView{
    NSLog(@"3");
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"Error : %@",error);
}



@end
