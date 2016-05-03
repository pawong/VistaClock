#import <AppKit/AppKit.h>
#import "NSDate+Tools.h"
#import <CalendarStore/CalendarStore.h>
#import <EventKit/EKEventStore.h>

//static int numberOfDayInMonthForYear(int aMonth,int aYear);

@interface MZCalendarControl : NSControl
{
    NSDate* selectedDate;
    
    BOOL newdate;
    id target;
    SEL action;
    int firstDay;
    int lastDay;
    NSDate* monthView[42];
    int firstWeekday;
    NSColor* dateColor;
    NSColor* shadowColor;
    NSShadow* shadow;
    int fontSize;
    NSColor* hiliteColor;

    int dayWidth;    
    int dayHeight;
    int nColumns;
    int cwOffset;
    
    // message images
    NSImage* eventImage;
    NSImage* reminderImage;
    NSImage* altEventImage;
    
    // user controled, off by default
    bool showWeekNumbers;
    bool showEventIndicators;
    bool showReminderIndicators;
    bool showBoxes;

    NSDictionary* titleAttributes;
    NSDictionary* normalAttributes;
    NSDictionary* daysNotThisMonth;
    NSDictionary* dayOfWeekAttributes;
    NSDictionary* currentDayAttributes;
    NSDictionary* currentMonthAttributes;
    NSDictionary* selectedDayAttributes;
    NSDictionary* weekAttributes;
    
    // calendar store
    EKEventStore* store;
}

-(void) setDate:(NSDate*) aDate;
-(NSDate*) getDate;
-(void) setShowWeekNumbers:(bool) value;
-(void) setShowEventIndicators:(bool) value;
-(void) setShowReminderIndicators:(bool) value;
-(void) setShowBoxes:(bool) value;
-(void) setFontSize:(int) value;
-(void) setHiliteColor:(NSColor*) value;

-(int) dayAtPoint:(NSPoint) aPoint;
-(NSDate*) dateAtPoint:(NSPoint) aPoint;
-(int) drawDay:(int) aDay;
-(int) controlAtPoint:(NSPoint) aPoint;

-(void) setColor:(NSColor*) color;
-(void) setShadowColor:(NSColor*) color;
-(void) setStyle;

-(void) nextMonth;
-(void) lastMonth;

//-(void) setAction:(SEL) aAction;
-(void) setTarget:(id) aTarget;

-(bool) HasEvents:(NSDate*) date;
-(bool) HasReminders:(NSDate*) date;

// Handler methods for Calendar Store notifications
- (void) calendarsChanged:(NSNotification *)notification;
- (void) eventsChanged:(NSNotification *)notification;
- (void) tasksChanged:(NSNotification *)notification;

@end
