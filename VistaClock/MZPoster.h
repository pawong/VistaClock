//
//  MZPoster.h
//  NCal
//
//  Created by Paul Wong on 1/31/16.
//  Copyright © 2016 Mazookie, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString* const SERVER_URL = @"http://home.mazookie.com/api/deployments";

@interface MZPoster : NSObject

-(NSString*) getMacAddress;
-(NSString*) sha256HashFor:(NSString*)input;
-(NSString*) buildPost:(NSDictionary*) addDict;
-(void) sendPost:(NSDictionary*) addDict;

@end
