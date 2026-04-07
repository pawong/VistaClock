//
//  MZVistaClockPreferences.m
//  VistaClock
//
//  Created by Paul Wong on 9/12/14.
//  Copyright (c) 2026 Mazookie, LLC. All rights reserved.
//

#import "MZVistaClockPreferences.h"
#import <ServiceManagement/ServiceManagement.h>
#import <ServiceManagement/SMAppService.h>
#import "VistaClock-Swift.h"

@implementation MZVistaClockPreferences

-(id) initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self)
    {
        // Initialization code here.
        settings = [VCSettings sharedSettings];
        
        // timezone array
        NSArray *timezoneNames = [NSTimeZone knownTimeZoneNames];
        
        timezones = [NSMutableDictionary
        	dictionaryWithCapacity:[timezoneNames count]];
        
        int max = 0;
        for (NSString* name in timezoneNames)
        {
            max = max<[name length]?(int)[name length]:max;
        }
		
        max++;
        
		for (NSString *name in [timezoneNames
            sortedArrayUsingSelector:@selector(compare:)])
		{
            NSTimeZone* tz = [NSTimeZone timeZoneWithName:name];
            float f = [tz secondsFromGMT]/3600.00;
        	NSString* str = [NSString stringWithFormat:@"%@%*s%+6.2f"
                , [tz name], (max - (int)[name length]), " ", f];
            [timezones setObject:[tz name] forKey:str];
        }
    }
    return self;
} // end initWithWindow


-(void) windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    clockConfigArray = [[NSMutableArray alloc] init];
    
    // load clock faces
    [self getClockFaceNames];
    
    // initials window settings
    [self initSettings];

    [addClockButton setEnabled:FALSE];
    
    // no more delay
    //[self updateClockConfigArray];
    // delay
    [self performSelector:@selector(updateClockConfigArray) withObject:nil afterDelay:0.25];
    
} // end windowDidLoad


// save settings before closing
-(void) windowWillClose:(NSNotification *) notification
{
    [settings archive];
} // end windowWillClose


-(IBAction) addClockConfig:(id)sender
{
	NSUInteger index = [[clockConfigController arrangedObjects] count];

	[clockConfigController insertObject:
        [NSDictionary dictionaryWithObjectsAndKeys:titleField.stringValue, @"Name"
        , [timezones objectForKey:[timezoneButton titleOfSelectedItem]], @"Timezone"
         , (([secondsCheckbox state] == NSControlStateValueOn) ? @"YES" : @"NO"), @"Seconds", nil]
        atArrangedObjectIndex:index];
    MZClockConfigItem* item = (MZClockConfigItem*)[clockConfigView itemAtIndex:index];
    
    [item.titleConfigLabel setStringValue:titleField.stringValue];
    [item.timezoneConfigLabel setStringValue:[timezones objectForKey:[timezoneButton titleOfSelectedItem]]];
    item.useSecond = ([secondsCheckbox state] == NSControlStateValueOn);
    
    // added so now turn off seconds by default
    [secondsCheckbox setState:NSControlStateValueOff];
    
    [self updateSettings:nil];
} // end addClockConfig


-(void) addClockConfig:(NSString*) title timezone:(NSString*) tz useSeconds:(BOOL) secs
{
    // must have values
	if (title != nil && tz != nil)
    {
        NSUInteger index = [[clockConfigController arrangedObjects] count];
    
        [clockConfigController insertObject:
            [NSDictionary dictionaryWithObjectsAndKeys: title, @"Name"
            , tz, @"Timezone"
            , (secs == YES ? @"YES" : @"NO"), @"Seconds"
            , nil]
            atArrangedObjectIndex:index];
        MZClockConfigItem* item = (MZClockConfigItem*)[clockConfigView itemAtIndex:index];

        [item.titleConfigLabel setStringValue:title];
        [item.timezoneConfigLabel setStringValue:tz];
        item.useSecond = secs;
    }
    
} // end addClockConfig


