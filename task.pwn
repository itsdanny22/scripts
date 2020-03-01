/*
LS-RCR Developer Application Task

Tables:

- group_data
- group_participants
- group_ranks

Commands:

- /pmg
- /acceptinvite
- /debug (testing purposes)
- /debug2 (testing purposes)
- /debug3 (testing purposes)

*/

//---------------- Includes

#include 	<a_samp>
#include	<YSI\y_iterate>
#include 	<a_mysql>
#include 	<izcmd>
#include    <sscanf2>

//---------------- Definitions

#undef 		MAX_PLAYERS
#define 	MAX_PLAYERS                 100

#define 	MAX_GROUPS          		200
#define     MAX_GROUPS_PER_PLAYER       10
#define     MAX_RANKS                   20

#define     MAX_RANK_NAME               24
#define 	MAX_GROUP_NAME      		50

#define     PERMISSION_LEVEL_NONE       0
#define     PERMISSION_LEVEL_MODERATOR  1
#define     PERMISSION_LEVEL_OWNER      2

#define     DIALOG_SELECT_GROUP 		1
#define     DIALOG_GROUP_SETTINGS       2
#define     DIALOG_GROUP_RANK_NAME		3
#define     DIALOG_GROUP_RANK_COLOR		4
#define     DIALOG_GROUP_RANK_MANAGE	5
#define     DIALOG_GROUP_SET_RANK 		6

#define 	strcat_format(%0,%1,%2)		format(%0[strlen(%0)], %1 - strlen(%0), %2)

//---------------- Enums

enum eGroupData
{
	group_id,
	group_name[MAX_GROUP_NAME]
}
new aGroupData[MAX_GROUPS][eGroupData];

enum eParticipantData
{
	participant_id,
	participant_name[MAX_PLAYER_NAME],
	participant_group_id,
	participant_rank,
	participant_muted,
	participant_mute_time
}
new aParticipantData[MAX_PLAYERS][MAX_GROUPS_PER_PLAYER][eParticipantData];

enum eRankData
{
    rank_id,
    rank_name[MAX_RANK_NAME],
    rank_color[7],
	rank_permission_level
};
new aRankData[MAX_GROUPS][MAX_RANKS][eRankData];

//---------------- Variables

new	MySQL:mysql,
	groupSelected[MAX_PLAYERS] = -1,
	invite[MAX_PLAYERS];
	
//---------------- Main Callbacks

main()
{

}

public OnGameModeInit()
{
	//Connection to the database
 	mysql_log(ALL);
	if ( mysql_errno( ( mysql = mysql_connect("127.0.0.1", "root", "", "tasks" ) ) ) ){
		print( "Failure to connect to MySQL database" );
	} else {
		print( "Connection to database is successful" );
	}
	
	//Load group data
	mysql_tquery(mysql, "SELECT * FROM `group_data`", "OnGroupDataLoad", "");
	mysql_tquery(mysql, "SELECT * FROM `group_ranks`", "OnGroupRankLoad", "");
	
	//Class
    AddPlayerClass(265,1958.3783,1343.1572,15.3746,270.1425,0,0,0,0,-1,-1);
    
    //Preparing ranks
    for(new z = 0; z < MAX_GROUPS; z++)
	{
	    for(new i = 0; i < MAX_RANKS; i++)
		{
		    aRankData[z][i][rank_id] = -1;
		}
	}
	return 1;
}

