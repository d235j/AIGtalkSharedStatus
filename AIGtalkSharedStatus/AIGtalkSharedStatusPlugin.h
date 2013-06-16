//
//  GoogleSharedStatus.h
//  GoogleSharedStatus
//
//  Created by David on 6/15/13.
//  Copyright (c) 2013 David Ryskalczyk. All rights reserved.
//


#import <Adium/AIPlugin.h>
#import <Adium/AIStatus.h>
#import <AdiumLibpurple/AILibpurplePlugin.h>
#import "gtalk-shared-status.h"
#import <objc/objc-class.h>
#import <AdiumLibpurple/ESPurpleJabberAccount.h>

@interface AIGtalkSharedStatusPlugin : AIPlugin <AILibpurplePlugin>
{
}

@end

static void
account_status_changed_cb(PurpleAccount *account, PurpleStatus *old, PurpleStatus *new, gpointer data);