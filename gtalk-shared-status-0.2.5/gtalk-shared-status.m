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

#import <Adium/AIStatus.h>

#import <Adium/AISharedAdium.h>

#import <Adium/AIStatusControllerProtocol.h>

#import <AdiumLibpurple/AIPurpleGTalkAccount.h>
#import <AdiumLibpurple/SLPurpleCocoaAdapter.h>

#import "gtalk-shared-status.h"

// globals
static PurplePlugin *this_plugin = NULL;
static GList *shared_status_list = NULL;


// prototypes
static gint 					sscmp( gconstpointer a, gconstpointer b);
static GTalkSharedStatusEl *	ssl_find(PurpleAccount *account);
static void						ssl_set_shared_status(PurpleAccount *account, xmlnode *shared_status);
static gboolean					ssl_is_changing_saved_status(PurpleAccount *account);
static void						ssl_set_changing_saved_status(PurpleAccount *account, gboolean value);
static GTalkSharedStatusEl *	ssl_add(PurpleAccount *account);
static char *					get_simple_name(PurpleAccount *account);
static char *					make_account_pref(PurpleAccount *account);
static void 					add_status_invisible(PurpleAccount *account);
static const char *				map_status(gboolean mode, const char *status_id);
static xmlnode *				create_shared_status_iq(GTalkSharedStatusEl *el, PurpleStatus *old, PurpleStatus *new);
static char *					get_show(const xmlnode *query);
static gboolean                 get_has_status(const xmlnode *query);
static char *					get_status(const xmlnode *query);
static gboolean					is_shared_status_invisible(xmlnode *shared_status);
static gboolean					is_same_state(PurpleStatus *status, xmlnode *shared_status);
static void 					account_status_changed_cb(PurpleAccount *account, PurpleStatus *old, PurpleStatus *new, gpointer data);
static void						request_shared_status(PurpleAccount *account);
static void						strip_prefixes(xmlnode *query);
static void						sync_with_shared_status(PurpleAccount *account, xmlnode *iq);
static gboolean					is_protocol_disco_info(xmlnode *iq);
static gboolean					is_shared_status_capable(xmlnode *iq);
static gboolean					is_shared_status(xmlnode *iq);
static gboolean					jabber_iq_received_cb(PurpleConnection *pc, const char *type, const char *id, const char *from, xmlnode *iq);
static gboolean					plugin_load (PurplePlugin *plugin);
static gboolean					plugin_unload (PurplePlugin *plugin);
static PurplePluginPrefFrame *	get_plugin_pref_frame(PurplePlugin *plugin);
static void						init_plugin (PurplePlugin * plugin);
static void                     set_account_status(PurpleAccount *account, const char *statusID, const char *statusString);


static gint
sscmp(gconstpointer a, gconstpointer b)
{
	//purple_debug_info(PLUGIN_STATIC_NAME, "sscmp\n");

	if (a && (PurpleAccount *) ((GTalkSharedStatusEl *) a)->account == (PurpleAccount *) b)
		return 0;
	else
		return 1;
}


static GTalkSharedStatusEl *
ssl_find(PurpleAccount *account)
{
	GList *el = g_list_find_custom(shared_status_list, account, sscmp);
	
	//purple_debug_info(PLUGIN_STATIC_NAME, "ssl_find\n");
	
	if (el)
		return (GTalkSharedStatusEl *) el->data;
	else
		return NULL;
}


static void
ssl_set_shared_status(PurpleAccount *account, xmlnode *shared_status)
{
	GTalkSharedStatusEl *el = ssl_find(account);
	
	if (el)
		el->shared_status = xmlnode_copy(shared_status);
}


static gboolean
ssl_is_changing_saved_status(PurpleAccount *account)
{
	GTalkSharedStatusEl *el = ssl_find(account);
	
	if (el)
		return el->changing_saved_status;
	
	return FALSE;
}


static void
ssl_set_changing_saved_status(PurpleAccount *account, gboolean value)
{
	GTalkSharedStatusEl *el = ssl_find(account);
	
	if (el)
		el->changing_saved_status = value;
}


