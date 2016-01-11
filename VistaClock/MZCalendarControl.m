#import "MZCalendarControl.h"

#define MZCALENDARCONTROL_OFFSET_H              4
#define MZCALENDARCONTROL_OFFSET_V              6
#define MZINDICATOR_X_OFFSET                    5.0
#define MZINDICATOR_Y_OFFSET                    5.0
#define NUMBER_OF_ROWS                          8


#define MZMONTH_VIEW_DAYS                       42

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
} // end numberOfDayInMonthForYear

@implementation MZCalendarControl

-(void) awakeFromNib
{
    showWeekNumbers = false;                // off by default
    showEventIndicators = false;            // off by default
    showReminderIndicators = false;         // off by default
    hiliteColor = false;                      // off by default
    showBoxes = false; // off by default
    firstWeekday = (int)[[NSCalendar currentCalendar] firstWeekday];
    [self setDate:[NSDate getDateNSDate:[NSDate date]]];
    dateColor = [[NSColor blackColor] copy];
    shadowColor = [[NSColor darkGrayColor] copy];
    shadow = [[NSShadow alloc] init];
    fontSize = 13;
    [self setStyle];

    hiliteColor = [NSColor selectedMenuItemColor];
        
    store = [[EKEventStore alloc] init];
    NSDictionary* systemVersionDictionary = [NSDictionary dictionaryWithContentsOfFile:
        @"/System/Library/CoreServices/SystemVersion.plist"];
    NSString* systemVersion =
        [systemVersionDictionary objectForKey:@"ProductVersion"];

    if ([systemVersion compare:@"10.9" options:NSNumericSearch] == NSOrderedDescending)
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
        [store requestAccessToEntityType:EKEntityTypeReminder completion:^(BOOL granted, NSError *error) {
            if (granted) {
                [[NSNotificationCenter defaultCenter] addObserver:self
                    selector:@selector(tasksChanged:)
                    name:EKEventStoreChangedNotification
                    object:nil];
            }
        }];
        useTasks = FALSE;
    }
    else
    {
        useTasks = TRUE;
    }
} // end awakeFromNib

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
} // end setDate

-(NSDate*) getDate
{
    return selectedDate;
} // end getDate

-(void) setShowWeekNumbers:(bool) value
{
    if (showWeekNumbers != value)
    {
        showWeekNumbers = value;
        [self setNeedsDisplay:YES];
    }
} // end setShowWeekNumbers

-(void) setShowEventIndicators:(bool) value
{
    if (showEventIndicators != value)
    {
        showEventIndicators = value;
        [self setNeedsDisplay:YES];
    }
} // end setShowEventIndicators

-(void) setShowReminderIndicators:(bool) value
{
    if (showReminderIndicators != value)
    {
        showReminderIndicators = value;
        [self setNeedsDisplay:YES];
    }
} // end setShowReminderIndicators

-(void) setShowBoxes:(bool) value
{
    if (showBoxes != value)
    {
        showBoxes = value;
        [self setNeedsDisplay:YES];
    }
} // end setShowBoxes

-(void) setFontSize:(int) value
{
    if (value > 0)
    {
        fontSize = value;
        [self setStyle];
    }
} // end setFontSize

-(void) setHiliteColor:(NSColor*) value
{
    hiliteColor = value;
    [self setStyle];
} // end setHiliteDay

-(void) setStyle
{
    // Calendar Fonts
    //NSFont *dayFont = [NSFont fontWithName:@"Andale Mono" size:13];
    NSFont *dayFont = [NSFont systemFontOfSize:fontSize];
    
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
    	[NSFont labelFontOfSize:fontSize-3], NSFontAttributeName
        , dateColor, NSForegroundColorAttributeName
        , shadow, NSShadowAttributeName
        , nil];
    
    if (titleAttributes != nil)
    {
        titleAttributes = nil;
    }
    
    titleAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
        [NSFont labelFontOfSize:(fontSize+2)], NSFontAttributeName
        , dateColor, NSForegroundColorAttributeName
        , shadow, NSShadowAttributeName
        , nil];
    
    if (weekAttributes != nil)
    {
        weekAttributes = nil;
    }    
    
    weekAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
    	[NSFont labelFontOfSize:fontSize-4], NSFontAttributeName
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
    
    // current day
    currentDayAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
        dayFont, NSFontAttributeName
        , [NSColor selectedMenuItemTextColor], NSForegroundColorAttributeName
        , shadow, NSShadowAttributeName
        , nil
    ];

    
    if (selectedDayAttributes != nil)
    {
        selectedDayAttributes = nil;
    }
    
    selectedDayAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
        dayFont, NSFontAttributeName
        , dateColor, NSForegroundColorAttributeName
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
    // draw and done.
    [self setNeedsDisplay:YES];
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

