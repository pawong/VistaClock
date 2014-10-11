#import "MZClockControl.h"
// -----------------------------------------------------------------------------
//  MZClockCell
// -----------------------------------------------------------------------------

@implementation MZClockControl

+(void) initialize
{
    if (self == [MZClockControl class]) 
    {
        // Do it once
        [self setCellClass: [MZClockControlCell class]];
    }
} // end initialize

+(Class) cellClass
{
    return [MZClockControlCell class];
} // end cellClass

-(id) init 
{
    self = [super init];
    if (self)
    {
    }
    return self;
} // end init


// Like most NSControls, we don't do much ourselves....

-(void) setTime:(NSDate*)newTime 
{
    [[self cell] setTime: newTime];
} // end setTime

-(void) useSecondHand:(bool)on
{
    [[self cell] useSecondHand: on];
} // end useSecondHand

-(void) useWhiteHands:(bool)on
{
    [[self cell] useWhiteHands: on];
} // end useWhiteHands

-(void) setClockFace:(NSString*)name
{
    [[self cell] setClockFaceName:name];
} // end setClockFace

-(NSDate*) getTime 
{
    return [[self cell] getTime];
} // end getTime

@end

// -----------------------------------------------------------------------------
//  End MZClockControl
// -----------------------------------------------------------------------------
