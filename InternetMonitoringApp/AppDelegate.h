//
//  AppDelegate.h
//  InternetMonitoringApp
//
//  Created by Vanguard on 3/23/15.
//  Copyright (c) 2015 mendy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "AppEngine.h"
#import "BrowserDelegate.h"
#import "CustomPlaceHolderTextColorTextField.h"
#import "UIColor+CustomColors.h"

#define kOFFSET_KEYBOARD 190
#define WRONG_CREDENTIAL @"Please check your password and try again!"

#define BaseURL @"https://api.webshadow.com"
#define ParentLoginAPI @"http://webshadow.org/api/v1-0/accounts/token"
#define SetDeviceNameAPI @"http://webshadow.org/api/v1-0/config/bootstrap"
#define GetChildrenAPI @"http://webshadow.org/api/v1-0/config/file"
#define ChildLoginAPI @"http://webshadow.org/api/v1-0/config/surfer"
#define LogAPI @"http://webshadow.org/api/v1-0/logs/ship"
#define GetDeviceAPI @"http://webshadow.org/api/v1-0/config/file/devices"

@interface AppDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate>{
    CLLocationManager *curLocManager;
    NSMutableDictionary *parsedData;
    CLLocation *startLocation;
}

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, retain) NSMutableDictionary *accountInfo, *deviceInfo, *childrenInfo;
@property (nonatomic, retain) NSMutableDictionary *parentInfo, *userChildInfo;
@property (nonatomic, retain) NSString *mainPass;
@property (nonatomic, readwrite) BOOL bParent, bNewDevice;
@property (nonatomic, readwrite) BOOL g_bPhone4;

+ (AppDelegate*)sharedInstance;
- (void)showAlertMessage:(NSString*)title message:(NSString*)content;
- (NSString*)UDID;
- (void) postResource:(NSString *)resource andMethod:(NSString *)method andWithParams:(NSDictionary *)params andLink:(NSString*)link AndCallback: (void (^)(id result, NSError *error))callbac;

@end

