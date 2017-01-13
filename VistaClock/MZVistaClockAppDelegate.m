//
//  MZVistaClockAppDelegate.m
//  VistaClock
//
//  Created by Paul Wong on 9/5/14.
//  Copyright (c) 2014 Mazookie, LLC. All rights reserved.
//

#import "MZVistaClockAppDelegate.h"


@implementation MZVistaClockAppDelegate

@synthesize prefsWindow, abox;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    // get settings first thing
    settings = [VCSettings sharedSettings];
    
    // process the command line
    [self processCommandLine];

    // show dock icon
    if (settings.showDockIcon) {
        ProcessSerialNumber psn = { 0, kCurrentProcess };
        TransformProcessType(&psn, kProcessTransformToForegroundApplication);
    }

    // init eventArray
	clockCollectionArray = [[NSMutableArray alloc] init];
    
    // default start
    [_vistaClockWindow setCollectionBehavior: NSWindowCollectionBehaviorCanJoinAllSpaces];

    // ask for calendar access
    [self getCalendarAccess];

    // only for 10.10 and beyond
    _vistaClockWindow.titleVisibility = NSWindowTitleHidden;

    // setup toolbar
    showToolbar = FALSE;
    if (showToolbar)
    {
        [self configureToolbar: TRUE];
    }
    else
    {
        [self configureToolbar: FALSE];
    }

    // set the date box place holder to locale date
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateStyle:NSDateFormatterShortStyle];
    [dateFormat setLocale:[NSLocale currentLocale]];

    // set the format field for the date box
    [gotoDateField setPlaceholderString:[dateFormat dateFormat]];

    // should be yes, but make sure
    settings.needsDisplay = YES;
 
    // status item init
    // set status item to the right.
    [self createStatusItem];
    
    statusItemView = [[MZStatusItemView alloc] init];
    [statusItemView setMenu:statusMenu];
    
    statusItemView.statusItem = statusItem;
    statusItemView.target = self;
    statusItemView.action = @selector(toggleVistaClockWindow:);
    [statusItem setView:statusItemView];

    // get the date
    lastDate = [[NSDate getDateNSDate:[NSDate date]] copy];

    // dark menu, init
    darkMenu = FALSE;

    // report home
    MZPoster* report = [[MZPoster alloc] init];
    [report sendPost];

    // launch the timer last
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(fireTimer:)
        userInfo:nil repeats:YES];
        
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
        [NSApp activateIgnoringOtherApps:true];
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

    // inverse title
    [statusItemView setUseInverseTitle:settings.useInverseTitle];

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
                weekImage = [[NSImage imageNamed:@"bw_calendar"] copy];
            }
            else
            {
                weekImage = [[NSImage imageNamed:@"c_calendar"] copy];
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
            NSPoint p = {x, 1};
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
        if (settings.showDateTime && (settings.showTime || settings.showDate)) // show time
        {
            // show nothing
            [statusItemView setImage:nil];
        }
        else
        {

            if (settings.useBWIcon) // use black and white
            {
                if ([self isDarkMenu])
                {
                    [statusItemView setImage:[[NSImage imageNamed:@"bw_w_mazookie"] copy]];
                }
                else
                {
                    [statusItemView setImage:[[NSImage imageNamed:@"bw_b_mazookie"] copy]];
                }
            }
            else
            {
                if ([self isDarkMenu])
                {
                    [statusItemView setImage:[[NSImage imageNamed:@"c_w_mazookie"] copy]];
                }
                else
                {
                    [statusItemView setImage:[[NSImage imageNamed:@"c_b_mazookie"] copy]];
                }
            }
        }
    }

    if (settings.showDateTime) // show time
    {
        if (settings.showStatusSecondaryTime && settings.showTime)
        {
            NSDateFormatter* title1DateFormat = [[NSDateFormatter alloc] init];
            [title1DateFormat setDateFormat:DATE_FORMAT_TIMEZONE_DAY];
            [title1DateFormat setTimeZone:[NSTimeZone timeZoneWithName:settings.statusSecondaryTimezone]];
            NSString* title1 = [title1DateFormat stringFromDate:now];
            NSDateFormatter* title2DateFormat = [[NSDateFormatter alloc] init];
            if (settings.useStatusMilitary)
            {
                [title2DateFormat setDateFormat:TIME_FORMAT_MILITARY];
            }
            else
            {
                [title2DateFormat setDateFormat:TIME_FORMAT_NORMAL];
            }
            [title2DateFormat setTimeZone:[NSTimeZone timeZoneWithName:settings.statusSecondaryTimezone]];
            NSString* title2 = [title2DateFormat stringFromDate:now];
        
            [statusItemView setTitles:statusItemDate subTitle1:title1 subTitle2:title2];
        }
        else
        {
            [statusItemView setTitle:statusItemDate];
        }
    }
    else
    {
        [statusItemView setTitle:@""];
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
            if (showToolbar == TRUE)
            {
                [_vistaClockWindow setTitle:normalFullTime];
            }
            else
            {
                [_vistaClockWindow setTitle:@""];
            }
            [titleLabel setStringValue:normalFullTime];
        }
        else
        {
            if (showToolbar == TRUE)
            {
                [_vistaClockWindow setTitle:fullDate];
            }
            else
            {
                [_vistaClockWindow setTitle:@""];
            }
            int windowSize = _vistaClockWindow.frame.size.width;
            if (windowSize > 288)
            {
                [titleLabel setStringValue:fullDate];
            }
            else if (windowSize > 150)
            {
                [titleLabel setStringValue:mediumDate];
            }
            else
            {
                [titleLabel setStringValue:shortDate];
            }
        }

        // update clocks
        MZClockItem* item;
        for (long i=0; i<clockCollectionArray.count; i++)
        {
            item = (MZClockItem*)[clockCollectionView itemAtIndex:i];
            [item update:now];
            if (i == 0 && settings.showDockIcon) {
                [NSApp setApplicationIconImage: [item getImage]];
            }
        }
        
        // update calendar
        if ([self isCalendarChanged] == TRUE && settings.showCalendar == TRUE)
        {
            if ([lastCal compare:@"gregorian"] == NSOrderedSame)
            {
                [calendar setHidden:false];
                [altcal setHidden:true];
                [calendar setDate:[NSDate getDateNSDate:now]];
                [toolBarMenuItem setEnabled:TRUE];
            
            }
            else
            {
                [altcal setHidden:false];
                [calendar setHidden:true];
                [altcal setDateValue:now];
                // toolbar is only enabled if gregorian calendar is showing
                if (showToolbar == TRUE)
                {
                    [self toggleToolbar:self];
                }
                [toolBarMenuItem setEnabled:FALSE];

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
    
    // update day details
    if ([_vistaClockWindow isVisible] && showToolbar)
    {
        NSDate* selectedDate = [calendar getDate];
        NSTimeInterval secondsBetween = [selectedDate timeIntervalSinceDate:[NSDate getDateNSDate:now]];
        
        [dayDetailLabel setStringValue:[[NSString alloc] initWithFormat:@"%@ / %ld"
            , [selectedDate getDayOfYearString], (long)secondsBetween/86400]];
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
            [settings archive];
        }
    }
    // now handle the rest
    for (int i=0; i<arguments.count; i++)
    {
        if ([[arguments objectAtIndex:i] isEqualToString:@"-F:1"])
        {
            settings.floatRight = TRUE;
            [settings archive];
        }
        else if ([[arguments objectAtIndex:i] isEqualToString:@"-F:0"])
        {
            settings.floatRight = FALSE;
            [settings archive];
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
-(IBAction) toggleVistaClockWindow:(id)sender
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
} // end of toggleVistaClockWindow


- (void)cancelOperation:(id)sender
{
    [self toggleVistaClockWindow:self];
} // end of cancelOperation


-(IBAction) launchAboutBoxPanel:(id)sender
{
    // hide main window
    //[_vistaClockWindow orderOut:sender];
    // launch about box
    //[[NSApplication sharedApplication] orderFrontStandardAboutPanel:sender];
    //[NSApp arrangeInFront:self];
    if (abox == nil) {
        abox = [[MZAboutBox alloc] initWithWindowNibName:@"MZAboutBox"];
        [abox setMacId:@"id466690161"];
    }
    [abox.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
    [abox showWindow:self];
    [abox forceHelp:FALSE];
} // end of launchAboutBox


-(IBAction) launchHelpPanel:(id)sender
{
    if (abox == nil) {
        abox = [[MZAboutBox alloc] initWithWindowNibName:@"MZAboutBox"];
        [abox setMacId:@"id466690161"];
    }
    [abox.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
    [abox showWindow:self];
    [abox forceHelp:TRUE];
} // end of launchHelpPanel


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

    // use red to highlight dates?
    if (settings.useHiliteColor)
    {
        [calendar setHiliteColor:[NSColor redColor]];
    }
    else
    {
        [calendar setHiliteColor:[NSColor selectedMenuItemColor]];
    }
    
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

    if (settings.useLargeFonts)
    {
        [calendar setFontSize:[NSFont systemFontSize]+2];
    }
    else
    {
        [calendar setFontSize:[NSFont systemFontSize]];
    }

    // background color
    if (settings.useDarkTheme == YES)
    {
        [_vistaClockWindow setBackgroundColor:[NSColor colorWithPatternImage:
            [NSImage imageNamed:@"bg-texture"]]];
        [calendar setColor:[NSColor whiteColor]];
    }
    else
    {
        [_vistaClockWindow setBackgroundColor:[NSColor windowBackgroundColor]];
        [calendar setColor:[NSColor blackColor]];
    }
    
    // toolbar is only enabled if calendar is showing
    if (settings.showCalendar == NO)
    {
        showToolbar = TRUE;
        [self toggleToolbar:self];
        [toolBarMenuItem setEnabled:FALSE];
    }
    else
    {
        [self resizeWindow];
        [toolBarMenuItem setEnabled:TRUE];
    }
    
    // add clocks from config last
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
                largeFonts:settings.useLargeFonts
                seconds:config.useSeconds
                militaryTime:settings.useMilitary];
        }
    }
    [clockScrollView setNeedsDisplay:YES];

    // done painting
    settings.needsDisplay = NO;
} // end of configureWindow