static GTalkSharedStatusEl *
ssl_add(PurpleAccount *account)
{
	GTalkSharedStatusEl *el = NULL;

	purple_debug_info(PLUGIN_STATIC_NAME, "ssl_add\n");
	
	if (ssl_find(account))
		return ssl_find(account);
	
	el = g_new0(GTalkSharedStatusEl, 1);
	el->account = account;
	
	shared_status_list = g_list_prepend(shared_status_list, (gpointer) el);
	
	return el;
}


static char *
get_simple_name(PurpleAccount *account)
{
	gchar **name = NULL;

	name = g_strsplit(purple_account_get_username(account), "/", 2);
//	purple_debug_info(PLUGIN_STATIC_NAME, "get_simple_name: %s %s\n", purple_account_get_username(account), name[0]);
	
	g_free(name[1]);
	
	return name[0];
}


static char *
make_account_pref(PurpleAccount *account)
{
	char *name = NULL;
	char *pref = NULL;

	name = get_simple_name(account);
	pref = g_strdup_printf("%s/%s", PREF_PREFIX, name);
	g_free(name);
	return pref;
}


static void 
add_status_invisible(PurpleAccount *account)
{
	PurpleStatusType *inv_type = NULL;
	PurpleStatus *inv_status = NULL;
	PurplePresence *pres = NULL;
	GList *types = NULL;
	GList *statuses = NULL;
	
	inv_type = purple_status_type_new_full(
		PURPLE_STATUS_INVISIBLE,	//primitive
		NULL,						//id
		NULL,						//name 
		FALSE,						//saveable
		TRUE,						//user_settable
		FALSE);						//independent
		
	purple_debug_info(PLUGIN_STATIC_NAME, "add_status_invisible\n");

	types = purple_account_get_status_types(account);

    // if status 'INVISIBLE' is already present there's no need to add it    
	for (; types; types = types->next)
	{
		if (purple_status_type_get_primitive(types->data) == PURPLE_STATUS_INVISIBLE)
			return;
	}
	
	types = purple_account_get_status_types(account);
	types = g_list_append(types, inv_type);
    account->status_types = types;
//	purple_account_set_status_types(account, types);

	pres = purple_account_get_presence(account);
	inv_status = purple_status_new(inv_type, pres);
	
	statuses = purple_presence_get_statuses(pres);
	statuses = g_list_append(statuses, inv_status);
		
	if (purple_account_is_connected(account))
		purple_notify_warning(
			this_plugin,
			PLUGIN_NAME,
			"WARNING!!!",
			"Gtalk Shared Status plugin requires restart! Please exit and restart to get it working");
}


static const char *
map_status(gboolean mode, const char *status_id)
{
	purple_debug_info(PLUGIN_STATIC_NAME, "map_status: STATUS_ID %s\n", status_id);

	if (mode == FROM_GOOGLE_TO_PURPLE)
	{
		if (!g_strcmp0("default", status_id))
            return 	purple_primitive_get_id_from_type(PURPLE_STATUS_AVAILABLE);
			
		if (!g_strcmp0("dnd", status_id))
            return purple_primitive_get_id_from_type(PURPLE_STATUS_AWAY);
		
		return NULL;
	} else {
		if (!g_strcmp0("available", status_id) || !g_strcmp0(purple_primitive_get_id_from_type(PURPLE_STATUS_AVAILABLE), status_id))
			return "default";
		
		if (!g_strcmp0("unavailable", status_id) ||
            !g_strcmp0(purple_primitive_get_id_from_type(PURPLE_STATUS_UNAVAILABLE), status_id) ||
            !g_strcmp0("away", status_id) ||
            !g_strcmp0(purple_primitive_get_id_from_type(PURPLE_STATUS_AWAY), status_id))
			return "dnd";

        return NULL;
	}	
}


