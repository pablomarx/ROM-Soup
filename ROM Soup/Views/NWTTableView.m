//
//  NWTTableView.m
//  ROM Soup
//
//  Created by Steve White on 12/28/13.
//  Copyright (c) 2013 Steve White. All rights reserved.
//

#import "NWTTableView.h"

@implementation NWTTableView

- (NSMenu*)menuForEvent:(NSEvent*)event
{
	if ([[self delegate] respondsToSelector:@selector(tableView:menuForRows:)] == NO) {
    return [super menuForEvent:event];
  }
  
	NSPoint location = [self convertPoint:[event locationInWindow] fromView:nil];
	NSInteger row = [self rowAtPoint:location];
  if (row < 0) {
    return [super menuForEvent:event];
  }
  
  if ([event type] != NSRightMouseDown && ([event type] != NSLeftMouseDown || ([event modifierFlags] & NSControlKeyMask) != NSControlKeyMask)) {
		return [super menuForEvent:event];
  }
  
	NSIndexSet *selected = [self selectedRowIndexes];
	if ([selected containsIndex:row] == NO) {
		selected = [NSIndexSet indexSetWithIndex:row];
		[self selectRowIndexes:selected byExtendingSelection:NO];
	}

  return [(id)[self delegate] tableView:self menuForRows:selected];
}

- (void)keyDown:(NSEvent *)event {
	if ([[self delegate] respondsToSelector:@selector(tableViewEnterKeyPressed:)] == NO) {
    [super keyDown:event];
    return;
  }
  
  unichar  u = [[event charactersIgnoringModifiers]
                characterAtIndex: 0];
  
  if (u == NSEnterCharacter || u == NSCarriageReturnCharacter) {
    [(id)[self delegate] tableViewEnterKeyPressed:self];
  }
  else {
    [super keyDown:event];  // all other keys
  }
}

@end
