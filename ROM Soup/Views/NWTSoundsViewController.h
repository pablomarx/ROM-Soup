//
//  NWTSoundsViewController.h
//  ROM Soup
//
//  Created by Steve White on 12/27/13.
//  Copyright (c) 2013 Steve White. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <Cocoa/Cocoa.h>

@interface NWTSoundsViewController : NSViewController<AVAudioPlayerDelegate, NSTableViewDataSource, NSTableViewDelegate> {
  NSTableView *_tableView;
  NSString *_romGlobalVarName;
  NSMutableArray *_sounds;
  AVAudioPlayer *_player;
}

@property (strong, atomic) NSString *romGlobalVarName;
@property (strong, atomic) IBOutlet NSTableView *tableView;

@end