static xmlnode *
create_shared_status_iq(
	GTalkSharedStatusEl *el,
	PurpleStatus *old, 
	PurpleStatus *new)
{
	xmlnode *iq = NULL;
	xmlnode *query = NULL;
	xmlnode *show = NULL;
	xmlnode *status = NULL;
	xmlnode *status_list = NULL;
	xmlnode *invisible = NULL;
	xmlnode *s = NULL;
	xmlnode *sl = NULL;
	char *show_str = NULL;
	char *status_str = NULL;
	int i = 0;

	purple_debug_info(PLUGIN_STATIC_NAME, "create_shared_status_iq\n");

	// el and shared_status can't be embty...
	if (!el || !el->shared_status)
		return NULL;
	
	//create iq node
	iq = xmlnode_new("iq");
	xmlnode_set_attrib(iq, "type", "set");
	xmlnode_set_attrib(iq, "to", get_simple_name(el->account));
	xmlnode_set_attrib(iq, "id", IQ_SET_SHARED_STATUS_ID);

	// create query node
	query = xmlnode_new("query");
	xmlnode_set_attrib(query, "version", "2");
	xmlnode_set_namespace(query, "google:shared-status");
	xmlnode_insert_child(iq, query);
	
	// create status node
	status = xmlnode_new("status");
	// it can be null
	status_str = purple_markup_strip_html(purple_status_get_attr_string(new, "message"));
	if (status_str)
		xmlnode_insert_data(status, status_str, -1);
	xmlnode_insert_child(query, status);
	
	// create show node
	show_str = g_strdup(map_status(FROM_PURPLE_TO_GOOGLE, purple_primitive_get_id_from_type(purple_status_type_get_primitive(purple_status_get_type(new)))));
	
	// if show is passed then use it. Otherwise copy it from query node passed
	if (show_str)
	{
		show = xmlnode_new("show");
		xmlnode_insert_data(show, show_str, -1);
	} else
		show = xmlnode_copy(xmlnode_get_child(el->shared_status, "show"));
	xmlnode_insert_child(query, show);

	// create status-list nodes
	status = NULL;
	sl = xmlnode_get_child(el->shared_status, "status-list");	
	while (sl)
	{
		status_list = NULL;
		
		// if status-list's show = show and status is not null
		if (!g_strcmp0(xmlnode_get_attrib(sl, "show"), show_str) && status_str)
		{
			status = NULL;
		
			// search status in this status-list
			s = xmlnode_get_child(sl, "status");
			while (s)
			{
				if (!g_strcmp0(status_str, xmlnode_get_data(s)))
				{
					status = xmlnode_copy(s);
					break;
				}
				
				s = xmlnode_get_next_twin(s);
			}
			
			// create a new status-list node
			status_list = xmlnode_new("status-list");
			xmlnode_set_attrib(status_list, "show", show_str);
				
			// if status were not in status-list create a new status node and
			// add it to the new status-list
			if (!status)
			{
				status = xmlnode_new("status");
				xmlnode_insert_data(status, status_str, -1);
			}
			xmlnode_insert_child(status_list, status);
			
			// add all other status while status-list length is lesser than
			// STATUS_LIST_CONTENTS_MAX and every status is different from status
			i = 1;
			s = xmlnode_get_child(sl, "status");
			while (s && i < STATUS_LIST_CONTENTS_MAX)
			{
				if (g_strcmp0(xmlnode_get_data(status), xmlnode_get_data(s)))
					xmlnode_insert_child(status_list, xmlnode_copy(s));
				else
					i--;
					
				s = xmlnode_get_next_twin(s);
				i++;
			}
		}
		
		// if this status-list is not the one to modify then copy it as is
		if (!status_list)
			status_list = xmlnode_copy(sl);
			
		xmlnode_insert_child(query, status_list);
		
		sl = xmlnode_get_next_twin(sl);
	}

	// if status were not found nor added then it means that there're no such 
	// status-list (with same show attrib) so add a new status-list with attrib
	// show and the new status
	if (!status && status_str)
	{
		status_list = xmlnode_new("status-list");
		xmlnode_set_attrib(status_list, "show", show_str);
		xmlnode_insert_child(query, status_list);
		
		status = xmlnode_new("status");
		xmlnode_insert_data(status, status_str, -1);
		xmlnode_insert_child(status_list, status);
	}
	
	// create invisible node
	invisible = xmlnode_new("invisible");
	xmlnode_set_attrib(invisible, "value", purple_status_type_get_primitive(purple_status_get_type(new)) == PURPLE_STATUS_INVISIBLE ? "true" : "false");
	xmlnode_insert_child(query, invisible);

	el->iq_new_shared_status = xmlnode_copy(iq);
	
	purple_debug_info(PLUGIN_STATIC_NAME, "account_status_changed: \n%s\n", xmlnode_to_formatted_str(iq, &i));

	g_free(show_str);
	g_free(status_str);	
	xmlnode_free(iq);

	return el->iq_new_shared_status;
}


