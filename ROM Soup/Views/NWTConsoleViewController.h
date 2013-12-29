//
//  NWTConsoleViewController.h
//  ROM Soup
//
//  Created by Steve White on 12/26/13.
//  Copyright (c) 2013 Steve White. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface NWTConsoleViewController : NSViewController {
  WebView *_webView;
  NSString *_romGlobalVarName;
}

@property (strong, atomic) IBOutlet WebView *webView;
@property (strong, atomic) NSString *romGlobalVarName;

@end
