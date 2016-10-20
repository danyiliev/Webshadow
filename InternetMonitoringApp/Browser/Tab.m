//
//  Tab.m
//
//  Created by Alexandru Catighera on 4/28/11.
//  Customized by Stanimir Avramov on 2/8/16
//  Copyright 2011 Evidon. All rights reserved.
//

#import "Tab.h"
#import "BrowserViewController.h"
#import "BookmarksFormController.h"
#import "UIMainView.h"

@implementation Tab

@synthesize tabButton, g_webView, closeButton, tabTitleLabel, history, traverse, history_position, scrollPosition, currentURLString, currentURL, current, urlConnection, connectionURLString, actionSheetVisible, loadStartTime, loadEndTime, pageInfoJS, g_response, viewController, loading, pageData;

-(id) initWithFrame:(CGRect)frame addTarget:(BrowserViewController *) vc {
	if ((self = [super initWithFrame:frame])) {
        viewController = vc;
        NSString *path = [[NSBundle mainBundle] pathForResource:@"page_info" ofType:@"js"];
        pageInfoJS = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        
		// Create tab button
		[self setTabButton:[UIButton buttonWithType:UIButtonTypeCustom]];
	
		// Style tab button
		[[tabButton layer] setCornerRadius: 5.0f];
		[[tabButton layer] setMasksToBounds:YES];
		[[tabButton layer] setBorderWidth: 0.2f];
	
		[tabButton setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
	
		tabButton.titleLabel.font = [UIFont systemFontOfSize: 11];
		[tabButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];

		tabButton.contentEdgeInsets = UIEdgeInsetsMake(0.0, 8.0, 0.0, 0.0);
		tabButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
		tabButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
	
		tabButton.frame = CGRectMake(0.0, 0.0, 100.0, 26.0);
	
		// Create close tab button
//		[self setCloseButton:[UIButton buttonWithType:UIButtonTypeCustom]];
	
//		[closeButton setTitle:@"x" forState:UIControlStateNormal];
//        [closeButton setAccessibilityLabel:@"close tab"];
//		[closeButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
//		closeButton.frame = CGRectMake(79.0, -1.0, 25.0, 25.0);
//		closeButton.titleLabel.font = [UIFont systemFontOfSize: 18];
	
		// append views
		[self addSubview:tabButton];
//		[self addSubview:closeButton];
	 
		// Set up webview
        UIWebView *wvTemplate = (UIView *)[viewController webViewTemplate];
        int minWebViewSize = wvTemplate.frame.size.height + 20; //Venus, change "+ 20"@
        int maxWebViewSize = minWebViewSize + [viewController bottomBar].frame.size.height;
        
        int height = [viewController bottomBar].alpha > 0.0 ? minWebViewSize : maxWebViewSize;
        CGRect frame = CGRectMake(wvTemplate.frame.origin.x, wvTemplate.frame.origin.y, wvTemplate.frame.size.width, height); //Venus, origin: y+60
		
        g_webView = [[UIWebView alloc] initWithFrame:frame];
		g_webView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
		g_webView.scalesPageToFit = true;
        g_webView.scrollView.scrollEnabled = YES;
        g_webView.scrollView.bounces = YES;
		[g_webView sizeToFit];
		[g_webView setDelegate:self];
        [g_webView setBackgroundColor:[UIColor whiteColor]];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextualMenuAction:) name:@"TapAndHoldNotification" object:nil];
        
        // Scroll topbar
        [[g_webView scrollView] setDelegate:viewController];

//        [[g_webView scrollView] setContentInset:UIEdgeInsetsMake([viewController topBar].frame.size.height, 0, 0, 0)];
//        [[g_webView scrollView] setContentOffset:CGPointMake(0, - [viewController topBar].frame.size.height)];
        
        [[g_webView scrollView] setContentInset:UIEdgeInsetsMake(-[g_webView scrollView].contentOffset.y, 0, 0, 0)];
        [[g_webView scrollView] setContentOffset:CGPointMake(0, - [viewController topBar].frame.size.height) animated:NO];

		[[viewController view] addSubview:g_webView];
		[[viewController view] sendSubviewToBack:g_webView];
        [[viewController view] sendSubviewToBack:[viewController webViewTemplate]];
	
        
		// Set up interactions
		[tabButton addTarget:viewController 
					action:@selector(selectTab:)
					forControlEvents:UIControlEventTouchDown];
		[closeButton addTarget:viewController 
					action:@selector(removeTab:)
					forControlEvents:UIControlEventTouchDown];
		
        //Set history
        [self setHistory:[[NSMutableArray alloc] initWithCapacity:0]];
        traverse = 0;
        history_position = 0;
	
		//Set title
		[tabButton setTitle:@"New Tab" forState:UIControlStateNormal];
		[tabButton setTitle:@"New Tab" forState:UIControlStateHighlighted];
	}
	return self;
}

