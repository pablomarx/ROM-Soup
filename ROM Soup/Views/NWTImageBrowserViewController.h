//
//  NWTImageBrowserViewController.h
//  ROM Soup
//
//  Created by Steve White on 12/26/13.
//  Copyright (c) 2013 Steve White. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

@interface NWTImageBrowserViewController : NSViewController {
  IKImageBrowserView *_imageBrowser;
  NSString *_romGlobalVarName;
  NSMutableArray *_images;
  NSMutableArray *_imageWindows;
}

@property (strong, atomic) IBOutlet IKImageBrowserView *imageBrowser;
@property (strong, atomic) NSString *romGlobalVarName;

@end

@interface NWTImageBrowserItem : NSObject {
  NSString *_imageTitle;
  NSString *_imageUID;
  NSString *_imageRepresentationType;
  id _imageRepresentation;
  BOOL _pict;
}

@property (strong, atomic) NSString *imageTitle;
@property (strong, atomic) NSString *imageUID;
@property (strong, atomic) NSString *imageRepresentationType;
@property (strong, atomic) id imageRepresentation;
@property (atomic, getter = isPICT) BOOL pict;

@end
