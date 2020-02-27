/*Sample script of the class system. Classes can be easily added using the enum. You can set the class description which will show up in the textdraw on
OnPlayerRequestClass and when the player spawns*/

#include <YSI\y_hooks>

new 		gTeam[ MAX_PLAYERS ];

#define     TEAM_NULL                               0

#define 	TEAM_COPS 								1
#define 	COLOR_TEAM_COPS 					0x0079B5FF
#define 	TEAM_SECRET_SERVICE						2
#define 	COLOR_TEAM_SECRET_SERVICE 			0x0079B5FF
#define 	TEAM_SWAT 								3
#define 	COLOR_TEAM_SWAT 					0x33CCFFFF
#define 	TEAM_ARMY 								4
#define 	COLOR_TEAM_ARMY 					0x00FF00FF
#define 	TEAM_FIREFIGHTERS 						5
#define 	COLOR_TEAM_FIREFIGHTERS 			0xFF00E1FF
#define 	TEAM_DRIVERS 							6
#define 	COLOR_TEAM_DRIVERS 					0x00663FFF
#define 	TEAM_CIV                                7
#define 	COLOR_TEAM_CIV						0xFFFFFFFF


enum ePlayerClasses
{
	class_name[25],
	class_description[100],
	class_skin,
	class_teamid,
	class_teamcolor,
	Float:spawn_x,
	Float:spawn_y,
	Float:spawn_z,
	Float:spawn_f
};

new const aPlayerClasses[][ePlayerClasses] =
{
	{"Police Officer", "Hunt down and arrest criminals to keep the streets of Los Santos clean", 266, TEAM_COPS, COLOR_TEAM_COPS, 1576.9141, -1692.2262, 6.2188, 180.0963},
	{"Police Officer", "Hunt down and arrest criminals to keep the streets of Los Santos clean", 265, TEAM_COPS, COLOR_TEAM_COPS, 1576.9141, -1692.2262, 6.2188, 180.0963},
	{"Secret Service", "Collect intelligence information in an effort to maintain the security of the city", 165, TEAM_SECRET_SERVICE, COLOR_TEAM_SECRET_SERVICE, 914.2285,-1003.2111,38.0078,5.3542},
	{"Secret Service", "Collect intelligence information in an effort to maintain the security of the city", 166, TEAM_SECRET_SERVICE, COLOR_TEAM_SECRET_SERVICE, 914.2285,-1003.2111,38.0078,5.3542},
	{"SWAT", "Carry out covert and undercover operations and bring criminals to justice", 285, TEAM_SWAT, COLOR_TEAM_SWAT, 281.2758, -1646.4691, 17.8593, 344.0955},
	{"Los Santos Army", "Use powerful weaponry and machinery to take down Los Santos' most wanted criminals", 287, TEAM_ARMY, COLOR_TEAM_ARMY, 2778.7278,-2410.4207,13.6359,180.4225},
    {"Marine Corp", "Use powerful weaponry and machinery to take down Los Santos' most wanted criminals", 179, TEAM_ARMY, COLOR_TEAM_ARMY, 32.1407,-2436.6592,18.5274,208.8188},
	{"Firefighters", "Respond to calls and protect the public in emergency situations", 277, TEAM_FIREFIGHTERS, COLOR_TEAM_FIREFIGHTERS, 2027.7826,-1404.2111,17.2339,179.8795},
	{"Taxi Driver", "Pick up and drop off customers to their desired destination", 261, TEAM_DRIVERS, COLOR_TEAM_DRIVERS, 1487.9397,-2175.2778,13.6000,89.1229},
    {"Civilian", "Rob stores and escape from law enforcement to show them how you run the streets", 249, TEAM_CIV, COLOR_TEAM_CIV, 0.0, 0.0, 0.0, 0.0}
};

hook OnGameModeInit()
{
    //---------Load Classes
	for(new i = 0; i < sizeof(aPlayerClasses); i ++)
	{
		AddPlayerClass(aPlayerClasses[i][class_skin], aPlayerClasses[i][spawn_x], aPlayerClasses[i][spawn_y], aPlayerClasses[i][spawn_z], aPlayerClasses[i][spawn_f], 0, 0, 0, 0, 0, 0);
	}
	return 1;
}

