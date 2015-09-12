//
//  MZVistaClockAppDelegate.h
//  VistaClock
//
//  Created by Paul Wong on 9/5/14.
//  Copyright (c) 2014 Mazookie, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MZStatusItemView.h"
#import "MZClockItem.h"
#import "MZCalendarControl.h"
#import "MZVistaClockPreferences.h"
#import <ServiceManagement/ServiceManagement.h>
#import <EventKit/EKEventStore.h>
#import "VCSettings.h"

#define DATE_FORMAT_DAY_FULL            @"eeee"
#define DATE_FORMAT_TIMEZONE_DAY        @"z ccc"
#define TIME_FORMAT_NORMAL              @"h:mm a"
#define TIME_FORMAT_NORMAL_FULL         @"h:mm:ss a"
#define TIME_FORMAT_MILITARY            @"HH:mm"
#define TIME_FORMAT_MILITARY_FULL       @"HH:mm:ss"

@interface MZVistaClockAppDelegate : NSObject <NSApplicationDelegate>
{
    // status item controls
    NSStatusItem* statusItem;
    MZStatusItemView* statusItemView;
    IBOutlet NSMenu* statusMenu;
    NSString* statusItemFormat;
    IBOutlet NSTextField* titleTextLabel;
    IBOutlet NSMenuItem* goDateMenuItem;
    
    // clocks
    IBOutlet NSCollectionView *clockCollectionView;
	IBOutlet NSArrayController *clockArrayController;
	NSMutableArray* clockCollectionArray;
    
    // calendar
    IBOutlet MZCalendarControl* calendar;
    IBOutlet NSScrollView* clockScrollView;
    IBOutlet NSDatePicker* altcal;
    IBOutlet NSTextField* gotoDateField;
    IBOutlet NSTextField* doyLabel;
    IBOutlet NSTextField* dayIntervalLabel;
    
    // timer
    NSTimer* timer;
    
    // settings
    VCSettings* settings;
    
    // MISC
    NSInteger lastWeek;
    NSString* lastCal;
    NSDate* lastDate;
    bool darkMenu;
    EKEventStore* store;
}

@property (assign) IBOutlet NSWindow *vistaClockWindow;
@property (strong) NSWindowController* prefsWindow;
@property (assign) IBOutlet NSMenuItem* timeNow;
@property (assign) IBOutlet NSDrawer* dateDrawer;


// methods
-(void) fireTimer: NSTimer;
-(void) updateTime;
-(int) addClock;
-(void) removeClock;
-(void) resizeWindow;
-(CGFloat) titleBarHeight:(NSWindow*) window;
-(CGFloat) toolbarHeight:(NSWindow*) window;
-(NSString*) buildStatusItemDateFormatString;
-(void) createStatusItem;

-(IBAction) openVistaClockWindow:(id)sender;
-(IBAction) launchAboutBoxPanel:(id)sender;
-(IBAction) launchDateTimePreferencePanel:(id)sender;
-(IBAction) openPreferences:(id)sender;
-(IBAction) openDateDrawer:(id)sender;

-(NSDate*) AddToDate:(NSDate*) originalDate unitType:(int) unitType units:(int) units;
-(int) GetDays:(NSString*) inputString;
-(int) GetWeeks:(NSString*) inputString;
-(int) GetMonths:(NSString*) inputString;
-(int) GetYears:(NSString*) inputString;

-(IBAction) gotoDate:(id)sender;
-(IBAction) goToday:(id)sender;


-(void) getCalendarAccess;
-(IBAction)launchCalendar:(id)sender;
-(IBAction)launchReminders:(id)sender;

-(NSString*) getCurrentCalendar;
-(bool) isCalendarChanged;
-(bool) isDarkMenu;

@end

// -----------------------------------------------------------------------------
// for hidden api
@interface NSStatusBar (NSStatusBar_Private)
-(id) _statusItemWithLength:(float)l withPriority:(int)p;
-(id) _insertStatusItem:(NSStatusItem*)i withPriority:(int)p;
@end