public OnPlayerConnect(playerid)
{
	//Preparing variables
	invite[playerid] = -1;
	groupSelected[playerid] = -1;
	
	for(new z = 0; z < MAX_GROUPS_PER_PLAYER; z++)
	{
	    new name[MAX_PLAYER_NAME];
		aParticipantData[playerid][z][participant_id] = -1;
	    aParticipantData[playerid][z][participant_name] = name;
	    aParticipantData[playerid][z][participant_group_id] = -1;
	    aParticipantData[playerid][z][participant_rank] = -1;
	    aParticipantData[playerid][z][participant_muted] = -1;
   	 	aParticipantData[playerid][z][participant_mute_time] = -1;
	}
	
	//Load Player Info
	new query[128];
	
	mysql_format(mysql, query, sizeof(query), "SELECT * FROM `group_participants` where `playername` = '%s'", GetName(playerid));
  	mysql_tquery(mysql, query, "OnParticipantDataLoad", "d", playerid);
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    //Preparing variables
	invite[playerid] = -1;
	groupSelected[playerid] = -1;
    for(new z = 0; z < MAX_GROUPS_PER_PLAYER; z++)
	{
	    new name[MAX_PLAYER_NAME];
		aParticipantData[playerid][z][participant_id] = -1;
	    aParticipantData[playerid][z][participant_name] = name;
	    aParticipantData[playerid][z][participant_group_id] = -1;
	    aParticipantData[playerid][z][participant_rank] = -1;
     	aParticipantData[playerid][z][participant_muted] = -1;
   	 	aParticipantData[playerid][z][participant_mute_time] = -1;
	}
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	new str[300];
	//Set Player Rank
 	if( dialogid == DIALOG_GROUP_SET_RANK )
	{
        if(response)
        {
            new counter = -1;
            new id = groupSelected[playerid];
			if( id != -1 )
			{
		        for(new z = 0; z < MAX_RANKS; z++)
				{
				    if(aRankData[id][z][rank_id] > 0)
				    {
				        counter++;
					    if(counter == listitem)
					    {
					        new userid = GetPVarInt(playerid, "set_rank_playerid");

	        				for(new i = 0; i < MAX_GROUPS_PER_PLAYER; i++)
							{
							    if(aParticipantData[userid][i][participant_group_id] == groupSelected[playerid])
							    {
                                    aParticipantData[userid][i][participant_rank] = z;
							    }
							}
					        
					        format(str, sizeof(str), "%s(%d) has set %s(%d)'s rank to %s", GetName(playerid), playerid, GetName(userid), userid, aRankData[groupSelected[playerid]][z][rank_name] );
							SendMessageToGroup(groupSelected[playerid], str);
					        
					        mysql_format(mysql, str, sizeof(str), "UPDATE `group_participants` SET `rank`='%d' WHERE `playername`='%s' AND `groupid`='%d'", z, GetName(userid), groupSelected[playerid]);
 							mysql_tquery(mysql, str, "", "");
 							
 							DeletePVar(playerid, "set_rank_playerid");
	        			}
				    }
				}
			}
		}
	}
	//Modifiying Rank Names
    if( dialogid == DIALOG_GROUP_SETTINGS )
	{
		if(response)
		{
		    switch(listitem)
		    {
		        case 0:
		        {
					new id = groupSelected[playerid];
					if( id != -1 )
					{
                        format(str, sizeof(str), "ID\tName\tPermission Level\n");
						for(new z = 0; z < MAX_RANKS; z++)
						{
						    if(aRankData[id][z][rank_id] >= 0)
						    {
						        strcat_format(str, sizeof(str), "{FFFFFF}%d\t{%s}%s\t{FFFFFF}%d\n", z, aRankData[id][z][rank_color], aRankData[id][z][rank_name], GetGroupRankPermissionLevel(id, aRankData[id][z][rank_id]));
							}
						    
						}
					}
					ShowPlayerDialog(playerid, DIALOG_GROUP_RANK_MANAGE, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}Manage Ranks", str, "Select", "Close");
		        }
		    }
		}
	}
    if( dialogid == DIALOG_GROUP_RANK_MANAGE )
    {
        if(response)
        {
            new counter = -1;
            new id = groupSelected[playerid];
			if( id != -1 )
			{
		        for(new z = 0; z < MAX_RANKS; z++)
				{
				    if(aRankData[id][z][rank_id] > 0)
				    {
				        counter++;
					    if(counter == listitem)
					    {
					        SetPVarInt(playerid, "rank_edit_group_id", id);
					        SetPVarInt(playerid, "rank_edit_rank_id", z);

					        new header[50];
					        format(header, sizeof(header), "{FFFFFF}Editing Rank: %s(%d)", aRankData[id][z][rank_name], aRankData[id][z][rank_id]);
					        ShowPlayerDialog(playerid, DIALOG_GROUP_RANK_NAME, DIALOG_STYLE_INPUT, header, "{FFFFFF}Please enter your new desired name for the rank (max 25 characters)", "Continue", "Close");
					    }
				    }
				}
			}
		}
    }
	if( dialogid == DIALOG_GROUP_RANK_NAME )
    {
        if(response)
        {
            if(!strlen(inputtext) || strlen(inputtext) > MAX_RANK_NAME)
			{
			    SendClientMessage(playerid, -1, "Error: Must be between 1 - 25 characters");
			    ShowPlayerDialog(playerid, DIALOG_GROUP_RANK_NAME, DIALOG_STYLE_INPUT, "Edit Rank", "{FFFFFF}Please enter your new desired name for the rank (max 25 characters)", "Continue", "Close");
			}
			else if(IsNumeric(inputtext))
			{
				SendClientMessage(playerid, -1, "Error: Rank name cannot be numeric");
   				ShowPlayerDialog(playerid, DIALOG_GROUP_RANK_NAME, DIALOG_STYLE_INPUT, "Edit Rank", "{FFFFFF}Please enter your new desired name for the rank (max 25 characters)", "Continue", "Close");
			}
			else
			{
			    ShowPlayerDialog(playerid, DIALOG_GROUP_RANK_COLOR, DIALOG_STYLE_INPUT, "{FFFFFF}Edit Rank: Color", "{FFFFFF}Please enter the hex code for your rank name (6 characters).\nUse FFFFFF for white", "Continue", "Close");
	            SetPVarString(playerid, "temp_rank_name", inputtext);
			}
		}
    }
    if( dialogid == DIALOG_GROUP_RANK_COLOR )
    {
        if(response)
        {
            if(!strlen(inputtext) || strlen(inputtext) != 6)
			{
			    SendClientMessage(playerid, -1, "Error: Hex code must be 6 characters.");
			    ShowPlayerDialog(playerid, DIALOG_GROUP_RANK_COLOR, DIALOG_STYLE_INPUT, "{FFFFFF}Edit Rank: Color", "{FFFFFF}Please enter the hex code for your rank name (6 characters).\nUse FFFFFF for white", "Continue", "Close");
			}
			else
			{
			    new name[MAX_RANK_NAME];
				GetPVarString(playerid, "temp_rank_name", name, sizeof(name));
                
	            format(str, sizeof(str), "You have successfully modified rank %s(%d) | Name: %s | Color: #%s", aRankData[GetPVarInt(playerid, "rank_edit_group_id")][GetPVarInt(playerid, "rank_edit_rank_id")][rank_name], GetPVarInt(playerid, "rank_edit_rank_id"), name, inputtext);
	            SendClientMessage(playerid, -1, str);
	            
    			format(aRankData[GetPVarInt(playerid, "rank_edit_group_id")][GetPVarInt(playerid, "rank_edit_rank_id")][rank_name], MAX_RANK_NAME, name);
			    format(aRankData[GetPVarInt(playerid, "rank_edit_group_id")][GetPVarInt(playerid, "rank_edit_rank_id")][rank_color], 7, inputtext);
	            
	            mysql_format(mysql, str, sizeof(str), "UPDATE `group_ranks` SET `rank_name`='%s', `rank_color`='%s' WHERE `rank_group_id`='%d' AND `rank_id`='%d'", name, inputtext, GetPVarInt(playerid, "rank_edit_group_id"), GetPVarInt(playerid, "rank_edit_rank_id"));
 				mysql_tquery(mysql, str, "", "");
 				
 				DeletePVar(playerid, "temp_rank_name");
 				DeletePVar(playerid, "rank_edit_rank_id");
 				DeletePVar(playerid, "rank_edit_group_id");
			}
		}
	}
	//Group Selection
    if( dialogid == DIALOG_SELECT_GROUP )
	{
		if(response)
		{
		    new counter = 0;
	        for(new z = 0; z < MAX_GROUPS_PER_PLAYER; z++)
			{
			    if(aParticipantData[playerid][z][participant_id] != -1)
			    {
			        counter++;
				    if(listitem == 0)
				    {
						groupSelected[playerid] = -1;
						SendClientMessage(playerid, -1, "You have deselected your current group");
						break;
				    }
				    if(counter == listitem)
				    {
				        format(str, sizeof(str), "You have successfully selected [%d] %s as your main messaging group", aGroupData[aParticipantData[playerid][z][participant_group_id]][group_id], aGroupData[aParticipantData[playerid][z][participant_group_id]][group_name]);
				        SendClientMessage(playerid, -1, str);
						groupSelected[playerid] = aGroupData[aParticipantData[playerid][z][participant_group_id]][group_id];
				    }
			    }
			}
		}
	}
	return 1;
}


