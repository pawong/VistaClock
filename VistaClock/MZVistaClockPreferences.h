//
//  MZVistaClockPreferences.h
//  VistaClock
//
//  Created by Paul Wong on 9/12/14.
//  Copyright (c) 2014 Mazookie, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MZClockConfigItem.h"
#import "VCSettings.h"
#import "MZClockControl.h"
#import "MZClockConfig.h"
#import <ServiceManagement/ServiceManagement.h>

@interface MZVistaClockPreferences : NSWindowController
{
    // config window
    NSArray* clockConfigArray;
    IBOutlet NSArrayController* clockConfigController;
    IBOutlet NSCollectionView* clockConfigView;
    
    IBOutlet NSTextField* titleField;
    IBOutlet NSPopUpButton* timezoneButton;
    IBOutlet NSButton* secondsCheckbox;

    // general settings
    IBOutlet NSButton* useAutoLaunchCB;
    IBOutlet NSButton* useAutoHideCB;
    IBOutlet NSButton* useKeepTopCB;
    IBOutlet NSButton* useShadowsCB;
    IBOutlet NSButton* useDarkThemeCB;
    IBOutlet NSButton* useLargeFontsCB;

    // menu bar
    IBOutlet NSButton* showDateTimeCB;
    IBOutlet NSButton* useBWIconCB;
    IBOutlet NSButton* showWeekNumberIconCB;
    IBOutlet NSButton* useBWWeekIconCB;
    IBOutlet NSButton* useInverseTitleCB;

    IBOutlet NSButton* showDateCB;
    IBOutlet NSButton* showMonthCB;
    IBOutlet NSButton* showStatusFullMonthCB;
    IBOutlet NSButton* showStatusWeekDayCB;

    IBOutlet NSButton* showTimeCB;
    IBOutlet NSButton* showStatusSecondsCB;
    IBOutlet NSButton* useStatusMilitaryCB;
    IBOutlet NSButton* showStatusAMPMCB;
    IBOutlet NSButton* showStatusSecondaryTimeCB;
    IBOutlet NSPopUpButton* statusTimezoneButton;

    // clock settings
    IBOutlet NSButton* useMilitaryCB;
    IBOutlet NSButton* addClockButton;
    
    // calendar settings
    IBOutlet NSButton* showCalendarCB;
    IBOutlet NSButton* showWeekNumbersCB;
    IBOutlet NSButton* showEventsCB;
    IBOutlet NSButton* showRemindersCB;
    IBOutlet NSButton* showCalendarBoxesCB;
    IBOutlet NSButton* useHiliteColorCB;
    
    // settings
    VCSettings* settings;
    
    // clock faces
    NSArray* clockFaceArray;
    int clockFaceIndex;
    IBOutlet MZClockControl* clockPicker;
    NSMutableDictionary* timezones;
}

-(IBAction) addClockConfig:(id)sender;
-(IBAction) moveUpClockConfig:(id)sender;
-(IBAction) moveDownClockConfig:(id)sender;
-(IBAction) removeClockConfig:(id)sender;
-(void) removeAllClockConfig;
-(void) addClockConfig:(NSString*) title timezone:(NSString*) tz useSeconds:(BOOL) secs;
-(void) updateSettingsClockArray;
-(void) updateClockConfigArray;

-(IBAction) updateSettings:(id)sender;
-(void) setEnabledItems;


@end
