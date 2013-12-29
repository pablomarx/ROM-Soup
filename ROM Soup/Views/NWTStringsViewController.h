//
//  NWTStringsViewController.h
//  ROM Soup
//
//  Created by Steve White on 12/28/13.
//  Copyright (c) 2013 Steve White. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NWTStringsViewController : NSViewController<NSTableViewDataSource, NSTableViewDelegate> {
  NSString *_romGlobalVarName;
  NSMutableArray *_strings;
  NSTableView *_tableView;
  CGFloat _tableColumnWidth;
}

@property (strong, atomic) NSString *romGlobalVarName;
@property (strong, atomic) IBOutlet NSTableView *tableView;

@end