-(IBAction) removeClockConfig:(id)sender
{
    // looks for the button(sender) that asked to be deleted
    for( long i = 0; i < [[clockConfigController arrangedObjects] count]; i++ )
    {
        MZClockConfigItem *item = (MZClockConfigItem*)[clockConfigView itemAtIndex:i];
        
        // does button id match item button id?
        if(sender == [item deleteButton])
        {
            [clockConfigController removeObjectAtArrangedObjectIndex:i];
            [self updateSettings:nil];
            
            //NSLog(@"Delete");
            break;
        }
    }
    
} // end removeClockConfig

-(IBAction) moveUpClockConfig:(id)sender
{
    long clockCount = [[clockConfigController arrangedObjects] count];
    // looks for the button(sender) that asked to be moved up
    for( long i = 0; i < clockCount; i++ )
    {
        MZClockConfigItem *item = (MZClockConfigItem*)[clockConfigView itemAtIndex:i];
        
        // does button id match item button id?
        if(sender == [item upButton])
        {
            if (i != 0) // not top do it
            {
                NSString *title = [item.titleConfigLabel stringValue];
                NSString *timezone = [item.timezoneConfigLabel stringValue];
                bool second = item.useSecond;
                
                MZClockConfigItem *item1 = (MZClockConfigItem*)[clockConfigView itemAtIndex:i-1];
                NSString *title1 = [item1.titleConfigLabel stringValue];
                NSString *timezone1 = [item1.timezoneConfigLabel stringValue];
                bool second1 = item1.useSecond;
                
                [item1.titleConfigLabel setStringValue:title];
                [item1.timezoneConfigLabel setStringValue:timezone];
                item1.useSecond = second;
                
                [item.titleConfigLabel setStringValue:title1];
                [item.timezoneConfigLabel setStringValue:timezone1];
                item.useSecond = second1;
                
                [self updateSettings:nil];
                //NSLog(@"Move UP");
            }
            break;
        }
    }
    
} // end moveUpClockConfig

-(IBAction) moveDownClockConfig:(id)sender
{
    long clockCount = [[clockConfigController arrangedObjects] count];
    // looks for the button(sender) that asked to be moved down
    for( long i = 0; i < clockCount; i++ )
    {
        MZClockConfigItem *item = (MZClockConfigItem*)[clockConfigView itemAtIndex:i];
        
        // does button id match item button id?
        if(sender == [item downButton])
        {
            if (i != clockCount-1) // not bottom so do it
            {
                NSString *title = [item.titleConfigLabel stringValue];
                NSString *timezone = [item.timezoneConfigLabel stringValue];
                bool second = item.useSecond;
                
                MZClockConfigItem *item1 = (MZClockConfigItem*)[clockConfigView itemAtIndex:i+1];
                NSString *title1 = [item1.titleConfigLabel stringValue];
                NSString *timezone1 = [item1.timezoneConfigLabel stringValue];
                bool second1 = item1.useSecond;
                
                [item1.titleConfigLabel setStringValue:title];
                [item1.timezoneConfigLabel setStringValue:timezone];
                item1.useSecond = second;
                
                [item.titleConfigLabel setStringValue:title1];
                [item.timezoneConfigLabel setStringValue:timezone1];
                item.useSecond = second1;
                
                [self updateSettings:nil];
                //NSLog(@"Move DOWN");
            }
            break;
        }
    }
    
} // end moveDownClockConfig

-(void) removeAllClockConfig
{
 	NSUInteger index = [[clockConfigController arrangedObjects] count];
    for (long i = index; i>0; i--)
		[clockConfigController removeObjectAtArrangedObjectIndex:i];
} // end removeAllClockConfig