-(int) dayAtPoint:(NSPoint) aPoint
{
    return [[self dateAtPoint:aPoint] getDay];
} // end dayAtPoint

-(NSDate*) dateAtPoint:(NSPoint) aPoint
{
    NSRect tBounds = [self bounds];
    int tColumn, tRow;
    
    if (aPoint.y > NSHeight(tBounds) - MZCALENDARCONTROL_OFFSET_V - dayHeight)
    {
        // it's a control
        return nil;
    }
    
    tRow = (NSHeight(tBounds) - aPoint.y - MZCALENDARCONTROL_OFFSET_V - dayHeight*2)/dayHeight;
    tColumn = (aPoint.x - MZCALENDARCONTROL_OFFSET_H - cwOffset)/dayWidth;
    
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
    else if (tRow > 5)
    {
        tRow = 5;
    }
    
    return monthView[tRow*7 + tColumn];
} // end dateAtPoint

-(void) drawBox:(NSRect) rectangle isRounded:(BOOL) rounded color:(NSColor*) color size:(int) size
{
    // Draw box
    [NSBezierPath setDefaultLineWidth:size];
    
    NSBezierPath* path;
    if (rounded)
        path = [NSBezierPath bezierPathWithRoundedRect:rectangle xRadius:5.0 yRadius:5.0];
    else
        path = [NSBezierPath bezierPathWithRect:rectangle];
    [color set];
    [path setLineJoinStyle:NSRoundLineJoinStyle];
    [path stroke];
} // end drawBox

-(int) drawDay:(int) aDay
{
    float center = 0.5;
    NSRect tBounds = [self bounds];
    int tRow, tColumn;
    NSString* tString;
    NSSize tSize;
    NSRect tRect;
    
    tRow = aDay/7;
    tColumn = aDay - (tRow*7);
    
	tString=[monthView[aDay] getDayString];

    tRect = NSMakeRect(
        MZCALENDARCONTROL_OFFSET_H + (dayWidth*tColumn) + cwOffset
        , NSHeight(tBounds) - (tRow+3)*dayHeight - MZCALENDARCONTROL_OFFSET_V
        , dayWidth -1
        , dayHeight -1
    );

    //[self drawBox:tRect isRounded:FALSE color:[NSColor blackColor] size:1];
    // current day?
    if ([[NSDate getDateNSDate:[NSDate date]] compare:monthView[aDay]]
    	== NSOrderedSame)
    {
    	// draw current day -----------------------------------------------------------------------
        [NSBezierPath setDefaultLineWidth:1.0];
        NSBezierPath* path = [NSBezierPath bezierPathWithRoundedRect:tRect
            xRadius:5.0 yRadius:5.0];
        
        [path setLineJoinStyle:NSRoundLineJoinStyle];
        [hiliteColor set];
        [path fill];

        if ((showBoxes == true) && !(aDay < firstDay || aDay > lastDay))
        {
        	// Draw box
            [self drawBox:tRect isRounded:TRUE color:dateColor size:1];
    	}
        
        tSize = [tString sizeWithAttributes:currentDayAttributes];
    	[tString drawAtPoint:NSMakePoint(NSMidX(tRect) - tSize.width*center
            , NSMinY(tRect)+3) withAttributes:currentDayAttributes];
    }
    else if (aDay < firstDay || aDay > lastDay)
    {

        // draw days not in month of current month view -------------------------------------------
    	tSize = [tString sizeWithAttributes:daysNotThisMonth];
    	[tString drawAtPoint:NSMakePoint(NSMidX(tRect) - tSize.width*center
    		, NSMinY(tRect)+3) withAttributes:daysNotThisMonth];
    }
    else
    {
        // draw regular old day -------------------------------------------------------------------
        if (showBoxes == true)
        {
        	// Draw box
            [self drawBox:tRect isRounded:TRUE color:dateColor size:1];
    	}

        tSize = [tString sizeWithAttributes:normalAttributes];
        [tString drawAtPoint:NSMakePoint(NSMidX(tRect) - tSize.width*center
            , NSMinY(tRect)+3) withAttributes:normalAttributes];
    }
    
    // selected date
    if ([selectedDate getDay] == [monthView[aDay] getDay]  
    	&& aDay >= firstDay && aDay <= lastDay)
    {
        // Draw box
        NSRect selectedRect;
        selectedRect.origin.x = tRect.origin.x+1;
        selectedRect.origin.y = tRect.origin.y+1;
        selectedRect.size.height = tRect.size.height-2;
        selectedRect.size.width = tRect.size.width-2;
        
        [self drawBox:selectedRect isRounded:TRUE color:hiliteColor size:2];
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
        bool hasReminders = FALSE;
        if (useTasks == TRUE)
        {
            hasReminders = [self HasReminders:monthView[aDay]];
        }
        else
        {
            hasReminders = [self HasReminders:monthView[aDay]];
        }
    	if (hasReminders == true)
    	{
        	[reminderImage drawAtPoint:
            	NSMakePoint(tRect.origin.x+tRect.size.width-MZINDICATOR_X_OFFSET
            	, NSMidY(tRect)) fromRect:NSZeroRect
            	operation:NSCompositeSourceOver fraction:1.0];
    	}
    }
    return 0;
} // end drawDay

