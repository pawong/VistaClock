//
//  MZClockConfig.h
//  VistaClock
//
//  Created by Paul Wong on 9/24/14.
//  Copyright (c) 2014 Mazookie, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MZClockConfig : NSObject

@property (nonatomic, retain) NSString* title;
@property (nonatomic, retain) NSString* timezoneName;
@property (nonatomic, assign) BOOL useSeconds;

@end