-(void) updateSettingsClockArray
{
    [settings.clockConfigs removeAllObjects];
    int cnt = (int)[[clockConfigController arrangedObjects] count];
    for (int i=0; i<cnt; i++)
    {
        MZClockConfigItem* item = (MZClockConfigItem*)[clockConfigView itemAtIndex:i];
        MZClockConfig* newClock = [[MZClockConfig alloc] init];
        [newClock setTitle:item.titleConfigLabel.stringValue];
        [newClock setTimezoneName:item.timezoneConfigLabel.stringValue];
        [newClock setUseSeconds:item.useSecond];
        [settings.clockConfigs addObject:newClock];
    }
    
} // end updateSettingsClockArry


-(void) updateClockConfigArray
{
    [self removeAllClockConfig];
    int cnt = (int)settings.clockConfigs.count;
    for (int i=0; i<cnt; i++)
    {
        MZClockConfig* item = [settings.clockConfigs objectAtIndex:i];
        [self addClockConfig:item.title timezone:item.timezoneName useSeconds:item.useSeconds];
    }
    [addClockButton setEnabled:TRUE];
} // end updateClockConfigArray
    

// init the shared settings
-(void) initSettings
{
    // update window controls
    [self updateWindowControls];

    // enable options
    [self setEnabledItems];

} // end initSettings


-(void) updateWindowControls
{
    // general settings
    [useAutoLaunchCB setState:settings.useAutoLaunch];
    [useAutoHideCB setState:settings.useAutoHide];
    [useKeepTopCB setState:settings.useKeepTop];
    [useShadowsCB setState:settings.useShadows];
    [useLargeFontsCB setState:settings.useLargeFonts];
    [showDockIconCB setState:settings.showDockIcon];

    [showDateTimeCB setState:settings.showDateTime];
    [useBWIconCB setState:settings.useBWIcon];
    [showWeekNumberIconCB setState:settings.showWeekNumberIcon];
    [useBWWeekIconCB setState:settings.useBWWeekIcon];
    [useInverseTitleCB setState:settings.useInverseTitle];
    [useFuzzyTimeCB setState:settings.useFuzzyTime];

    [showDateCB setState:settings.showDate];
    [showMonthCB setState:settings.showMonth];
    [showStatusFullMonthCB setState:settings.showStatusFullMonth];
    [showStatusWeekDayCB setState:settings.showStatusWeekDay];

    [showTimeCB setState:settings.showTime];
    [showStatusSecondsCB setState:settings.showStatusSeconds];
    [useStatusMilitaryCB setState:settings.useStatusMilitary];
    [showStatusAMPMCB setState:settings.showStatusAMPM];

    [showStatusSecondaryTimeCB setState:settings.showStatusSecondaryTime];
    NSArray* tz = [timezones allKeysForObject:settings.statusSecondaryTimezone];
    if ([tz count] > 0)
    {
        [statusTimezoneButton selectItemWithTitle:[tz objectAtIndex:0]];
    }
    else
    {
        [statusTimezoneButton selectItemAtIndex:0];
    }

    // clock settings
    [useMilitaryCB setState:settings.useMilitary];
    clockFaceIndex = [self getIndexClockFaceArray:settings.clockFaceName];
    [self updateClockPicker];

    // calendar settings
    [showCalendarCB setState:settings.showCalendar];
    [showWeekNumbersCB setState:settings.showWeekNumbers];
    [showEventsCB setState:settings.showEvents];
    [showRemindersCB setState:settings.showReminders];
    [showCalendarBoxesCB setState:settings.showCalendarBoxes];
    [useHiliteColorCB setState:settings.useHiliteColor];
} // end updateWindowControls

