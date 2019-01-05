//
//  MZClockControlCell.m
//  VistaClock2
//
//  Created by Paul Wong on 6/7/14.
//  Copyright (c) 2014 Paul Wong. All rights reserved.
//

#import "MZClockControlCell.h"


#define kSClockHandWidth	1.5	    	/* Line width of the second hand   	*/
#define kMClockHandWidth	2.0	    	/* Line width of the minute hand   	*/
#define kHClockHandWidth 	3.0	    	/* Line width of the hour hand     	*/

#define kSClockHandLength	8.0	    	/* Line width of the second hand   	*/
#define kMClockHandLength	7.0	    	/* Line width of the minute hand   	*/
#define kHClockHandLength 	5.0	    	/* Line width of the hour hand     	*/

#define kSClockHandAlpha	0.7     	/* Alpha component for second hand 	*/
#define kMClockHandAlpha	0.6     	/* Alpha component for minute hand 	*/
#define kHClockHandAlpha 	0.5	    	/* Alpha component for hour hand   	*/
#define kHClockHandWhite	1.0			/* White hands						*/
#define kClockHandBlack		0.0			/* Black hands						*/

#define HOUR_MINUTE_MERIDIEM_FORMAT  @"%I:%M %p"  /* Hour : Minute  Meridiem */
#define MERIDIEM_FORMAT			     @"%p"        /* Meridiem */



@implementation MZClockControlCell


// ---------------------------------------------------------
//  Initialization
// ---------------------------------------------------------

-(id) init 
{
    self = [super init];
    if (self)
    {
		// show second hand by default
        showSecondHand = NO;
        
        // use black hands by default
        handColor = 0.0;

        // default to 01 clockface
        [self setClockFaceName:@"VCB01.png"];
        
        // default to now
        [self setTime:[NSDate date]];
    }
    return self;
} // end init

-(void) sendActionToTarget 
{
    if ([self target] && [self action])
    {
        [(NSControl *)[self controlView] sendAction: [self action]
            to:[self target]];
    }
} // end sendActionToTarget

// ---------------------------------------------------------
//  Setting time (conveniences)
// ---------------------------------------------------------

-(void) setTimeToNow:(id)sender 
{
    [self setTime:[NSDate date]];
} // end setTimeToNow

-(void) incrementHour:(int)hour andMinute:(int)minute andSecond:(int)second
{
    [[self getTime] dateByAddingTimeInterval:hour*3600 + minute*60 + second];
} // end incrementHour

-(void) setHour:(int)hour andMinute:(int)minute andSecond:(int)second
{
    NSDate* currentTime = [self getTime];
    int secondInc = (int)(second>=0 ? second-[currentTime getSeconds] : 0);
    int minuteInc = (int)(minute>=0 ? minute-[currentTime getMinutes] : 0);
    int hourInc = (int)(hour>=0 ? hour-[currentTime getHours] : 0);
    [self incrementHour: hourInc andMinute:minuteInc andSecond:secondInc];
} // end setHour

-(void) setHourHandByAngleFromNorth:(float)angle 
{
    int hour = ((angle) * (12.0 / 360.0));
    float hourAngle = (float)hour * (360.0 / 12.0);
    int minute = 60.0*((angle-hourAngle) / (360.0 / 12.0));
    int second = 60.0*((angle-hourAngle) / (360.0 / 12.0));
        
    // Preserve the AM/PM setting.  
    hour = ([[self getTime] getHours]>11 ? hour + 12 : hour);
    [self setHour:hour andMinute: minute andSecond: second];
} // end setHourHandByAngleFromNorth

// ---------------------------------------------------------
//  Setting and getting values
// ---------------------------------------------------------

-(void) setTime:(NSDate*)newTime 
{
    if (newTime && ![time isEqual:newTime]) 
    {
        // Change the time!
        time = [newTime copy];
	
        // Tell our control view to redisplay us.
        [(NSControl*)[self controlView] updateCell: self];
	
        // For this example, we just send the action whenever the time changes.
        // Usually you would only want to send an action in response to user events.
        [self sendActionToTarget];
    }
} // end setTime

-(void) useSecondHand:(bool)on
{
    showSecondHand = on;
} // end useSecondHand