-(void) drawRect:(NSRect) aRect
{  
    int i = 0;
    NSString* dayArray[7] = {[monthView[0] getDayNameShortString]
    	, [monthView[1] getDayNameShortString]
        , [monthView[2] getDayNameShortString]
        , [monthView[3] getDayNameShortString]
        , [monthView[4] getDayNameShortString]
        , [monthView[5] getDayNameShortString]
        , [monthView[6] getDayNameShortString]
    };
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
    dayHeight = (tBounds.size.height-2*MZCALENDARCONTROL_OFFSET_V)/NUMBER_OF_ROWS;
    
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
    tRect = NSMakeRect(
        MZCALENDARCONTROL_OFFSET_H
        , NSHeight(tBounds) - dayHeight - MZCALENDARCONTROL_OFFSET_V
        , dayWidth*(nColumns-3) -1
        , dayHeight -1);
    //[self drawBox:tRect isRounded:FALSE];
    [tString drawAtPoint:NSMakePoint(NSMinX(tRect) + MZCALENDARCONTROL_OFFSET_H
        , NSMinY(tRect)+2) withAttributes:titleAttributes];
    
	tString = @"⇠";
    tSize = [tString sizeWithAttributes:titleAttributes];
    tRect = NSMakeRect(MZCALENDARCONTROL_OFFSET_H + (4*dayWidth) + cwOffset
        , NSHeight(tBounds) - dayHeight - MZCALENDARCONTROL_OFFSET_V
        , dayWidth -1, dayHeight -1);
    //[self drawBox:tRect isRounded:FALSE];
    [tString drawAtPoint:NSMakePoint(NSMidX(tRect) - tSize.width * 0.5
        , NSMinY(tRect)+2) withAttributes:titleAttributes];
    
    tString = @"•";
    tSize = [tString sizeWithAttributes:titleAttributes];
    tRect = NSMakeRect(MZCALENDARCONTROL_OFFSET_H + (5*dayWidth) + cwOffset
        , NSHeight(tBounds) - dayHeight - MZCALENDARCONTROL_OFFSET_V
        , dayWidth -1, dayHeight -1);
    //[self drawBox:tRect isRounded:FALSE];
    [tString drawAtPoint:NSMakePoint(NSMidX(tRect) - tSize.width * 0.5
        , NSMinY(tRect)+2) withAttributes:titleAttributes];
    
    tString = @"⇢";
    tSize = [tString sizeWithAttributes:titleAttributes];
    tRect = NSMakeRect(MZCALENDARCONTROL_OFFSET_H + (6*dayWidth) + cwOffset
        , NSHeight(tBounds) - dayHeight - MZCALENDARCONTROL_OFFSET_V
        , dayWidth -1, dayHeight -1);
    //[self drawBox:tRect isRounded:FALSE];
    [tString drawAtPoint:NSMakePoint(NSMidX(tRect) - tSize.width * 0.5
        , NSMinY(tRect)+2) withAttributes:titleAttributes];
        
    // Draw the week header
    for(i=0; i<7; i++)
    {            
        tRect = NSMakeRect(
            MZCALENDARCONTROL_OFFSET_H + (i*dayWidth) + cwOffset
            , NSHeight(tBounds) - dayHeight*2 - MZCALENDARCONTROL_OFFSET_V
            , dayWidth -1
            , dayHeight -1
        );
        //[self drawBox:tRect isRounded:FALSE];
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
    	for(i=0; i<8; i++)
    	{
            
        	tRect = NSMakeRect(
                MZCALENDARCONTROL_OFFSET_H
            	, NSHeight(tBounds) - (i+1)*dayHeight - MZCALENDARCONTROL_OFFSET_V
            	, dayWidth - 1, dayHeight - 1
            );

            //[self drawBox:tRect isRounded:FALSE];
        	if (i==1)
        	{
            	tString = @"cw";
            	[tString drawAtPoint:NSMakePoint(NSMinX(tRect)
                	+MZCALENDARCONTROL_OFFSET_H
                	, NSMinY(tRect)+4.5) withAttributes:weekAttributes];
        	}
        	else
        	{
            	tString = [monthView[(i-2)*7] getWeekString];
            	[tString drawAtPoint:NSMakePoint(NSMinX(tRect)
                	+MZCALENDARCONTROL_OFFSET_H
        			, NSMinY(tRect)+4.5) withAttributes:weekAttributes];
        	}
    	}
    }
} // end drawRect

