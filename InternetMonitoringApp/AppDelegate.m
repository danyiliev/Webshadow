//
//  AppDelegate.m
//  InternetMonitoringApp
//
//  Created by Vanguard on 3/23/15.
//  Copyright (c) 2015 mendy. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // estimate iphone type
    if ([[UIScreen mainScreen] bounds].size.height == 480)
        _g_bPhone4 = YES;
    else
        _g_bPhone4 = NO;
    
    // flag: current device is existing or not
    [AppDelegate sharedInstance].bNewDevice = YES;

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark -
#pragma mark App Engine methods
+ (AppDelegate*)sharedInstance{
    return (AppDelegate*)[[UIApplication sharedApplication] delegate];
}

-(NSString*)UDID {
    NSString *uuidString = nil;
    // get os version
    NSUInteger currentOSVersion = [[[[[UIDevice currentDevice] systemVersion] componentsSeparatedByString:@"."] objectAtIndex:0] integerValue];
    
    if(currentOSVersion <= 5) {
        if([[NSUserDefaults standardUserDefaults] valueForKey:@"udid"]) {
            uuidString = [[NSUserDefaults standardUserDefaults] valueForKey:@"udid"];
        } else {
            CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
            uuidString = (NSString *)CFBridgingRelease(CFUUIDCreateString(NULL, uuidRef));
            CFRelease(uuidRef);
        }
        return uuidString;
    } else {
        return [[UIDevice currentDevice].identifierForVendor UUIDString];
    }
}

#pragma mark Alert
- (void)showAlertMessage:(NSString*)title message:(NSString*)content{
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:content
                                                   delegate:nil
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil];
    [alert show];
    [self performSelector:@selector(dismiss:) withObject:alert afterDelay:2.5];
}

- (void)dismiss:(UIAlertView*)alert{
    [alert dismissWithClickedButtonIndex:0 animated:YES];
}


#pragma mark Location Manager Delegate methods
- (void)setLocationManager{
    curLocManager = [[CLLocationManager alloc] init];
    curLocManager.desiredAccuracy = kCLLocationAccuracyBest;
    curLocManager.delegate = self;
    
    // Override point for customization after application launch.
    if (IS_OS_8_OR_LATER){
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIRemoteNotificationTypeBadge
                                                                                             |UIRemoteNotificationTypeSound
                                                                                             |UIRemoteNotificationTypeAlert) categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        [curLocManager requestAlwaysAuthorization];
    }else{
        //register to receive notifications
        UIRemoteNotificationType myTypes = UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound;
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:myTypes];
    }
    
    [curLocManager startUpdatingLocation];
    startLocation = nil;
    

}

-(void)resetDistance:(id)sender{
    startLocation = nil;
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    [self setLocationManager];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    CLLocation *location_updated = [locations lastObject];
}



#pragma mark - POST Request delegate methods
- (void) postResource:(NSString *)resource andMethod:(NSString *)method andWithParams:(NSDictionary *)params andLink:(NSString*)link AndCallback: (void (^)(id result, NSError *error))callback
{
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:link]];
    [httpClient setParameterEncoding:AFJSONParameterEncoding];
    
    
    //send photos from array
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    NSMutableURLRequest *request = [httpClient requestWithMethod:method path:resource parameters:params];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]initWithRequest:request];
    [AFHTTPRequestOperation addAcceptableContentTypes:[NSSet setWithObject:@"application/json"]];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
    {
         // parse response to JSON
         NSString *convertedString = [[NSString alloc] initWithData:operation.responseData encoding:NSUTF8StringEncoding];
//         NSLog(@"========== response result ==========\n%@", convertedString);
        
         parsedData = [NSJSONSerialization JSONObjectWithData:operation.responseData options:kNilOptions error:nil];
         NSString *sessionId = [operation.response.allHeaderFields valueForKey:@"Set-Cookie"];
         
         if ([sessionId length] != 0)
         {
             [prefs setObject:sessionId forKey:@"session_id"];
             [prefs synchronize];
         }
         callback(parsedData, nil);
     } failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         if (403 == operation.response.statusCode){
             
             NSMutableDictionary *dict = [NSJSONSerialization JSONObjectWithData: [operation.responseString dataUsingEncoding:NSUTF8StringEncoding]
                                                                         options: NSJSONReadingMutableContainers
                                                                           error: nil];
             [dict setObject:@403 forKey:@"error_code"];
             
             callback(dict , error);
         }else
             if(operation.responseData)
             {
                 NSDictionary* deserializedData = [NSJSONSerialization
                                                   JSONObjectWithData:operation.responseData //1
                                                   options:kNilOptions
                                                   error:&error];
                 
                 
                 NSError *valuesError = [NSError errorWithDomain:@"myDomain" code:100 userInfo:deserializedData];
                 
                 callback(deserializedData, valuesError);
             } else {
                 callback(operation.responseString, error);
             }
     }];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperation:operation];
}

@end
