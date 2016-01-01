//
//  Settings.m
//  VistaClock
//
//  Created by Paul Wong on 9/12/14.
//  Copyright (c) 2014 Mazookie, LLC. All rights reserved.
//

#import "VCSettings.h"

#define insist(e) if(!(e)) [NSException raise: @"assertion failed." format: @"%@:%d (%s)", [[NSString stringWithCString:__FILE__ encoding:NSUTF8StringEncoding] lastPathComponent], __LINE__, #e]

static VCSettings* sharedSettings = nil;

@implementation VCSettings

// other shared things
@synthesize needsDisplay, floatRight, clockConfigs;

// general panel options
@synthesize useAutoLaunch, useAutoHide, useKeepTop, showOtherClocks, useShadows
    , useDarkTheme, useLargeFonts;

// status item options
@synthesize showWeekNumberIcon, useBWWeekIcon, showStatusSeconds
    , useStatusMilitary, showStatusAMPM, showStatusWeekDay, showStatusDate
    , showStatusFullMonth, showStatusSecondaryTime, statusSecondaryTimezone
    , showDateTime, useBWIcon;

// clock panel options
@synthesize useMilitary, clockFaceName;

// calendar options
@synthesize showCalendar, showWeekNumbers, showEvents, showReminders
    , showCalendarBoxes;


-(void) archive
{
    [NSKeyedArchiver archiveRootObject:self toFile:[VCSettings archivePath]];
} // end archive


+(NSString*) archivePath
{
    NSArray*paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory
        , NSUserDomainMask, YES);
    insist(paths && [paths count]);
    NSString* programName = [NSString stringWithFormat:@"%@.cfg",
        [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey]
        ];
    return [[paths objectAtIndex:0] stringByAppendingPathComponent:programName];
} // end archivePath


-(void) initTransient
{
    // set up new arrays
} // end initTransient


+(VCSettings*) sharedSettings
{
    if (sharedSettings == nil)
    {
        // get saved
        NSFileManager*fileManager = [NSFileManager defaultManager];
        insist(fileManager);
        
        if ([fileManager fileExistsAtPath:[VCSettings archivePath]])
        {
            sharedSettings = [NSKeyedUnarchiver unarchiveObjectWithFile:
                [VCSettings archivePath]];
            [sharedSettings initTransient];
            return sharedSettings;
        }
        
        // alloc new one and init it
        sharedSettings = [[super allocWithZone:NULL] init];
    }
    
    return sharedSettings;
} // end sharedSettings


-(id)initWithCoder:(NSCoder*) decoder
{
    insist(decoder);
    self = [super init];
    insist(self);
    
    // decode
    // others
    floatRight = [decoder decodeBoolForKey:@"floatRight"];
    
    // clock configs array
    clockConfigs = [[decoder decodeObjectForKey:@"clockConfigs"] mutableCopy];
    
    // clock panel options
    useAutoLaunch = [decoder decodeBoolForKey:@"useAutoLaunch"];
    useAutoHide = [decoder decodeBoolForKey:@"useAutoHide"];
    useKeepTop = [decoder decodeBoolForKey:@"useKeepTop"];

    showOtherClocks = [decoder decodeBoolForKey:@"showOtherClocks"];
    useShadows = [decoder decodeBoolForKey:@"useShadows"];
    useDarkTheme = [decoder decodeBoolForKey:@"useDarkTheme"];
    useLargeFonts = [decoder decodeBoolForKey:@"useLargeFonts"];
    
    // status item options
    showWeekNumberIcon = [decoder decodeBoolForKey:@"showWeekNumberIcon"];
    useBWWeekIcon = [decoder decodeBoolForKey:@"useBWWeekIcon"];
    showStatusSeconds = [decoder decodeBoolForKey:@"showStatusSeconds"];
    useStatusMilitary = [decoder decodeBoolForKey:@"useStatusMilitary"];
    showStatusAMPM = [decoder decodeBoolForKey:@"showStatusAMPM"];
    showStatusWeekDay = [decoder decodeBoolForKey:@"showStatusWeekDay"];
    showStatusDate = [decoder decodeBoolForKey:@"showStatusDate"];
    showStatusFullMonth = [decoder decodeBoolForKey:@"showStatusFullMonth"];
    showStatusSecondaryTime = [decoder decodeBoolForKey:@"showStatusSecondaryTime"];
    statusSecondaryTimezone = [decoder decodeObjectForKey:@"statusSecondaryTimezone"];
    showDateTime = [decoder decodeBoolForKey:@"showDateTime"];
    useBWIcon = [decoder decodeBoolForKey:@"useBWIcon"];
    
    // clock panel options
    useMilitary = [decoder decodeBoolForKey:@"useMilitary"];
    clockFaceName = [decoder decodeObjectForKey:@"clockFace"];
    
    // calendar options
    showCalendar = [decoder decodeBoolForKey:@"showCalendar"];
    showWeekNumbers = [decoder decodeBoolForKey:@"showWeekNumbers"];
    showEvents = [decoder decodeBoolForKey:@"showEvents"];
    showReminders = [decoder decodeBoolForKey:@"showReminders"];
    showCalendarBoxes = [decoder decodeBoolForKey:@"showCalendarBoxes"];
    
    needsDisplay = YES;

    return self;
} // end initWithCoder