//---------------- Commands

CMD:debug(playerid)
{
	new str[200];
	for(new z = 0; z < MAX_GROUPS_PER_PLAYER; z++)
	{
	    if(aParticipantData[playerid][z][participant_group_id] > 0)
	    {
	        format(str, sizeof(str), "%d | Participant ID %d | Participant Name %s | Participant Group ID %d | Participant Rank %d", z, aParticipantData[playerid][z][participant_id], aParticipantData[playerid][z][participant_name], aParticipantData[playerid][z][participant_group_id], aParticipantData[playerid][z][participant_rank]);
			SendClientMessage(playerid, -1, str);
	    }
	}
	return 1;
}

CMD:debug2(playerid)
{
	new str[200];
	new id = groupSelected[playerid];
	if( id != -1 )
	{
		for(new z = 0; z < MAX_RANKS; z++)
		{
		    if(aRankData[id][z][rank_id] >= 0)
		    {
		        format(str, sizeof(str), "%d | Group ID %d | Rank Name %s | Rank Color %s | Permission Level %d", z, id, aRankData[id][z][rank_name], aRankData[id][z][rank_color], aRankData[id][z][rank_permission_level]);
				SendClientMessage(playerid, -1, str);
		    }
		}
	}
	return 1;
}

CMD:debug3(playerid)
{
	new rank, str[128];
    for(new z = 0; z < MAX_GROUPS_PER_PLAYER; z++)
	{
	    if(aParticipantData[playerid][z][participant_group_id] == groupSelected[playerid])
	    {
	        rank = aParticipantData[playerid][z][participant_rank];
		}
	}
	format(str, sizeof(str), "Rank %d for Group %s", rank, aGroupData[groupSelected[playerid]][group_name]);
	SendClientMessage(playerid, -1, str);
	return 1;
}

