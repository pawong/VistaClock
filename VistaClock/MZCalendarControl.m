#import "MZCalendarControl.h"

#define MZCALENDARCONTROL_WEEK_OFFSET_V         32  // title set
#define MZCALENDARCONTROL_OFFSET_H              4
#define MZCALENDARCONTROL_OFFSET_V              6
#define MZINDICATOR_X_OFFSET                    5.0
#define MZINDICATOR_Y_OFFSET                    5.0


#define MZMONTH_VIEW_DAYS					42

static NSImage* _gCalendarBackground_ = nil;

static int numberOfDayInMonthForYear(int aMonth, int aYear)
{
    if (aMonth>=1 && aMonth<=12)
    {
        static int sNumberOfDay[12]={31,28,31,30,31,30,31,31,30,31,30,31};
        
        if (aMonth==2)
        {
            if (((aYear%4)==0) && ((aYear%100)!=0 || (aYear%400)==0))
            {
                return 29;
            }
        }
        
        return sNumberOfDay[aMonth-1];
    }
    
    return 1;
}

@implementation MZCalendarControl

-(id) initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        showWeekNumbers = false;                // off by default
        showEventIndicators = false;            // off by default
        showReminderIndicators = false;         // off by default
        showBoxes = false; // off by default
        firstWeekday = (int)[[NSCalendar currentCalendar] firstWeekday];
        [self setDate:[NSDate getDateNSDate:[NSDate date]]];
        dateColor = [[NSColor blackColor] copy];
        shadowColor = [[NSColor darkGrayColor] copy];
        shadow = [[NSShadow alloc] init];
        [self setStyle];
        
        store = [[EKEventStore alloc] init];
    }
    
    return self;
}


-(void) awakeFromNib
{
	// Register for notifications on calendars, events and tasks so we can
	// update the GUI to reflect any changes beneath us
    [store requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
        if (granted) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                selector:@selector(calendarsChanged:)
                name:EKEventStoreChangedNotification
                object:nil];
        }
    }];
}

-(void) setDate:(NSDate*) aDate
{
    if (aDate!=nil)
    {
        int numberOfDays
        	, numberOfDaysLast
            , lastYear
            , i;
        NSDate* firstDayOfMonth;
        NSDate* lastDayOfMonth;
        NSDate* firstMonthViewDate;
                
        // release the old values
        if (selectedDate != nil)
        {
            selectedDate = nil;
        }
        for (i=0; i<42; i++)
        {
            if (monthView[i] != nil)
            {
                monthView[i] = nil;
            }
        }
        
        selectedDate = [[NSDate getDateNSDate:aDate] copy];
        
        numberOfDays = numberOfDayInMonthForYear([selectedDate getMonth]
            , [selectedDate getYear]);
            
        // find the number of day's last month
        if ([selectedDate getMonth] == 1)
        {
        	lastYear = [selectedDate getYear] - 1;
        	numberOfDaysLast = numberOfDayInMonthForYear(12, lastYear);
        }
        else
        {
        	lastYear = [selectedDate getYear];
            numberOfDaysLast = numberOfDayInMonthForYear(
            	[selectedDate getMonth] - 1, lastYear);
        }

        firstWeekday = (int)[[NSCalendar currentCalendar] firstWeekday]-1;
        
    	firstDayOfMonth = [NSDate getDateWithYMD:[selectedDate getYear] 
    		month:[selectedDate getMonth] day:1];
        lastDayOfMonth = [NSDate getDateWithYMD:[selectedDate getYear] 
            month:[selectedDate getMonth] day:numberOfDays];       

        // find the first day of the month
        firstDay = [firstDayOfMonth getDayOfWeek]-1;
        //firstDay = ((([firstDayOfMonth getDayOfWeek] 
    		//- ([firstDayOfMonth getDay]%7) - firstDayOfWeek + 1)) + 7)%7;
        
        // leave some last month days first
        if (firstDay == 0)
        {
            firstDay = 7;
        }
        
        // find the day which the view starts on
        firstMonthViewDate = [NSDate getDateWithYMD:lastYear month:
            ([selectedDate getMonth]==1?12:[selectedDate getMonth]-1)
            day:(numberOfDaysLast-firstDay+1)];
            
        for(i=0; i<42; i++)
        {
            monthView[i] = [[firstMonthViewDate 
            	dateByAddingTimeInterval:60*60*24*i] copy];
            if ([monthView[i] compare:firstDayOfMonth] == NSOrderedSame)
            {
            	firstDay = i;
            }
            if ([monthView[i] compare:lastDayOfMonth] == NSOrderedSame)
            {
            	lastDay = i;
            }   
        }
        
        [self setNeedsDisplay:YES];
    }
}