-(void) encodeWithCoder:(NSCoder*) encoder
{
    insist(encoder);
    
    // encode
    // others
    [encoder encodeBool:floatRight forKey:@"floatRight"];
    
    // clock configs array
    [encoder encodeObject:clockConfigs forKey:@"clockConfigs"];
    
    // general panel options
    [encoder encodeBool:useAutoLaunch forKey:@"useAutoLaunch"];
    [encoder encodeBool:useAutoHide forKey:@"useAutoHide"];
    [encoder encodeBool:useKeepTop forKey:@"useKeepTop"];

    [encoder encodeBool:showOtherClocks forKey:@"showOtherClocks"];
    [encoder encodeBool:useShadows forKey:@"useShadows"];
    [encoder encodeBool:useDarkTheme forKey:@"useDarkTheme"];
    [encoder encodeBool:useLargeFonts forKey:@"useLargeFonts"];

    
    // status item options
    [encoder encodeBool:showWeekNumberIcon forKey:@"showWeekNumberIcon"];
    [encoder encodeBool:useBWWeekIcon forKey:@"useBWWeekIcon"];
    [encoder encodeBool:showStatusSeconds forKey:@"showStatusSeconds"];
    [encoder encodeBool:useStatusMilitary forKey:@"useStatusMilitary"];
    [encoder encodeBool:showStatusAMPM forKey:@"showStatusAMPM"];
    [encoder encodeBool:showStatusWeekDay forKey:@"showStatusWeekDay"];
    [encoder encodeBool:showStatusDate forKey:@"showStatusDate"];
    [encoder encodeBool:showStatusFullMonth forKey:@"showStatusFullMonth"];
    [encoder encodeBool:showStatusSecondaryTime forKey:@"showStatusSecondaryTime"];
    [encoder encodeObject:statusSecondaryTimezone forKey:@"statusSecondaryTimezone"];
    [encoder encodeBool:showDateTime forKey:@"showDateTime"];
    [encoder encodeBool:useBWIcon forKey:@"useBWIcon"];
    
    // clock options
    [encoder encodeBool:useMilitary forKey:@"useMilitary"];
    [encoder encodeObject:clockFaceName forKey:@"clockFace"];

    // calendar options
    [encoder encodeBool:showCalendar forKey:@"showCalendar"];
    [encoder encodeBool:showWeekNumbers forKey:@"showWeekNumbers"];
    [encoder encodeBool:showEvents forKey:@"showEvents"];
    [encoder encodeBool:showReminders forKey:@"showReminders"];
    [encoder encodeBool:showCalendarBoxes forKey:@"showCalendarBoxes"];

} // end encodeWithCoder


-(void) reset
{
    // other shared things
    needsDisplay = YES;
    floatRight = NO;
    
    // clock panel options
    useAutoLaunch = NO;
    useAutoHide = YES;
    useKeepTop = NO;
    showOtherClocks = YES;
    useShadows = YES;
    useDarkTheme = NO;
    useLargeFonts = NO;

    // status item options
    showWeekNumberIcon = YES;
    useBWWeekIcon = NO;
    showStatusSeconds = NO;
    useStatusMilitary = NO;
    showStatusAMPM = YES;
    showStatusWeekDay = NO;
    showStatusDate = NO;
    showStatusFullMonth = NO;
    showStatusSecondaryTime = NO;
    statusSecondaryTimezone = @"GMT";
    showDateTime = YES;
    useBWIcon = NO;
    
    // clock options
    useMilitary = NO;
    clockFaceName = @"VCB01.png";
    
    // calendar options
    showCalendar = YES;
    showWeekNumbers = NO;
    showEvents = NO;
    showReminders = NO;
    showCalendarBoxes = NO;
    
    // clock configs
    MZClockConfig* config = [[MZClockConfig alloc] init];
    config.title = @"Portland, OR";
    config.timezoneName = @"America/Los_Angeles";
    config.useSeconds = YES;
    if (clockConfigs == nil)
    {
        clockConfigs = [[NSMutableArray alloc] initWithObjects:config, nil];
    }
    else
    {
        [clockConfigs removeAllObjects];
        [clockConfigs addObject:config];
    }
    
    needsDisplay = TRUE;
} // end reset


// call this only when no archived file exist
- (id) init
{
    self = [super init];
    insist(self);
    
    // build stuff that doesn't get archived
    [self initTransient];
    
    [self reset];

    return self;
} // end init


- (id) copyWithZone:(NSZone*)zone
{
    needsDisplay = TRUE;
    return self;
} // end copyWithZone


@end
