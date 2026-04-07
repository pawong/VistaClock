#if !defined(__aarch64__)
#error "This application is supported only on Apple Silicon (arm64)."
#endif

#if defined(__aarch64__)
//
/* 
  NSDate+Tools.m
  Created by Paul Wong on 1/22/12.
  Copyright (c) 2026 Mazookie, LLC. All rights reserved.
*/

#import "NSDate+Tools.h"

@implementation NSDate (Tools)

+(NSDate*) getDateWithYMD:(int) year month:(int) month day:(int) day
{
    NSString* dateString = [NSString stringWithFormat:@"%d-%d-%d 12:00:00 +000", year, month, day];
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:[[NSLocale preferredLanguages] firstObject]];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss ZZZ";

    return [dateFormatter dateFromString:dateString];
}

+(NSDate*) getDateNSDate:(NSDate*) date
{
    NSString* dateString = [NSString stringWithFormat:@"%d-%d-%d 12:00:00 +000", [date getYear], [date getMonth]
        , [date getDay]];
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:[[NSLocale preferredLanguages] firstObject]];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss ZZZ";

    return [dateFormatter dateFromString:dateString];
}

-(NSDate*) set24Hour:(int)hour andMinute:(int)minute andSecond:(int)second;
{
    NSString* dateString = [NSString stringWithFormat:@"%d-%d-%d %d:%d:%d +000", [self getYear], [self getMonth]
        , [self getDay], hour, minute, second];
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:[[NSLocale preferredLanguages] firstObject]];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss ZZZ";

    return [dateFormatter dateFromString:dateString];
}


-(int) getYear
{
    int retval = 1;
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    format.locale = [[NSLocale alloc] initWithLocaleIdentifier:[[NSLocale preferredLanguages] firstObject]];
    [format setDateFormat:@"yyyy"];
    retval = [[format stringFromDate:(NSDate*)self] intValue];
    return retval;
}

-(int) getMonth
{
    int retval = 1;
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    format.locale = [[NSLocale alloc] initWithLocaleIdentifier:[[NSLocale preferredLanguages] firstObject]];
    [format setDateFormat:@"M"];
    retval = [[format stringFromDate:(NSDate*)self] intValue];
    return retval;
}

-(NSString*) getMonthString
{
    NSString* retval;
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    format.locale = [[NSLocale alloc] initWithLocaleIdentifier:[[NSLocale preferredLanguages] firstObject]];
    [format setDateFormat:@"MMMM"];
    retval = [format stringFromDate:(NSDate*)self];
    return retval;    
}

-(int) getDay
{
    int retval = 1;
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    format.locale = [[NSLocale alloc] initWithLocaleIdentifier:[[NSLocale preferredLanguages] firstObject]];
    [format setDateFormat:@"d"];
    retval = [[format stringFromDate:(NSDate*)self] intValue];
    return retval;
}

-(NSString*) getDayOfWeekString
{
    NSString* retval;
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    format.locale = [[NSLocale alloc] initWithLocaleIdentifier:[[NSLocale preferredLanguages] firstObject]];
    [format setDateFormat:@"EEEE"];
    retval = [format stringFromDate:(NSDate*)self];
    return retval;    
}

-(NSString*) getTimeString
{
    NSString* retval;
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    format.locale = [[NSLocale alloc] initWithLocaleIdentifier:[[NSLocale preferredLanguages] firstObject]];
    [format setDateFormat:@"h:mm:ss a"];
    retval = [format stringFromDate:(NSDate*)self];
    return retval;     
}

-(NSString*) getTime24String
{
    NSString* retval;
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    format.locale = [[NSLocale alloc] initWithLocaleIdentifier:[[NSLocale preferredLanguages] firstObject]];
    [format setDateFormat:@"HH:mm:ss"];
    retval = [format stringFromDate:(NSDate*)self];
    return retval;     
}

-(NSString*) getAMPMString
{
    NSString* retval;
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    format.locale = [[NSLocale alloc] initWithLocaleIdentifier:[[NSLocale preferredLanguages] firstObject]];
    [format setDateFormat:@"a"];
    retval = [format stringFromDate:(NSDate*)self];
    return retval;     
}

-(NSString*) getMonthYearString
{
    NSString* retval;
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    format.locale = [[NSLocale alloc] initWithLocaleIdentifier:[[NSLocale preferredLanguages] firstObject]];
    [format setDateFormat:@"MMMM yyyy"];
    retval = [format stringFromDate:(NSDate*)self];
    return retval;     
}