// update the shared settings
-(IBAction) updateSettings:(id)sender
{
    // general settings
    settings.useAutoLaunch = ([useAutoLaunchCB state] == NSControlStateValueOn)?YES:NO;
    settings.useAutoHide = ([useAutoHideCB state] == NSControlStateValueOn)?YES:NO;
    settings.useKeepTop = ([useKeepTopCB state] == NSControlStateValueOn)?YES:NO;
    settings.useShadows = ([useShadowsCB state] == NSControlStateValueOn)?YES:NO;
    settings.useLargeFonts = ([useLargeFontsCB state] == NSControlStateValueOn)?YES:NO;
    settings.showDockIcon = ([showDockIconCB state] == NSControlStateValueOn)?YES:NO;

    settings.showDateTime = ([showDateTimeCB state] == NSControlStateValueOn)?YES:NO;
    settings.useBWIcon = ([useBWIconCB state] == NSControlStateValueOn)?YES:NO;
    settings.showWeekNumberIcon = ([showWeekNumberIconCB state] == NSControlStateValueOn)?YES:NO;
    settings.useBWWeekIcon = ([useBWWeekIconCB state] == NSControlStateValueOn)?YES:NO;
    settings.useInverseTitle = ([useInverseTitleCB state] == NSControlStateValueOn)?YES:NO;
    settings.useFuzzyTime = ([useFuzzyTimeCB state] == NSControlStateValueOn)?YES:NO;

    settings.showDate = ([showDateCB state] == NSControlStateValueOn)?YES:NO;
    settings.showMonth = ([showMonthCB state] == NSControlStateValueOn)?YES:NO;
    settings.showStatusFullMonth = ([showStatusFullMonthCB state] == NSControlStateValueOn)?YES:NO;
    settings.showStatusWeekDay = ([showStatusWeekDayCB state] == NSControlStateValueOn)?YES:NO;

    settings.showTime = ([showTimeCB state] == NSControlStateValueOn)?YES:NO;
    settings.showStatusSeconds = ([showStatusSecondsCB state] == NSControlStateValueOn)?YES:NO;
    settings.useStatusMilitary = ([useStatusMilitaryCB state] == NSControlStateValueOn)?YES:NO;
    settings.showStatusAMPM = ([showStatusAMPMCB state] == NSControlStateValueOn)?YES:NO;

    settings.showStatusSecondaryTime = ([showStatusSecondaryTimeCB state] == NSControlStateValueOn)?YES:NO;
    settings.statusSecondaryTimezone = [timezones objectForKey:[statusTimezoneButton titleOfSelectedItem]];


    // clock settings
    settings.useMilitary = ([useMilitaryCB state] == NSControlStateValueOn)?YES:NO;
    settings.clockFaceName = [clockFaceArray objectAtIndex:clockFaceIndex];
    
    // calendar settings
    settings.showCalendar = ([showCalendarCB state] == NSControlStateValueOn)?YES:NO;
    settings.showWeekNumbers = ([showWeekNumbersCB state] == NSControlStateValueOn)?YES:NO;
    settings.showEvents = ([showEventsCB state] == NSControlStateValueOn)?YES:NO;
    settings.showReminders = ([showRemindersCB state] == NSControlStateValueOn)?YES:NO;
    settings.showCalendarBoxes = ([showCalendarBoxesCB state] == NSControlStateValueOn)?YES:NO;
    settings.useHiliteColor = ([useHiliteColorCB state] == NSControlStateValueOn)?YES:NO;

    // enable options
    [self setEnabledItems];

    // update auto launch
    [self toggleLaunchAtLogin:settings.useAutoLaunch];
    
    // update clocks
    [self updateSettingsClockArray];

    // show dock icon
    if (settings.showDockIcon) {
        ProcessSerialNumber psn = { 0, kCurrentProcess };
        TransformProcessType(&psn, kProcessTransformToForegroundApplication);
    } else {
        ProcessSerialNumber psn = { 0, kCurrentProcess };
        TransformProcessType(&psn, kProcessTransformToUIElementApplication);
    }

    settings.needsDisplay = YES;
} // end updateSettings