-(void) setTitle:(NSString *)title {
	if ([title length] > 11) {
		title = [[title substringToIndex:11] stringByAppendingString:@".."];
	}
    
	[[self tabButton] setTitle:title forState:UIControlStateNormal];
	[[self tabButton] setTitle:title forState:UIControlStateHighlighted];
    [[self tabButton] setAccessibilityLabel:[NSString stringWithFormat:@"Tab with title %@", title]];
    [[self closeButton] setAccessibilityLabel:[NSString stringWithFormat:@"Close Tab with title %@", title]];
}

-(void) select {
    current = YES;
    UIColor *color = [UIColor colorWithRed:210/255.0 green:230/255.0 blue:240/255.0 alpha:1.0];
	[tabButton setBackgroundColor:color];
	tabButton.selected = YES;
	tabButton.enabled = NO;
	[g_webView.superview bringSubviewToFront:g_webView];
	[self.superview bringSubviewToFront:self];
}

-(void) deselect {
    current = NO;
	[tabButton setBackgroundColor:[UIColor whiteColor]];
	tabButton.selected = NO;
	tabButton.enabled = YES;
	[g_webView.superview sendSubviewToBack:g_webView];
	[self.superview sendSubviewToBack:self];
}

-(void) incrementOffset {
	self.frame = CGRectOffset(self.frame, -100.0, 0.0);
}

-(void) hideText {
    [tabButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

-(void) showText {
    [tabButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
}

// CONNECTION
#pragma mark -
#pragma mark urlConnection delegate

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse {
    self.loading =YES;
    self.urlConnection = connection;
    self.connectionURLString = [[[connection currentRequest] URL] absoluteString];
    if (![self.connectionURLString hasSuffix:@"/"]) {
        self.connectionURLString = [self.connectionURLString stringByAppendingString:@"/"];
    }
    
    if (redirectResponse) {
        NSMutableURLRequest *r = [[connection currentRequest] mutableCopy]; // original request
        [r setURL: [request URL]];
        self.currentURL = [request URL];
        self.currentURLString = [[request URL] absoluteString];
        return r;
    } else {
        return request;
    }
}

- (void)connection: (NSURLConnection*) connection didReceiveResponse: (NSHTTPURLResponse*) response
{
    self.currentURL = [response URL];
    self.currentURLString = [[response URL] absoluteString];
    [self setG_response:response];
    if (current) {
        [[self progressBar] setProgress:0.25 animated:NO];
    }
    pageData = [[NSMutableData alloc] initWithLength:0];
}

- (void) connection: (NSURLConnection*) connection didReceiveData: (NSData*) data
{
    [pageData appendData: data];
    if ([[self progressBar] progress] < 0.75) {
        [[self progressBar] setProgress:[[self progressBar] progress] + .05 animated:NO];
    }
    // Broadcast a notification with the progress change, or call a delegate
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if ([pageData length] == 0) {
        [[self history] removeLastObject];
        self.currentURL = [[[self history] lastObject] URL];
        self.currentURLString = [[[[self history] lastObject] URL] absoluteString];
        if (current && ![currentURLString isEqualToString:@"about:blank"] && [currentURLString rangeOfString:@"https://google.com"].location == NSNotFound) {
            [[viewController addressBar] setText:self.currentURLString];
        }
        
        [[self progressBar] setHidden:YES];
        return;
    }
    if ([[g_response MIMEType] isEqualToString:@"text/html"] || [[g_response MIMEType] isEqualToString:@"application/xhtml+xml"] || [[g_response MIMEType] isEqualToString:@"text/vnd.wap.wml"]) {
        NSStringEncoding *enc;
        if ([g_response textEncodingName] != nil) {
            enc = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((CFStringRef)[g_response textEncodingName]));
        } else {
            enc = NSUTF8StringEncoding;
        }
        NSString *page = (NSString *)[[NSString alloc] initWithData:pageData encoding:enc];
        
        [[self g_webView] stopLoading];
        [[self g_webView] loadHTMLString:page baseURL:self.currentURL];
        
    } else {
        [[self g_webView] stopLoading];
        [[self g_webView] loadData:pageData MIMEType:[g_response MIMEType] textEncodingName:[g_response textEncodingName] baseURL:self.currentURL];
        //[whiteView setHidden:YES];
    }
    
    [[self progressBar] setProgress:0.75 animated:NO];
    pageData = nil;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [[self progressBar] setHidden:YES];
    if ([[connection currentRequest] URL] != NULL) {
        [viewController cannotConnect:g_webView];
    } else {

     [[self g_webView] loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"launch" ofType:@"html"]isDirectory:NO]]];
     [[viewController addressBar] setText:@""];
    }
}