-(NSString*) getDateTimeString
{
    NSString* retval;
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    format.locale = [[NSLocale alloc] initWithLocaleIdentifier:[[NSLocale preferredLanguages] firstObject]];
    [format setDateFormat:@"EEEE MMMM d, yyyy h:mm:ss a"];
    retval = [format stringFromDate:(NSDate*)self];
    return retval;     
}

-(NSString*) getDateString
{
    NSString* retval;
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    format.locale = [[NSLocale alloc] initWithLocaleIdentifier:[[NSLocale preferredLanguages] firstObject]];
    [format setDateFormat:@"EEEE  MMMM d, yyyy"];
    retval = [format stringFromDate:(NSDate*)self];
    return retval;     
}

-(NSString*) getWeekNumberString
{
    NSString* retval;
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    format.locale = [[NSLocale alloc] initWithLocaleIdentifier:[[NSLocale preferredLanguages] firstObject]];
    [format setDateFormat:@"w"];
    retval = [format stringFromDate:(NSDate*)self];
    return retval;  
}

-(NSString*) getIsoWeekNumberString
{
    NSString* retval;
    retval = [NSString stringWithFormat:@"%d", [self getIsoWeekNumber]];
    return retval;
}

-(NSString*) getDayNameShortString
{
    NSString* retval;
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    format.locale = [[NSLocale alloc] initWithLocaleIdentifier:[[NSLocale preferredLanguages] firstObject]];
    [format setDateFormat:@"EEEEE"];
    retval = [format stringFromDate:(NSDate*)self];
    //retval = [[format stringFromDate:(NSDate*)self] substringWithRange:
    //	NSMakeRange(0,2)];
    return retval; 
}

-(NSString*) getDayString
{
    NSString* retval;
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    format.locale = [[NSLocale alloc] initWithLocaleIdentifier:[[NSLocale preferredLanguages] firstObject]];
    [format setDateFormat:@"d"];
    retval = [format stringFromDate:(NSDate*)self];
    return retval; 
}

-(NSString*) getDayOfYearString
{
    NSString* retval;
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    format.locale = [[NSLocale alloc] initWithLocaleIdentifier:[[NSLocale preferredLanguages] firstObject]];
    [format setDateFormat:@"D"];
    retval = [format stringFromDate:(NSDate*)self];
    return retval; 
}

-(int) getHours
{
    int retval;
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    format.locale = [[NSLocale alloc] initWithLocaleIdentifier:[[NSLocale preferredLanguages] firstObject]];
    [format setDateFormat:@"h"];
    retval = [[format stringFromDate:(NSDate*)self] intValue];
    return retval;     
}

-(int) getMinutes
{
    int retval;
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    format.locale = [[NSLocale alloc] initWithLocaleIdentifier:[[NSLocale preferredLanguages] firstObject]];
    [format setDateFormat:@"m"];
    retval = [[format stringFromDate:(NSDate*)self] intValue];
    return retval;     
}

-(int) getSeconds
{
    int retval;
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    format.locale = [[NSLocale alloc] initWithLocaleIdentifier:[[NSLocale preferredLanguages] firstObject]];
    [format setDateFormat:@"s"];
    retval = [[format stringFromDate:(NSDate*)self] intValue];
    return retval;     
}

-(int) getDayOfWeek
{
    int retval;
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    format.locale = [[NSLocale alloc] initWithLocaleIdentifier:[[NSLocale preferredLanguages] firstObject]];
    [format setDateFormat:@"e"];
    retval = [[format stringFromDate:(NSDate*)self] intValue];
    return retval;
}

-(int) getUSDayOfWeek
{
    int retval;
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    format.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    [format setDateFormat:@"e"];
    retval = [[format stringFromDate:(NSDate*)self] intValue];
    return retval;
}

-(int) getWeekNumber
{
    int retval;
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    format.locale = [[NSLocale alloc] initWithLocaleIdentifier:[[NSLocale preferredLanguages] firstObject]];
    [format setDateFormat:@"w"];
    retval = [[format stringFromDate:(NSDate*)self] intValue];
    return retval;     
}

-(int) getIsoWeekNumber
{
    int retval;
    NSCalendar *iso8601Calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierISO8601];
    retval = (int)[iso8601Calendar component: NSCalendarUnitWeekOfYear fromDate: (NSDate*)self];
    return retval;
}
@end
#endif // defined(__aarch64__)

