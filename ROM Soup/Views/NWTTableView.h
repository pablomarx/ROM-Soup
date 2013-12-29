//
//  NWTTableView.h
//  ROM Soup
//
//  Created by Steve White on 12/28/13.
//  Copyright (c) 2013 Steve White. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NWTTableView : NSTableView

@end

@interface NSObject (NWTTableViewDelegate)
- (NSMenu*)tableView:(NSTableView*)aTableView menuForRows:(NSIndexSet*)rows;
- (void) tableViewEnterKeyPressed:(NSTableView *)tableView;
@end