//
//  BrowserViewController.h
//  InternetMonitoringApp
//
//  Created by Vanguard on 4/7/15.
//  Copyright (c) 2015 mendy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BrowserViewController : UIViewController<UITextFieldDelegate>{
    IBOutlet UIView *searchView;
    IBOutlet UITextField *urlTxtField;
    IBOutlet UIButton *goButton;
    IBOutlet UIWebView *webView;
}

- (IBAction)Go:(id)sender;

@end
