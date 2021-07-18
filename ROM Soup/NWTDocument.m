//
//  NWTDocument.m
//  ROM Soup
//
//  Created by Steve White on 12/25/13.
//  Copyright (c) 2013 Steve White. All rights reserved.
//

#import "NWTDocument.h"

#import "NWTRomImporter.h"

#import "NWTBlobsViewController.h"
#import "NWTConsoleViewController.h"
#import "NWTImageBrowserViewController.h"
#import "NWTSoundsViewController.h"
#import "NWTStringsViewController.h"

static NSString *NWTDocumentViewControllerPrefix = @"viewController-";

@implementation NWTDocument

@synthesize toolbar = _toolbar;
@synthesize contentView = _contentView;

- (id) init {
  self = [super init];
  if (self != nil) {
    _viewControllers = [[NSMutableArray alloc] init];
  }
  return self;
}

- (NSString *)windowNibName {
  return @"NWTDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
  [super windowControllerDidLoadNib:aController];
  
  NWTConsoleViewController *consoleController = [[NWTConsoleViewController alloc] init];
  [_viewControllers addObject:consoleController];

  NWTImageBrowserViewController *imagesController = [[NWTImageBrowserViewController alloc] init];
  [_viewControllers addObject:imagesController];

  NWTSoundsViewController *soundsController = [[NWTSoundsViewController alloc] init];
  [_viewControllers addObject:soundsController];

  NWTBlobsViewController *blobsController = [[NWTBlobsViewController alloc] init];
  [_viewControllers addObject:blobsController];

  NWTStringsViewController *stringsController = [[NWTStringsViewController alloc] init];
  [_viewControllers addObject:stringsController];

  for (NSViewController *aViewController in _viewControllers) {
    if ([aViewController respondsToSelector:@selector(setRomGlobalVarName:)]) {
      [aViewController setRomGlobalVarName:_romGlobalVarName];
    }
  }

  // Unique identifier so that any other windows don't intefere with
  // our toolbar
  NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:[NSString stringWithFormat:@"%p", self]];
  toolbar.delegate = self;
  toolbar.displayMode = NSToolbarDisplayModeLabelOnly;
  aController.window.toolbar = toolbar;
  self.toolbar = toolbar;
  
  [self setActiveViewController:[_viewControllers objectAtIndex:0]];
}

+ (BOOL)autosavesInPlace {
  return NO;
}

- (void)updateChangeCount:(NSDocumentChangeType)changeType {
  // Not passing along to super as I don't want the "needs save" icon
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
  NSException *exception = [NSException exceptionWithName:@"UnimplementedMethod"
                                                   reason:[NSString stringWithFormat:@"%@ is unimplemented", NSStringFromSelector(_cmd)]
                                                 userInfo:nil];
  @throw exception;
  return nil;
}

- (BOOL) readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
  NSString *romFile = [url path];
  NWTROMImporter *romImporter = [[NWTROMImporter alloc] initWithContentsOfFile:romFile
                                                                         error:outError];
  if (romImporter == nil) {
    return NO;
  }
  
  NSString *romName = [[romFile lastPathComponent] stringByDeletingPathExtension];
  NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(^\\d*|\\s|\\W)" options:0 error:nil];
  _romGlobalVarName = [regex stringByReplacingMatchesInString:romName options:0 range:NSMakeRange(0, [romName length]) withTemplate:@""];

  romImporter.romGlobalVarName = _romGlobalVarName;
  BOOL success = NO;
  @try {
    [romImporter import];
    success = YES;
  }
  @catch (id e) {
    NSRunAlertPanel(NSLocalizedString(@"Deep toast alert", @"Deep toast alert"),
                    [NSString stringWithFormat:@"Importing the ROM resulted in: %@", e],
                    NSLocalizedString(@"Bummer!", @"Bummer!"),
                    nil,
                    nil);
  }

  return success;
}

#pragma mark -
#pragma mark Toolbar / ViewController switching
- (void) setActiveViewController:(NSViewController *)viewController {
  if (_activeViewController == viewController) {
    return;
  }
  
  NSView *contentView = self.contentView;
  if (_activeViewController != nil) {
    if ([_activeViewController.view superview] == contentView) {
      [_activeViewController.view removeFromSuperview];
    }
  }
  
  _activeViewController = viewController;
  
  if (viewController != nil) {
    NSView *view = [viewController view];
    view.frame = contentView.bounds;
    view.autoresizingMask = NSViewMinXMargin | NSViewMinYMargin | NSViewMaxXMargin | NSViewMaxYMargin | NSViewWidthSizable | NSViewHeightSizable;
    [contentView addSubview:view];
  }

  [self.toolbar setSelectedItemIdentifier:[self toolbarIdentifierForViewController:_activeViewController]];
}

- (NSViewController *) viewControllerWithToolbarIdentifier:(NSString *)itemIdentifier {
  if ([itemIdentifier hasPrefix:NWTDocumentViewControllerPrefix] == NO) {
    return nil;
  }
  
  NSInteger vcIndex = [[itemIdentifier substringFromIndex:[NWTDocumentViewControllerPrefix length]] integerValue];
  NSViewController *viewController = [_viewControllers objectAtIndex:vcIndex];
  return viewController;
}

- (NSString *) toolbarIdentifierForViewController:(NSViewController *)viewController {
  NSInteger vcIndex = [_viewControllers indexOfObject:viewController];
  if (vcIndex == NSNotFound) {
    return nil;
  }
  
  NSString *toolbarIdentifier = [NSString stringWithFormat:@"%@%i", NWTDocumentViewControllerPrefix, vcIndex];
  return toolbarIdentifier;
}

- (IBAction)changeViewController:(id)sender {
  if ([sender isKindOfClass:[NSToolbarItem class]] == NO) {
    return;
  }
  
  NSViewController *viewController = [self viewControllerWithToolbarIdentifier:[sender itemIdentifier]];
  [self setActiveViewController:viewController];
}

#pragma mark -
#pragma mark NSToolbar delegates
- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar {
  NSMutableArray *identifiers = [NSMutableArray array];
  for (int i=0; i<[_viewControllers count]; i++) {
    NSString *toolbarIdentifier = [NSString stringWithFormat:@"%@%i", NWTDocumentViewControllerPrefix, i];
    [identifiers addObject:toolbarIdentifier];
  }
  return identifiers;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
  return [self toolbarSelectableItemIdentifiers:toolbar];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
  return [self toolbarSelectableItemIdentifiers:toolbar];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
     itemForItemIdentifier:(NSString *)itemIdentifier
 willBeInsertedIntoToolbar:(BOOL)flag
{
  NSViewController *viewController = [self viewControllerWithToolbarIdentifier:itemIdentifier];
  if (viewController == nil) {
    return nil;
  }
  
  NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
  [item setAction:@selector(changeViewController:)];
  [item setTarget:self];
  [item setLabel:[viewController title]];
  if ([viewController respondsToSelector:@selector(toolbarImage)]) {
    [item setImage:[viewController toolbarImage]];
  }
  return item;
}

@end