-(void) setShowWeekNumbers:(bool) value
{
    if (showWeekNumbers != value)
    {
        showWeekNumbers = value;
        [self setNeedsDisplay:YES];
    }
}

-(void) setShowEventIndicators:(bool) value
{
    if (showEventIndicators != value)
    {
        showEventIndicators = value;
        [self setNeedsDisplay:YES];
    }
}

-(void) setShowReminderIndicators:(bool) value
{
    if (showReminderIndicators != value)
    {
        showReminderIndicators = value;
        [self setNeedsDisplay:YES];
    }
}

-(void) setShowBoxes:(bool) value
{
    if (showBoxes != value)
    {
        showBoxes = value;
        [self setNeedsDisplay:YES];
    }
}

-(int) dayAtPoint:(NSPoint) aPoint
{
    NSRect tBounds = [self bounds];
    int tColumn, tRow;
    
    if (aPoint.y > NSHeight(tBounds)-MZCALENDARCONTROL_WEEK_OFFSET_V 
    	-MZCALENDARCONTROL_OFFSET_V)
    {
        return 0;
    }
    
    tRow = (NSHeight(tBounds) - aPoint.y - MZCALENDARCONTROL_WEEK_OFFSET_V 
    	- MZCALENDARCONTROL_OFFSET_V)/dayHeight;
    
    tColumn = (aPoint.x-MZCALENDARCONTROL_OFFSET_H-cwOffset)/dayWidth;
    
    if (tColumn < 0)
    {
        tColumn = 0;
    }
    else if (tColumn > 6)
    {
        tColumn = 6;
    }
    
    if (tRow < 0)
    {
        tRow = 0;
    }
    else if (tRow > 6)
    {
        tRow = 6;
    }
    
    return [monthView[tRow*7 + tColumn] getDay];
}

-(void) setStyle
{
    // Calendar Fonts
    //NSFont *dayFont = [NSFont fontWithName:@"Andale Mono" size:13];
    NSFont *dayFont = [NSFont systemFontOfSize:13];
    
    // Font Shadow
    [shadow setShadowColor:shadowColor];
    [shadow setShadowOffset:NSMakeSize( 1, -1 )];
    [shadow setShadowBlurRadius:1.5];
    
    // labels
    if (dayOfWeekAttributes != nil)
    {
        dayOfWeekAttributes = nil;
    }
    
    dayOfWeekAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
    	[NSFont labelFontOfSize:11], NSFontAttributeName
        , dateColor, NSForegroundColorAttributeName
        , shadow, NSShadowAttributeName
        , nil];
    
    if (titleAttributes != nil)
    {
        titleAttributes = nil;
    }
    
    titleAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
        [NSFont labelFontOfSize:13], NSFontAttributeName            
        , dateColor, NSForegroundColorAttributeName
        , shadow, NSShadowAttributeName
        , nil];
    
    if (weekAttributes != nil)
    {
        weekAttributes = nil;
    }    
    
    weekAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
    	[NSFont labelFontOfSize:10], NSFontAttributeName
        , [NSColor grayColor], NSForegroundColorAttributeName
        , shadow, NSShadowAttributeName
        , nil];
    
    
    // days
    if (daysNotThisMonth != nil)
    {
        daysNotThisMonth = nil;
    }         
    
    daysNotThisMonth = [[NSDictionary alloc] initWithObjectsAndKeys:
    	dayFont, NSFontAttributeName
        , [NSColor grayColor], NSForegroundColorAttributeName
        , shadow, NSShadowAttributeName
        , nil];
    
    if (currentDayAttributes != nil)
    {
        currentDayAttributes = nil;
    }
    
    currentDayAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
        dayFont, NSFontAttributeName
        , [NSColor selectedMenuItemTextColor], NSForegroundColorAttributeName
        , shadow, NSShadowAttributeName
        , nil];
    
    if (selectedDayAttributes != nil)
    {
        selectedDayAttributes = nil;
    }
    
    selectedDayAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
        dayFont, NSFontAttributeName
        , [NSColor lightGrayColor]
        , NSForegroundColorAttributeName
        , shadow, NSShadowAttributeName
        , nil];
    
    if (normalAttributes != nil)
    {
        normalAttributes = nil;
    }
    
    normalAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
        dayFont, NSFontAttributeName
        , dateColor, NSForegroundColorAttributeName
        , shadow, NSShadowAttributeName
        , nil];

    if (_gCalendarBackground_==nil)
    {
        //_gCalendarBackground_=[[NSImage imageNamed:@"CalendarBack"] retain];
    }
    
    // load event indicators
    if (eventImage == nil)
    {
        eventImage = [NSImage imageNamed:@"tinybluelighton.png"];
    }
    
    if (altEventImage == nil)
    {
        altEventImage = [NSImage imageNamed:@"tinygreylighton.png"];
    }
    
    if (reminderImage == nil)
    {
        reminderImage = [NSImage imageNamed:@"tinyredlighton.png"];
    }
    
} // end of setStyle

