//
//  GoogleSharedStatus.m
//  GoogleSharedStatus
//
//  Created by David on 6/15/13.
//  Copyright (c) 2013 David Ryskalczyk. All rights reserved.
//

#import "AIGtalkSharedStatusPlugin.h"
#import "gtalk-shared-status.h"
#import <objc/objc-class.h>
#import "ESPurpleJabberAccount.h"

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
}
}

- (void) loadLibpurplePlugin
{
    // load the actual plugin.
    purple_init_gtalk_shared_status_plugin();
}

@end
