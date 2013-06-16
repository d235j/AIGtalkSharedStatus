//
//  GoogleSharedStatus.h
//  GoogleSharedStatus
//
//  Created by David on 6/15/13.
//  Copyright (c) 2013 David Ryskalczyk. All rights reserved.
//

#import <objc/objc-class.h>

#import <Adium/AIPlugin.h>
#import <Adium/AIStatus.h>
#import <Adium/AIStatusControllerProtocol.h>

#import <AdiumLibpurple/AILibpurplePlugin.h>
#import <AdiumLibpurple/AIPurpleGTalkAccount.h>
#import <AdiumLibpurple/SLPurpleCocoaAdapter.h>


#import "gtalk-shared-status.h"

@interface AIGtalkSharedStatusPlugin : AIPlugin <AILibpurplePlugin>
{
}

@end

static void
account_status_changed_cb(PurpleAccount *account, PurpleStatus *old, PurpleStatus *new, gpointer data);