-(UIProgressView *) progressBar {
    return current ? [viewController progressBar] : nil;
}

#pragma mark -
#pragma mark webview delegate

-(BOOL) webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
    
    if (request == nil) {
        return NO;
    }
    
    // CAPTURE PAGE LOAD
    if ([[[request URL] absoluteString] isEqualToString:@"js:gh-page-loaded"]) {
        [self webViewDidFinishFinalLoad:webView];
    }
    
	//CAPTURE USER LINK-CLICK.
	else if (navigationType == UIWebViewNavigationTypeLinkClicked || navigationType == UIWebViewNavigationTypeFormSubmitted) {
        if ([[[request URL] absoluteString] isEqualToString:[[request mainDocumentURL] absoluteString]]) {
            NSURL *URL = [request URL];
            if ([[URL absoluteString] isEqualToString:@"about:blank"]) {
                return YES;
            }
            if ([[URL scheme] isEqualToString:@"http"] || [[URL scheme] isEqualToString:@"https"]) {
                if (current) {
                    [[viewController addressBar] setText:[URL absoluteString]];
                }
                [viewController gotoAddress:nil withRequestObj:request inTab:self];
            }
            return NO;
        }
	}
	return YES;
}

-(void) webViewDidStartLoad:(UIWebView *)webView {
}

-(void) webViewDidFinishFinalLoad:(UIWebView *)webView {
    self.loading = NO;
    if (current) {
        [viewController currentWebViewDidFinishFinalLoad:webView];
    }
    
    // set title
    NSString *tabTitleString = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    NSString *url = [webView stringByEvaluatingJavaScriptFromString:@"window.location.href"];
    if ([tabTitleString length] == 0) {
        [self setTitle:@"Untitled"];
    } else {
        [self setTitle:tabTitleString];
    }
    
    NSLog(@"TESTER Loaded url: %@", [webView.request mainDocumentURL]);
    NSLog(@"TESTER Loaded title: %@", tabTitleString);
    
    url = [[webView.request mainDocumentURL] absoluteString];
    tabTitleLabel.text = tabTitleString;

    if (traverse != -1)
        [self updateHistory];


    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy.MM.dd-HH:mm:ss"];
    [df setTimeZone:[NSTimeZone systemTimeZone]];
    NSString *dateString = [df stringFromDate:[NSDate date]];
    
    NSLog(@"%@", [AppDelegate sharedInstance].userChildInfo[@"Token"]);
    NSLog(@"date = %@", dateString);
    
    tempDict = [[NSMutableDictionary alloc] init];
    [tempDict setObject:[AppDelegate sharedInstance].userChildInfo[@"Token"] forKey:@"SurferToken"];
    [tempDict setObject:dateString forKey:@"SurfedAt"];
    [tempDict setObject:url forKey:@"Url"];
    [tempDict setObject:tabTitleString forKey:@"Title"];
    [tempDict setObject:@"text/html" forKey:@"ContentType"];
    [tempDict setObject:@"200" forKey:@"StatusCode"];

    NSLog(@"%@", tempDict);

    if (![AppDelegate sharedInstance].bParent) {
        [self performSelector:@selector(delayedDidFinish) withObject:nil afterDelay:0.0];
    }
}

