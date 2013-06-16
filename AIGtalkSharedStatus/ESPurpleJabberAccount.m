//
//  ESPurpleJabberAccountSwizzle.m
//  GoogleSharedStatus
//
//  Created by David on 6/15/13.
//  Copyright (c) 2013 David Ryskalczyk. All rights reserved.
//

#import <Adium/AIStatus.h>
#import <AdiumLibpurple/ESPurpleJabberAccount.h>
#import <AdiumLibpurple/AIPurpleGTalkAccount.h>

@implementation ESPurpleJabberAccount (XMPPInvisible)

- (const char *)purpleStatusIDForStatusOverride:(AIStatus *)statusState
                                     arguments:(NSMutableDictionary *)arguments
{
    if(statusState.statusType == AIInvisibleStatusType &&
       [self isKindOfClass:[AIPurpleGTalkAccount class]]) {
        return "invisible";
    } else {
        return [self purpleStatusIDForStatusOverride:statusState arguments:arguments];
    }
}

@end