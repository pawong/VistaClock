//
//  MZClockItem.h
//  VistaClock
//
//  Created by Paul Wong on 5/27/14.
//  Copyright (c) 2014 Mazookie, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MZClockControl.h"

@interface MZClockItem : NSCollectionViewItem
{
    IBOutlet MZClockControl* clock;
    IBOutlet NSTextField* clockCaption;
    IBOutlet NSTextField* time;
    IBOutlet NSTextField* day;
    
    NSTimeZone* timezone;
    
    bool useDarkTheme;
    bool useShadow;
    bool useLargeFonts;
    bool useSeconds;
    bool useMilitaryTime;
}

-(void) configureClockItem:(NSString*) newCaption
    zone:(NSTimeZone*) newZone
    clockFace:(NSString*) newClockFace
    darkTheme:(bool) newDarkTheme
    shadow:(bool) newShadow
    largeFonts:(bool) newLargeFonts
    seconds:(bool) newSeconds
    militaryTime:(bool) newMilitaryTime;

-(void) setUseMilitaryTime:(bool) value;

-(void) setUseDarkTheme:(bool) value;

-(void) setUseShadow:(bool) value;

-(void) setUseLargeFonts:(bool) value;

-(void) setUseSeconds:(bool) value;

-(void) setClockFace:(NSString*)name;

-(void) setCaption:(NSString*) newCaption;

-(void) update:(NSDate*) now;

-(NSImage*) getImage;

@end
