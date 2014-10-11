//
//  MZClockControlCell.h
//  VistaClock2
//
//  Created by Paul Wong on 6/7/14.
//  Copyright (c) 2014 Paul Wong. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MathUtils.h"               	/* for AngleFromNorth() */
#import "NSDate+Tools.h"


@interface MZClockControlCell : NSCell
{
    NSDate* time;
    bool showSecondHand;
    float handColor; // 1.0 or 0.0
    NSString* clockFaceName;
    
    NSImage* clockFaceImage;
    NSImage* secondHandImage;
    NSImage* minuteHandImage;
    NSImage* hourHandImage;
    NSImage* dotImage;
    
    NSView* myView;
}


-(void) setTime:(NSDate*)newTime;
-(NSDate*) getTime;

-(void) useSecondHand:(bool)on;
-(void) useWhiteHands:(bool)on;
-(void) setClockFaceName:(NSString*)name;

@end