-(void) setColor:(NSColor*) color
{
    if (dateColor != nil)
    {
        dateColor = nil;
    }
    dateColor = [color copy];
    [self setStyle];
} // end of setColor

-(void) setShadowColor:(NSColor*) color
{
    if (shadowColor != nil)
    {
        shadowColor = nil;
    }
    shadowColor = [color copy];
    [self setStyle];
} // end of setShadowColor

-(NSDate*) dateAtPoint:(NSPoint) aPoint
{
    NSRect tBounds = [self bounds];
    int tColumn, tRow;
    
    if (aPoint.y > NSHeight(tBounds) - MZCALENDARCONTROL_WEEK_OFFSET_V 
    	- MZCALENDARCONTROL_OFFSET_V)
    {
        return nil;
    }
    
    tRow = (NSHeight(tBounds)-aPoint.y-MZCALENDARCONTROL_WEEK_OFFSET_V 
            - MZCALENDARCONTROL_OFFSET_V)/dayHeight;
    
    tColumn = (aPoint.x - MZCALENDARCONTROL_OFFSET_H-cwOffset)/dayWidth;
    
    if (tColumn < 0)
    {
        tColumn = 0;
    }
    else if (tColumn > 6)
    {
        tColumn = 6;
    }
    
    if (tRow < 0)
    {
        tRow = 0;
    }
    else if (tRow > 6)
    {
        tRow = 6;
    }
    
    return monthView[tRow*7 + tColumn];
}

