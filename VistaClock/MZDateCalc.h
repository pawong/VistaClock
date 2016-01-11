//
//  MZDateCalc.h
//  VistaClock
//
//  Created by Paul Wong on 1/10/16.
//  Copyright © 2016 Mazookie, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MZCalendarControl.h"

@interface MZDateCalc : NSObject

@property (nonatomic, assign) MZCalendarControl* calendar;

-(NSDate*) AddToDate:(NSDate*) originalDate unitType:(int) unitType units:(int) units;
-(int) GetDays:(NSString*) inputString;
-(int) GetWeeks:(NSString*) inputString;
-(int) GetMonths:(NSString*) inputString;
-(int) GetYears:(NSString*) inputString;
-(int) GetWeekNumber:(NSString*) inputString;
-(int) GetDayNumber:(NSString*) inputString;
-(int) GetB5Days:(NSString*) inputString;
-(int) GetB6Days:(NSString*) inputString;

-(BOOL) parseDate:(NSString*) string;
-(void) moveDate:(NSString*) string useToday:(BOOL) today;


@end