hook OnPlayerConnect(playerid)
{
	PreloadAnimLib(playerid,"BOMBER"); //using a function
	PreloadAnimLib(playerid,"RAPPING");
	PreloadAnimLib(playerid,"SHOP");
	PreloadAnimLib(playerid,"BEACH");
	PreloadAnimLib(playerid,"SMOKING");
	PreloadAnimLib(playerid,"FOOD");
	PreloadAnimLib(playerid,"ON_LOOKERS");
	PreloadAnimLib(playerid,"DEALER");
	PreloadAnimLib(playerid,"CRACK");
	PreloadAnimLib(playerid,"CARRY");
	PreloadAnimLib(playerid,"COP_AMBIENT");
	PreloadAnimLib(playerid,"PARK");
	PreloadAnimLib(playerid,"INT_HOUSE");
	PreloadAnimLib(playerid,"FOOD");
	PreloadAnimLib(playerid,"PED");
	PreloadAnimLib(playerid,"ROB_BANK");
	PreloadAnimLib(playerid,"DANCING");
	PreloadAnimLib(playerid,"BENCHPRESS");
	PreloadAnimLib(playerid,"GANGS");
	PreloadAnimLib(playerid,"GHANDS");
	PreloadAnimLib(playerid,"SPRAYCAN");
	return 1;
}

hook OnPlayerRequestClass(playerid, classid)
{
	for(new i = 0; i < sizeof(aPlayerClasses); i ++)
	{
	    if( classid == i )
		{
		    gTeam[ playerid ] = aPlayerClasses[i][class_teamid];

			new environment_id = random(sizeof(aClassEnvironments)); //Credits to Kevin for his random camera angle cords

			SetPlayerPos(playerid, aClassEnvironments[environment_id][class_environment_x], aClassEnvironments[environment_id][class_environment_y], aClassEnvironments[environment_id][class_environment_z]);
			SetPlayerFacingAngle(playerid, aClassEnvironments[environment_id][class_environment_angle]);

			SetPlayerCameraLookAt(playerid, aClassEnvironments[environment_id][class_environment_x], aClassEnvironments[environment_id][class_environment_y], aClassEnvironments[environment_id][class_environment_z]);
			SetPlayerCameraPos(playerid, aClassEnvironments[environment_id][class_environment_x] + (5 * floatsin(-aClassEnvironments[environment_id][class_environment_angle], degrees)), aClassEnvironments[environment_id][class_environment_y] + (5 * floatcos(-aClassEnvironments[environment_id][class_environment_angle], degrees)), aClassEnvironments[environment_id][class_environment_z]);

            new selected = RandomBetween(0, 9);
            switch(selected)
			{
				case 0: ApplyAnimation(playerid, "BENCHPRESS", "GYM_BP_CELEBRATE", 4.1, 1, 1, 1, 0, 0, 1);
				case 1: ApplyAnimation(playerid, "DANCING", "DAN_LOOP_A", 4.1, 1, 1, 1, 0, 0, 1);
				case 2: ApplyAnimation(playerid, "DANCING", "DNCE_M_A", 4.1, 1, 1, 1, 0, 0, 1);
				case 3: ApplyAnimation(playerid, "DANCING", "DNCE_M_B", 4.1, 1, 1, 1, 0, 0, 1);
				case 4: ApplyAnimation(playerid, "DANCING", "DNCE_M_C", 4.1, 1, 1, 1, 0, 0, 1);
				case 5: ApplyAnimation(playerid, "DANCING", "DNCE_M_D", 4.1, 1, 1, 1, 0, 0, 1);
				case 6: ApplyAnimation(playerid, "DANCING", "DNCE_M_E", 4.1, 1, 1, 1, 0, 0, 1);
				case 7: ApplyAnimation(playerid, "GANGS", "PRTIAL_GNGTLKA", 4.1, 1, 1, 1, 0, 0, 1);
				case 8: ApplyAnimation(playerid, "GHANDS", "GSIGN5", 4.1, 1, 1, 1, 0, 0, 1);
				case 9: ApplyAnimation(playerid, "SPRAYCAN", "spraycan_full", 4.1, 1, 1, 1, 0, 0, 1);
			}
			ShowClassTextdraw(playerid, aPlayerClasses[i][class_teamcolor], aPlayerClasses[i][class_name], aPlayerClasses[i][class_description]);
		}
	}
	return 1;
}

hook OnPlayerSpawn(playerid)
{
    if(gTeam[playerid] != TEAM_NULL)
	{
		new description[100], commands[30], str[200], name[30];
	 	for(new i = 0; i < sizeof(aPlayerClasses); i ++)
	    {
	        if( aPlayerClasses[i][class_teamid] == gTeam[playerid] )
			{
			    format(description, sizeof(description), "%s", aPlayerClasses[i][class_description]);
			    format(name, sizeof(name), "%s", aPlayerClasses[i][class_name]);
			}
		}

		upper(name);
		format(str, sizeof(str), "You have spawned as a %s.", name);
		SendClientMessage(playerid, -1, str);

		description[0] = tolower(description[0]);
		format(str, sizeof(str), "Your role is to %s.", description);
		SendClientMessage(playerid, -1, str);

		SendClientMessage(playerid, -1, "You can view your job specific commands using /commands.");
	}
	return 1;
}
