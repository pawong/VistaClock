//
//  Settings.h
//  VistaClock
//
//  Created by Paul Wong on 9/12/14.
//  Copyright (c) 2014 Mazookie, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MZClockConfig.h"

@interface VCSettings : NSObject

// other settings
@property (nonatomic, assign) BOOL needsDisplay;
@property (nonatomic, assign) BOOL floatRight;
@property (nonatomic, retain) NSMutableArray* clockConfigs;

// general panel settings
@property (nonatomic, assign) BOOL useAutoLaunch;
@property (nonatomic, assign) BOOL useAutoHide;
@property (nonatomic, assign) BOOL useKeepTop;
@property (nonatomic, assign) BOOL showOtherClocks;
@property (nonatomic, assign) BOOL useShadows;
@property (nonatomic, assign) BOOL useDarkTheme;
@property (nonatomic, assign) BOOL useLargeFonts;

// status item settings
@property (nonatomic, assign) BOOL showWeekNumberIcon;
@property (nonatomic, assign) BOOL useBWWeekIcon;
@property (nonatomic, assign) BOOL showStatusSeconds;
@property (nonatomic, assign) BOOL useStatusMilitary;
@property (nonatomic, assign) BOOL showStatusAMPM;
@property (nonatomic, assign) BOOL showStatusWeekDay;
@property (nonatomic, assign) BOOL showStatusDate;
@property (nonatomic, assign) BOOL showStatusFullMonth;
@property (nonatomic, assign) BOOL showStatusSecondaryTime;
@property (nonatomic, assign) NSString* statusSecondaryTimezone;
@property (nonatomic, assign) BOOL showDateTime;
@property (nonatomic, assign) BOOL useBWIcon;

// clock panel settings
@property (nonatomic, assign) BOOL useMilitary;
@property (nonatomic, retain) NSString* clockFaceName;

// calendar settings
@property (nonatomic, assign) BOOL showCalendar;
@property (nonatomic, assign) BOOL showWeekNumbers;
@property (nonatomic, assign) BOOL showEvents;
@property (nonatomic, assign) BOOL showReminders;
@property (nonatomic, assign) BOOL showCalendarBoxes;
@property (nonatomic, assign) BOOL useHiliteColor;


+(VCSettings*) sharedSettings;
-(void) archive;
-(void) reset;

@end
