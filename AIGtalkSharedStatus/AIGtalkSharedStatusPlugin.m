//
//  GoogleSharedStatus.m
//  GoogleSharedStatus
//
//  Created by David on 6/15/13.
//  Copyright (c) 2013 David Ryskalczyk. All rights reserved.
//

#import "AIGtalkSharedStatusPlugin.h"

#define KEY_JABBER_PRIORITY_AWAY		@"Jabber:Priority when Away"

extern void purple_init_gtalk_shared_status_plugin();

@implementation AIGtalkSharedStatusPlugin

- (void) installLibpurplePlugin
{
    purple_signal_connect(purple_accounts_get_handle(),
                          "account-status-changed",
                          adium_purple_get_handle(),
                          PURPLE_CALLBACK(account_status_changed_cb),
                          NULL);
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
    return @"ADIUM_PLUGIN_VERSION";
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
    @autoreleasepool {
        AIStatus *currentStatus;
        CBPurpleAccount	*aIaccount = accountLookup(account);
        if([aIaccount isKindOfClass:[AIPurpleGTalkAccount class]]) {
            
            PurpleStatusPrimitive status = purple_status_type_get_primitive(purple_status_get_type(new));
            switch (status) {
                case PURPLE_STATUS_AWAY:
                case PURPLE_STATUS_EXTENDED_AWAY:
                case PURPLE_STATUS_UNAVAILABLE:
                    currentStatus = [adium.statusController awayStatus];
                    break;
                case PURPLE_STATUS_INVISIBLE:
                    currentStatus = [adium.statusController invisibleStatus];
                    break;
                case PURPLE_STATUS_OFFLINE:
                    currentStatus = [adium.statusController offlineStatus];
                    break;
                case PURPLE_STATUS_AVAILABLE:
                case PURPLE_STATUS_TUNE:
                default:
                    currentStatus = [adium.statusController availableStatus];
                    break;
            }
            
            if([aIaccount statusType] != [currentStatus statusType]) {
                [aIaccount setStatusState:currentStatus];
            }
        }
    }
}