// enable and disable preference options
-(void) setEnabledItems
{
    // update view
    // disable status date time
    [useBWIconCB setEnabled:!settings.showDateTime && !settings.showWeekNumberIcon];

    [useInverseTitleCB setEnabled:settings.showDateTime];
    [useFuzzyTimeCB setEnabled:settings.showDateTime];

    [showDateCB setEnabled:settings.showDateTime && !settings.useFuzzyTime];
    [showMonthCB setEnabled:settings.showDateTime && settings.showDate && !settings.useFuzzyTime];
    [showStatusFullMonthCB setEnabled:settings.showDateTime && settings.showDate && !settings.useFuzzyTime];
    [showStatusWeekDayCB setEnabled:settings.showDateTime && settings.showDate && !settings.useFuzzyTime];

    [showTimeCB setEnabled:settings.showDateTime && !settings.useFuzzyTime];
    [showStatusSecondsCB setEnabled:settings.showDateTime && settings.showTime && !settings.useFuzzyTime];
    [useStatusMilitaryCB setEnabled:settings.showDateTime && settings.showTime && !settings.useFuzzyTime];
    [showStatusAMPMCB setEnabled:settings.showDateTime && settings.showTime && !settings.useFuzzyTime];

    [showStatusSecondaryTimeCB setEnabled:settings.showDateTime && settings.showTime && !settings.useFuzzyTime];
    [statusTimezoneButton setEnabled:settings.showDateTime && settings.showTime && !settings.useFuzzyTime];

    // always
    [useBWWeekIconCB setEnabled:settings.showWeekNumberIcon];

    // disable status options
    if (settings.showDateTime == YES)
    {
        [useBWIconCB setEnabled:!settings.showDateTime || (!settings.showDate && !settings.showTime && !settings.useFuzzyTime)];
        [showStatusAMPMCB setEnabled:!settings.useStatusMilitary && settings.showTime && !settings.useFuzzyTime];
        [showStatusFullMonthCB setEnabled:settings.showMonth && settings.showDateTime && settings.showDate && !settings.useFuzzyTime];
        [useInverseTitleCB setEnabled:settings.showDate || settings.showTime || settings.useFuzzyTime];
        [statusTimezoneButton setEnabled:settings.showStatusSecondaryTime && !settings.useFuzzyTime];
    }

    // disable keep on top
    [useKeepTopCB setEnabled:!settings.useAutoHide];

    // disable calendar options
    [showWeekNumbersCB setEnabled:settings.showCalendar];
    [showEventsCB setEnabled:settings.showCalendar];
    [showRemindersCB setEnabled:settings.showCalendar];
    [showCalendarBoxesCB setEnabled:settings.showCalendar];
    [useHiliteColorCB setEnabled:settings.showCalendar];
} // end of setEnabledItems


// clock face setting
// get the clock face files files
-(void) getClockFaceNames
{
    NSFileManager* filemgr;
    NSArray* allfiles;
    NSString* directoryString = [[NSBundle mainBundle] resourcePath];

    filemgr = [NSFileManager defaultManager];
    allfiles = [filemgr contentsOfDirectoryAtPath:directoryString error:nil];
    clockFaceArray = [allfiles filteredArrayUsingPredicate:[NSPredicate 
    	predicateWithFormat:@"self BEGINSWITH 'VC' AND self ENDSWITH '.png'"]];
} // end of getClockFaceNames


-(int) getIndexClockFaceArray:(NSString*) name
{
	int i = (int)[clockFaceArray indexOfObject:name];
    return (i>0?i:0);
}  // end of getIndexClockFaceArray


// move to next clock
-(IBAction)moveNextClockFace:(id)sender
{
	if (clockFaceArray != nil)
    {
        if (clockFaceIndex < [clockFaceArray count]-1)
        {
            clockFaceIndex++;
            [self updateClockPicker];
            [self updateSettings:nil];
        }
    }
} // end of moveNextClockFace


// move to previous clock
-(IBAction)movePreviousClockFace:(id)sender
{
    if (clockFaceArray != nil)
    {
        if (clockFaceIndex > 0)
        {
            clockFaceIndex--;
            [self updateClockPicker];
            [self updateSettings:nil];
        }
    }
} // end of movePreviousClockFace


