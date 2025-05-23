#include <amxmodx>
#include <replays>
#include <record_runs>
#include <timer>

#define PLUGIN "Timer Records Menu"
#define VERSION "1.0"
#define AUTHOR "MrShark45"

#define MAX_CATEGORIES 64

enum eMenuOption{
	bool:eMenuBhop,
	bool:eMenuGravity
}

enum eCategoryInfo{
	eID,
	bool:eEnabled = false,
	eRuleFps,
	Float:eRuleGravity,
	eRuleMaxSpeed,
	Float:eRuleGroundSpeed,
	eRuleStartSpeed,
	eRuleAutoBhop,
	eRuleSpeedrun,
	eRuleHook,
	eRecordTime,
	eDisplay[32]
};

new Array:g_aSourcesArray;
new Array:g_aCategories;

enum eCategorySet{
	bool:eBhop,
	bool:eSR,
	bool:eOthers
}

enum eCategoryGravitySubset{
	bool:eNormal,
	bool:eLowGravity
}

new g_bCategory[eCategorySet];
new g_iCategoryTypes;

new g_bCategoryGravity[eCategoryGravitySubset];
new g_iCategoryGravityTypes;

new g_iMenuSelect[MAX_PLAYERS][eMenuOption];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
}


public timer_db_loaded()
{
	g_aCategories = get_categories_array();
	CheckCategoriesEnabled();
}

public record_runs_open_menu(id, Array:array)
{
	g_aSourcesArray = array;
	ShowSourcesMenu(id);
}

public CheckCategoriesEnabled()
{
	new cat[eCategoryInfo];
	for(new i=0;i<ArraySize(g_aCategories);i++){
		ArrayGetArray(g_aCategories, i, cat);

		if(!cat[eRuleSpeedrun])
			g_bCategory[eBhop] = true;
		
		if(cat[eRuleSpeedrun])
			g_bCategory[eSR] = true;

		if(!cat[eRuleAutoBhop])
			g_bCategory[eOthers] = true;

		if(cat[eRuleGravity] > 0.0)
			g_bCategoryGravity[eNormal] = true;

		if(cat[eRuleGravity] == 0.0)
			g_bCategoryGravity[eLowGravity] = true;
	}

	g_iCategoryTypes = _:g_bCategory[eBhop] + _:g_bCategory[eSR] + _:g_bCategory[eOthers];
	g_iCategoryGravityTypes = _:g_bCategoryGravity[eNormal] + _:g_bCategoryGravity[eLowGravity];
	
	//server_print("CategoryTypes ENABLED: %d", g_iCategoryTypes);
	//server_print("CategoryGravityTypes ENABLED: %d", g_iCategoryGravityTypes);
}


public ShowSourcesMenu(id){
	if(g_iCategoryTypes == 1)
	{
		g_iMenuSelect[id][eMenuBhop] = g_bCategory[eBhop];
		SourcesGravityMenu(id);

		return PLUGIN_CONTINUE;
	}

	new szTitle[128];
	formatex(szTitle, charsmax(szTitle), "\r[FWO] \d- \wSources Menu");

	new menu = menu_create(szTitle, "sources_select_handler");

	if(g_bCategory[eBhop])
		menu_additem(menu, "\wBhop", "1", 0);

	if(g_bCategory[eSR])
		menu_additem(menu, "\wSpeedrun", "2", 0);

	if(g_bCategory[eOthers])
		menu_additem(menu, "\wOthers", "3", 0);

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);

	menu_display(id, menu, 0);

	return PLUGIN_CONTINUE;
}

public sources_select_handler(id, menu, item){
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}

	new info[32];
	menu_item_getinfo(menu, item, _, info, charsmax(info), _, _, _);

	new set = str_to_num(info);

	switch(set)
	{
		case 1:
		{
			g_iMenuSelect[id][eMenuBhop] = true;
			SourcesGravityMenu(id);
		}
		case 2:
		{
			g_iMenuSelect[id][eMenuBhop] = false;
			SourcesGravityMenu(id);
		}
		case 3:
			SourcesOtherMenu(id);
	}

	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public SourcesGravityMenu(id){
	if(g_iCategoryGravityTypes == 1)
	{
		g_iMenuSelect[id][eMenuGravity] = !g_bCategoryGravity[eNormal];
		SelectSource(id);

		return PLUGIN_CONTINUE;
	}

	new szTitle[128];
	formatex(szTitle, charsmax(szTitle), "\r[FWO] \d- \wSources Menu");

	new menu = menu_create(szTitle, "surces_gravity_menu_handler");

	menu_additem(menu, "\wNormal", "", 0);
	menu_additem(menu, "\yGravity", "", 0);

	menu_setprop(menu, MPROP_EXITNAME, "Back");

	menu_display(id, menu, 0);

	return PLUGIN_CONTINUE;
}

