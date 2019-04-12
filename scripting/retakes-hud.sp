#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required

Handle cvar_autoplant_enabled = null;
Handle cvar_red = null;
Handle cvar_green = null;
Handle cvar_blue = null;
Handle cvar_fadein = null;
Handle cvar_fadeout = null;
Handle cvar_xcord = null;
Handle cvar_ycord = null;
Handle cvar_holdtime = null;
Handle cvar_showterrorists = null;

bool autoplantEnabled;
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
    version = "2.2.4",
    url = "https://github.com/b3none/retakes-hud"
};

public void OnPluginStart()
{
    cvar_autoplant_enabled = FindConVar("sm_autoplant_enabled");
    cvar_red = CreateConVar("sm_redhud", "255");
    cvar_green = CreateConVar("sm_greenhud", "255");
    cvar_blue = CreateConVar("sm_bluehud", "255");
    cvar_fadein = CreateConVar("sm_fadein", "0.5");
    cvar_fadeout = CreateConVar("sm_fadeout", "0.5");
    cvar_holdtime = CreateConVar("sm_holdtime", "5.0");
    cvar_xcord = CreateConVar("sm_xcord", "0.42");
    cvar_ycord = CreateConVar("sm_ycord", "0.3");
    cvar_showterrorists = CreateConVar("sm_showterrorists", "1", "Should we display HUD to terrorists?");

    AutoExecConfig(true, "retakehud");
    HookEvent("round_start", Event_OnRoundStart);
}

public void OnConfigsExecuted()
{
    autoplantEnabled = false;
	
    if (cvar_autoplant_enabled != null)
    {
        autoplantEnabled = GetConVarBool(cvar_autoplant_enabled);
    }

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
	bomber = GetBomber();
	
	if (IsValidClient(bomber))
	{
		bombsite = GetNearestBombsite(bomber);
		
		CreateTimer(1.0, displayHud);
	}
}

public Action displayHud(Handle timer)
{
    if (IsWarmup() || bombsite == BOMBSITE_INVALID)
    {
        return;
    }
    
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
	
	if (aDist < bDist)
	{
		return BOMBSITE_A;
	}
	
	return BOMBSITE_B;
}

stock bool IsValidClient(int client)
{
    return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client);
}