static char *
get_show(const xmlnode *query)
{
	if (xmlnode_get_child(query, "show")) 
		return xmlnode_get_data(
					xmlnode_get_child(query, "show"));
	else
		return NULL;
}

static gboolean
get_has_status(const xmlnode *query)
{
    return (xmlnode_get_child(query, "status") != NULL);
}

static char *
get_status(const xmlnode *query)
{
	if (xmlnode_get_child(query, "status"))
		return xmlnode_get_data(
					xmlnode_get_child(query, "status"));
	else
		return NULL;

    /*
    const char *show = map_status(FROM_GOOGLE_TO_PURPLE, get_show(query));
    xmlnode *status_list = xmlnode_get_child(query, "status-list");
    xmlnode *status = xmlnode_get_child(status_list, "status");;
    
    do {
        if(g_strcmp0(xmlnode_get_attrib(status, "show"), show) == 0) {
            break;
        }
        status = xmlnode_get_next_twin(status);
    } while(status != NULL);
    if(status != NULL) {
        return xmlnode_get_data(status);
    } else {
        return NULL;
    }
     */
}


static gboolean
is_shared_status_invisible(xmlnode *shared_status)
{
	purple_debug_info(PLUGIN_STATIC_NAME, "is_shared_status_invisible\n");

	if (xmlnode_get_child(shared_status, "invisible") 
		&& !g_strcmp0(
				xmlnode_get_attrib(
					xmlnode_get_child(shared_status, "invisible"),
					"value"), 
				"true"))
		return TRUE;
	else
		return FALSE;
}


static gboolean
is_same_state(PurpleStatus *status, xmlnode *shared_status)
{
	PurpleStatusPrimitive primitive = purple_status_type_get_primitive(purple_status_get_type(status));
	
	purple_debug_info(PLUGIN_STATIC_NAME, "is_same_state\n");
	
	if (!shared_status)
		return FALSE;

	// invisible status is a mess!!!
	if (primitive == PURPLE_STATUS_INVISIBLE && is_shared_status_invisible(shared_status))
		return TRUE;
		
	if (primitive != PURPLE_STATUS_INVISIBLE && is_shared_status_invisible(shared_status))
		return FALSE;
	
	if (g_strcmp0(purple_primitive_get_id_from_type(primitive), map_status(FROM_GOOGLE_TO_PURPLE, get_show(shared_status))))
			return FALSE;

	if (g_strcmp0(
			purple_status_get_attr_string(status, "message"),
			get_status(shared_status)))
		return FALSE;
		
	return TRUE;
}