CMD:acceptinvite(playerid, params[])
{
	new id;

    if( sscanf(params, "d", id))
	    return SendClientMessage(playerid, -1, "Usage: /acceptinvite (group id)");

    if(groupSelected[playerid] != -1)
	    return SendClientMessage(playerid, -1, "Error: You must first deselect your messaging group (/pmg select)");
	    
    printf("playerid %d, id %d, group id %d", playerid, id, groupSelected[playerid]);

	if(id != invite[playerid])
	    return SendClientMessage(playerid, -1, "Error: You have not received an invitation to join this group");
	
	new query[200];
    mysql_format(mysql, query, sizeof(query), "INSERT INTO `group_participants` (`playername`, `groupid`, `rank`) VALUES ('%s', '%d', 1)", GetName(playerid), id);
    mysql_tquery(mysql, query, "OnGroupAddedParticipant", "dd", playerid, id);
    
	groupSelected[playerid] = id;
    
	format(query, sizeof(query), "%s(%d) has joined the group using an invitation", GetName(playerid), playerid);
    SendMessageToGroup(id, query);
    
    invite[playerid] = -1;
	return 1;
}

CMD:pmg(playerid, params[])
{
	new string[300], option[10], option2[100];

	if( sscanf(params, "s[10]S()[100]", option, option2))
	{
		SendClientMessage(playerid, -1, "Usage: /pmg (create/select/say/members/leave/kick/invite/mute/unmute/setrank/settings)");
	}
	else if(!strcmp(option, "create", true))
    {
  		if( groupSelected[playerid] != -1 )
	    	return SendClientMessage(playerid, -1, "Error: You must first deselect your messaging group (/pmg select)");

        new groupname[100];

        if( sscanf(params, "s[24]s[100]", params, groupname))
	    	return SendClientMessage(playerid, -1, "Usage: /pmg create (group name)");

		if( strlen(groupname) > MAX_GROUP_NAME )
		    return SendClientMessage(playerid, -1, "Error: Group name too long");
	    	
		if( HasApostrophe(groupname) )
		    return SendClientMessage(playerid, -1, "Error: Your group name cannot contain an apostrophe");

		format(string, sizeof(string), "%s: You have successfully created your own messaging group!", groupname);
		SendClientMessage(playerid, 0xFF0000FF, string);

	    mysql_format(mysql, string, sizeof(string), "INSERT INTO `group_data` (`group_name`) VALUES('%s')", groupname);
		mysql_tquery(mysql, string, "OnGroupCreated", "ds", playerid, groupname);
	}
    else if(!strcmp(option, "select", true))
    {
        strcat_format(string, sizeof(string), "None\n");
        for(new z = 0; z < MAX_GROUPS_PER_PLAYER; z++)
		{
		    if(aParticipantData[playerid][z][participant_group_id] > 0)
		    {
		        strcat_format(string, sizeof(string), "{FFFFFF}[%d] %s\n", aGroupData[aParticipantData[playerid][z][participant_group_id]][group_id], aGroupData[aParticipantData[playerid][z][participant_group_id]][group_name]);
		    }
		}
		ShowPlayerDialog(playerid, DIALOG_SELECT_GROUP, DIALOG_STYLE_LIST, "{FFFFFF}Select Group", string, "Select", "Close");
	}
	else if(!strcmp(option, "say", true))
	{
	    new message[100];
	    
		if( groupSelected[playerid] == -1 )
	    	return SendClientMessage(playerid, -1, "Error: You must first select a messaging group (/pmg select)");
	    	
        if( sscanf(params, "s[24]s[100]", params, message))
	    	return SendClientMessage(playerid, -1, "Usage: /pmg say (message)");

        for(new z = 0; z < MAX_GROUPS_PER_PLAYER; z++)
		{
      		if(aParticipantData[playerid][z][participant_group_id] == groupSelected[playerid])
		    {
		        if( gettime() < (aParticipantData[playerid][z][participant_muted] + aParticipantData[playerid][z][participant_mute_time]))
		            return SendClientMessage(playerid, -1, "Error: You are currently muted from messaging");
			}
		}

        format(string, sizeof(string), "(%s) %s(%d): %s", GetGroupRankName(groupSelected[playerid], GetPlayerGroupRank(playerid)), GetName(playerid), playerid, message);
		SendMessageToGroup(groupSelected[playerid], string);
	}
	else if(!strcmp(option, "members", true))
	{
		if( groupSelected[playerid] == -1 )
	    	return SendClientMessage(playerid, -1, "Error: You must first select a messaging group (/pmg select)");

		SendClientMessage(playerid, -1, "Currently connected group members:");
		
		for(new i = 0; i < MAX_PLAYERS; i++)
	    {
			if(groupSelected[playerid] == groupSelected[i])
			{
			    format(string, sizeof(string), "%s(%d): %s", GetName(i), i, GetGroupRankName(groupSelected[i], GetPlayerGroupRank(i)));
       			SendClientMessage(playerid, -1, string);
			}
	    }
	}
	else if(!strcmp(option, "leave", true))
	{
		if( groupSelected[playerid] == -1 )
	    	return SendClientMessage(playerid, -1, "Error: You must first select a messaging group (/pmg select)");
	    	
        if( GetGroupRankPermissionLevel(groupSelected[playerid], GetPlayerGroupRank(playerid)) == PERMISSION_LEVEL_OWNER )
		    return SendClientMessage(playerid, -1, "Error: You cannot leave your own group");
		    
        format(string, sizeof(string), "%s(%d) has left the group", GetName(playerid), playerid);
		SendMessageToGroup(groupSelected[playerid], string);
		
		RemovePlayerFromGroup(playerid, groupSelected[playerid]);
	}
	else if(!strcmp(option, "kick", true))
	{
		if( groupSelected[playerid] == -1 )
	    	return SendClientMessage(playerid, -1, "Error: You must first select a messaging group (/pmg select)");

		if( GetGroupRankPermissionLevel(groupSelected[playerid], GetPlayerGroupRank(playerid)) < PERMISSION_LEVEL_MODERATOR )
		    return SendClientMessage(playerid, -1, "Error: Permission denied");

		new id;
		
		if(sscanf(params, "s[24]u", params, id))
			return SendClientMessage(playerid, -1, "Usage: /pmg kick (playerid)");
			
		if( playerid == id )
		    return SendClientMessage(playerid, -1, "Error: You cannot kick yourself from the group");
		    
        if(!IsPlayerConnected(id))
	    	return SendClientMessage(playerid, -1, "Error: Player is not connected to the server");
	    	
		if( groupSelected[playerid] != groupSelected[id] )
		    return SendClientMessage(playerid, -1, "Error: Player is not connected to your group");
		    
        if( GetGroupRankPermissionLevel(groupSelected[playerid], GetPlayerGroupRank(id)) == PERMISSION_LEVEL_OWNER )
		    return SendClientMessage(playerid, -1, "Error: You cannot kick the group owner");

        format(string, sizeof(string), "%s(%d) has kicked %s(%d) from the group", GetName(playerid), playerid, GetName(id), id);
		SendMessageToGroup(groupSelected[playerid], string);

		RemovePlayerFromGroup(id, groupSelected[id]);
	}
	else if(!strcmp(option, "invite", true))
	{
		if( groupSelected[playerid] == -1 )
	    	return SendClientMessage(playerid, -1, "Error: You must first select a messaging group (/pmg select)");

        if( GetGroupRankPermissionLevel(groupSelected[playerid], GetPlayerGroupRank(playerid)) < PERMISSION_LEVEL_MODERATOR )
		    return SendClientMessage(playerid, -1, "Error: Permission denied");

		new id;

		if(sscanf(params, "s[24]u", params, id))
			return SendClientMessage(playerid, -1, "Usage: /pmg invite (playerid)");

		if( playerid == id )
		    return SendClientMessage(playerid, -1, "Error: You cannot invite yourself to the group");

        if(!IsPlayerConnected(id))
	    	return SendClientMessage(playerid, -1, "Error: Player is not connected to the server");
	    	
        for(new z = 0; z < MAX_GROUPS_PER_PLAYER; z++)
		{
		    if(aParticipantData[id][z][participant_group_id] == groupSelected[playerid])
			    return SendClientMessage(playerid, -1, "Error: Player is already a member of your group");
		}
		    
		format(string, sizeof(string), "You have successfully invited %s(%d) to join your group", GetName(id), id);
		SendClientMessage(playerid, -1, string);

		format(string, sizeof(string), "%s(%d) has invited you to join their messaging group (/acceptinvite %d)", GetName(playerid), playerid, groupSelected[playerid]);
		SendClientMessage(id, -1, string);
		    
		invite[id] = groupSelected[playerid];
	}
	else if(!strcmp(option, "mute", true))
	{
		if( groupSelected[playerid] == -1 )
	    	return SendClientMessage(playerid, -1, "Error: You must first select a messaging group (/pmg select)");
		
		if( GetGroupRankPermissionLevel(groupSelected[playerid], GetPlayerGroupRank(playerid)) < PERMISSION_LEVEL_MODERATOR )
		    return SendClientMessage(playerid, -1, "Error: Permission denied");

		new id, seconds;

		if(sscanf(params, "s[24]ud", params, id, seconds))
			return SendClientMessage(playerid, -1, "Usage: /pmg mute (playerid) (seconds)");

		if( playerid == id )
		    return SendClientMessage(playerid, -1, "Error: You cannot mute yourself");

        if(!IsPlayerConnected(id))
	    	return SendClientMessage(playerid, -1, "Error: Player is not connected to the server");

		if( groupSelected[playerid] != groupSelected[id] )
		    return SendClientMessage(playerid, -1, "Error: Player is not connected to your group");

     	if( seconds < 0 || seconds > 600 )
	    	return SendClientMessage(playerid, -1, "Error: Invalid mute time (0 - 600)");

        format(string, sizeof(string), "%s(%d) has muted %s(%d) for %d seconds", GetName(playerid), playerid, GetName(id), id, seconds);
		SendMessageToGroup(groupSelected[playerid], string);
		
        for(new z = 0; z < MAX_GROUPS_PER_PLAYER; z++)
		{
      		if(aParticipantData[id][z][participant_group_id] == groupSelected[playerid])
		    {
		        aParticipantData[id][z][participant_muted] = gettime();
		        aParticipantData[id][z][participant_mute_time] = seconds;
			}
		}
	}
	else if(!strcmp(option, "unmute", true))
	{
		if( groupSelected[playerid] == -1 )
	    	return SendClientMessage(playerid, -1, "Error: You must first select a messaging group (/pmg select)");
		
		if( GetGroupRankPermissionLevel(groupSelected[playerid], GetPlayerGroupRank(playerid)) < PERMISSION_LEVEL_MODERATOR )
		    return SendClientMessage(playerid, -1, "Error: Permission denied");

		new id;

		if(sscanf(params, "s[24]u", params, id))
			return SendClientMessage(playerid, -1, "Usage: /pmg unmute (playerid)");

		if( playerid == id )
		    return SendClientMessage(playerid, -1, "Error: You cannot unmute yourself");

        if(!IsPlayerConnected(id))
	    	return SendClientMessage(playerid, -1, "Error: Player is not connected to the server");

		if( groupSelected[playerid] != groupSelected[id] )
		    return SendClientMessage(playerid, -1, "Error: Player is not connected to your group");
		    
        for(new z = 0; z < MAX_GROUPS_PER_PLAYER; z++)
		{
      		if(aParticipantData[playerid][z][participant_group_id] == groupSelected[playerid])
		    {
		        if( gettime() > (aParticipantData[playerid][z][participant_muted] + aParticipantData[playerid][z][participant_mute_time]))
		            return SendClientMessage(playerid, -1, "Error: Player is not currently muted");
			}
		}

        format(string, sizeof(string), "%s(%d) has unmuted %s(%d)", GetName(playerid), playerid, GetName(id), id);
		SendMessageToGroup(groupSelected[playerid], string);

        for(new z = 0; z < MAX_GROUPS_PER_PLAYER; z++)
		{
      		if(aParticipantData[id][z][participant_group_id] == groupSelected[playerid])
		    {
		        aParticipantData[id][z][participant_muted] = -1;
		        aParticipantData[id][z][participant_mute_time] = -1;
			}
		}
	}
	else if(!strcmp(option, "setrank", true))
	{
		if( groupSelected[playerid] == -1 )
	    	return SendClientMessage(playerid, -1, "Error: You must first select a messaging group (/pmg select)");


		if( GetGroupRankPermissionLevel(groupSelected[playerid], GetPlayerGroupRank(playerid)) < PERMISSION_LEVEL_OWNER )
		    return SendClientMessage(playerid, -1, "Error: Permission denied");

		new id;

		if(sscanf(params, "s[24]u", params, id))
			return SendClientMessage(playerid, -1, "Usage: /pmg setrank (playerid)");

		if( playerid == id )
		    return SendClientMessage(playerid, -1, "Error: You cannot set your own rank");

        if(!IsPlayerConnected(id))
	    	return SendClientMessage(playerid, -1, "Error: Player is not connected to the server");

		if( groupSelected[playerid] != groupSelected[id] )
		    return SendClientMessage(playerid, -1, "Error: Player is not connected to your group");
	    	
		new groupid = groupSelected[playerid], header[50];
		format(header, sizeof(header), "{FFFFFF}Set Rank: %s(%d)", GetName(id), id);
		
		format(string, sizeof(string), "ID\tName\tPermission Level\n");
		for(new z = 0; z < MAX_RANKS; z++)
		{
		    if(aRankData[groupid][z][rank_id] >= 0)
		    {
		        strcat_format(string, sizeof(string), "{FFFFFF}%d\t{%s}%s\t{FFFFFF}%d\n", z, aRankData[groupid][z][rank_color], aRankData[groupid][z][rank_name], GetGroupRankPermissionLevel(groupid, aRankData[groupid][z][rank_id]));
			}

		}
		ShowPlayerDialog(playerid, DIALOG_GROUP_SET_RANK, DIALOG_STYLE_TABLIST_HEADERS, header, string, "Select", "Close");
						
		SetPVarInt(playerid, "set_rank_playerid", id);
	}
	else if(!strcmp(option, "settings", true))
	{
	    if( groupSelected[playerid] == -1 )
	    	return SendClientMessage(playerid, -1, "Error: You must first select a messaging group (/pmg select)");
		
		if( GetGroupRankPermissionLevel(groupSelected[playerid], GetPlayerGroupRank(playerid)) < PERMISSION_LEVEL_OWNER )
		    return SendClientMessage(playerid, -1, "Error: Permission denied");
		
	    ShowPlayerDialog(playerid, DIALOG_GROUP_SETTINGS, DIALOG_STYLE_LIST, "{FFFFFF}Group Settings", "{FFFFFF}Edit Ranks", "Select", "Close");
	}
	else
	{
		SendClientMessage(playerid, -1, "Usage: /pmg (create/select/say/members/leave/kick/invite/mute/unmute/setrank/settings)");
	}
	return 1;
}

