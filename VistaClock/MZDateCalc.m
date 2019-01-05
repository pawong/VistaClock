//
//  MZDateCalc.m
//  VistaClock
//
//  Created by Paul Wong on 1/10/16.
//  Copyright © 2016 Mazookie, LLC. All rights reserved.
//

#import "MZDateCalc.h"
#include <math.h>


@implementation MZDateCalc


-(BOOL) isWeekend:(NSDate*) date isFull:(BOOL) full
{
    NSInteger day = [[[NSCalendar currentCalendar] components:NSCalendarUnitWeekday fromDate:date] weekday];

    const int kSunday = 1;
    const int kSaturday = 7;
    BOOL isWeekdayResult = FALSE;

    if (full)
    {
        isWeekdayResult = day != kSunday && day != kSaturday;
    }
    else
    {
        isWeekdayResult = day != kSunday;
    }

    return isWeekdayResult;
} // end of isWeekend


-(NSDate*) addBusinessDaysToDate:(NSDate*) startDate addDays:(int) daysToAdvance isFull:(BOOL) full
{
    NSDate* endDate = startDate;
    int start = 0;
    int units = 1;

    if (daysToAdvance < 0)
    {
        daysToAdvance = abs(daysToAdvance);
        units = -1;
    }


    while (start < daysToAdvance)
    {
        endDate = [self AddToDate: endDate unitType:0 units:units];

        if ([self isWeekend:endDate isFull: full])
        {
            start++;
        }
    }
    
    return endDate;
} // end of addBusinessDaysToDate


-(NSDate*) AddToDate:(NSDate*) originalDate unitType:(int) unitType units:(int) units
{
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    NSCalendar *currentCalendar = [NSCalendar currentCalendar];
    switch (unitType)
    {
        case 1: [dateComponents setDay: units*7]; 	// week
            break;
        case 2: [dateComponents setMonth: units]; 	// month
            break;
        case 3: [dateComponents setYear: units];	// year
            break;
        case 0:
        default: [dateComponents setDay: units];	// day
            break;
    }

    return([currentCalendar dateByAddingComponents:dateComponents toDate:originalDate options:0]);
} // end of AddToDate


-(int) GetDays:(NSString*) inputString
{
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(-?\\d+)(d|D)"
        options:NSRegularExpressionCaseInsensitive	error:NULL];
    NSUInteger numberOfMatches = [regex numberOfMatchesInString:inputString options:0 range:NSMakeRange(0, [inputString length])];
    if (numberOfMatches)
    {
        NSTextCheckingResult *textCheckingResult = [regex firstMatchInString:inputString options:0 range:NSMakeRange(0, [inputString length])];
        NSRange matchRange = [textCheckingResult rangeAtIndex:1];
        NSString *match = [inputString substringWithRange:matchRange];
        return [match intValue];
    }
    return 0;
} // end of GetDays


-(int) GetWeeks:(NSString*) inputString
{
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(-?\\d+)(w|W)"
        options:NSRegularExpressionCaseInsensitive	error:NULL];
    NSUInteger numberOfMatches = [regex numberOfMatchesInString:inputString options:0 range:NSMakeRange(0, [inputString length])];
    if (numberOfMatches)
    {
        NSTextCheckingResult *textCheckingResult = [regex firstMatchInString:inputString options:0 range:NSMakeRange(0, [inputString length])];
        NSRange matchRange = [textCheckingResult rangeAtIndex:1];
        NSString *match = [inputString substringWithRange:matchRange];
        return [match intValue];
    }
    return 0;
} // end of GetWeeks


-(int) GetMonths:(NSString*) inputString
{
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(-?\\d+)(m|M)"
        options:NSRegularExpressionCaseInsensitive	error:NULL];
    NSUInteger numberOfMatches = [regex numberOfMatchesInString:inputString options:0 range:NSMakeRange(0, [inputString length])];
    if (numberOfMatches)
    {
        NSTextCheckingResult *textCheckingResult = [regex firstMatchInString:inputString options:0 range:NSMakeRange(0, [inputString length])];
        NSRange matchRange = [textCheckingResult rangeAtIndex:1];
        NSString *match = [inputString substringWithRange:matchRange];
        return [match intValue];
    }
    return 0;
} // end of GetMonths


