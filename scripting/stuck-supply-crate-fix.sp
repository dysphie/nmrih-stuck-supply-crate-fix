#include <sourcemod>
#include <sdktools>

#define NMR_FL_ATCONTROLS 128

public Plugin myinfo = {
    name        = "Don't Freeze Supply Crate Users",
    author      = "Dysphie",
    description = "",
    version     = "1.0.0",
    url         = ""
};

#define NMR_MAXPLAYERS 9

Handle fnEndUseForPlayer;

ConVar cvMaxDist;

public void OnPluginStart()
{
	LoadTranslations("stuck-supply-crate-fix.phrases");
	GameData gd = new GameData("stuck-supply-crate-fix.games");

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gd, SDKConf_Signature, "CItem_InventoryBox::EndUseForPlayer");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer); 
	fnEndUseForPlayer = EndPrepSDKCall();
	if (!fnEndUseForPlayer) {
		SetFailState("Failed to set up SDKCall for CItem_InventoryBox::EndUseForPlayer");
	}

	delete gd;

	cvMaxDist = CreateConVar("sv_supply_crate_max_use_dist", "150", 
		"Maximum distance at which players can interact with supply crates");

	AutoExecConfig(true, "stuck-supply-crate-fix");

	HookUserMessage(GetUserMessageId("ItemBoxOpen"), OnItemBoxOpen);
	AddCommandListener(OnTakeItems, "takeitems");
}

Action OnTakeItems(int client, const char[] command, int argc)
{
	if (!IsValidClient(client)) {
		return Plugin_Continue;
	}

	char cmdIndex[11];
	GetCmdArg(1, cmdIndex, sizeof(cmdIndex));
	int box = StringToInt(cmdIndex);

	if (IsValidEdict(box) && ClassnameEquals(box, "item_inventory_box"))
	{
		if (!CouldInteractWithBox(client, box)) 
		{
			PrintCenterText(client, "%t", "You are too far away");
			return Plugin_Stop;
		}
	}

	return Plugin_Continue;
}

Action OnItemBoxOpen(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	int box = msg.ReadShort();
	if (!IsValidEdict(box) || !ClassnameEquals(box, "item_inventory_box")) {
		return Plugin_Continue;
	}

	for (int i = 0; i < playersNum; i++)
	{
		int client = players[i];
		if (IsValidClient(client))
		{
			UnfreezePlayer(client);

			DataPack data;
			CreateDataTimer(0.1, Timer_CheckIsInRange, data, TIMER_REPEAT);
			data.WriteCell(EntIndexToEntRef(box));
			data.WriteCell(GetClientSerial(client));
		}
	}

	return Plugin_Continue;
}

Action Timer_CheckIsInRange(Handle timer, DataPack data)
{
	data.Reset();

	int box = EntRefToEntIndex(data.ReadCell());
	int client = GetClientFromSerial(data.ReadCell());

	if (!IsValidEntity(box) || !client || !IsClientInGame(client)) {
		return Plugin_Stop;
	}

	if (!CouldInteractWithBox(client, box))
	{
		ClientCommand(client, "closeitembox %d", box);
		SDKCall(fnEndUseForPlayer, box, client);
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

int CouldInteractWithBox(int client, int box)
{
	float boxPos[3];
	GetEntPropVector(box, Prop_Data, "m_vecAbsOrigin", boxPos);

	float eyePos[3];
	GetClientEyePosition(client, eyePos);

	return GetVectorDistance(eyePos, boxPos) <= cvMaxDist.FloatValue;
}

bool ClassnameEquals(int entity, const char[] classname)
{
	char buffer[64];
	GetEntityClassname(entity, buffer, sizeof(buffer));
	return StrEqual(buffer, classname);
}

bool IsValidClient(int client)
{
	return 0 < client <= MaxClients && IsClientInGame(client);
}

void UnfreezePlayer(int client)
{
	int curFlags = GetEntProp(client, Prop_Send, "m_fFlags");
	SetEntProp(client, Prop_Send, "m_fFlags", curFlags & ~NMR_FL_ATCONTROLS);
}