-(int) drawDay:(int) aDay
{
    NSRect tBounds = [self bounds];
    int tRow, tColumn;
    NSString* tString;
    NSSize tSize;
    NSRect tRect;
    
    tRow = aDay/7;
    tColumn = aDay - (tRow*7);
    
	tString=[monthView[aDay] getDayString];

    tRect = NSMakeRect(
        MZCALENDARCONTROL_OFFSET_H+dayWidth*tColumn+cwOffset -1
        , NSHeight(tBounds) - MZCALENDARCONTROL_WEEK_OFFSET_V
        - (tRow+1)*dayHeight - MZCALENDARCONTROL_OFFSET_V-1
        , dayWidth -1
        , dayHeight -1
        );
    
    // current day?
    if ([[NSDate getDateNSDate:[NSDate date]] compare:monthView[aDay]]
    	== NSOrderedSame)
    {
    	// draw current day
        [NSBezierPath setDefaultLineWidth:1.0];
        NSBezierPath* path = [NSBezierPath bezierPathWithRoundedRect:tRect
            xRadius:5.0 yRadius:5.0];
        
        [path setLineJoinStyle:NSRoundLineJoinStyle];
        [[NSColor selectedMenuItemColor] set];
        [path fill];

        if (showBoxes == true)
        {
        	// Draw box
        	[NSBezierPath setDefaultLineWidth:0.5];
        	NSBezierPath* path = [NSBezierPath bezierPathWithRect:tRect];
        	[path setLineJoinStyle:NSRoundLineJoinStyle];
        	[dateColor set];
            [path stroke];
    	}
        
        tSize = [tString sizeWithAttributes:currentDayAttributes];
    	[tString drawAtPoint:NSMakePoint(NSMidX(tRect) - tSize.width*0.5
            , NSMinY(tRect)+3) withAttributes:currentDayAttributes];
    }
    else if (aDay < firstDay || aDay > lastDay)
    {

        // draw days not in month of current month view
    	tSize = [tString sizeWithAttributes:daysNotThisMonth];
    	[tString drawAtPoint:NSMakePoint(NSMidX(tRect) - tSize.width*0.5
    		, NSMinY(tRect)+3) withAttributes:daysNotThisMonth];
    }
    else
    {
        // draw regular old day
        if (showBoxes == true)
        {
        	// Draw boxes
        	[NSBezierPath setDefaultLineWidth:0.5];
        	NSBezierPath* path = [NSBezierPath bezierPathWithRect:tRect];
        	[path setLineJoinStyle:NSRoundLineJoinStyle];
        	[dateColor set];
            [path stroke];
    	}
        
        tSize = [tString sizeWithAttributes:normalAttributes];
    	[tString drawAtPoint:NSMakePoint(NSMidX(tRect) - tSize.width*0.5
            , NSMinY(tRect)+3) withAttributes:normalAttributes];
    }
    
    // selected date
    if ([selectedDate getDay] == [monthView[aDay] getDay]  
    	&& aDay >= firstDay && aDay <= lastDay)
    {
        [NSBezierPath setDefaultLineWidth:1];
        NSBezierPath* path = [NSBezierPath bezierPathWithRoundedRect:tRect
            xRadius:5.0 yRadius:5.0];
        [dateColor set];
        [path setLineJoinStyle:NSRoundLineJoinStyle];
        [path stroke];
    }
    
    // check for events
    if (showEventIndicators)
    {
    	if ([self HasEvents:monthView[aDay]] == true)
    	{
    		// change color on current day
        	if ([[NSDate getDateNSDate:[NSDate date]] compare:monthView[aDay]]
	            == NSOrderedSame)
    	    {
        		[altEventImage drawAtPoint:
            		NSMakePoint(tRect.origin.x+tRect.size.width-MZINDICATOR_X_OFFSET
        			, NSMidY(tRect)-MZINDICATOR_Y_OFFSET) fromRect:NSZeroRect
            		operation:NSCompositeSourceOver fraction:1.0];
    		}
        	else
        	{
            	[eventImage drawAtPoint:
            		NSMakePoint(tRect.origin.x+tRect.size.width-MZINDICATOR_X_OFFSET
                	, NSMidY(tRect)-MZINDICATOR_Y_OFFSET) fromRect:NSZeroRect
                	operation:NSCompositeSourceOver fraction:1.0];
        	}
    	}
    }
    
    // check for reminders
    if (showReminderIndicators)
    {
    	if ([self HasReminders:monthView[aDay]] == true)
    	{
        	[reminderImage drawAtPoint:
            	NSMakePoint(tRect.origin.x+tRect.size.width-MZINDICATOR_X_OFFSET
            	, NSMidY(tRect)) fromRect:NSZeroRect
            	operation:NSCompositeSourceOver fraction:1.0];
    	}
    }
    return 0;
}