-(void) useWhiteHands:(bool)on
{
	if (on == true)
    {
        handColor = 1.0;
    }
    else
    {
        handColor = 0.0;
    }
} // end useWhiteHands

-(void) setClockFaceName:(NSString*)name
{
    clockFaceName = [name copy];
    
    clockFaceImage = [NSImage imageNamed: clockFaceName];
    if (clockFaceImage == nil)
    {
    	clockFaceName = @"VCB01.png";
        clockFaceImage = [NSImage imageNamed: clockFaceName];
    }
    
    //set hands
	dotImage
    	= [NSImage imageNamed:[@"D" stringByAppendingString:clockFaceName]];
    if (dotImage != nil)
    {
    	secondHandImage
        	= [NSImage imageNamed:[@"S" stringByAppendingString:clockFaceName]];
    	minuteHandImage
        	= [NSImage imageNamed:[@"M" stringByAppendingString:clockFaceName]];
    	hourHandImage
        	= [NSImage imageNamed:[@"H" stringByAppendingString:clockFaceName]];
    }
    else
    {
        //get the default hands
        if (handColor == 1.0)
        {
            // use white default hands
            dotImage = [NSImage imageNamed:@"DWVCB01.png"];
            secondHandImage = [NSImage imageNamed:@"SWVCB01.png"];
            minuteHandImage = [NSImage imageNamed:@"MWVCB01.png"];
            hourHandImage = [NSImage imageNamed:@"HWVCB01.png"];
        }
        else
        {
            // use black default hands
            dotImage = [NSImage imageNamed:@"DBVCB01.png"];
            secondHandImage = [NSImage imageNamed:@"SBVCB01.png"];
            minuteHandImage = [NSImage imageNamed:@"MBVCB01.png"];
            hourHandImage = [NSImage imageNamed:@"HBVCB01.png"];
        }
    }
} // end setClockFaceName

-(NSDate *) getTime 
{ 
    return time;
} // end getTime

-(NSString*) stringValue 
{
    return [[self getTime] getDateString];
} // end stringValue

// ---------------------------------------------------------
//  Drawing Routines
// ---------------------------------------------------------