// update the current picker
-(void) updateClockPicker
{
    //[clockPicker useSecondHand:false];
    if (clockFaceArray != nil)
    {
    	// set clock picker
    	[clockPicker useWhiteHands:[[clockFaceArray 
			objectAtIndex:clockFaceIndex] hasPrefix:@"VCW"]];
		[clockPicker setClockFace:[clockFaceArray 
        	objectAtIndex:clockFaceIndex]];
    }
    [clockPicker setTime: [NSDate date]];
} // end of updateClockPicker


// -----------------------------------------------------------------------------
// code to add item to start on launch

// new helper crap
// set helper app to launch at login
-(void) toggleLaunchAtLogin:(NSInteger)mode
{
    NSURL *helperURL = [[[NSBundle mainBundle] bundleURL]
        URLByAppendingPathComponent: @"Contents/Library/LoginItems/VistaClockLoginHelper.app"
        isDirectory: YES
    ];
    OSStatus status = LSRegisterURL((__bridge CFURLRef)helperURL, YES);
    if (status != noErr) {
        NSLog(@"Failed to LSRegisterURL '%@': %jd", helperURL, (intmax_t)status);
    }
    if (@available(macOS 13.0, *)) {
        // Prefer SMAppService on macOS 13+
        NSError *error = nil;
        static NSString * const kLoginItemIdentifier = @"com.Mazookie.VistaClockLoginHelper";

        SMAppService *loginItemService = [SMAppService loginItemServiceWithIdentifier:kLoginItemIdentifier];
        SMAppServiceStatus currentStatus = loginItemService.status;
        if (mode == NSControlStateValueOn) {
            if (currentStatus != SMAppServiceStatusEnabled) {
                if (![loginItemService registerAndReturnError:&error]) {
                    NSLog(@"Failed to enable login item: %@", error);
                }
            }
        } else {
            if (currentStatus == SMAppServiceStatusEnabled) {
                if (![loginItemService unregisterAndReturnError:&error]) {
                    NSLog(@"Failed to disable login item: %@", error);
                }
            }
        }
    } else {
#if !__has_feature(attribute_availability_macOS_app_extension)
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        // Fallback for macOS versions prior to 13.0 using SMLoginItemSetEnabled
        CFStringRef identifier = CFSTR("com.Mazookie.VistaClockLoginHelper");
        if (mode == NSControlStateValueOn) {
            SMLoginItemSetEnabled(identifier, YES);
        } else {
            SMLoginItemSetEnabled(identifier, NO);
        }
    #pragma clang diagnostic pop
#else
        // In app extensions, login item management is unavailable prior to macOS 13
        (void)mode;
#endif
    }
} // end of toggleLaunchAtLogin


// collection view stuff
/*
-(BOOL) collectionView:(NSCollectionView*) collectionView
    writeItemsAtIndexes:(NSIndexSet*) indexes toPasteboard:(NSPasteboard*) pasteboard
{
    NSLog(@"Write Items at indexes : %@", indexes);
    return YES;
}

- (BOOL) collectionView:(NSCollectionView*) collectionView
    canDragItemsAtIndexes:(NSIndexSet*) indexes withEvent:(NSEvent*) event
{
    NSLog(@"Can Drag");
    return YES;
}

-(BOOL) collectionView:(NSCollectionView*) collectionView
    acceptDrop:(id<NSDraggingInfo>)draggingInfo index:(NSInteger) index
    dropOperation:(NSCollectionViewDropOperation) dropOperation
{
    NSLog(@"Accept Drop");
    return YES;
}

-(NSDragOperation) collectionView:(NSCollectionView*) collectionView
    validateDrop:(id<NSDraggingInfo>) draggingInfo
    proposedIndex:(NSInteger*) proposedDropIndex
    dropOperation:(NSCollectionViewDropOperation*) proposedDropOperation
{
    NSLog(@"Validate Drop");
    return NSDragOperationMove;
}
*/
@end