-(int) GetYears:(NSString*) inputString
{
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(-?\\d+)(y|Y)"
        options:NSRegularExpressionCaseInsensitive	error:NULL];
    NSUInteger numberOfMatches = [regex numberOfMatchesInString:inputString options:0 range:NSMakeRange(0, [inputString length])];
    if (numberOfMatches)
    {
        NSTextCheckingResult *textCheckingResult = [regex firstMatchInString:inputString options:0 range:NSMakeRange(0, [inputString length])];
        NSRange matchRange = [textCheckingResult rangeAtIndex:1];
        NSString *match = [inputString substringWithRange:matchRange];
        return [match intValue];
    }
    return 0;
} // end of GetYears


-(int) GetWeekNumber:(NSString*) inputString
{
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"w(\\d+)"
        options:NSRegularExpressionCaseInsensitive	error:NULL];
    NSUInteger numberOfMatches = [regex numberOfMatchesInString:inputString options:0 range:NSMakeRange(0, [inputString length])];
    if (numberOfMatches)
    {
        NSTextCheckingResult *textCheckingResult = [regex firstMatchInString:inputString options:0 range:NSMakeRange(0, [inputString length])];
        NSRange matchRange = [textCheckingResult rangeAtIndex:1];
        NSString *match = [inputString substringWithRange:matchRange];
        return [match intValue];
    }
    return 0;
} // end of GetWeekNumber


-(int) GetDayNumber:(NSString*) inputString
{
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"d(\\d+)"
                                                                           options:NSRegularExpressionCaseInsensitive	error:NULL];
    NSUInteger numberOfMatches = [regex numberOfMatchesInString:inputString options:0 range:NSMakeRange(0, [inputString length])];
    if (numberOfMatches)
    {
        NSTextCheckingResult *textCheckingResult = [regex firstMatchInString:inputString options:0 range:NSMakeRange(0, [inputString length])];
        NSRange matchRange = [textCheckingResult rangeAtIndex:1];
        NSString *match = [inputString substringWithRange:matchRange];
        return [match intValue];
    }
    return 0;
} // end of GetDayNumber


-(int) GetB5Days:(NSString*) inputString
{
    // Business days 5
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(-?\\d+)(b|B)5"
        options:NSRegularExpressionCaseInsensitive	error:NULL];
    NSUInteger numberOfMatches = [regex numberOfMatchesInString:inputString options:0 range:NSMakeRange(0, [inputString length])];
    if (numberOfMatches)
    {
        NSTextCheckingResult *textCheckingResult = [regex firstMatchInString:inputString options:0 range:NSMakeRange(0, [inputString length])];
        NSRange matchRange = [textCheckingResult rangeAtIndex:1];
        NSString *match = [inputString substringWithRange:matchRange];
        return [match intValue];
    }
    return 0;
} // end of GetB5Days


-(int) GetB6Days:(NSString*) inputString
{
    // Business days 6
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(-?\\d+)(b|B)6"
        options:NSRegularExpressionCaseInsensitive	error:NULL];
    NSUInteger numberOfMatches = [regex numberOfMatchesInString:inputString options:0 range:NSMakeRange(0, [inputString length])];
    if (numberOfMatches)
    {
        NSTextCheckingResult *textCheckingResult = [regex firstMatchInString:inputString options:0 range:NSMakeRange(0, [inputString length])];
        NSRange matchRange = [textCheckingResult rangeAtIndex:1];
        NSString *match = [inputString substringWithRange:matchRange];
        return [match intValue];
    }
    return 0;
} // end of GetB6Days


