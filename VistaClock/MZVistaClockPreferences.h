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
    
    // for later use
    IBOutlet NSButton* showMasterClockCB;
    IBOutlet NSButton* showOtherClocksCB;

    // menu bar
    IBOutlet NSButton* showWeekNumberIconCB;
    IBOutlet NSButton* useBWWeekIconCB;
    IBOutlet NSButton* showStatusSecondsCB;
    IBOutlet NSButton* useStatusMilitaryCB;
    IBOutlet NSButton* showStatusAMPMCB;
    IBOutlet NSButton* showStatusWeekDayCB;
    IBOutlet NSButton* showStatusDateCB;
    IBOutlet NSButton* showStatusFullMonthCB;
    IBOutlet NSButton* showStatusSecondaryTimeCB;
    IBOutlet NSPopUpButton* statusTimezoneButton;
    IBOutlet NSButton* showDateTimeCB;
    IBOutlet NSButton* useBWIconCB;

    
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

-(IBAction) openMazookie:(id)sender;


@end