-(void) drawClockHandsForTime:(NSDate*)theTime 
    withFrame:(NSRect)cellFrame inView:(NSView*)controlView 
{
    float sHandTheta;
    float mHandTheta;
    float hHandTheta;
    float clockDiameter;

    NSPoint centerPoint;
    NSRect clockRect;
    
    // Indicate nil time, by not drawing any hands.
    if (!theTime) return;
    
    // Compute where the clock lives in the cellFrame.
    clockDiameter = MIN(NSWidth(cellFrame), NSHeight(cellFrame));
    clockRect = NSMakeRect(NSMinX(cellFrame), NSMinY(cellFrame)
        , clockDiameter, clockDiameter);

    // If we have focus, draw a focus ring around the entire cellFrame 
    // (inset it a little so it looks nice).
    if ([self showsFirstResponder]) 
    {
        // showsFirstResponder is set for us by the NSControl that is 
        // drawing us.
        NSRect focusRingFrame = clockRect;
        focusRingFrame.size.height -= 2.0;
        [NSGraphicsContext saveGraphicsState];
        NSSetFocusRingStyle(NSFocusRingOnly);
        [[NSBezierPath bezierPathWithRect:
        	NSInsetRect(focusRingFrame,4,4)] fill];
        [NSGraphicsContext restoreGraphicsState];
    }
    
    // Determine a few values to help us figure out where to draw the hands.
    sHandTheta = ToRad(0.0 - (360.0*((float)[theTime getSeconds]/60.0)));
    mHandTheta = ToRad(0.0 - (360.0*((float)[theTime getMinutes]/60.0) 
    	+ (360.0 / 60.0) * ((float)[theTime getSeconds]/60.0)));
    hHandTheta = ToRad(0.0 - (360.0*((float)[theTime getHours]/12.0) 
    	+ (360.0 / 12.0) * ((float)[theTime getMinutes] / 60.0)));
    centerPoint = NSMakePoint(floor(NSMidX(clockRect) + 0.5)
    	, floor(NSMidY(clockRect) + 0.5));

    // Draw the hour hand.
    NSAffineTransform *transformh = [NSAffineTransform transform];
    [transformh translateXBy: centerPoint.x yBy: centerPoint.y];
    [transformh rotateByRadians:hHandTheta];
    [transformh translateXBy:-0.5f*[hourHandImage size].width 
        yBy:-0.5f*[hourHandImage size].height];
    [NSGraphicsContext saveGraphicsState];
    [transformh concat];
    [hourHandImage drawAtPoint:NSZeroPoint fromRect:NSZeroRect
        operation:NSCompositingOperationSourceOver fraction:1.0];
    [NSGraphicsContext restoreGraphicsState];
    
    // Draw the minute hand.
    NSAffineTransform *transform = [NSAffineTransform transform];
    [transform translateXBy: centerPoint.x yBy: centerPoint.y];
    [transform rotateByRadians:mHandTheta];
    [transform translateXBy:-0.5f*[minuteHandImage size].width 
        yBy:-0.5f*[minuteHandImage size].height];
    [NSGraphicsContext saveGraphicsState];
    [transform concat];
    [minuteHandImage drawAtPoint:NSZeroPoint fromRect:NSZeroRect
                       operation:NSCompositingOperationSourceOver fraction:0.95];
    [NSGraphicsContext restoreGraphicsState];

    // Draw the second hand.
    if (showSecondHand == true)
    {
        NSAffineTransform *transform = [NSAffineTransform transform];
        [transform translateXBy: centerPoint.x yBy: centerPoint.y];
        [transform rotateByRadians:sHandTheta];
        [transform translateXBy:-0.5f*[secondHandImage size].width 
        	yBy:-0.5f*[secondHandImage size].height];
        [NSGraphicsContext saveGraphicsState];
        [transform concat];
        [secondHandImage drawAtPoint:NSZeroPoint fromRect:NSZeroRect
                           operation:NSCompositingOperationSourceOver fraction:0.9];
        [NSGraphicsContext restoreGraphicsState];
    }
    
    // draw the center dot
    NSAffineTransform *transformd = [NSAffineTransform transform];
    [transformd translateXBy: centerPoint.x yBy: centerPoint.y];
    [transformd rotateByRadians:sHandTheta];
    [transformd translateXBy:-0.5f*[dotImage size].width 
                        yBy:-0.5f*[dotImage size].height];
    [NSGraphicsContext saveGraphicsState];
    [transformd concat];
    [dotImage drawAtPoint:NSZeroPoint fromRect:NSZeroRect
                operation:NSCompositingOperationSourceOver fraction:0.85];
    [NSGraphicsContext restoreGraphicsState];    
} // end drawClockHandsForTime

-(void) drawWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
    float clockDiameter = MIN(NSHeight(cellFrame), NSWidth(cellFrame));
    
    // Draw the clock face (draw it flipped if we are in a flipped view
    // , like NSMatrix).
    [clockFaceImage drawInRect:NSMakeRect(NSMinX(cellFrame), NSMinY(cellFrame)
        , clockDiameter, clockDiameter) fromRect:NSMakeRect( 0, 0
        , [clockFaceImage size].width
        , [clockFaceImage size].height) operation:NSCompositingOperationSourceOver
        fraction:1.0
    ];
        
    //scale hands
    float scaleFactor = clockDiameter/dotImage.size.height;
    [dotImage setSize:NSMakeSize(dotImage.size.width*scaleFactor
        , clockDiameter)];
    [secondHandImage setSize:NSMakeSize(secondHandImage.size.width*scaleFactor
        , clockDiameter)];
    [minuteHandImage setSize:NSMakeSize(minuteHandImage.size.width*scaleFactor
        , clockDiameter)];
    [hourHandImage setSize:NSMakeSize(hourHandImage.size.width*scaleFactor
        , clockDiameter)];
                                          
    // Draw the clock hour and minute hands.
    [self drawClockHandsForTime:time withFrame:cellFrame inView:controlView];
} // end drawWithFrame


-(NSImage*) getImage
{
    NSData* data = [self.controlView dataWithPDFInsideRect:[self.controlView bounds]];
    return [[NSImage alloc] initWithData:data];
} // end of getImage

@end
