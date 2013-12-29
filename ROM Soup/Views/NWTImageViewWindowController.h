//
//  NWTImageViewWindowController.h
//  ROM Soup
//
//  Created by Steve White on 12/28/13.
//  Copyright (c) 2013 Steve White. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class IKImageView;
@class NWTImageBrowserItem;

@interface NWTImageViewWindowController : NSWindowController {
  NWTImageBrowserItem *_imageItem;
  IKImageView *_imageView;
}

@property (strong, atomic) IBOutlet IKImageView *imageView;
@property (readonly, atomic) NWTImageBrowserItem *imageItem;

- (id) initWithImageItem:(NWTImageBrowserItem *)imageItem;

@end
