//
//  NSDate+Tools.m
//
//  Created by Paul Wong on 1/22/12.
//  Copyright (c) 2012 Mazookie, LLC. All rights reserved.
//

#import "NSDate+Tools.h"

@implementation NSDate (Tools)

+(NSDate*) getDateWithYMD:(int) year month:(int) month day:(int) day
{
    NSString* dateString = [NSString stringWithFormat:@"%d-%d-%d 12:00:00 +000", year, month, day];
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss ZZZ";

    return [dateFormatter dateFromString:dateString];
}

+(NSDate*) getDateNSDate:(NSDate*) date
{
    NSString* dateString = [NSString stringWithFormat:@"%d-%d-%d 12:00:00 +000", [date getYear], [date getMonth]
        , [date getDay]];
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss ZZZ";

    return [dateFormatter dateFromString:dateString];
}

-(NSDate*) set24Hour:(int)hour andMinute:(int)minute andSecond:(int)second;
{
    NSString* dateString = [NSString stringWithFormat:@"%d-%d-%d %d:%d:%d +000", [self getYear], [self getMonth]
        , [self getDay], hour, minute, second];
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss ZZZ";

    return [dateFormatter dateFromString:dateString];
}


-(int) getYear
{
    int retval = 1;
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"yyyy"];
    retval = [[format stringFromDate:(NSDate*)self] intValue];
    return retval;
}

-(int) getMonth
{
    int retval = 1;
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"M"];
    retval = [[format stringFromDate:(NSDate*)self] intValue];
    return retval;
}

-(NSString*) getMonthString
{
    NSString* retval;
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"MMMM"];
    retval = [format stringFromDate:(NSDate*)self];
    return retval;    
}

-(int) getDay
{
    int retval = 1;
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"d"];
    retval = [[format stringFromDate:(NSDate*)self] intValue];
    return retval;
}

-(NSString*) getDayOfWeekString
{
    NSString* retval;
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"EEEE"];
    retval = [format stringFromDate:(NSDate*)self];
    return retval;    
}

-(NSString*) getTimeString
{
    NSString* retval;
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"h:mm:ss a"];
    retval = [format stringFromDate:(NSDate*)self];
    return retval;     
}

-(NSString*) getTime24String
{
    NSString* retval;
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"HH:mm:ss"];
    retval = [format stringFromDate:(NSDate*)self];
    return retval;     
}

-(NSString*) getAMPMString
{
    NSString* retval;
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"a"];
    retval = [format stringFromDate:(NSDate*)self];
    return retval;     
}

-(NSString*) getMonthYearString
{
    NSString* retval;
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"MMMM yyyy"];
    retval = [format stringFromDate:(NSDate*)self];
    return retval;     
}

-(NSString*) getDateTimeString
{
    NSString* retval;
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"EEEE MMMM d, yyyy h:mm:ss a"];
    retval = [format stringFromDate:(NSDate*)self];
    return retval;     
}

-(NSString*) getDateString
{
    NSString* retval;
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"EEEE  MMMM d, yyyy"];
    retval = [format stringFromDate:(NSDate*)self];
    return retval;     
}

-(NSString*) getWeekString
{
    NSString* retval;
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"w"];
    retval = [format stringFromDate:(NSDate*)self];
    return retval;  
}

-(NSString*) getDayNameShortString
{
    NSString* retval;
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
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
    [format setDateFormat:@"d"];
    retval = [format stringFromDate:(NSDate*)self];
    return retval; 
}

-(NSString*) getDayOfYearString
{
    NSString* retval;
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"D"];
    retval = [format stringFromDate:(NSDate*)self];
    return retval; 
}

-(int) getHours
{
    int retval;
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"h"];
    retval = [[format stringFromDate:(NSDate*)self] intValue];
    return retval;     
}

-(int) getMinutes
{
    int retval;
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"m"];
    retval = [[format stringFromDate:(NSDate*)self] intValue];
    return retval;     
}

-(int) getSeconds
{
    int retval;
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"s"];
    retval = [[format stringFromDate:(NSDate*)self] intValue];
    return retval;     
}

-(int) getDayOfWeek
{
    int retval;
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"e"];
    retval = [[format stringFromDate:(NSDate*)self] intValue];
    return retval;     
}

-(int) getWeek
{
    int retval;
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"w"];
    retval = [[format stringFromDate:(NSDate*)self] intValue];
    return retval;     
}


@end
