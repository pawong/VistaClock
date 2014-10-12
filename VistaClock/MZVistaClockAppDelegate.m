//
//  MZVistaClockAppDelegate.m
//  VistaClock
//
//  Created by Paul Wong on 9/5/14.
//  Copyright (c) 2014 Mazookie, LLC. All rights reserved.
//

#import "MZVistaClockAppDelegate.h"

@implementation MZVistaClockAppDelegate

@synthesize prefsWindow;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    // get settings first thing
    settings = [VCSettings sharedSettings];
    
    // process the command line
    [self processCommandLine];
    
    // init eventArray
	clockCollectionArray = [[NSMutableArray alloc] init];
    
    // default start
    [_vistaClockWindow setCollectionBehavior
        :NSWindowCollectionBehaviorCanJoinAllSpaces];
    
    // only for 10.10 and beyond
    //_vistaClockWindow.titleVisibility = NSWindowTitleHidden;
    
    // should be yes, but make sure
    settings.needsDisplay = YES;
 
    // status item init
    // set status item to the right.
    [self createStatusItem];
    
    statusItemView = [[MZStatusItemView alloc] init];
    [statusItemView setMenu:statusMenu];
    
    statusItemView.statusItem = statusItem;
    statusItemView.target = self;
    statusItemView.action = @selector(openVistaClockWindow:);
    [statusItem setView:statusItemView];

    // get the date
    lastDate = [[NSDate getDateNSDate:[NSDate date]] copy];

    // dark menu, init
    darkMenu = FALSE;

    // get calendar access
    [self getCalendarAccess];
    
    // launch the timer last
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self 
        selector:@selector(fireTimer:) userInfo:nil repeats:YES];
        
    // keeps timer moving, even when menu has control
    [[NSRunLoop currentRunLoop] addTimer:timer 
        forMode:NSEventTrackingRunLoopMode];
} // end of applicationDidFinishLaunching


// called by the timer
-(void) fireTimer:(NSTimer*)timer 
{
    [self updateTime];
} // end of fireTimer


