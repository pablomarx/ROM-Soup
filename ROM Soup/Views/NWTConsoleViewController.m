//
//  NWTConsoleViewController.m
//  ROM Soup
//
//  Created by Steve White on 12/26/13.
//  Copyright (c) 2013 Steve White. All rights reserved.
//

#import "NWTConsoleViewController.h"
#import "NWTConsoleBackend.h"

@implementation NWTConsoleViewController

@synthesize webView = _webView;
@synthesize romGlobalVarName = _romGlobalVarName;

- (NSString *) nibName {
  return NSStringFromClass([self class]);
}

- (NSString *) title {
  return NSLocalizedString(@"Console", @"Console");
}

- (void) awakeFromNib {
  [super awakeFromNib];
  
  NSBundle *mainBundle = [NSBundle mainBundle];
  
  WebView *webView = self.webView;
  
  // Custom style sheet to neuter some unwanted bits of the WebKit Inspector
  WebPreferences *webPreferences = webView.preferences;
  [webPreferences setUserStyleSheetEnabled:YES];
  NSURL *styleSheetURL = [NSURL fileURLWithPath:[mainBundle pathForResource:@"userStyle" ofType:@"css"]];
  [webPreferences setUserStyleSheetLocation:styleSheetURL];
  
  NSString *inspectorRoot = [mainBundle pathForResource:@"webkit" ofType:@""];
  NSString *inspectorPath = [inspectorRoot stringByAppendingPathComponent:@"WebCore/inspector/front-end/inspector.html"];
  NSString *inspectorContents = [NSString stringWithContentsOfFile:inspectorPath
                                                      usedEncoding:nil
                                                             error:nil];
  [webView.mainFrame loadHTMLString:inspectorContents
                            baseURL:[NSURL fileURLWithPath:[inspectorPath stringByDeletingLastPathComponent]]];
}

- (void) loadInspectorROMDefinition {
  if (self.romGlobalVarName == nil) {
    return;
  }
  
  NSString *initScript = @"WebInspector.console.prompt.text = \"%@\"\n"\
  "var dummyEvent = { altKey: false, ctrlKey: false, shiftKey: false, cancelBubble: function(){}, preventDefault: function(){}, stopPropagation: function(){} };\n" \
  "WebInspector.console._enterKeyPressed.call(WebInspector.console, dummyEvent);\n"
  ;
  [self.webView.windowScriptObject evaluateWebScript:[NSString stringWithFormat:initScript, self.romGlobalVarName]];
}

- (void)webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)windowObject forFrame:(WebFrame *)frame {
  NWTConsoleBackend *backend = [[NWTConsoleBackend alloc] init];
  [windowObject setValue:backend forKey:@"NWTConsoleBackend"];
}

- (void) webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
  if (frame == sender.mainFrame) {
    NSString *selectConsolePanelScript = @"WebInspector.ConsolePanel.prototype.show.apply(WebInspector.panels.console);";
    [sender.windowScriptObject evaluateWebScript:selectConsolePanelScript];
    [self loadInspectorROMDefinition];
  }
}

@end