-(void) resizeWindow
{
    NSRect screenRect = [[NSScreen mainScreen] visibleFrame];
    NSRect frame = [_vistaClockWindow frame];
    
    int clockWidth = 0;
    NSPoint clockOrigin;
    int maxSize = screenRect.size.width;

    int windowWidth = 0;

    // is toolbar showing?
    if (showToolbar)
    {
        frame.size.height = WINDOW_HEIGHT_TOOLBAR;
        [_vistaClockWindow setTitleVisibility:NSWindowTitleVisible];
    }
    else
    {
        // adjust for wierd shift
        if (toolBarChanged)
        {
            toolBarChanged = FALSE;
            frame.origin.y -= 2;
        }

        frame.size.height = WINDOW_HEIGHT;
        [_vistaClockWindow setTitleVisibility:NSWindowTitleHidden];
    }

    // clocks only
    if (!settings.showCalendar && [settings.clockConfigs count] > 0)
    {
        [calendar setHidden:TRUE];
        [altcal setHidden:TRUE];
        clockOrigin = NSMakePoint(8, 8);
        windowWidth = 16;
    }
    else // clock and calendar
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
        clockOrigin = NSMakePoint(CALENDAR_WIDTH + 8, 8);
        windowWidth = CALENDAR_WIDTH + 16;
    }
    
    for (long i=0; i<[settings.clockConfigs count]; i++)
    {
        if (clockWidth + CLOCK_WIDTH + windowWidth > maxSize)
            break;
        clockWidth += CLOCK_WIDTH;
    }

    windowWidth += clockWidth;
    frame.size.width = windowWidth;

    [_vistaClockWindow setFrame:frame display:YES animate:YES];

    [clockScrollView setFrameOrigin:clockOrigin];
    [clockScrollView setFrameSize:NSMakeSize(clockWidth, CLOCK_HEIGHT)];
    [calendar setFrameOrigin:NSMakePoint(8,8)];

    //NSLog(@"Window Frame:   (%4.0f,%4.0f)(%4.0f,%4.0f)", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
} // end of resizeWindow