-(void) drawRect:(NSRect) aRect
{
    int i = 0;
    NSString* dayArray[7] = {[monthView[0] getDayNameShortString]
    	, [monthView[1] getDayNameShortString]
        , [monthView[2] getDayNameShortString]
        , [monthView[3] getDayNameShortString]
        , [monthView[4] getDayNameShortString]
        , [monthView[5] getDayNameShortString]
        , [monthView[6] getDayNameShortString]};
    NSString* tString;
    NSSize tSize;
    NSRect tRect;
    
    // draw the selected date if in current monthview
    NSRect tBounds = [self bounds]; 
	// set sizes
    if (showWeekNumbers == true)
    {
        nColumns = 8;
    }
    else
    {
        nColumns = 7;
    }
    
    dayWidth = (tBounds.size.width-2*MZCALENDARCONTROL_OFFSET_H)/nColumns;
    dayHeight = (tBounds.size.height-20)/7;
    
    if (showWeekNumbers == true)
    {
        cwOffset = dayWidth;
    }
    else
    {
        cwOffset = 0;
    }
    
	// Draw the background
    tRect.origin=NSZeroPoint;
    tRect.size=[_gCalendarBackground_ size];
    
    [_gCalendarBackground_ drawAtPoint:NSZeroPoint fromRect:tRect 
    	operation:NSCompositeSourceOver fraction:1.0];
    
    // draw header
    // month + year and controls
    tString = [selectedDate getMonthYearString];
    tSize = [tString sizeWithAttributes:titleAttributes];
    tRect = NSMakeRect(MZCALENDARCONTROL_OFFSET_H
        , NSHeight(tBounds) - MZCALENDARCONTROL_OFFSET_V - tSize.height
        , dayWidth*nColumns
        , tSize.height);
    [tString drawAtPoint:NSMakePoint(NSMinX(tRect) + MZCALENDARCONTROL_OFFSET_H
        , NSMinY(tRect)+1) withAttributes:titleAttributes];
    
	tString = @"⇠";
    tSize = [tString sizeWithAttributes:titleAttributes];
    tRect = NSMakeRect(MZCALENDARCONTROL_OFFSET_H + 4 * dayWidth+cwOffset-2
        , NSHeight(tBounds) - MZCALENDARCONTROL_OFFSET_V - tSize.height
        , dayWidth, dayHeight);
    [tString drawAtPoint:NSMakePoint(NSMidX(tRect) - tSize.width * 0.5
        , NSMinY(tRect)) withAttributes:titleAttributes];
    
    tString = @"•";
    tSize = [tString sizeWithAttributes:titleAttributes];
    tRect = NSMakeRect(MZCALENDARCONTROL_OFFSET_H + 5 * dayWidth+cwOffset-2
        , NSHeight(tBounds) - MZCALENDARCONTROL_OFFSET_V - tSize.height
        , dayWidth, dayHeight);
    [tString drawAtPoint:NSMakePoint(NSMidX(tRect) - tSize.width * 0.5
        , NSMinY(tRect)) withAttributes:titleAttributes];
    
    tString = @"⇢";
    tSize = [tString sizeWithAttributes:titleAttributes];
    tRect = NSMakeRect(MZCALENDARCONTROL_OFFSET_H + 6 * dayWidth+cwOffset-2
        , NSHeight(tBounds) - MZCALENDARCONTROL_OFFSET_V - tSize.height
        , dayWidth, dayHeight);
    [tString drawAtPoint:NSMakePoint(NSMidX(tRect) - tSize.width * 0.5
        , NSMinY(tRect)) withAttributes:titleAttributes];
        
    // Draw the week header
    for(i=0; i<7; i++)
    {            
        tRect = NSMakeRect(
            MZCALENDARCONTROL_OFFSET_H + i * dayWidth+cwOffset -1
            , NSHeight(tBounds) - MZCALENDARCONTROL_WEEK_OFFSET_V
            - MZCALENDARCONTROL_OFFSET_V-4
            , dayWidth -1
            , dayHeight -1
        );
        
        tString = dayArray[i];
            
        tSize = [tString sizeWithAttributes:dayOfWeekAttributes];
    
        [tString drawAtPoint:NSMakePoint(NSMidX(tRect) - tSize.width * 0.5
        	, NSMinY(tRect)+3) withAttributes:dayOfWeekAttributes];
    }
    
    // Draw the days
    for(i=0; i<42; i++)
    {
        [self drawDay:i];
    }
    
    // Draw the week views
    if (showWeekNumbers == true)
    {
    	for(i=0; i<7; i++)
    	{
        	tRect = NSMakeRect(MZCALENDARCONTROL_OFFSET_H
            	, NSHeight(tBounds) - MZCALENDARCONTROL_WEEK_OFFSET_V 
            	- (i)*dayHeight - MZCALENDARCONTROL_OFFSET_V-2
            	, dayWidth, dayHeight);
        	if (i==0)
        	{
            	tString = @"cw";
            	[tString drawAtPoint:NSMakePoint(NSMinX(tRect)
                	+MZCALENDARCONTROL_OFFSET_H
                	, NSMinY(tRect)+1) withAttributes:weekAttributes];
        	}
        	else
        	{
            	tString = [monthView[(i-1)*7] getWeekString];
            	[tString drawAtPoint:NSMakePoint(NSMinX(tRect)
                	+MZCALENDARCONTROL_OFFSET_H
        			, NSMinY(tRect)+4.5) withAttributes:weekAttributes];
        	}
    	}
    }
}

-(void) nextMonth
{
    NSDateComponents* dateComponents = [[NSDateComponents alloc]init];
    [dateComponents setMonth:1];
    NSCalendar* calendar = [NSCalendar currentCalendar];
    [self setDate:[calendar dateByAddingComponents:dateComponents 
    	toDate:selectedDate options:0]];
}

-(void) lastMonth
{
    NSDateComponents* dateComponents = [[NSDateComponents alloc]init];
    [dateComponents setMonth:-1];
    NSCalendar* calendar = [NSCalendar currentCalendar];
    [self setDate:[calendar dateByAddingComponents:dateComponents 
    	toDate:selectedDate options:0]];
}

