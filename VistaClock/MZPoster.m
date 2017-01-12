//
//  MZPoster.m
//
//  Created by Paul Wong on 1/31/16.
//  Copyright © 2016 Mazookie, LLC. All rights reserved.
//

#import "MZPoster.h"
#import <CommonCrypto/CommonDigest.h>

#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>

@implementation MZPoster

-(NSString*) getMacAddress
{
    int                 mgmtInfoBase[6];
    char                *msgBuffer = NULL;
    size_t              length;
    unsigned char       macAddress[6];
    struct if_msghdr    *interfaceMsgStruct;
    struct sockaddr_dl  *socketStruct;
    NSString            *errorFlag = NULL;

    // Setup the management Information Base (mib)
    mgmtInfoBase[0] = CTL_NET;        // Request network subsystem
    mgmtInfoBase[1] = AF_ROUTE;       // Routing table info
    mgmtInfoBase[2] = 0;
    mgmtInfoBase[3] = AF_LINK;        // Request link layer information
    mgmtInfoBase[4] = NET_RT_IFLIST;  // Request all configured interfaces

    // With all configured interfaces requested, get handle index
    if ((mgmtInfoBase[5] = if_nametoindex("en0")) == 0)
        errorFlag = @"if_nametoindex failure";
    else
    {
        // Get the size of the data available (store in len)
        if (sysctl(mgmtInfoBase, 6, NULL, &length, NULL, 0) < 0)
            errorFlag = @"sysctl mgmtInfoBase failure";
        else
        {
            // Alloc memory based on above call
            if ((msgBuffer = malloc(length)) == NULL)
                errorFlag = @"buffer allocation failure";
            else
            {
                // Get system information, store in buffer
                if (sysctl(mgmtInfoBase, 6, msgBuffer, &length, NULL, 0) < 0)
                    errorFlag = @"sysctl msgBuffer failure";
            }
        }
    }

    // Befor going any further...
    if (errorFlag != NULL)
    {
        NSLog(@"Error: %@", errorFlag);
        return errorFlag;
    }

    // Map msgbuffer to interface message structure
    interfaceMsgStruct = (struct if_msghdr *) msgBuffer;

    // Map to link-level socket structure
    socketStruct = (struct sockaddr_dl *) (interfaceMsgStruct + 1);

    // Copy link layer address data in socket structure to an array
    memcpy(&macAddress, socketStruct->sdl_data + socketStruct->sdl_nlen, 6);

    // Read from char array into a string object, into traditional Mac address format
    NSString *macAddressString = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
                                  macAddress[0], macAddress[1], macAddress[2],
                                  macAddress[3], macAddress[4], macAddress[5]];

    // Release the buffer memory
    free(msgBuffer);

    return macAddressString;
} // end of getMacAddress


-(NSString*)sha256HashFor:(NSString*)input
{
    const char* str = [input UTF8String];
    unsigned char result[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(str, (int)strlen(str), result);

    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH*2];
    for(int i = 0; i<CC_SHA256_DIGEST_LENGTH; i++)
    {
        [ret appendFormat:@"%02x",result[i]];
    }
    return ret;
} // end of sha256HashFor


-(NSString*) buildPost
{
    NSString* jsonString = NULL;
    NSMutableDictionary* dict = [NSMutableDictionary new];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS ZZZ"];
    NSString* date = [dateFormatter stringFromDate:[NSDate date]];

    [dict setObject:NSUserName() forKey:@"user_name"];
    [dict setObject:[[NSHost currentHost] localizedName] forKey:@"host_name"];
    [dict setObject:date forKey:@"date"];

    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    NSString* program_name = [info objectForKey:@"CFBundleExecutable"];
    [dict setObject:[info objectForKey:@"CFBundleIdentifier"] forKey:@"bundle_id"];
    [dict setObject:program_name forKey:@"program_name"];
    [dict setObject:[info objectForKey:@"CFBundleShortVersionString"] forKey:@"version"];
    [dict setObject:[info objectForKey:@"CFBundleVersion"] forKey:@"build"];

    NSString* version = [[NSProcessInfo processInfo] operatingSystemVersionString];
    [dict setObject:version forKey:@"os_version"];

    [dict setObject:[self getMacAddress] forKey:@"mac_address"];

    [dict setObject:[self sha256HashFor:[program_name stringByAppendingString:date]] forKey:@"key"];

    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    if (jsonData)
    {
        jsonString = [[NSString alloc] initWithBytes:[jsonData bytes] length:[jsonData length] encoding:NSUTF8StringEncoding];
    }

    //NSLog(@"%@", jsonString);
    return jsonString;
} // end of buildReport


-(void) sendPost
{
    NSString* rawString = [self buildPost];
    NSData* postData = [rawString dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];

    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:SERVER_URL]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];

   // NSLog(@"request = %@", [[NSString alloc] initWithData:postData encoding:NSASCIIStringEncoding]);

    NSURLResponse* response;
    NSError* error = nil;

    //Capturing server response
    //NSData* result =
    [NSURLConnection sendSynchronousRequest:request  returningResponse:&response error:&error];

    //NSLog(@"result = %@", [[NSString alloc] initWithData:result encoding:NSASCIIStringEncoding]);
} // end of sendReport

@end