//---------------- Forwards

forward OnGroupCreated(playerid, const name[]);
public OnGroupCreated(playerid, const name[])
{
    new query[200];
    
	//Creating a new group
    new id = cache_insert_id();
	aGroupData[id][group_id] = id;
	format(aGroupData[id][group_name], MAX_GROUP_NAME, name);
    
    //Making player a participant
    mysql_format(mysql, query, sizeof(query), "INSERT INTO `group_participants` (`playername`, `groupid`, `rank`) VALUES ('%s', '%d', 3)", GetName(playerid), id);
    mysql_tquery(mysql, query, "OnGroupCreatedParticipant", "dd", playerid, id);
    
    //Creating default ranks
    mysql_format(mysql, query, sizeof(query), "INSERT INTO `group_ranks` (`rank_id`, `rank_group_id`, `rank_name`, `rank_color`, `rank_permission_level`) VALUES (1, '%d', 'Regular', 'FFFFFF', 0)", id);
    mysql_tquery(mysql, query, "", "");
    
    mysql_format(mysql, query, sizeof(query), "INSERT INTO `group_ranks` (`rank_id`, `rank_group_id`, `rank_name`, `rank_color`, `rank_permission_level`) VALUES (2, '%d', 'Moderator', 'FFFFFF', 1)", id);
    mysql_tquery(mysql, query, "", "");
    
    mysql_format(mysql, query, sizeof(query), "INSERT INTO `group_ranks` (`rank_id`, `rank_group_id`, `rank_name`, `rank_color`, `rank_permission_level`) VALUES (3, '%d', 'Owner', 'FFFFFF', 2)", id);
    mysql_tquery(mysql, query, "", "");

    aRankData[id][1][rank_id] = 1;
    format(aRankData[id][1][rank_name], MAX_RANK_NAME, "Regular");
    format(aRankData[id][1][rank_color], 7, "FFFFFF");
    aRankData[id][1][rank_permission_level] = PERMISSION_LEVEL_NONE;

    aRankData[id][2][rank_id] = 2;
    format(aRankData[id][2][rank_name], MAX_RANK_NAME, "Moderator");
    format(aRankData[id][2][rank_color], 7, "FFFFFF");
    aRankData[id][2][rank_permission_level] = PERMISSION_LEVEL_MODERATOR;

    aRankData[id][3][rank_id] = 3;
    format(aRankData[id][3][rank_name], MAX_RANK_NAME, "Owner");
    format(aRankData[id][3][rank_color], 7, "FFFFFF");
    aRankData[id][3][rank_permission_level] = PERMISSION_LEVEL_OWNER;
	return 1;
}

