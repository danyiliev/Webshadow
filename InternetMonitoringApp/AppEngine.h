//
//  AppEngine.h
//  InternetMonitoringApp
//
//  Created by Vanguard on 3/25/15.
//  Copyright (c) 2015 mendy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Availability.h>
#import <AFNetworking/AFHTTPClient.h>
#import <AFNetworking/AFHTTPRequestOperation.h>
#import <MBProgressHUD/MBProgressHUD.h>

#import "AppDelegate.h"

#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

@interface AppEngine : NSObject{
    NSMutableDictionary *parsedData;
}

@property (strong, nonatomic) NSUserDefaults *defaults;

- (AppEngine*)sharedInstance;
- (void) postResource:(NSString *)resource andMethod:(NSString *)method andWithParams:(NSDictionary *)params andLink:(NSString*)link AndCallback: (void (^)(id result, NSError *error))callback;

@end
