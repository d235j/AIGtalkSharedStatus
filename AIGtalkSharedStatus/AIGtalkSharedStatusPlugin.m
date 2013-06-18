//
//  GoogleSharedStatus.m
//  GoogleSharedStatus
//
//  Created by David Ryskalczyk on 6/15/13.
//

#import "AIGtalkSharedStatusPlugin.h"

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