-(void) nextMonth
{
    NSDateComponents* dateComponents = [[NSDateComponents alloc]init];
    [dateComponents setMonth:1];
    NSCalendar* calendar = [NSCalendar currentCalendar];
    [self setDate:[calendar dateByAddingComponents:dateComponents 
    	toDate:selectedDate options:0]];
} // end nextMonth

-(void) lastMonth
{
    NSDateComponents* dateComponents = [[NSDateComponents alloc]init];
    [dateComponents setMonth:-1];
    NSCalendar* calendar = [NSCalendar currentCalendar];
    [self setDate:[calendar dateByAddingComponents:dateComponents 
    	toDate:selectedDate options:0]];
} // end lastMonth

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
} // end controlAtPoint

-(void) mouseDown:(NSEvent *) theEvent
{
    NSPoint tPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
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
} // end mouseDown

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
} // end rightMouseDown

-(void) setTarget:(id) aTarget
{
    target = aTarget;
} // end setTarget


-(bool) HasEvents:(NSDate*) date
{
	bool retval = false;

    NSDateComponents* comps = [[NSCalendar currentCalendar]
    	components: NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay
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
} // end HasEvents

-(bool) HasReminders:(NSDate*) date
{
    __block bool remindersFound = FALSE;

    NSDateComponents* comps = [[NSCalendar currentCalendar]
    	components: NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay
        fromDate: date];
        
    NSDate* startDate = [[NSCalendar currentCalendar] dateFromComponents:comps];
    NSDate* endDate = [startDate dateByAddingTimeInterval:(24*60*60)-1];

    // Create the predicate from the event store's instance method
    NSPredicate *predicate
        = [store predicateForIncompleteRemindersWithDueDateStarting:startDate
        ending:endDate calendars:nil];
    
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    // Fetch all events that match the predicate
    [store fetchRemindersMatchingPredicate:predicate completion:^(NSArray *reminders) {
        if ([reminders count] > 0) {
            remindersFound = TRUE;
        }
        dispatch_semaphore_signal(sema);
    }];
    
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    
	return remindersFound;
} // end HasReminders


// With the observable keys set up above and the appropriate bindings in IB,
// we can trigger UI updates just by signaling changes to the keys
-(void) calendarsChanged:(NSNotification *)notification
{
	if (showEventIndicators)
    {
		[self setNeedsDisplay:YES];
    }
} // end calendarsChanged

-(void) eventsChanged:(NSNotification *)notification
{
	if (showEventIndicators)
    {
		[self setNeedsDisplay:YES];
    }
} // end eventsChanged

-(void) tasksChanged:(NSNotification *)notification
{
	if (showReminderIndicators)
    {
		[self setNeedsDisplay:YES];
    }
} // end tasksChanged

@end // end MZCalendarControl
