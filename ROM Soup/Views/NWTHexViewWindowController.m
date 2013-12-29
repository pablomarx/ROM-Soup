//
//  NWTHexViewWindowController.m
//  ROM Soup
//
//  Created by Steve White on 12/28/13.
//  Copyright (c) 2013 Steve White. All rights reserved.
//

#import "NWTHexViewWindowController.h"

#import <HexFiend/HexFiend.h>

#import "NWTBlobsViewController.h"

@implementation NWTHexViewWindowController

@synthesize containerView = _containerView;
@synthesize blobItem = _blobItem;

- (id) initWithBlobItem:(NWTBlobItem *)blobItem {
  self = [self init];
  if (self != nil) {
    _blobItem = blobItem;
  }
  return self;
}

- (void) dealloc {
  [_layoutRep release];
  [_containerView release];
  [_inMemoryController release];
  [super dealloc];
}

- (NSString *) windowNibName {
  return NSStringFromClass([self class]);
}

- (void) windowDidLoad {
  [super windowDidLoad];
  
  NWTBlobItem *blobItem = self.blobItem;
  NSMutableString *windowTitle = [NSMutableString string];
  if (blobItem.name != nil) {
    [windowTitle appendString:blobItem.name];
    [windowTitle appendString:@" "];
  }
  if (blobItem.className != nil) {
    [windowTitle appendFormat:@"(%@) ", blobItem.className];
  }
  [windowTitle appendFormat:@"@ %i", blobItem.itemRef];
  [self.window setTitle:windowTitle];

  _inMemoryController = [[HFController alloc] init];
  [_inMemoryController setBytesPerColumn:4];
   
  /* Put our data in a byte slice. */
  HFSharedMemoryByteSlice *byteSlice = [[[HFSharedMemoryByteSlice alloc] initWithData:[[blobItem.data mutableCopy] autorelease]] autorelease];
  HFByteArray *byteArray = [[[HFBTreeByteArray alloc] init] autorelease];
  [byteArray insertByteSlice:byteSlice inRange:HFRangeMake(0, 0)];
  [_inMemoryController setByteArray:byteArray];
  
  /* Here we're going to make three representers - one for the hex, one for the ASCII, and one for the scrollbar.  To lay these all out properly, we'll use a fourth HFLayoutRepresenter. */
  _layoutRep = [[HFLayoutRepresenter alloc] init];

  HFLineCountingRepresenter *lineRep = [[[HFLineCountingRepresenter alloc] init] autorelease];
  HFHexTextRepresenter *hexRep = [[[HFHexTextRepresenter alloc] init] autorelease];
  HFStringEncodingTextRepresenter *asciiRep = [[[HFStringEncodingTextRepresenter alloc] init] autorelease];
  HFVerticalScrollerRepresenter *scrollRep = [[[HFVerticalScrollerRepresenter alloc] init] autorelease];
  
  /* Add all our reps to the controller. */
  [_inMemoryController addRepresenter:lineRep];
  [_inMemoryController addRepresenter:_layoutRep];
  [_inMemoryController addRepresenter:hexRep];
  [_inMemoryController addRepresenter:asciiRep];
  [_inMemoryController addRepresenter:scrollRep];
  
  /* Tell the layout rep which reps it should lay out. */
  [_layoutRep addRepresenter:lineRep];
  [_layoutRep addRepresenter:hexRep];
  [_layoutRep addRepresenter:asciiRep];
  [_layoutRep addRepresenter:scrollRep];
  
  /* Grab the layout rep's view and stick it into our container. */
  NSView *layoutView = [_layoutRep view];
  [layoutView setFrame:[self.containerView bounds]];
  [layoutView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
  [self.containerView addSubview:layoutView];
}

- (void)windowDidBecomeKey:(NSNotification *)notification {
  NSRect windowFrame = [self.window frame];
  windowFrame.size.width = [_layoutRep minimumViewWidthForLayoutInProposedWidth:windowFrame.size.width];
  [self.window setFrame:windowFrame display:NO animate:NO];
}

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize {
  return (NSSize){
    .width = [_layoutRep minimumViewWidthForLayoutInProposedWidth:frameSize.width],
    .height = frameSize.height
  };
}

@end