// Set current date time things.
-(void) updateTime
{
    // need to update the display?
    if (settings.needsDisplay == YES)
    {
        [self configureWindow];
    }

    // use dark menus, and then force to update
    if ([self isDarkMenu] != darkMenu)
    {
        lastWeek = -1; // force redraw
        darkMenu = [self isDarkMenu];
        if (darkMenu)
        {
            [statusItemView setDarkTheme:TRUE];
        }
        else
        {
            [statusItemView setDarkTheme:FALSE];
        }
    }

    NSDate* now = [NSDate date];
    
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    
    // Date formats
    [dateFormatter setDateFormat:statusItemFormat];
    NSString* statusItemDate = [dateFormatter stringFromDate:now];
    
    [dateFormatter setDateStyle:NSDateFormatterFullStyle];
    NSString* fullDate = [dateFormatter stringFromDate:now];
    
    [dateFormatter setTimeStyle:NSDateFormatterLongStyle];
    NSString* fullDateTime = [dateFormatter stringFromDate:now];
    
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle]; // clear
        
    //[dateFormatter setDateStyle:NSDateFormatterLongStyle];
    //NSString* longDate = [dateFormatter stringFromDate:now];
        
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    NSString* mediumDate = [dateFormatter stringFromDate:now];
        
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    NSString* shortDate = [dateFormatter stringFromDate:now];

    [dateFormatter setDateStyle:NSDateFormatterNoStyle]; // clear
    
    // Time formats
    //[dateFormatter setDateFormat:TIME_FORMAT_NORMAL];
    //NSString* normalTime = [dateFormatter stringFromDate:now];
 
    [dateFormatter setDateFormat:TIME_FORMAT_NORMAL_FULL];
    NSString* normalFullTime = [dateFormatter stringFromDate:now];
    
    //[dateFormatter setDateFormat:TIME_FORMAT_MILITARY];
    //NSString* militaryTime = [dateFormatter stringFromDate:now];
 
    //[dateFormatter setDateFormat:TIME_FORMAT_MILITARY_FULL];
    //NSString* militaryFullTime = [dateFormatter stringFromDate:now];

    // update status item
    if (settings.showWeekNumberIcon == YES)
    {
        NSDateFormatter* weekFormat = [[NSDateFormatter alloc] init];
        [weekFormat setDateFormat:@"w"];
        NSString* weekString = [weekFormat stringFromDate:now];
        NSInteger thisWeek = [weekString integerValue];
        if (lastWeek != thisWeek)
        {
            // create and set the image
            NSImage* weekImage;
            if (settings.useBWWeekIcon == TRUE)
            {
                weekImage = [[NSImage imageNamed:@"statusbarIconBW.png"] copy];
            }
            else
            {
                weekImage = [[NSImage imageNamed:@"statusbarIcon.png"] copy];
            }
                
            int x;
            if (thisWeek < 10)
            {
                x = 8;
            }
            else
            {
                x = 4;
            }
            NSPoint p = {x, 2};
            [weekImage lockFocus];
            
            // switch font color for dark menus?
            if ([self isDarkMenu] && settings.useBWWeekIcon == TRUE)
            {
                NSDictionary* attributes = [NSDictionary
                    dictionaryWithObject:[NSColor whiteColor]
                    forKey:NSForegroundColorAttributeName];
                [weekString drawAtPoint:p withAttributes:attributes];
            }
            else
            {
                [weekString drawAtPoint:p withAttributes:nil];
            }
            [weekImage unlockFocus];
            
            // update image
            [statusItemView setImage:weekImage];
            lastWeek = thisWeek;
        }
    }
    else
    {
        // show nothing
        [statusItemView setImage:nil];
    }
    
    if (settings.showStatusSecondaryTime)
    {
        NSDateFormatter* title1DateFormat = [[NSDateFormatter alloc] init];
        [title1DateFormat setDateFormat:DATE_FORMAT_TIMEZONE_DAY];
        [title1DateFormat setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
        NSString* title1 = [title1DateFormat stringFromDate:now];
        NSDateFormatter* title2DateFormat = [[NSDateFormatter alloc] init];
        [title2DateFormat setDateFormat:TIME_FORMAT_NORMAL];
        [title2DateFormat setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
        NSString* title2 = [title2DateFormat stringFromDate:now];
        
        [statusItemView setTitles:statusItemDate subTitle1:title1 subTitle2:title2];
    }
    else
    {
        [statusItemView setTitle:statusItemDate];
    }
    
    
    // only update panel when the window is visiable
    //if ([_vistaClockWindow isVisible])
    {
        // set menu item
        [_timeNow setTitle:fullDateTime];
    
        // set window items
        // check size of window to see if title will fit
        if (clockCollectionArray.count<1)
        {
            [titleTextLabel setStringValue:normalFullTime];
        }
        else
        {
            int windowSize = _vistaClockWindow.frame.size.width;
            if (windowSize > 288)
            {
                [titleTextLabel setStringValue:fullDate];
            }
            else if (windowSize > 150)
            {
                [titleTextLabel setStringValue:mediumDate];
            }
            else
            {
                [titleTextLabel setStringValue:shortDate];
            }
        }

        // update secondary clocks
        MZClockItem* item;
        for (long i=0; i<clockCollectionArray.count; i++)
        {
            item = (MZClockItem*)[clockCollectionView itemAtIndex:i];
            [item update:now];
        }
        
        // update calendar
        if ([self isCalendarChanged] == TRUE && settings.showCalendar == TRUE)
        {
            if ([lastCal compare:@"gregorian"] == NSOrderedSame)
            {
                [calendar setHidden:false];
                [altcal setHidden:true];
                [calendar setDate:[NSDate getDateNSDate:now]];
            
            }
            else
            {
                [altcal setHidden:false];
                [calendar setHidden:true];
                [altcal setDateValue:now];
            }
        }
    
        // move to current date if changed
        if ([lastDate compare:[NSDate getDateNSDate:now]]
            != NSOrderedSame)
        {
            lastDate = [[NSDate getDateNSDate:now] copy];
            [calendar setDate:lastDate];
        }
    }
    
} // end of updateTime


// process command line arguments
-(void) processCommandLine
{
    NSArray *arguments = [[NSProcessInfo processInfo] arguments];
    // reset takes takes priority
    for (int i=0; i<arguments.count; i++)
    {
    	if ([[arguments objectAtIndex:i] isEqualToString:@"-R"])
        {
        	[settings reset];
        }
    }
    // now handle the rest
    for (int i=0; i<arguments.count; i++)
    {
        if ([[arguments objectAtIndex:i] isEqualToString:@"-F:1"])
        {
            settings.floatRight = TRUE;
        }
        else if ([[arguments objectAtIndex:i] isEqualToString:@"-F:0"])
        {
            settings.floatRight = FALSE;
        }
    }
} // end of processCommandLine


// create the status item and move it to the right
-(void) createStatusItem
{
    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    int priority = 0;
    
    // floatRight or not
    if (settings.floatRight == TRUE)
    {
        priority = INT32_MAX;
    }
    
    // Create the item with 0 length and the change it.
    if (!statusItem) 
    {
        statusItem = [bar _statusItemWithLength:0 withPriority:priority];
        [statusItem setLength:NSVariableStatusItemLength];
    }
    
} // end of createStatusItem


// This method is called when opening the panel
-(IBAction) openVistaClockWindow:(id)sender
{
    if ([_vistaClockWindow isVisible] && [NSApp isActive])
    {
        // hide window
        [_vistaClockWindow orderOut:self];
        [NSApp activateIgnoringOtherApps:false];
    }  
    else
    {
        // show window
        [_vistaClockWindow makeKeyAndOrderFront:sender];
        [NSApp activateIgnoringOtherApps:true];
    }
} // end of openVistaClockPanel


-(IBAction) launchAboutBoxPanel:(id)sender
{
    // hide main window
    [_vistaClockWindow orderOut:sender];
    // launch about box
    [[NSApplication sharedApplication] orderFrontStandardAboutPanel:sender];
    [NSApp arrangeInFront:self];
} // end of launchAboutBox

// launch the date & time preference panel
-(IBAction) launchDateTimePreferencePanel:(id)sender
{
    [[NSWorkspace sharedWorkspace] 
        openFile:@"/System/Library/PreferencePanes/DateAndTime.prefPane"];
} // end of launchDateTimePreferencePanel


-(int) addClock
{
	NSUInteger index = [[clockArrayController arrangedObjects] count];

	[clockArrayController insertObject:
        [NSDictionary dictionaryWithObjectsAndKeys:@"Name", @"Name", nil]
        atArrangedObjectIndex:index];
    
    //[self resizeWindow];
    return (int)index;
} // end of addClock


-(void) removeClock
{
 	NSUInteger index = [[clockArrayController arrangedObjects] count];
	if ( index > 0) {
		index--;
		[clockArrayController removeObjectAtArrangedObjectIndex:index];
	}
    
    //[self resizeWindow];
} // end of removeClock


-(void) removeAllClocks
{
 	NSUInteger cnt = [[clockArrayController arrangedObjects] count];
    for (long i=cnt; i>0; i--)
    {
        [clockArrayController removeObjectAtArrangedObjectIndex:i-1];
	}
    
    //[self resizeWindow];
} // end of removeAllClocks

-(void) configureWindow
{
    // remove all clocks
    [self removeAllClocks];
    
    // reset last week to redraw
    lastWeek = -1;
    
    // configure status item
    statusItemFormat = [self buildStatusItemDateFormatString];
    
    // set keep on top
    if (settings.useKeepTop == YES)
    {
        [_vistaClockWindow setLevel:1];
    }
    else
    {
        [_vistaClockWindow setLevel:NSNormalWindowLevel];
    }
    
    // turn on auto hide
    [_vistaClockWindow setHidesOnDeactivate:settings.useAutoHide];
    
    // show week numbers on calendar
    [calendar setShowWeekNumbers:settings.showWeekNumbers];
    
    // show boxes on calendar
    [calendar setShowBoxes:settings.showCalendarBoxes];
    
    // show calendar event indicator
    [calendar setShowEventIndicators:settings.showEvents];
    
    // show calendar reminder indicator
    [calendar setShowReminderIndicators:settings.showReminders];
    
    // set theme elements
    // Font Shadow this code should move into calendar at some point
    NSColor* shadowColor;
    NSShadow* shadow = [[NSShadow alloc] init];
    [shadow setShadowOffset:NSMakeSize( 1, 1 )];
    [shadow setShadowBlurRadius:1.5];
    
    if (settings.useShadows)
    {
        if (settings.useDarkTheme) // use dark theme
        {
            shadowColor = [NSColor blackColor];
        }
        else
        {
            shadowColor = [NSColor lightGrayColor];
        }
    }
    else
    {
        shadowColor = NULL;
    }
    [calendar setShadowColor:shadowColor];

    // background color
    if (settings.useDarkTheme == YES)
    {
        [_vistaClockWindow setBackgroundColor:[NSColor colorWithPatternImage:
            [NSImage imageNamed:@"bg-texture.png"]]];
        [calendar setColor:[NSColor whiteColor]];
    }
    else
    {
        [_vistaClockWindow setBackgroundColor:[NSColor windowBackgroundColor]];
        [calendar setColor:[NSColor blackColor]];
    }
    
    
    // add clocks from config
    int cnt = (int)[settings clockConfigs].count;
    for (int i=0; i<cnt; i++)
    {
        MZClockConfig* config = [[settings clockConfigs] objectAtIndex:i];
        MZClockItem* item = (MZClockItem*)[clockCollectionView itemAtIndex:[self addClock]];
        if (config.timezoneName != nil && config.title != nil)
        {
            [item configureClockItem:config.title
                zone:[NSTimeZone timeZoneWithName:config.timezoneName]
                clockFace:settings.clockFaceName
                darkTheme:settings.useDarkTheme
                shadow:settings.useShadows
                seconds:config.useSeconds
                militaryTime:settings.useMilitary];
        }
    }
    
    // resize the panel
    [self resizeWindow];
    
    // done painting
    settings.needsDisplay = NO;
} // end of configureWindow

-(void) resizeWindow
{
    NSScreen* main = [NSScreen mainScreen];
    NSRect screenRect = [main visibleFrame];
    
    int clockSize = 0;
    int maxSize = screenRect.size.width;
    
    for (long i=0; i<clockCollectionArray.count; i++)
    {
        if (clockSize+(2*128) > maxSize)
            break;
        clockSize+=128;
    }
    NSRect clockFrame = [clockScrollView frame];
    clockFrame.size.width = clockSize;
    [clockScrollView setFrame:clockFrame];
    
    int windowSize = 0;
    // show calendar?
    if (!settings.showCalendar && clockCollectionArray.count > 0)
    {
        [calendar setHidden:TRUE];
        [altcal setHidden:TRUE];
        [clockScrollView setFrameOrigin:NSMakePoint(10, 10)];
        [clockScrollView setNeedsDisplay:TRUE];
        windowSize = 20;
    }
    else // no clocks means you have to have a calendar
    {
        if ([lastCal compare:@"gregorian"] == NSOrderedSame)
        {
            [calendar setHidden:FALSE];
            [altcal setHidden:TRUE];
        }
        else
        {
            [calendar setHidden:TRUE];
            [altcal setHidden:FALSE];
        }
        [clockScrollView setFrameOrigin:NSMakePoint(252, 10)];
        [clockScrollView setNeedsDisplay:TRUE];
        [calendar setFrameOrigin:NSMakePoint(10, 10)];
        [calendar setNeedsDisplay:TRUE];
        windowSize = 258;
    }
    
    windowSize += clockSize;
    
    NSRect frame = [_vistaClockWindow frame];
    frame.size.width = windowSize;
    [_vistaClockWindow setFrame:frame display:YES animate:YES];
} // end of resizeWindow


// build StatusItem DateFormat String
-(NSString*) buildStatusItemDateFormatString
{
    //@"MMM d  h:mm a"
    NSString* buildString = [[NSString alloc] init];
    
    buildString = [buildString stringByAppendingString:@""];

    if (settings.showStatusWeekDay)
    {
        buildString = [buildString stringByAppendingString:@"EEE "];
    }
    if (settings.showStatusDate)
    {
    	NSDateFormatter *format = [[NSDateFormatter alloc] init];
        [format setDateStyle:NSDateFormatterLongStyle];
        NSString *dateFormat = [format dateFormat];
        dateFormat = [dateFormat stringByReplacingOccurrencesOfString:@"y" 
        	withString:@""];
        dateFormat = [dateFormat stringByReplacingOccurrencesOfString:@"," 
        	withString:@""];
        dateFormat = [dateFormat stringByReplacingOccurrencesOfString:@"MMMM" 
        	withString:@"MMM"];
        buildString = [buildString stringByAppendingString:dateFormat];
    }
    if (settings.useStatusMilitary)
    {
        if (settings.showStatusSeconds)
        {
            buildString = [buildString stringByAppendingString:@" HH:mm:ss"];
        }
        else
        {
            buildString = [buildString stringByAppendingString:@" HH:mm"];
        }
    }
    else
    {
        if (settings.showStatusAMPM)
        {
            if (settings.showStatusSeconds)
            {
                buildString = [buildString stringByAppendingString:@" h:mm:ss a"];
            }
            else
            {
                buildString = [buildString stringByAppendingString:@" h:mm a"];
            }
        }
        else
        {
            if (settings.showStatusSeconds)
            {
                buildString = [buildString stringByAppendingString:@" h:mm:ss"];
            }
            else
            {
                buildString = [buildString stringByAppendingString:@" h:mm"];
            }
        }
    }
    
    return buildString;
} // end of buildStatusItemDateFormatString



// get the current calendar
-(NSString*) getCurrentCalendar
{
    NSCalendar *usersCalendar = [[NSLocale currentLocale]
    	objectForKey:NSLocaleCalendar];
    return [usersCalendar calendarIdentifier];
} // end of getCurrentCalendar


// check for a change in calendar
-(bool) isCalendarChanged
{
    bool retval = false;
    NSString* currentCal = [self getCurrentCalendar];
    if ([currentCal compare:lastCal] != NSOrderedSame)
    {
        lastCal = [currentCal copy];
        retval = true;
    }
    return retval;
} // end of isCalendarChanged


-(IBAction) openPreferences:(id)sender
{
    if (prefsWindow == nil)
        prefsWindow = [[MZVistaClockPreferences alloc] initWithWindowNibName:@"MZVistaClockPreferences"];
    [prefsWindow showWindow:self];
    [prefsWindow.window makeKeyAndOrderFront:nil];
    //[NSApp runModalForWindow:prefsWindow.window];
} // end of openPreferences


-(void) getCalendarAccess
{
    // get calendar access
    store = [[EKEventStore alloc] init];
    BOOL needsToRequestAccessToEventStore = NO; // iOS 5 behavior
    EKAuthorizationStatus authorizationStatus = EKAuthorizationStatusAuthorized; // iOS 5 behavior
    if ([[EKEventStore class] respondsToSelector:@selector(authorizationStatusForEntityType:)])
    {
        authorizationStatus = [EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent&EKEntityTypeEvent];
        needsToRequestAccessToEventStore = (authorizationStatus == EKAuthorizationStatusNotDetermined);
    }

    if (needsToRequestAccessToEventStore)
    {
        [store requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error)
        {
            if (granted)
            {
                dispatch_async(dispatch_get_main_queue(),
                ^{
                    // You can use the event store now
                });
            }
        }];
    }
    else if (authorizationStatus != EKAuthorizationStatusAuthorized)
    {
        // Access denied
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Access to calendar data has been denied!  Please enable access in System Preferences and restart NextEvent."];
        [alert runModal];
        // quit
        [NSApp terminate:self];
        
    }
} // end of getCalendarAccess

-(IBAction)launchCalendar:(id)sender
{
    [[NSWorkspace sharedWorkspace] launchApplication:@"iCal"];
} // end of launchCalendar


-(IBAction)launchReminders:(id)sender;
{
    [[NSWorkspace sharedWorkspace] launchApplication:@"Reminders"];
} // end of launchReminders


-(bool) isDarkMenu
{
    bool retval = FALSE;
    
    // get the key
    NSString* value = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
    
    // if got a key
    if (value && [value compare:@"Dark"] == NSOrderedSame)
    {
        retval = TRUE;
    }
    
    return retval;
} // end of isDarkMenu

@end