static void 
account_status_changed_cb(PurpleAccount *account, PurpleStatus *old, PurpleStatus *new, gpointer data)
{
	GTalkSharedStatusEl *el = NULL;

	purple_debug_info(PLUGIN_STATIC_NAME, "account_status_changed: %s\n", purple_account_get_username(account));

	el = ssl_find(account);

	if (!el)
		return;
	
	// if new and active shared status are the same, this callback was caused
	// by sync_shared_status so there's nothing to do
	if (is_same_state(new, el->shared_status))
		return;

	// warn the user that changing from Invisible to Idle/Away leaves the shared status still invisible
	if ((purple_status_type_get_primitive(purple_status_get_type(new)) == PURPLE_STATUS_AWAY
		|| purple_status_type_get_primitive(purple_status_get_type(new)) == PURPLE_STATUS_EXTENDED_AWAY)
		&& purple_status_type_get_primitive(purple_status_get_type(old)) == PURPLE_STATUS_INVISIBLE)
	{
		purple_notify_warning(
			this_plugin,
			PLUGIN_NAME,
			purple_account_get_username(account),
			"You've changed from Invisible to Idle/Away but your shared status is still Invisible!\nChange first to Available or Do not Disturb and then to Idle/Away.");
	}
		

	// manage only available, dnd and invisibile
	if (purple_status_type_get_primitive(purple_status_get_type(new)) != PURPLE_STATUS_AVAILABLE
		&& purple_status_type_get_primitive(purple_status_get_type(new)) != PURPLE_STATUS_UNAVAILABLE
		&& purple_status_type_get_primitive(purple_status_get_type(new)) != PURPLE_STATUS_INVISIBLE)
		return;
	
	// manage unique google shared status
	if (purple_prefs_get_bool(PREF_UNIQUE_GOOGLE_SHARED_STATUS) && ssl_is_changing_saved_status(account))
		return;
	
	create_shared_status_iq(el, old, new);

	if (!el->iq_new_shared_status)
	{
		purple_debug_warning(PLUGIN_STATIC_NAME, "not el->iq_new_shared_status!!!\n");
		return;
	}

	purple_signal_emit(
		purple_connection_get_prpl(purple_account_get_connection(account)),
		"jabber-sending-xmlnode",
		purple_account_get_connection(account),
		&el->iq_new_shared_status);

	xmlnode_free(el->iq_new_shared_status);
	el->iq_new_shared_status = NULL;
}


static void
request_shared_status(PurpleAccount *account)
{
	xmlnode *iq = NULL;
	xmlnode *query = NULL;
	char *name = NULL;

	purple_debug_info(PLUGIN_STATIC_NAME, "request_shared_status\n");
	
	name = get_simple_name(account);
	
	iq = xmlnode_new("iq");
	xmlnode_set_attrib(iq, "type", "get");
	xmlnode_set_attrib(iq, "to", name);
	xmlnode_set_attrib(iq, "id", IQ_REQ_SHARED_STATUS_ID);

	query = xmlnode_new_child(iq, "query");
	xmlnode_set_namespace(query, "google:shared-status");
	xmlnode_set_attrib(query, "version", "2");

	purple_signal_emit(
		purple_connection_get_prpl(purple_account_get_connection(account)),
		"jabber-sending-xmlnode",
		purple_account_get_connection(account),
		&iq);
		                   
	if (iq != NULL)
		xmlnode_free(iq);
		
	g_free(name);
}


static void
strip_prefixes(xmlnode *query)
{
	xmlnode *node = NULL;
	xmlnode *slnode = NULL;
	
	xmlnode_set_prefix(query, NULL);
	
	node = xmlnode_get_child(query, "status");
	if (node)
		xmlnode_set_prefix(node, NULL);
	
	node = xmlnode_get_child(query, "show");
	if (node)
		xmlnode_set_prefix(node, NULL);
	
	// status-list default
	slnode = xmlnode_get_child(query, "status-list");
	if (slnode)
	{
		xmlnode_set_prefix(slnode, NULL);
		
		node = xmlnode_get_child(slnode, "status");
		while (node)
		{
			xmlnode_set_prefix(node, NULL);
			node = xmlnode_get_next_twin(node);
		}
	}
	
	// status-list dnd
	slnode = xmlnode_get_next_twin(slnode);
	if (slnode)
	{
		xmlnode_set_prefix(slnode, NULL);
		
		node = xmlnode_get_child(slnode, "status");
		while (node)
		{
			xmlnode_set_prefix(node, NULL);
			node = xmlnode_get_next_twin(node);
		}
	}
	
	node = xmlnode_get_child(query, "invisible");
	if (node)
		xmlnode_set_prefix(node, NULL);
}