- (void)delayedDidFinish{
    NSString *accountToken = [AppDelegate sharedInstance].accountInfo[@"account"][@"token"];
    
    NSString *devToken;
    if ([AppDelegate sharedInstance].bNewDevice) {
        devToken = [AppDelegate sharedInstance].deviceInfo[@"Tokens"][1][@"Content"];
    }else{
        devToken = [AppDelegate sharedInstance].deviceInfo[@"Token"];
    }
    
    NSString *urlString = [NSString stringWithFormat:@"%@/%@/%@", LogAPI, accountToken, devToken];
    //    POST /logs/ship/{accountToken}/{deviceToken}/{isGzipped}/{isRetry}

    NSDictionary *param = [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:tempDict, nil], @"Surfages", nil];
    NSLog(@"%@", param);

    [[AppDelegate sharedInstance] postResource:@"" andMethod:@"POST" andWithParams:param andLink:urlString AndCallback:^(id result, NSError *error) {
        [MBProgressHUD hideAllHUDsForView:self animated:YES];
        
        NSLog(@"%@", result);
        if (result != NULL) {
            if ([result isKindOfClass:[NSDictionary class]] && [[result allKeys] count] > 1) {
                
            }else{
                [[AppDelegate sharedInstance] showAlertMessage:@"" message:result[@"status"]];
            }
        }else {
            [[AppDelegate sharedInstance] showAlertMessage:@"" message:@"please try again"];
        }
    }];
}

-(void) webViewDidFinishLoad:(UIWebView *)webView {
    if (![[[webView request] URL] isFileURL] && currentURL != nil) {
        [webView stringByEvaluatingJavaScriptFromString:@"if (document.getElementById('gh-page-loaded') == null && document.documentElement.innerHTML != '<head></head><body></body>') {"
         "var iframe = document.createElement('IFRAME');"
         "iframe.setAttribute('id','gh-page-loaded');"
         "iframe.setAttribute('src', 'js:gh-page-loaded');"
         "iframe.setAttribute('style', 'display:none');"
         "document.body.appendChild(iframe);"
         "iframe = null;"
         "document.body.style.webkitTouchCallout='none';}" ];
    }
}

- (void)contextualMenuAction:(NSNotification*)notification
{
    if (actionSheetVisible || g_webView != [viewController webView]) {
        return;
    }
    CGPoint pt;
    NSDictionary *coord = [notification object];
    pt.x = [[coord objectForKey:@"x"] floatValue];
    pt.y = [[coord objectForKey:@"y"] floatValue];
    
    // convert point from window to view coordinate system
    pt = [g_webView convertPoint:pt fromView:nil];
    
    // convert point from view to HTML coordinate system
//    CGPoint offset  = [self scrollOffset];
    CGSize viewSize = [g_webView frame].size;
    CGSize windowSize = [self windowSize];
    
    CGFloat f = windowSize.width / viewSize.width;
    pt.x = pt.x * f;// + offset.x;
    pt.y = pt.y * f;// + offset.y;
    
    [self openContextualMenuAt:pt];}


- (void)openContextualMenuAt:(CGPoint)pt
{
    // Load the JavaScript code from the Resources and inject it into the web page
    NSString *path = [[NSBundle mainBundle] pathForResource:@"JSTools" ofType:@"js"];
    NSString *jsCode = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    [g_webView stringByEvaluatingJavaScriptFromString: jsCode];
    
    NSInteger topOffset;
    if ([viewController isPad]) {
        topOffset = ((NSInteger)[viewController topBar].frame.size.height) +
        ((NSInteger)[(UIMainView *)[viewController view] statusBarView].frame.size.height);
    } else {
        topOffset = ((NSInteger)[(UIMainView *)[viewController view] statusBarView].frame.size.height);
    }
    
    // get the Tags at the touch location
    NSArray *r = [[g_webView stringByEvaluatingJavaScriptFromString:
                      [NSString stringWithFormat:@"MyAppGetHTMLElementsAtPoint(%i,%i);",(NSInteger)pt.x,(NSInteger)pt.y - topOffset]] componentsSeparatedByString:@"|"];
    
    NSString *tags = [r objectAtIndex:0];
    NSString *url = [r objectAtIndex:1];
    
    // create the UIActionSheet and populate it with buttons related to the tags
    if ([url isEqualToString:@""]) {
        return;
    }
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:[url isEqualToString:@""] ? @"Menu" : url
                                                       delegate:self cancelButtonTitle:@"Cancel"
                                         destructiveButtonTitle:nil otherButtonTitles:nil];
    
    
    // If a link was touched, add link-related buttons
    if ([tags rangeOfString:@",A,"].location != NSNotFound) {
        [sheet addButtonWithTitle:@"Open Link"];
        [sheet addButtonWithTitle:@"Open Link in New Tab"];
        [sheet addButtonWithTitle:@"Copy Link"];
    }
    // If an image was touched, add image-related buttons
    if ([tags rangeOfString:@",IMG,"].location != NSNotFound) {
        [sheet addButtonWithTitle:@"Save Image"];
    }
    // Add buttons which should be always available
    [sheet addButtonWithTitle:@"Save Page as Bookmark"];
    [sheet addButtonWithTitle:@"Open Page in Safari"];
    
    [sheet showInView:g_webView];
}

