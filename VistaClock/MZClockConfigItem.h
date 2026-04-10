//
//  MZClockConfigItem.h
//  VistaClock
//
//  Created by Paul Wong on 5/27/14.
//  Copyright (c) 2026 Mazookie, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MZClockConfigItem : NSCollectionViewItem

@property (nonatomic, retain) IBOutlet NSTextField* titleConfigLabel;
@property (nonatomic, retain) IBOutlet NSTextField* timezoneConfigLabel;
@property (nonatomic, retain) IBOutlet NSButton* deleteButton;
@property (nonatomic, retain) IBOutlet NSButton* upButton;
@property (nonatomic, retain) IBOutlet NSButton* downButton;
    
@property (nonatomic, assign) bool useSecond;

-(void) setRepresentedObject:(id)object;

@end