forward OnGroupAddedParticipant(playerid, groupid);
public OnGroupAddedParticipant(playerid, groupid)
{
    new slot_found = -1;
    for(new z = 0; z < MAX_GROUPS_PER_PLAYER; z++)
	{
	    if(aParticipantData[playerid][z][participant_id] == -1) //checking for an empty slot
		{
	        slot_found = z;
	        break;
	    }
	}
	if (slot_found != -1) // found empty slot
	{
	    aParticipantData[playerid][slot_found][participant_id] = cache_insert_id();
        format(aParticipantData[playerid][slot_found][participant_name], MAX_PLAYER_NAME, "%s", GetName(playerid));
        aParticipantData[playerid][slot_found][participant_group_id] = groupid;
        aParticipantData[playerid][slot_found][participant_rank] = 1;
	}

	groupSelected[playerid] = groupid;
	return 1;
}

forward OnGroupCreatedParticipant(playerid, groupid);
public OnGroupCreatedParticipant(playerid, groupid)
{
    new slot_found = -1;
    for(new z = 0; z < MAX_GROUPS_PER_PLAYER; z++)
	{
	    if(aParticipantData[playerid][z][participant_id] == -1) //checking for an empty slot
		{
	        slot_found = z;
	        break;
	    }
	}
	if (slot_found != -1) // found empty slot
	{
	    aParticipantData[playerid][slot_found][participant_id] = cache_insert_id();
        format(aParticipantData[playerid][slot_found][participant_name], MAX_PLAYER_NAME, "%s", GetName(playerid));
        aParticipantData[playerid][slot_found][participant_group_id] = groupid;
        aParticipantData[playerid][slot_found][participant_rank] = 3;
	}
	
	groupSelected[playerid] = groupid;
	return 1;
}

