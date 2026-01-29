new Float:g_bLastUsed[MAX_PLAYERS];

public bot_menu(id)
{
	if(get_gametime() - g_bLastUsed[id] < 20.0 && !(get_user_flags(id) & ADMIN_BAN)){
		client_print_color(id, print_team_red, "^4[BOT] ^1You must wait ^4[%.2f] ^1seconds to use the command again.", 20.0-(get_gametime() - g_bLastUsed[id]));
		return PLUGIN_HANDLED;
	}

	new menu = menu_create( "\r[FWO] \d- \wBot Menu:", "bot_handle" );
	new text[256];	
	menu_additem( menu, "\wStart/Restart Bot", "1");
	
	menu_additem( menu, "\wPause/Unpause Bot", "2", ADMIN_BAN);
	format(text, charsmax(text), "\wReplay Speed: %.2fx", 1.0 / float(g_BotData[slow]));
	menu_additem( menu, text, "3", ADMIN_BAN);
	menu_additem( menu, "\wFast forward", "4", ADMIN_BAN);	
	menu_additem( menu, "\wFast backward", "5", ADMIN_BAN);
	menu_additem( menu, "\wBot Sources", "6");
	
	menu_setprop( menu, MPROP_EXIT, MEXIT_ALL );
	menu_display( id, menu, 0 );
	
	return PLUGIN_HANDLED;
}

public bot_handle(id, menu, item)
{
	if( item == MENU_EXIT ) 
	{ 
		menu_destroy( menu ); 
		return PLUGIN_HANDLED; 
	} 
	switch( item )
	{
		case 0:
		{		
			SetCurrentReplay(g_BotData[current_source])
			g_BotData[current_frame] = 0;
			g_BotData[paused] = false;
		}
		case 1:
		{
			//g_BotData[paused] = !g_BotData[paused];
			g_BotData[paused] ^= true; // Toggle paused state (using ^= true to avoid compiler warning 226)

		}
		case 2:
		{		
			g_BotData[slow] *= 2;
			if(g_BotData[slow] > 4)
				g_BotData[slow] = 1;
		}
		case 3:
		{
			g_BotData[current_frame] += 157;
			if(g_BotData[current_frame] > GetReplaySize() - 1)
				g_BotData[current_frame] = 0;
		}
		case 4:
		{
			g_BotData[current_frame] -= 157;
			if(g_BotData[current_frame] < 0)
				g_BotData[current_frame] = 0;
		}
		case 5:
		{
			new iReturn;
			ExecuteForward(g_fwdOpenSourcesMenu, iReturn, id, g_Replays);

			return PLUGIN_CONTINUE; 
		}
	}
	g_bLastUsed[id] = get_gametime();
	bot_menu(id)
	
	return PLUGIN_HANDLED; 
}