- (CGSize)windowSize
{
    CGSize size;
    size.width = [[g_webView stringByEvaluatingJavaScriptFromString:@"window.innerWidth"] integerValue];
    size.height = [[g_webView stringByEvaluatingJavaScriptFromString:@"window.innerHeight"] integerValue];
    return size;
}

- (CGPoint)scrollOffset
{
    CGPoint pt;
    pt.x = [[g_webView stringByEvaluatingJavaScriptFromString:@"window.pageXOffset"] integerValue];
    pt.y = [[g_webView stringByEvaluatingJavaScriptFromString:@"window.pageYOffset"] integerValue];
    return pt;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSURL *url = [NSURL URLWithString:[actionSheet title]];
    NSString *clickedButton = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([clickedButton isEqualToString:@"Open Link"]) {
        [viewController gotoAddress:nil withRequestObj:[[NSURLRequest alloc] initWithURL:url] inTab:self];
    } else if ([clickedButton isEqualToString:@"Open Link in New Tab"]) {
        [viewController addTabWithAddress:[actionSheet title]];
    } else if ([clickedButton isEqualToString:@"Copy Link"]) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = [url absoluteString];
        [actionSheet resignFirstResponder];
    } else if ([clickedButton isEqualToString:@"Save Image"]) {
        UIImage *imageToBeSaved = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:url]];
        UIImageWriteToSavedPhotosAlbum(imageToBeSaved, nil, nil, nil);
    } else if ([clickedButton isEqualToString:@"Save Page as Bookmark"]) {
        [[viewController bookmarksFormController] setDefaultUrlFieldText:[url absoluteString]];
        [viewController addBookmarkFromSheet:actionSheet];
        [actionSheet resignFirstResponder];
    } else if ([clickedButton isEqualToString:@"Open Page in Safari"]) {
        [actionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
        [[UIApplication sharedApplication] openURL:url];
    }
}

- (void)didPresentActionSheet:(UIActionSheet *)actionSheet {
    actionSheetVisible = YES;
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    actionSheetVisible = NO;
}

// HISTORY
-(BOOL) canGoBack {
    return history.count > 0 && history_position > 0;
}

-(BOOL) canGoForward {
    return history.count > 0 && history_position < history.count - 1;
}

-(void) goBack {
    [self go:-1];
}

-(void) goForward {
    [self go:1];
}

-(void) go:(int)t {
    if (history.count > 0) {
        NSArray *req;
        [viewController forwardButton].enabled = FALSE;
        [viewController backButton].enabled = FALSE;
        traverse = t;
        history_position += traverse;

        if (history_position < 0){
            NSLog(@"Can not go back any more");
        }else if (history_position >=  [history count]) {
            req = [history lastObject];
        }else {
            req = [history objectAtIndex:history_position];
        }
        
        //[[viewController addressBar] setText:[[req URL] absoluteString]];
        if (req != nil) {
            [viewController gotoAddress:nil withRequestObj:req inTab:self];
        }
        
//        traverse = 0;
        if (history_position <= 0){
            [viewController.gobackButton setEnabled:NO];
            [viewController.gobackButton setAlpha:0.3];
        }else{
            [viewController.gobackButton setEnabled:YES];
            [viewController.gobackButton setAlpha:1.0];
        }
    }
}

-(void) updateHistory {
    if (traverse == 0) {
        if (history_position + 1 < history.count) {
            [history removeObjectsInRange:NSMakeRange(history_position + 1, history.count - history_position - 1)];
        }
        NSURLRequest *req = [[[self urlConnection] currentRequest] mutableCopy];
        
        [history addObject:req];
        history_position = history.count - 1;
    }
    traverse = 0;
    
    if (history_position <= 0){
        [viewController.gobackButton setEnabled:NO];
        [viewController.gobackButton setAlpha:0.3];
    }else{
        [viewController.gobackButton setEnabled:YES];
        [viewController.gobackButton setAlpha:1.0];
    }
}

@end