static void
sync_with_shared_status(PurpleAccount *account, xmlnode *iq)
{
	PurpleSavedStatus *saved_status = NULL;

	xmlnode *query = xmlnode_get_child(iq, "query");
	
	purple_debug_info(PLUGIN_STATIC_NAME, "sync_with_shared_status\n");
    // query does not contain the status! This function won't work properly in this case.
    if(!get_has_status(query)) {
        return;
    }

	// clean unwanted attributes
	strip_prefixes(query);
	xmlnode_remove_attrib(query, "status-min-ver");
	xmlnode_remove_attrib(query, "status-max");
	xmlnode_remove_attrib(query, "status-list-max");
	xmlnode_remove_attrib(query, "status-list-contents-max");

	// this should not be necessary because accounts should be added when receiving protocol/disco#info
    if (!ssl_find(account))
		ssl_add(account);

	ssl_set_shared_status(account, query);
	
	if (is_shared_status_invisible(query))
	{
		//purple_account_set_status(account, "invisible", TRUE, NULL);
        set_account_status(account, "invisible", NULL);
		return;
	}

	if (purple_prefs_get_bool(PREF_UNIQUE_GOOGLE_SHARED_STATUS))
	{
		ssl_set_changing_saved_status(account, TRUE);
		// look for a saved status already present
		saved_status = purple_savedstatus_find_transient_by_type_and_message(
						purple_primitive_get_type_from_id(map_status(FROM_GOOGLE_TO_PURPLE, get_show(query))),
						get_status(query));
	
		// if there's not such a saved status create a new one
		if (!saved_status)
		{
			saved_status = purple_savedstatus_new(NULL, purple_primitive_get_type_from_id(map_status(FROM_GOOGLE_TO_PURPLE, get_show(query))));
			purple_savedstatus_set_message(saved_status, get_status(query));
		}
		purple_savedstatus_activate(saved_status);
		ssl_set_changing_saved_status(account, FALSE);
	} else {
        set_account_status(account, map_status(FROM_GOOGLE_TO_PURPLE, get_show(query)), get_status(query));
	}
}


static gboolean
is_protocol_disco_info(xmlnode *iq)
{
	if (xmlnode_get_child(iq, "query") == NULL)
		return FALSE;
		
	return g_strcmp0(xmlnode_get_namespace(xmlnode_get_child(iq, "query")), "http://jabber.org/protocol/disco#info") == 0;
}


static gboolean
is_shared_status_capable(xmlnode *iq)
{
	xmlnode *cur = NULL;

	if (!iq || !xmlnode_get_child(iq, "query"))
		return FALSE;
		
	for (cur = xmlnode_get_child(xmlnode_get_child(iq, "query"), "feature"); cur; cur = xmlnode_get_next_twin(cur))
	{
		if (g_strcmp0(xmlnode_get_attrib(cur, "var"), "google:shared-status") == 0)
			return TRUE;
	}
	
	return FALSE;
}


static gboolean
is_shared_status(xmlnode *iq)
{	
	if (xmlnode_get_child(iq, "query") == NULL)
		return FALSE;
	
	return g_strcmp0(xmlnode_get_namespace(
				xmlnode_get_child(iq, "query")),
				"google:shared-status") == 0;
}


static gboolean
jabber_iq_received_cb(PurpleConnection *pc, const char *type, const char *id, const char *from, xmlnode *iq)
{
	PurpleAccount *account = NULL;
	char *pref = NULL;
//	int len = 0;
	
//	purple_debug_info(PLUGIN_STATIC_NAME, "IQ RECEIVED \n%s\n", xmlnode_to_formatted_str(iq, &len));
	
	account = purple_connection_get_account(pc);
    
    if(!is_shared_status_capable(iq)) {
		pref = make_account_pref(account);
        purple_prefs_add_bool(pref, FALSE);
    }

	if (is_protocol_disco_info(iq) && is_shared_status_capable(iq))
	{
		pref = make_account_pref(account);

		if (purple_prefs_get_bool(pref))
		{
			purple_debug_info(PLUGIN_STATIC_NAME, "adding %s\n", purple_account_get_username(account));
			ssl_add(account);
			request_shared_status(account);
		}

		g_free(pref);
		
		return FALSE;
	}
	
	// if iq is a shared status then process it but do not pass it to purple because
	// it's not purple stuff...
	if (is_shared_status(iq))
	{
		purple_debug_info(PLUGIN_STATIC_NAME, "IS SHARED STATUS\n");
		sync_with_shared_status(account, iq);
		return TRUE;
	}
	
	// iq response to ss-set
	if (!g_strcmp0(xmlnode_get_attrib(iq, "id"), IQ_SET_SHARED_STATUS_ID) 
		&& !g_strcmp0(xmlnode_get_attrib(iq, "type"), "result"))
		return TRUE;
	
	return FALSE;
}


