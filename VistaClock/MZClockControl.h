#import <AppKit/AppKit.h>
#import "MZClockControlCell.h"


@interface MZClockControl : NSControl

-(void) setTime:(NSDate*)newTime;
-(NSDate*) getTime;

-(void) useSecondHand:(bool)on;
-(void) useWhiteHands:(bool)on;
-(void) setClockFace:(NSString*)name;

@end
