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