forward OnParticipantDataLoad(playerid);
public OnParticipantDataLoad(playerid)
{
    new count = 0;
	for(new z = 0, rows = cache_num_rows(); z < rows; z++)
	{
	    cache_get_value_name_int(z, "id", aParticipantData[playerid][z][participant_id]);
	    cache_get_value_name(z, "playername", aParticipantData[playerid][z][participant_name], .max_len = MAX_PLAYER_NAME);
	    cache_get_value_name_int(z, "groupid", aParticipantData[playerid][z][participant_group_id]);
	    cache_get_value_name_int(z, "rank", aParticipantData[playerid][z][participant_rank]);
	    count++;
	}
	printf("DEBUG: %d groups loaded for %s", count, GetName(playerid));
	return 1;
}

forward OnGroupDataLoad();
public OnGroupDataLoad()
{
	new id, loaded;
	new rows = cache_num_rows();
 	if(rows)
    {
        while(loaded < rows)
        {
			cache_get_value_name_int(loaded, "group_id", id);
			aGroupData[id][group_id] = id;
			cache_get_value_name(loaded, "group_name", aGroupData[id][group_name], .max_len = MAX_GROUP_NAME);
            loaded++;
		}
	}
	printf("DEBUG: %d groups loaded", loaded);
	return 1;
}

