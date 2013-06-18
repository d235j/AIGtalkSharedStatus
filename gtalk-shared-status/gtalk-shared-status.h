/*
 * GTalk Shared Status Plugin
 *  Copyright (C) 2010, Federico Zanco <federico.zanco ( at ) gmail.com>
 *
 * 
 * License:
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
 * 02111-1301, USA.
 *
 */

#ifdef HAVE_CONFIG_H
# include <config.h>
#endif

/* config.h may define PURPLE_PLUGINS; protect the definition here so that we
 * don't get complaints about redefinition when it's not necessary. */
#ifndef PURPLE_PLUGINS
# define PURPLE_PLUGINS
#endif

#ifdef GLIB_H
# include <glib.h>
#endif

/* This will prevent compiler errors in some instances and is better explained in the
 * how-to documents on the wiki */
/*
 #ifndef G_GNUC_NULL_TERMINATED
# if __GNUC__ >= 4
#  define G_GNUC_NULL_TERMINATED __attribute__((__sentinel__))
# else
#  define G_GNUC_NULL_TERMINATED
# endif
#endif
*/
#include <blist.h>
#include <notify.h>
#include <debug.h>
#include <plugin.h>
#include <version.h>
#include <status.h>
#include <savedstatuses.h>
#include <prefs.h>
#include <string.h>


#define PLUGIN_ID			"gtalk-shared-status"
#define PLUGIN_NAME			"GTalk Shared Status"
#define PLUGIN_VERSION		"0.2.5"
#define PLUGIN_STATIC_NAME	"gtalk_shared_status"
#define PLUGIN_SUMMARY		"Provide Google Shared Status compatibility."
#define PLUGIN_DESCRIPTION	"Provide Google Shared Status compatibility."
#define PLUGIN_AUTHOR		"Federico Zanco <federico.zanco@gmail.com>"
#define PLUGIN_WEBSITE		"http://www.siorarina.net/gtalk-shared-status/"

#define PREF_PREFIX									"/plugins/core/" PLUGIN_ID
#define PREF_UNIQUE_GOOGLE_SHARED_STATUS			PREF_PREFIX "/unique_google_shared_status"
#define PREF_UNIQUE_GOOGLE_SHARED_STATUS_DEFAULT	FALSE // Unsupported with Adium!

#define	STATUS_MAX					512
#define	STATUS_LIST_MAX				3
#define STATUS_LIST_CONTENTS_MAX	5

#define GMAIL_DOMAIN 				"gmail.com"
#define PURPLE_ACCOUNT_ASS_INDEX	"active-shared-status-index" // hey! Ass is the acronym! :D
#define IQ_SET_SHARED_STATUS_ID		"set-ss"
#define IQ_REQ_SHARED_STATUS_ID		"req-ss"

#define FROM_GOOGLE_TO_PURPLE		0
#define FROM_PURPLE_TO_GOOGLE		1


typedef struct _GTalkSharedStatusEl GTalkSharedStatusEl;

struct _GTalkSharedStatusEl
{
	PurpleAccount	*account;
	xmlnode			*shared_status;
	gboolean		changing_saved_status;
	xmlnode			*iq_new_shared_status;
};
