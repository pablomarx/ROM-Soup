//
//  NWTHexViewWindowController.h
//  ROM Soup
//
//  Created by Steve White on 12/28/13.
//  Copyright (c) 2013 Steve White. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class HFController;
@class HFLayoutRepresenter;
@class NWTBlobItem;

@interface NWTHexViewWindowController : NSWindowController {
  NSView *_containerView;
  HFController *_inMemoryController;
  HFLayoutRepresenter *_layoutRep;
  NWTBlobItem *_blobItem;
}

@property (strong, atomic) IBOutlet NSView *containerView;
@property (readonly, atomic) NWTBlobItem *blobItem;

- (id) initWithBlobItem:(NWTBlobItem *)blobItem;

@end
