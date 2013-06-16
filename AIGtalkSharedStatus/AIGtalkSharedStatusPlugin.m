//
//  GoogleSharedStatus.m
//  GoogleSharedStatus
//
//  Created by David on 6/15/13.
//  Copyright (c) 2013 David Ryskalczyk. All rights reserved.
//

#import "AIGtalkSharedStatusPlugin.h"
#import <AdiumLibpurple/SLPurpleCocoaAdapter.h>

#define KEY_JABBER_PRIORITY_AWAY		@"Jabber:Priority when Away"

extern void purple_init_gtalk_shared_status_plugin();

@implementation AIGtalkSharedStatusPlugin

- (void) installLibpurplePlugin
{
    // we need to override Adium's hardcoded Invisible == Away logic for XMPP.
    @autoreleasepool {
        Method originalMethod = class_getInstanceMethod([ESPurpleJabberAccount class],
                                                        @selector(purpleStatusIDForStatus:arguments:));
        Method newMethod = class_getInstanceMethod([ESPurpleJabberAccount class],
                                                   @selector(purpleStatusIDForStatusOverride:arguments:));
        method_exchangeImplementations(originalMethod, newMethod);
        
        purple_signal_connect(purple_accounts_get_handle(),
                              "account-status-changed",
                              adium_purple_get_handle(),
                              PURPLE_CALLBACK(account_status_changed_cb),
                              NULL);
    }
}

- (void) loadLibpurplePlugin
{
    // load the actual plugin.
    purple_init_gtalk_shared_status_plugin();
}

- (NSString *) pluginAuthor
{
    return @"David Ryskalczyk";
}

- (NSString *) pluginVersion
{
    return @"0.1";
}

- (NSString *) pluginDescription
{
    return @"Support for Google Shared Status in Adium 1.7";
}

- (NSString *) pluginURL
{
    return @"https://github.com/d235j/AIGtalkSharedStatus";
}

@end

static void
account_status_changed_cb(PurpleAccount *account, PurpleStatus *old, PurpleStatus *new, gpointer data)
{
    AIStatusType aIstatusType;
    CBPurpleAccount	*aIaccount = accountLookup(account);
    if(strcmp([aIaccount protocolPlugin], "prpl-jabber") == 0) {
        PurpleStatusPrimitive status = purple_status_type_get_primitive(purple_status_get_type(new));
        
        switch (status) {
            case PURPLE_STATUS_AWAY:
            case PURPLE_STATUS_EXTENDED_AWAY:
                aIstatusType = AIAwayStatusType;
                break;
            case PURPLE_STATUS_INVISIBLE:
                aIstatusType = AIInvisibleStatusType;
                break;
            case PURPLE_STATUS_OFFLINE:
                aIstatusType = AIOfflineStatusType;
                break;
            case PURPLE_STATUS_AVAILABLE:
            case PURPLE_STATUS_TUNE:
            default:
                aIstatusType = AIAvailableStatusType;
                break;
        }
        
        [aIaccount setStatusState:[AIStatus statusOfType:aIstatusType]];
    }
}
