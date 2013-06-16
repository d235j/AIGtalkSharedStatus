//
//  ESPurpleJabberAccountSwizzle.m
//  GoogleSharedStatus
//
//  Created by David on 6/15/13.
//  Copyright (c) 2013 David Ryskalczyk. All rights reserved.
//

#import <Adium/AIStatus.h>
#import <AdiumLibpurple/ESPurpleJabberAccount.h>

@implementation ESPurpleJabberAccount (XMPPInvisible)

- (const char *)purpleStatusIDForStatusOverride:(AIStatus *)statusState
                                     arguments:(NSMutableDictionary *)arguments
{
    if(statusState.statusType == AIInvisibleStatusType &&
       ([[self serverSuffix] isEqualToString:@"@gmail.com"] ||
        [[self serverSuffix] isEqualToString:@"@talk.google.com"])
       ) {
        return "invisible";
    } else {
        return [self purpleStatusIDForStatusOverride:statusState arguments:arguments];
    }
}

@end