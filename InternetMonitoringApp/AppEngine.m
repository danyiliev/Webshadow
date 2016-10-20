//
//  AppEngine.m
//  InternetMonitoringApp
//
//  Created by Vanguard on 3/25/15.
//  Copyright (c) 2015 mendy. All rights reserved.
//

#import "AppEngine.h"

@implementation AppEngine

- (AppEngine*)sharedInstance{
    return [[AppEngine alloc] init];
}

#pragma mark -
#pragma mark POST Request delegate methods
- (void) postResource:(NSString *)resource andMethod:(NSString *)method andWithParams:(NSDictionary *)params andLink:(NSString*)link AndCallback: (void (^)(id result, NSError *error))callback
{
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:link]];
    [httpClient setParameterEncoding:AFJSONParameterEncoding];
    
    
    //send photos from array
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    NSMutableURLRequest *request = [httpClient multipartFormRequestWithMethod:method path:resource parameters:params constructingBodyWithBlock: ^(id <AFMultipartFormData>formData) {
    }];
    
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]initWithRequest:request];
    [AFHTTPRequestOperation addAcceptableContentTypes:[NSSet setWithObject:@"text/html"]];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         // parse response to JSON
         NSString *convertedString = [[NSString alloc] initWithData:operation.responseData encoding:NSUTF8StringEncoding];
         NSLog(@"========== response result ==========\n%@", convertedString);
         
         parsedData = [NSJSONSerialization JSONObjectWithData:operation.responseData options:kNilOptions error:nil];
         NSString *sessionId = [operation.response.allHeaderFields valueForKey:@"Set-Cookie"];
         
         if ([sessionId length] != 0){
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
