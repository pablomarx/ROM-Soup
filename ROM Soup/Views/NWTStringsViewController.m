//
//  NWTStringsViewController.m
//  ROM Soup
//
//  Created by Steve White on 12/28/13.
//  Copyright (c) 2013 Steve White. All rights reserved.
//

#import "NWTStringsViewController.h"

#import "NWTObjectEnumerator.h"

#include "NewtObj.h"

@implementation NWTStringsViewController

@synthesize romGlobalVarName = _romGlobalVarName;
@synthesize tableView = _tableView;

- (id) init {
  self = [super init];
  if (self != nil) {
    _strings = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void) dealloc {
  [_romGlobalVarName release];
  [_strings release];
  [_tableView release];
  [super dealloc];
}

- (NSString *) title {
  return NSLocalizedString(@"Strings", @"Strings");
}

- (NSString *) nibName {
  return NSStringFromClass([self class]);
}

- (void) awakeFromNib {
  [super awakeFromNib];
  
  NSMutableSet *valueRefs = [NSMutableSet set];
  NSMutableSet *uniqueStrings = [NSMutableSet set];
  [NWTObjectEnumerator enumerateGlobalVarNamed:self.romGlobalVarName
                                    usingBlock:^(newtRef parentRef, newtRef keyRef, newtRef valueRef, BOOL *stop)
   {
     // We're only interested in binaries
     if (NewtRefIsString(valueRef) == false || [valueRefs containsObject:@(valueRef)]) {
       return;
     }
     
     [valueRefs addObject:@(valueRef)];
     NSString *string = [NSString stringWithCString:NewtRefToString(valueRef)
                                           encoding:NSUTF8StringEncoding];
     if ([[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0) {
       return;
     }
     
     [uniqueStrings addObject:[string stringByReplacingOccurrencesOfString:@"\r"
                                                                withString:@"\n"]];
   }];
  
  [_strings addObjectsFromArray:[uniqueStrings allObjects]];
  [_strings sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
  [self.tableView setRowSizeStyle:NSTableViewRowSizeStyleCustom];
}

#pragma mark - 
#pragma mark
/*
 * Taken from:
 * https://developer.apple.com/library/mac/samplecode/CocoaTipsAndTricks/Listings/TableViewVariableRowHeights_TableViewVariableRowHeightsAppDelegate_m.html
 */
- (void)tableViewColumnDidResize:(NSNotification *)notification {
  _tableColumnWidth = [[[_tableView tableColumns] lastObject] width];
  // Tell the table that we will have changed the row heights
  [_tableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, _tableView.numberOfRows)]];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
  
  // It is important to use a constant value when calculating the height. Querying the tableColumn width will not work, since it dynamically changes as the user resizes -- however, we don't get a notification that the user "did resize" it until after the mouse is let go. We use the latter as a hook for telling the table that the heights changed. We must return the same height from this method every time, until we tell the table the heights have changed. Not doing so will quicly cause drawing problems.
  NSTableColumn *tableColumnToWrap = [[_tableView tableColumns] lastObject];
  NSInteger columnToWrap = [_tableView.tableColumns indexOfObject:tableColumnToWrap];
  
  // Grab the fully prepared cell with our content filled in. Note that in IB the cell's Layout is set to Wraps.
  NSCell *cell = [tableView preparedCellAtColumn:columnToWrap row:row];
  
  // See how tall it naturally would want to be if given a restricted with, but unbound height
  NSRect constrainedBounds = NSMakeRect(0, 0, _tableColumnWidth, CGFLOAT_MAX);
  NSSize naturalSize = [cell cellSizeForBounds:constrainedBounds];
  
  // Make sure we have a minimum height -- use the table's set height as the minimum.
  if (naturalSize.height > [_tableView rowHeight]) {
    return naturalSize.height;
  } else {
    return [_tableView rowHeight];
  }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
  return [_strings count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
  return [_strings objectAtIndex:rowIndex];
}

  @end
