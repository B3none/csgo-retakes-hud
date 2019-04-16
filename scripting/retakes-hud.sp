#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required

Handle cvar_autoplant_enabled = null;
Handle cvar_retakes_enabled = null;
Handle cvar_plugin_enabled = null;

Handle cvar_red = null;
Handle cvar_green = null;
Handle cvar_blue = null;
Handle cvar_fadein = null;
Handle cvar_fadeout = null;
Handle cvar_xcord = null;
Handle cvar_ycord = null;
Handle cvar_holdtime = null;
Handle cvar_showterrorists = null;

bool autoplantEnabled = false;
bool retakesEnabled = false;
bool pluginEnabled;

bool showTerrorists;
int red;
int green;
int blue;
float fadein;
float fadeout;
float holdtime;
float xcord;
float ycord;

enum //Bombsites
{
    BOMBSITE_INVALID = -1,
    BOMBSITE_A = 0,
    BOMBSITE_B = 1
}

int bomber = -1;
int bombsite = BOMBSITE_INVALID;

public Plugin myinfo =
{
    name = "[Retakes] Bombsite HUD",
    author = "B3none",
    description = "Displays the current bombsite in a HUD message. Will work with all versions of the Retakes plugin.",
    version = "2.3.0",
    url = "https://github.com/b3none/retakes-hud"
};

public void OnPluginStart()
{
    cvar_autoplant_enabled = FindConVar("sm_autoplant_enabled");
    cvar_retakes_enabled = FindConVar("sm_retakes_enabled");
    cvar_plugin_enabled = CreateConVar("sm_retakes_hud_enabled", "1", "Should we display the HUD?", _, true, 0.0, true, 1.0);
    
    cvar_red = CreateConVar("sm_retakes_hud_red", "255", "How much red would you like?", _, true, 0.0, true, 255.0);
    cvar_green = CreateConVar("sm_retakes_hud_green", "255", "How much green would you like?", _, true, 0.0, true, 255.0);
    cvar_blue = CreateConVar("sm_retakes_hud_blue", "255", "How much blue would you like?", _, true, 0.0, true, 255.0);
    cvar_fadein = CreateConVar("sm_retakes_hud_fade_in", "0.5", "How long would you like the fade in animation to last in seconds?", _, true, 0.0);
    cvar_fadeout = CreateConVar("sm_retakes_hud_fade_out", "0.5", "How long would you like the fade out animation to last in seconds?", _, true, 0.0);
    cvar_holdtime = CreateConVar("sm_retakes_hud_time", "5.0", "Time in seconds to display the HUD.", _, true, 1.0);
    cvar_xcord = CreateConVar("sm_retakes_hud_position_x", "0.42", "The position of the HUD on the X axis.", _, true, 0.0);
    cvar_ycord = CreateConVar("sm_retakes_hud_position_y", "0.3", "The position of the HUD on the Y axis.", _, true, 0.0);
    cvar_showterrorists = CreateConVar("sm_retakes_hud_showterrorists", "1", "Should we display HUD to terrorists?", _, true, 0.0, true, 1.0);

    AutoExecConfig(true, "retakes_hud");
    
    HookEvent("round_start", Event_OnRoundStart, EventHookMode_Pre);
}

public void OnConfigsExecuted()
{
    if (cvar_autoplant_enabled != null)
    {
        autoplantEnabled = GetConVarBool(cvar_autoplant_enabled);
    }
    
    if (cvar_retakes_enabled != null)
    {
        retakesEnabled = GetConVarBool(cvar_retakes_enabled);
    }
    
    pluginEnabled = GetConVarBool(cvar_plugin_enabled);
    showTerrorists = GetConVarBool(cvar_showterrorists);
    red = GetConVarInt(cvar_red);
    green = GetConVarInt(cvar_green);
    blue = GetConVarInt(cvar_blue);
    fadein = GetConVarFloat(cvar_fadein);
    fadeout = GetConVarFloat(cvar_fadeout);
    holdtime = GetConVarFloat(cvar_holdtime);
    xcord = GetConVarFloat(cvar_xcord);
    ycord = GetConVarFloat(cvar_ycord);
}

public void Event_OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	if (!pluginEnabled || !retakesEnabled || IsWarmup())
	{
		return;
	}
	
	bomber = GetBomber();
	
	if (!IsValidClient(bomber))
	{
		return;
	}
	
	bombsite = GetNearestBombsite(bomber);
	
	if (bombsite != BOMBSITE_INVALID)
	{
		CreateTimer(1.0, displayHud);
	}
}

public Action displayHud(Handle timer)
{
    char bombsiteStr[1];
    bombsiteStr = bombsite == BOMBSITE_A ? "A" : "B";

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i))
        {
            int clientTeam = GetClientTeam(i);
            
            SetHudTextParams(xcord, ycord, holdtime, red, green, blue, 255, 0, 0.25, fadein, fadeout);
            
            if (!autoplantEnabled && i == bomber)
            {
                ShowHudText(i, 5, "Plant the bomb!");
            }
            else if (clientTeam == CS_TEAM_CT || (clientTeam == CS_TEAM_T && showTerrorists))
            {
                ShowHudText(i, 5, "%s Bombsite: %s", clientTeam == CS_TEAM_T ? "Defend" : "Retake", bombsiteStr);
            }
        }
    }
}

stock bool IsWarmup()
{
	return GameRules_GetProp("m_bWarmupPeriod") == 1;
}

stock int GetBomber()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && HasBomb(i))
		{
			return i;
		}
	}
	
	return -1;
}

stock bool HasBomb(int client)
{
	return GetPlayerWeaponSlot(client, 4) != -1;
}

stock int GetNearestBombsite(int client)
{
	float pos[3];
	GetClientAbsOrigin(client, pos);
	
	int playerManager = FindEntityByClassname(INVALID_ENT_REFERENCE, "cs_player_manager");
	if (playerManager == INVALID_ENT_REFERENCE)
	{
		return BOMBSITE_INVALID;
	}
	
	float aCenter[3], bCenter[3];
	GetEntPropVector(playerManager, Prop_Send, "m_bombsiteCenterA", aCenter);
	GetEntPropVector(playerManager, Prop_Send, "m_bombsiteCenterB", bCenter);
	
	float aDist = GetVectorDistance(aCenter, pos, true);
	float bDist = GetVectorDistance(bCenter, pos, true);
	
	return (aDist < bDist) ? BOMBSITE_A : BOMBSITE_B;
}

stock bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client);
}
