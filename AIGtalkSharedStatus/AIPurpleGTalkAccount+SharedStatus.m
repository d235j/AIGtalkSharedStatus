//
//  ESPurpleJabberAccountSwizzle.m
//  GoogleSharedStatus
//
//  Created by David on 6/15/13.
//  Copyright (c) 2013 David Ryskalczyk. All rights reserved.
//

#import <Adium/AIStatus.h>
#import <AdiumLibpurple/AIPurpleGTalkAccount.h>
#import <Adium/AIStatusControllerProtocol.h>
#import <Adium/AISharedAdium.h>
#import "jutil.h"

@implementation AIPurpleGTalkAccount (SharedStatus)

- (const char *)purpleStatusIDForStatus:(AIStatus *)statusState
                              arguments:(NSMutableDictionary *)arguments
{
    const char		*statusID = NULL;
    NSString		*statusName = statusState.statusName;
    NSString		*statusMessageString = [statusState statusMessageString];
    NSNumber		*priority = nil;
    
    if (!statusMessageString) statusMessageString = @"";
    
    switch (statusState.statusType) {
        case(AIInvisibleStatusType):
            statusID = "invisible";
            priority = [self preferenceForKey:KEY_JABBER_PRIORITY_AVAILABLE group:GROUP_ACCOUNT_STATUS];
            break;
            // away state (Google Away == XMPP DND)
        case(AIAwayStatusType):
            if([statusName isEqualToString:STATUS_NAME_EXTENDED_AWAY] ||
               ([statusMessageString caseInsensitiveCompare:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_EXTENDED_AWAY]] == NSOrderedSame)) {
                statusID = jabber_buddy_state_get_status_id(JABBER_BUDDY_STATE_XA);
            } else {
                statusID = jabber_buddy_state_get_status_id(JABBER_BUDDY_STATE_DND);
            }
            priority = [self preferenceForKey:KEY_JABBER_PRIORITY_AWAY group:GROUP_ACCOUNT_STATUS];
            break;
        default:
            break; // allow main code to handle these cases (Online and Offline)
    }
    
    if(statusID == NULL) {
        // return default output in case this has failed to return
        return [super purpleStatusIDForStatus:statusState arguments:arguments];
    } else {
        // handle return value here
        
        //Set our priority, which is actually set along with the status...Default is 0.
        [arguments setObject:(priority ? priority : [NSNumber numberWithInteger:0])
                      forKey:@"priority"];
        
        //We could potentially set buzz on a per-status basis. We have no UI for this, however.
        [arguments setObject:[NSNumber numberWithBool:YES] forKey:@"buzz"];
        
        return statusID;
    }
}
@end