forward OnGroupRankLoad();
public OnGroupRankLoad()
{
	new id, groupid, loaded;
	new rows = cache_num_rows();
 	if(rows)
    {
        while(loaded < rows)
        {
            cache_get_value_name_int(loaded, "rank_id", id);
			cache_get_value_name_int(loaded, "rank_group_id", groupid);
			
   			aRankData[groupid][id][rank_id] = id;
   			
			cache_get_value_name(loaded, "rank_name", aRankData[groupid][id][rank_name], .max_len = MAX_GROUP_NAME);
			cache_get_value_name(loaded, "rank_color", aRankData[groupid][id][rank_color], .max_len = 7);
			cache_get_value_name_int(loaded, "rank_permission_level", aRankData[groupid][id][rank_permission_level]);
            loaded++;
		}
	}
 	printf("DEBUG: %d group ranks loaded", loaded);
	return 1;
}


//---------------- Stocks % Functions

stock GetName(playerid)
{
    new name[24];
    GetPlayerName(playerid, name, sizeof(name));
    return name;
}

stock SendMessageToGroup(groupid, const msg[])
{
	new str[200];
	foreach(new i: Player)
    {
		if(groupSelected[i] == groupid)
		{
		    format(str, sizeof(str), "%s: %s", aGroupData[groupid][group_name], msg);
		    SendClientMessage(i, 0xFF0000FF, str);
		}
    }
	return 1;
}

stock RemovePlayerFromGroup(playerid, groupid)
{
	new query[128];

	mysql_format(mysql, query, sizeof(query), "DELETE FROM `group_participants` WHERE `groupid`='%d' AND `playername`='%s'", groupid, GetName(playerid));
 	mysql_tquery(mysql, query, "", "");
 	
	for(new z = 0; z < MAX_GROUPS_PER_PLAYER; z++)
	{
	    if(aParticipantData[playerid][z][participant_group_id] == groupid)
	    {
			new name[MAX_PLAYER_NAME];
	        format(name, sizeof(name), "N/A");
	        
	        aParticipantData[playerid][z][participant_id] = -1;
		    aParticipantData[playerid][z][participant_name] = name;
		    aParticipantData[playerid][z][participant_group_id] = -1;
		    aParticipantData[playerid][z][participant_rank] = -1;
		    aParticipantData[playerid][z][participant_muted] = -1;
   	 		aParticipantData[playerid][z][participant_mute_time] = -1;
	    }
	}
	groupSelected[playerid] = -1;
	return 1;
}

stock GetPlayerGroupRank(playerid)
{
	new rank;
	for(new z = 0; z < MAX_GROUPS_PER_PLAYER; z++)
	{
	    if(aParticipantData[playerid][z][participant_group_id] == groupSelected[playerid])
	    {
	        rank = aParticipantData[playerid][z][participant_rank];
		}
	}
	return rank;
}

stock GetGroupRankName(groupid, rank)
{
	new name_rank[MAX_RANK_NAME];
	for(new z = 0; z < MAX_RANKS; z++)
	{
	    if(aRankData[groupid][z][rank_id] > 0)
	    {
			if(aRankData[groupid][z][rank_id] == rank)
			{
			    format(name_rank, sizeof(name_rank), "%s", aRankData[groupid][z][rank_name]);
			}
	    }

	}
	return name_rank;
}

stock GetGroupRankPermissionLevel(groupid, rank)
{
	new level;
	for(new z = 0; z < MAX_RANKS; z++)
	{
		if(aRankData[groupid][z][rank_id] == rank)
		{
		    level = aRankData[groupid][z][rank_permission_level];
		}
	}
	return level;
}

stock IsNumeric(const str[])
{
    return !sscanf(str, "{d}");
}

HasApostrophe(string[])
{
	new len = strlen(string);
	for(new i = 0; i < len; i++)
	{
		if(string[i] == ''') return true;
	}
	return false;
}