-(CGFloat) titleBarHeight:(NSWindow*) window
{
    CGFloat titleBarHeight = 0.0;
    NSRect frame = [window frame];

    NSRect contentRect;
    contentRect = [NSWindow contentRectForFrameRect: frame styleMask: window.styleMask];

    titleBarHeight = frame.size.height - contentRect.size.height;
    return titleBarHeight;
} // titleBarHeight


-(CGFloat) toolBarHeight:(NSWindow*) window
{
    NSToolbar *toolbar = [window toolbar];
    CGFloat toolBarHeight = 0.0;
    NSRect windowFrame;

    if (toolbar && [toolbar isVisible]) {
        windowFrame = [NSWindow contentRectForFrameRect:[window frame] styleMask:[window styleMask]];
        toolBarHeight = NSHeight(windowFrame) - NSHeight([[window contentView] frame]);
    }
    return toolBarHeight;
} // end toolbarHeight


// build StatusItem DateFormat String
-(NSString*) buildStatusItemDateFormatString
{
    //@"MMM d  h:mm a"
    NSString* buildString = [[NSString alloc] init];
    
    buildString = [buildString stringByAppendingString:@""];

    if (settings.showStatusWeekDay && settings.showDate)
    {
        buildString = [buildString stringByAppendingString:@"EEE"];
    }
    if (settings.showDate)
    {
    	NSDateFormatter *format = [[NSDateFormatter alloc] init];
        [format setDateStyle:NSDateFormatterLongStyle];
        NSString *dateFormat = [format dateFormat];
        dateFormat = [dateFormat stringByReplacingOccurrencesOfString:@"y" 
        	withString:@""];
        dateFormat = [dateFormat stringByReplacingOccurrencesOfString:@"," 
        	withString:@""];
        if (!settings.showMonth)
        {
            dateFormat = [dateFormat stringByReplacingOccurrencesOfString:@"MMMM"
                withString:@""];
        }
        else if (!settings.showStatusFullMonth)
        {
            dateFormat = [dateFormat stringByReplacingOccurrencesOfString:@"MMMM"
                withString:@"MMM"];
        }

        buildString = [buildString stringByAppendingString:@" "];
        buildString = [buildString stringByAppendingString:dateFormat];
    }
    if (settings.showTime)
    {
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
    }
    NSString *trimmedString = [buildString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    return trimmedString;
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
    [NSApp activateIgnoringOtherApps:YES];
    [prefsWindow.window setCanHide:NO];
} // end of openPreferences



-(void) configureToolbar:(bool) full
{
    // reset toolbar;
    [self resetToolbar];

    if (full)
    {
        [_vistaClockWindow.toolbar insertItemWithItemIdentifier:@"DateBoxID" atIndex:0];
        [_vistaClockWindow.toolbar insertItemWithItemIdentifier:@"GotoTodayID" atIndex:1];
        [_vistaClockWindow.toolbar insertItemWithItemIdentifier:@"DateDetailsID" atIndex:2];
        [_vistaClockWindow makeFirstResponder:gotoDateField];
    }
    else
    {
        [_vistaClockWindow.toolbar insertItemWithItemIdentifier:@"TitleID" atIndex:0];
        [_vistaClockWindow makeFirstResponder:clockCollectionView];
    }

    // redraw
    [self resizeWindow];
} // configureToolbar


-(void) resetToolbar
{
    while (_vistaClockWindow.toolbar.items.count > 0)
    {
        [_vistaClockWindow.toolbar removeItemAtIndex:0];
    }
    [_vistaClockWindow.toolbar insertItemWithItemIdentifier:NSToolbarFlexibleSpaceItemIdentifier atIndex:0];
    [_vistaClockWindow.toolbar insertItemWithItemIdentifier:@"SettingsID" atIndex:1];
} // resetToolbar


-(IBAction) toggleToolbar:(id)sender
{
    showToolbar = !showToolbar;
    toolBarChanged = TRUE;
    if (showToolbar)
    {
        [toolBarMenuItem setTitle:@"Hide Toolbar"];
    }
    else
    {
        [toolBarMenuItem setTitle:@"Show Toolbar"];
    }
    [self configureToolbar: showToolbar];
} // toggleToolbar


-(IBAction) gotoDate:(id)sender
{
    MZDateCalc* calc = [MZDateCalc alloc];
    [calc setCalendar:calendar];
    
    NSArray* strings = [[gotoDateField stringValue] componentsSeparatedByString:@","];

    // try to parse the date and set current date to it.
    if ([strings count] > 1)
    {
        if ([calc parseDate:strings[0]])
        {
            // got a date
            if (strings[1] != nil)
            {
                [calc moveDate:strings[1] useToday: NO];
            }
        }
        else
        {
            [calc moveDate:strings[1] useToday: NO];
        }
    }
    else
    {
        if (![calc parseDate:strings[0]])
        {
            [calc moveDate:strings[0] useToday: YES];
        }
    }
} // end of gotoDate


-(IBAction) goToday:(id)sender
{
    [gotoDateField setStringValue:@""];
    [calendar setDate:[NSDate getDateNSDate:[NSDate date]]];
} // end of goToday


-(void) getCalendarAccess
{
    // get calendar access do in main init.
    store = [[EKEventStore alloc] init]; 
        
    BOOL needsToRequestAccessToEventStore = NO; // iOS 5 behavior
    EKAuthorizationStatus authorizationStatus = EKAuthorizationStatusAuthorized; // iOS 5 behavior
    if ([[EKEventStore class] respondsToSelector:@selector(authorizationStatusForEntityType:)])
    {
        authorizationStatus = ([EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent] 
            & [EKEventStore authorizationStatusForEntityType:EKEntityTypeReminder]);
        needsToRequestAccessToEventStore = (authorizationStatus == EKAuthorizationStatusNotDetermined);
    }

    if (needsToRequestAccessToEventStore)
    {
        // events
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
        // reminders
        [store requestAccessToEntityType:EKEntityTypeReminder completion:^(BOOL granted, NSError *error)
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
        [alert setMessageText:@"Access to calendar or reminder data has been denied!\n"
            "Please enable access in System Preferences and restart VistaClock."];
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
