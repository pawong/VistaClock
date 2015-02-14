//
//  NSDate+Tools.h
//
//  Created by Paul Wong on 1/22/12.
//  Copyright (c) 2012 Mazookie, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (Tools)

+(NSDate*) getDateWithYMD:(int) year month:(int) month day:(int) day;
+(NSDate*) getDateNSDate:(NSDate*) date;

-(NSDate*) set24Hour:(int)hour andMinute:(int)minute andSecond:(int)second;

-(int) getYear;
-(int) getMonth;
-(int) getDay;
-(int) getHours;
-(int) getMinutes;
-(int) getSeconds;
-(int) getDayOfWeek;
-(int) getWeek;

-(NSString*) getMonthString;
-(NSString*) getDayOfWeekString;
-(NSString*) getTimeString;
-(NSString*) getTime24String;
-(NSString*) getAMPMString;
-(NSString*) getMonthYearString;
-(NSString*) getDateTimeString;
-(NSString*) getDateString;
-(NSString*) getWeekString;
-(NSString*) getDayNameShortString;
-(NSString*) getDayString;
-(NSString*) getDayOfYearString;

@end
