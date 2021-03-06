//
//  NWTDocument.h
//  ROM Soup
//
//  Created by Steve White on 12/25/13.
//  Copyright (c) 2013 Steve White. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NWTDocument : NSDocument<NSToolbarDelegate> {
  NSViewController *_activeViewController;
  NSMutableArray *_viewControllers;
  NSString *_romGlobalVarName;
  
  NSToolbar *_toolbar;
  NSView *_contentView;
}

@property (strong, atomic) NSToolbar *toolbar;
@property (strong, atomic) IBOutlet NSView *contentView;

@end

@interface NSViewController (NWTViewController)
- (void) setRomGlobalVarName:(NSString *)identifier;
- (NSImage *) toolbarImage;
@end