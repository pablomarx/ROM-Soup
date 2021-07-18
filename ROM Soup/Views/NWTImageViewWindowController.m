//
//  NWTImageViewWindowController.m
//  ROM Soup
//
//  Created by Steve White on 12/28/13.
//  Copyright (c) 2013 Steve White. All rights reserved.
//

#import "NWTImageViewWindowController.h"
#import <Quartz/Quartz.h>
#import "NWTImageBrowserViewController.h"

@implementation NWTImageViewWindowController

@synthesize imageView = _imageView;
@synthesize imageItem = _imageItem;

- (id) initWithImageItem:(NWTImageBrowserItem *)imageItem {
  self = [self init];
  if (self != nil) {
    _imageItem = imageItem;
  }
  return self;
}

- (NSString *) windowNibName {
  return NSStringFromClass([self class]);
}

- (void)windowDidLoad {
  [super windowDidLoad];
  
  NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:[_imageItem imageRepresentation]];
  [self.imageView setImage:[imageRep CGImage]
           imageProperties:nil];
  
  [self.window setTitle:[_imageItem imageTitle]];
}

@end