public surces_gravity_menu_handler(id, menu, item){
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		if(g_iCategoryTypes > 1)
			ShowSourcesMenu(id);
		return PLUGIN_CONTINUE;
	}

	switch(item)
	{
		case 0:
		{
			g_iMenuSelect[id][eMenuGravity] = false;
			SelectSource(id);
		}
		case 1:
		{
			g_iMenuSelect[id][eMenuGravity] = true;
			SelectSource(id);
		}
	}

	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public SourcesOtherMenu(id){
	new szTitle[128];
	formatex(szTitle, charsmax(szTitle), "\r[FWO] \d- \wOthers Cat");

	new menu = menu_create(szTitle, "sources_other_menu_handler");

	menu_additem(menu, "\wKZ", "", 0);

	menu_setprop(menu, MPROP_EXITNAME, "Back");

	menu_display(id, menu, 0);

	return PLUGIN_CONTINUE;
}

public sources_other_menu_handler(id, menu, item){
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		ShowSourcesMenu(id);
		return PLUGIN_CONTINUE;
	}

	switch(item)
	{
		case 0:
		{
			new source[eHeader];
			new cat[eCategoryInfo];
			for(new i=0;i<ArraySize(g_aSourcesArray);i++){
				ArrayGetArray(g_aSourcesArray, i, source);

				get_source_category(source[hInfo], cat);
				if(cat[eRuleAutoBhop]) continue;

				set_current_replay(i);

				menu_destroy(menu);
				return PLUGIN_HANDLED;
			}

			
		}
	}

	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public SelectSource(id){
	new szTitle[128];
	formatex(szTitle, charsmax(szTitle), "\r[FWO] \d- \wSources Menu");

	new menu = menu_create(szTitle, "source_handler");

	new source[eHeader], item[64], itemInfo[4];
	new cat[eCategoryInfo];
	new szTime[32];
	for(new i=0;i<ArraySize(g_aSourcesArray);i++){
		ArrayGetArray(g_aSourcesArray, i, source);
		get_source_category(source[hInfo], cat);
		

		if(!cat[eRuleAutoBhop]) continue; // Exclude KZ Category entirely
		
		// Continue if the selected menu doesn't match the category type (Bhop or Speedrun)
		if (g_iMenuSelect[id][eMenuBhop] == bool:cat[eRuleSpeedrun]) continue;

		// Continue if the selected Gravity menu doesn't match the category's gravity rule
		if (g_iMenuSelect[id][eMenuGravity] == (cat[eRuleGravity] > 0.0)) continue;

		get_formated_time(source[hTime], szTime, charsmax(szTime));
		format(item, charsmax(item), "\r%s \w- %s [\y%s\w]", source[hInfo], source[hName], szTime);
		format(itemInfo, charsmax(itemInfo), "%d", i);

		menu_additem(menu, item, itemInfo, 0);
	}

	if(menu_items(menu) < 10 && menu_items(menu) > 7)
	{	
		for(new i=menu_items(menu);i<8;i++)
			menu_additem(menu, "", "-3");
		
		menu_additem(menu, "^n", "-3");
		menu_additem(menu, "Back", "-3");
		menu_setprop(menu, MPROP_PERPAGE, 0);
	}

	menu_setprop(menu, MPROP_EXITNAME, "Back");

	menu_display(id, menu, 0);

	return PLUGIN_CONTINUE;
	
}

public source_handler(id, menu, item){
	new itemInfo[4], szItemName[12];
	new _access, item_callback;

	menu_item_getinfo( menu, item, _access, itemInfo, charsmax( itemInfo ), szItemName ,charsmax( szItemName ), item_callback );

	if(str_to_num(itemInfo) == -3 || item == MENU_EXIT)
	{
		menu_destroy(menu);
		if(g_iCategoryGravityTypes > 1)
			SourcesGravityMenu(id);
		else if(g_iCategoryTypes > 1)
			ShowSourcesMenu(id);
		return PLUGIN_CONTINUE;
	}

	new sourceId = str_to_num(itemInfo)
	set_current_replay(sourceId);
	
	menu_destroy(menu);
	ShowSourcesMenu(id);

	return PLUGIN_HANDLED;
}

public get_source_category(name[], cat[eCategoryInfo]){
	// Bad fix I know
	replace(name, 31, "[", "");
	replace(name, 31, "]", "");

	for(new i=0;i<ArraySize(g_aCategories);i++)
	{
		ArrayGetArray(g_aCategories, i, cat);
		if(equali(cat[eDisplay], name))
			break;
	}
}

stock get_formated_time(iTime, szTime[], size){
	formatex(szTime, size, "%d:%02d.%03ds", iTime/60000, (iTime/1000)%60, iTime%1000);
}