-(int) GetTodayShortcut:(NSString*) inputString
{
    // t | T
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(t|T)"
        options:NSRegularExpressionCaseInsensitive	error:NULL];
    NSUInteger numberOfMatches = [regex numberOfMatchesInString:inputString options:0 range:NSMakeRange(0, [inputString length])];
    if (numberOfMatches)
    {
        return 1;
    }
    return 0;
} // end of GetTodayShortcut


-(BOOL) parseDate:(NSString*) string
{
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    dateFormat.locale = [[NSLocale alloc] initWithLocaleIdentifier:[[NSLocale preferredLanguages] firstObject]];
    [dateFormat setDateStyle:NSDateFormatterShortStyle];
    [dateFormat setLocale:[NSLocale currentLocale]];
    NSDate* date = [dateFormat dateFromString:string];
    if (date != nil)
    {
        [_calendar setDate:date];
        return TRUE;
    }
    else if ([self GetTodayShortcut: string])
    {
        [_calendar setDate:[NSDate date]];
        return TRUE;
    }

    return FALSE;
} // end of parseDate


-(void) moveDate:(NSString*) string useToday:(BOOL) today
{
    NSDate* startDate = today?[NSDate date]:[_calendar getDate];

    int units = 0;
    int unitType = 0;

    if ((units = [self GetDays:string]) != 0)
    {
        unitType = 0; // days
    }
    else if ((units = [self GetWeeks:string]) != 0)
    {
        unitType = 1; // weeks
    }
    else if ((units = [self GetMonths:string]) != 0)
    {
        unitType = 2; // months
    }
    else if ((units = [self GetYears:string]) != 0)
    {
        unitType = 3; // years
    }
    else if ((units = [self GetWeekNumber:string]) != 0)
    {
        unitType = 4; // week number
    }
    else if ((units = [self GetDayNumber:string]) != 0)
    {
        unitType = 7; // day number
    }
    else if ((units = [self GetB5Days:string]) != 0)
    {
        unitType = 5; // 5 day business
    }
    else if ((units = [self GetB6Days:string]) != 0)
    {
        unitType = 6; // 6 day business
    }

    if (units != 0)
    {
        if (unitType <= 3)
        {
            NSDate* newDate = [self AddToDate:[NSDate getDateNSDate:startDate]
                unitType: unitType units: units];
            [_calendar setDate:newDate];
        }
        else if (unitType == 4 && units < 54)
        {
            NSCalendar* currentCalendar = [NSCalendar currentCalendar];
            NSDateComponents* dateComponents = [currentCalendar components:NSCalendarUnitYear | NSCalendarUnitMonth
                | NSCalendarUnitDay fromDate:startDate];
            NSInteger year = [dateComponents year];
            NSDateComponents *newDateComponents = [[NSDateComponents alloc] init];
            [newDateComponents setYearForWeekOfYear:year];
            [newDateComponents setWeekOfYear:units];
            [newDateComponents setWeekday:1];
            [_calendar setDate:[currentCalendar dateFromComponents:newDateComponents]];
        }
        else if (unitType == 7 && units < 366)
        {
            NSCalendar* currentCalendar = [NSCalendar currentCalendar];
            NSDateComponents* dateComponents = [currentCalendar components:NSCalendarUnitYear | NSCalendarUnitMonth
                | NSCalendarUnitDay fromDate:startDate];
            NSDateComponents *newDateComponents = [[NSDateComponents alloc] init];
            [newDateComponents setYear:[dateComponents year]];
            [newDateComponents setMonth:1];
            [newDateComponents setDay:1];
            NSDate* newDate = [self AddToDate:[NSDate getDateNSDate:
                [currentCalendar dateFromComponents:newDateComponents]] unitType: 0 units: units-1];
            [_calendar setDate:newDate];
        }
        else if (unitType == 5 || unitType == 6)
        {
            if (unitType == 5)
            {
                [_calendar setDate:[self addBusinessDaysToDate:startDate addDays:units isFull:TRUE]];
            }
            else if (unitType == 6)
            {
                [_calendar setDate:[self addBusinessDaysToDate:startDate addDays:units isFull:FALSE]];
            }
        }
    }
} // end of moveDate



@end