-(int) controlAtPoint:(NSPoint) aPoint
{
	int retval = 0;
    
    if (aPoint.x > (MZCALENDARCONTROL_OFFSET_H + 6 * dayWidth+cwOffset))
    {
        retval = 1;
    }
    else if (aPoint.x > (MZCALENDARCONTROL_OFFSET_H + 5 * dayWidth+cwOffset))
    {
        retval = 0;
    }
    else if (aPoint.x > (MZCALENDARCONTROL_OFFSET_H + 4 * dayWidth+cwOffset))
    {
        retval = -1;
    }
    
    return retval;
}

- (void) mouseDown:(NSEvent *) theEvent
{
	// move to date
    NSPoint tPoint = [self convertPoint:[theEvent locationInWindow] 
    	fromView:nil];
    
    NSDate* tDay;

    if ((tDay = [[self dateAtPoint:tPoint] copy]) == nil)
    {
    	// not a date so check controls
        switch ([self controlAtPoint:tPoint])
        {
        	case -1: 
            	[self lastMonth];
                break;
            case 1:
            	[self nextMonth];
                break;
            default:
            	[self setDate:[NSDate getDateNSDate:[NSDate date]]];
     	}
        return;
    }
    
    if ([tDay compare:selectedDate] != NSOrderedSame)
    {
    	if ([selectedDate getMonth] != [tDay getMonth])
        {
            [self setDate:tDay];
        }
        else
        {	
        	if (selectedDate != nil)
            {
                selectedDate = nil;
            }
    		selectedDate = [tDay copy];
        }        
        [self setNeedsDisplay:YES];
    }
    
    //if (target != nil && action != nil)
    //{
    //    [target performSelector:action  withObject:self];
    //}
}

-(void) rightMouseDown:(NSEvent *)theEvent
{
	// if control key pressed
	if (theEvent.modifierFlags & NSControlKeyMask)
    {
       	[[NSWorkspace sharedWorkspace] launchApplication:@"Reminders"]; 
    }
    else
    {
		[[NSWorkspace sharedWorkspace] launchApplication:@"iCal"];
    }
}

//-(void) setAction:(SEL) aAction
//{
//    action = aAction;
//}

-(void) setTarget:(id) aTarget
{
    target = aTarget;
}


-(bool) HasEvents:(NSDate*) date
{
	bool retval = false;

    NSDateComponents* comps = [[NSCalendar currentCalendar]
    	components: NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit
        fromDate: date];
    NSDate* startDate = [[NSCalendar currentCalendar] dateFromComponents:comps];
    NSDate* endDate = [startDate dateByAddingTimeInterval: (24*60*60)-1];
    
    // Create the predicate from the event store's instance method
    NSPredicate *predicate = [store predicateForEventsWithStartDate:startDate
        endDate:endDate calendars:nil];
    
    // Fetch all events that match the predicate
    NSArray *events = [store eventsMatchingPredicate:predicate];
    
    if ([events count] > 0)
    	retval = true;

	return retval;
}

-(bool) HasReminders:(NSDate*) date
{
    remindersFound = FALSE;

    NSDateComponents* comps = [[NSCalendar currentCalendar]
    	components: NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit
        fromDate: date];
        
    NSDate* startDate = [[NSCalendar currentCalendar] dateFromComponents:comps];
    NSDate* endDate = [startDate dateByAddingTimeInterval:(24*60*60)-1];

    // Create the predicate from the event store's instance method
    NSPredicate *predicate
        = [store predicateForIncompleteRemindersWithDueDateStarting:startDate
        ending:endDate calendars:nil];
    
    // Fetch all events that match the predicate
    [store fetchRemindersMatchingPredicate:predicate completion:^(NSArray *reminders) {
        if ([reminders count] > 0) {
            self->remindersFound = TRUE;
        }
    }];
    
	return remindersFound;
}

// With the observable keys set up above and the appropriate bindings in IB,
// we can trigger UI updates just by signaling changes to the keys
-(void) calendarsChanged:(NSNotification *)notification
{
	if (showEventIndicators)
    {
		[self setNeedsDisplay:YES];
    }
}

-(void) eventsChanged:(NSNotification *)notification
{
	if (showEventIndicators)
    {
		[self setNeedsDisplay:YES];
    }
}

-(void) tasksChanged:(NSNotification *)notification
{
	if (showReminderIndicators)
    {
		[self setNeedsDisplay:YES];
    }
}

@end