static gboolean
plugin_load(PurplePlugin *plugin)
{
	GList *accounts = NULL;
	PurpleAccount *account = NULL;
	this_plugin = plugin;
	char *pref = NULL;
	gboolean warn = FALSE;

	purple_debug_info(PLUGIN_STATIC_NAME, "plugin_load\n");
	
	purple_debug_info(PLUGIN_STATIC_NAME, "status type is %s\n",
		purple_primitive_get_name_from_type(
			purple_savedstatus_get_type(
				purple_savedstatus_get_default())));

	// add plugin pref
	purple_prefs_add_none(PREF_PREFIX);
	
	// check unique google shared status pref
	if (!purple_prefs_exists(PREF_UNIQUE_GOOGLE_SHARED_STATUS))
		purple_prefs_add_bool(PREF_UNIQUE_GOOGLE_SHARED_STATUS, PREF_UNIQUE_GOOGLE_SHARED_STATUS_DEFAULT);
	
	//add invisible status to all jabber accounts
	for (accounts = purple_accounts_get_all(); accounts; accounts = accounts->next)
	{
		account = (PurpleAccount *) accounts->data;
	
		if (!g_strcmp0(purple_account_get_protocol_id(account), "prpl-jabber"))
		{
			
			pref = make_account_pref(account);
		
			// check google shared status pref for this account. I've changed
 			// the very first setting policy so that every account are enabled
 			// This to avoid users complaing about: it does not work!
			if (!purple_prefs_exists(pref))
				purple_prefs_add_bool(pref, TRUE);
		
			if (purple_account_is_connected(account) && !warn)
			{
				purple_notify_warning(
					this_plugin,
					PLUGIN_NAME,
					"WARNING!!!",
					"Gtalk Shared Status plugin requires restart! Please exit and restart to get it working");
 				warn = TRUE;
			}
			
			if (purple_prefs_get_bool(pref))
				add_status_invisible(account);

			g_free(pref);
		}
	}	

	// add callbacks for signal handling

	// account status changed
	purple_signal_connect(purple_accounts_get_handle(),
		"account-status-changed",
		plugin,
		PURPLE_CALLBACK(account_status_changed_cb),
		NULL);

	// jabber receiving iq
	purple_signal_connect(purple_find_prpl("prpl-jabber"),
		"jabber-receiving-iq", plugin,
		PURPLE_CALLBACK(jabber_iq_received_cb),
		NULL);

	return TRUE;
}


static gboolean
plugin_unload (PurplePlugin *plugin)
{
	GList *cur = NULL;
	
	purple_debug_info(PLUGIN_STATIC_NAME, "plugin_unload\n");

	for (cur = shared_status_list; cur; cur = cur->next)
		xmlnode_free(((GTalkSharedStatusEl *) cur->data)->shared_status);
	
	g_list_free(shared_status_list);
	
	shared_status_list = NULL;
	
	return TRUE;
}


