//
//  NWTBlobsViewController.h
//  ROM Soup
//
//  Created by Steve White on 12/28/13.
//  Copyright (c) 2013 Steve White. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "NewtType.h"

@interface NWTBlobsViewController : NSViewController<NSTableViewDataSource, NSTableViewDelegate> {
  NSMutableArray *_hexWindows;
  NSTableView *_tableView;
  NSString *_romGlobalVarName;
  NSArray *_blobs;
}

@property (strong, atomic) NSString *romGlobalVarName;
@property (strong, atomic) IBOutlet NSTableView *tableView;

- (IBAction)tableViewRowWasDoubleClicked:(id)sender;

@end

@interface NWTBlobItem : NSObject {
  newtRef _itemRef;
  NSString *_name;
  NSString *_className;
  NSUInteger _length;
}

@property (atomic) newtRef itemRef;
@property (strong, atomic) NSString *name;
@property (strong, atomic) NSString *className;
@property (atomic) NSUInteger length;
@property (readonly, atomic) NSData *data;

@end