/*
static PurplePluginPrefFrame *
get_plugin_pref_frame(PurplePlugin *plugin)
{
	PurplePluginPrefFrame *frame;
	PurplePluginPref *pref;
	GList *accounts = NULL;
	char *label = NULL;
	char *name = NULL;
	char *pref_str = NULL;
	
 	purple_notify_warning(
 		this_plugin,
 		PLUGIN_NAME,
 		"WARNING!",
 		"Every change in account settings requires a restart. Please restart after any change.");

	
	frame = purple_plugin_pref_frame_new();
	
	// unique google shared status
	pref = purple_plugin_pref_new_with_name_and_label(
				PREF_UNIQUE_GOOGLE_SHARED_STATUS,
				"Unique Google Shared Status:\nthis means that every active Google account has the same state \nand every change is propagate to all accounts");
	purple_plugin_pref_frame_add(frame, pref);
	
	// enable google shared status accounts
	for (accounts = purple_accounts_get_all(); accounts; accounts = accounts->next)
	{
		if (!g_strcmp0(purple_account_get_protocol_id(accounts->data), "prpl-jabber"))
		{
			name = get_simple_name((PurpleAccount *) accounts->data);
			pref_str = make_account_pref((PurpleAccount *) accounts->data);
			label = g_strdup_printf("Enable Google Shared Status for account: %s", name);
			pref = purple_plugin_pref_new_with_name_and_label(pref_str, label);
			purple_plugin_pref_frame_add(frame, pref);
			g_free(label);
			g_free(name);
			g_free(pref_str);
		}
	}
	
	return frame;
}
*/
/*
static PurplePluginUiInfo prefs_info = {
	get_plugin_pref_frame,
	0,
	NULL,

	*//* padding *//*
	NULL,
	NULL,
	NULL,
	NULL
};
*/



/* For specific notes on the meanings of each of these members, consult the C Plugin Howto
 * on the website. */
static PurplePluginInfo info = {
	PURPLE_PLUGIN_MAGIC,
	PURPLE_MAJOR_VERSION,
	PURPLE_MINOR_VERSION,
	PURPLE_PLUGIN_STANDARD,
	NULL,
	0,
	NULL,
	PURPLE_PRIORITY_HIGHEST,
	PLUGIN_ID,
	PLUGIN_NAME,
	PLUGIN_VERSION,
	PLUGIN_SUMMARY,
	PLUGIN_DESCRIPTION,
	PLUGIN_AUTHOR,
	PLUGIN_WEBSITE,
	plugin_load,
	plugin_unload,
	NULL,
	NULL,
	NULL,
    NULL,//	&prefs_info,
	NULL,
	NULL,
	NULL,
	NULL,
	NULL,
};

static void
init_plugin (PurplePlugin * plugin)
{
}

PURPLE_INIT_PLUGIN(gtalk_shared_status, init_plugin, info);



// 			purple_account_set_status(account, map_status(FROM_GOOGLE_TO_PURPLE, get_show(query)), TRUE, "message", get_status(query), NULL);

static void
set_account_status(PurpleAccount *account, const char *statusID, const char *statusString)
{
    @autoreleasepool {
        AIStatus *currentStatus;
        CBPurpleAccount	*aIaccount = accountLookup(account);
        if(![aIaccount isKindOfClass:[AIPurpleGTalkAccount class]]) {
            return;
        }

        PurpleStatusPrimitive status = purple_primitive_get_type_from_id(statusID);

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

        if(statusString != NULL) {
            AIStatus *newStatus = NULL;
            NSString *statusNSString = [NSString stringWithUTF8String:statusString];
            for(AIStatus *statusItem in [adium.statusController flatStatusSet]) {
                if ([statusItem statusType] == [currentStatus statusType] &&
                    [[statusItem statusMessageString] isEqualToString:statusNSString]) {
                    newStatus = statusItem;
                    break;
                }
            }
            if(newStatus == NULL) {
                newStatus = [AIStatus statusOfType:[currentStatus statusType]];
                [newStatus setStatusMessageString:statusNSString];
                [newStatus setTitle:statusNSString];
                [adium.statusController addStatusState:newStatus];
            }
            currentStatus = newStatus;
        }

        NSLog(@"Message: %s", statusString);

        if([aIaccount statusType] != [currentStatus statusType] || [aIaccount statusMessageString] != [currentStatus statusMessageString]) {
                        [aIaccount setStatusState:currentStatus];
        }
    }
}
