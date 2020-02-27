/*
An apartment system. Players can use enter their garage, if they own an apartment, whilst in the garage entrance checkpoint. Players can also use a command
to exit their garage if they are within a certain proximity from the garage door within their apartment (must be inside a vehicle). The apartment configuration
panel allows players to deposit/withdraw from their safe, lock the apartment, and manage their furniture.

Credits: rootcase (samp forums) - furniture system
*/
#include <YSI\y_hooks>

#define 	MAX_APARTMENTS						(20)
#define 	MAX_OWNED_APARTMENTS    			(3)
#define    	INVALID_APARTMENT_ID    			(-1)
#define     INVALID_OWNER_NAME    				(24)

enum Apartments
{
	apt_id,
	apt_owner[MAX_PLAYER_NAME],
	apt_owned,
	apt_safe,
	apt_locked,
	apt_onsale,
	apt_vehicle,
};
new aptInfo[MAX_APARTMENTS][Apartments];

new	Iterator: Apartments<MAX_APARTMENTS>,
	CurrentAptID[ MAX_PLAYERS ] = {INVALID_APARTMENT_ID, ...},
	garageEntrance;

hook OnGameModeInit()
{
    garageEntrance = CreateDynamicCP( 1807.2919, -1290.0929, 13.6308, 3.0, .interiorid = 0 );
    mysql_tquery(mysql, "SELECT * FROM `"ApartmentTable"`", "OnLoadApartments", "");
    
    new glass = CreateObject(4605, 1823.68750, -1291.25000, 7.31250,   0.00000, 0.00000, 0.00000);
    SetObjectMaterial(glass, 0, 5722, "sunrise01_lawn", "plainglass", 0xFFFFFFFF);
    SetObjectMaterial(glass, 1, 5722, "sunrise01_lawn", "plainglass", 0xFFFFFFFF);
	CreateObject(18755, 1786.67627, -1303.42603, 14.56552,   0.00000, 0.00000, 270.00000);
	CreateObject(13028, 1810.13147, -1293.06335, 14.47138,   0.00000, 0.00000, 312.48312);
	
	CreateDynamic3DTextLabel("Press [Y] to access apartments", -1, 1786.5645, -1303.6823, 13.7655 + 0.5, 60.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1, -1, -1, -1, 50.0);

    return 1;
}

hook OnPlayerConnect(playerid)
{
    RemoveBuildingForPlayer(playerid, 4762, 1823.6875, -1291.2500, 7.3125, 0.25);
	RemoveBuildingForPlayer(playerid, 4605, 1823.6875, -1291.2500, 7.3125, 0.25);
	RemoveBuildingForPlayer(playerid, 1294, 1802.7891, -1270.9297, 17.1406, 0.25);
	return 1;
}

forward OnLoadApartments();
public OnLoadApartments()
{
    new id, loaded;
	new rows = cache_num_rows();
 	if(rows)
    {
        while(loaded < rows)
		{
			cache_get_value_name_int(loaded, "ID", id);
			aptInfo[id][apt_id] = id;
			cache_get_value_name(loaded, "Owner", aptInfo[id][apt_owner], .max_len = MAX_PLAYER_NAME);
			cache_get_value_name_int(loaded, "Owned", aptInfo[id][apt_owned]);
			cache_get_value_name_int(loaded, "Safe", aptInfo[id][apt_safe]);
			cache_get_value_name_int(loaded, "Locked", aptInfo[id][apt_locked]);
			cache_get_value_name_int(loaded, "OnSale", aptInfo[id][apt_onsale]);
			cache_get_value_name_int(loaded, "Vehicle", aptInfo[id][apt_vehicle]);
            Iter_Add(Apartments, id);
            loaded++;
		}
		if(loaded >= 1) printf("[DEBUG] %i %s were created... (IDs 0 - %i)", loaded, plural_singular(loaded, "apartment", "apartments"), loaded-1);
	}
	return 1;
}

hook Zones_Update(playerid)
{
	new str[26] = EOS, id = CurrentAptID[playerid];
 	if( spawned[playerid] == 1 )
    {
		if( id >= 0 )
		{
			format(str, sizeof(str), "%s apartment", AddPertinence(aptInfo[id][apt_owner]));

			TextDrawSetString(Zones[playerid], str);
			TextDrawShowForPlayer(playerid, Zones[playerid]);
		}
	}
	return 1;
}

hook OnPlayerEnterDynamicCP( playerid, checkpointid )
{
	if( checkpointid == garageEntrance )
	{
     	if(CurrentAptID[playerid] == INVALID_HOUSE_ID )
     	{
	    	SendClientMessage(playerid, RED, "Welcome to the Los Santos Apartment Complex garage. If you have a house, please use /entergarage");
	    	return 1;
		}
	}
	return 1;
}

hook OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if(!(newkeys & KEY_YES) && oldkeys & KEY_YES)
	{
	    if(IsPlayerInRangeOfPoint(playerid, 3, 1786.5645, -1303.6823, 13.7655))
	    {
			new string[400], owner[MAX_PLAYER_NAME];
		    format(string, sizeof(string), "ID\tOwner\n");
		    foreach(new i : Apartments)
			{
				format(owner, sizeof(owner), "%s", aptInfo[i][apt_owner]);
       			strcat_format(string, sizeof(string), "{FFFFFF}Apartment %d\t%s\n", i+1, (aptInfo[i][apt_onsale] == 1) ? ("For Sale") : (owner));
			}
			ShowPlayerDialog(playerid, APARTMENT_DIALOG, DIALOG_STYLE_TABLIST_HEADERS, "{FFFFFF}Los Santos Apartment Complex", string, "Enter", "Close");
		}
	}
	return 1;
}


DEFINE_HOOK_REPLACEMENT__(OnPlayer, OP_);

hook OP_SelectDynamicObject(playerid, objectid, modelid, Float: x, Float: y, Float: z)
{
	switch(SelectMode[playerid])
	{
	    case SELECT_MODE_EDIT:
		{
			EditingFurniture[playerid] = true;
			EditDynamicObject(playerid, objectid);
		}

	    case SELECT_MODE_SELL:
	    {
	        CancelEdit(playerid);

			new data[e_furniture], string[128];
			SetPVarInt(playerid, "SelectedFurniture", objectid);
			Streamer_GetArrayData(STREAMER_TYPE_OBJECT, objectid, E_STREAMER_EXTRA_ID, data);
			format(string, sizeof(string), "Do you want to sell your %s?\nYou'll get {2ECC71}$%s.", HouseFurnitures[ data[ArrayID] ][FurnitureName], AddCommas(HouseFurnitures[ data[ArrayID] ][Price]));
			ShowPlayerDialog(playerid, DIALOG_FURNITURE_SELL, DIALOG_STYLE_MSGBOX, "{D3DCE3}Confirm Sale", string, "Sell", "Close");
		}
	}

    SelectMode[playerid] = SELECT_MODE_NONE;
	return 1;
}

DEFINE_HOOK_REPLACEMENT__(OnPlayer, OP_);

hook OP_EditDynamicObject(playerid, objectid, response, Float: x, Float: y, Float: z, Float: rx, Float: ry, Float: rz)
{
	if(EditingFurniture[playerid])
	{
		switch(response)
		{
		    case EDIT_RESPONSE_CANCEL:
		    {
		        new data[e_furniture];
		        Streamer_GetArrayData(STREAMER_TYPE_OBJECT, objectid, E_STREAMER_EXTRA_ID, data);
		        SetDynamicObjectPos(objectid, data[furnitureX], data[furnitureY], data[furnitureZ]);
		        SetDynamicObjectRot(objectid, data[furnitureRX], data[furnitureRY], data[furnitureRZ]);

		        EditingFurniture[playerid] = false;
		    }

			case EDIT_RESPONSE_FINAL:
			{
			    new data[e_furniture], query[256];
			    Streamer_GetArrayData(STREAMER_TYPE_OBJECT, objectid, E_STREAMER_EXTRA_ID, data);
			    data[furnitureX] = x;
			    data[furnitureY] = y;
			    data[furnitureZ] = z;
	            data[furnitureRX] = rx;
	            data[furnitureRY] = ry;
	            data[furnitureRZ] = rz;
	            SetDynamicObjectPos(objectid, data[furnitureX], data[furnitureY], data[furnitureZ]);
		        SetDynamicObjectRot(objectid, data[furnitureRX], data[furnitureRY], data[furnitureRZ]);
		        Streamer_SetArrayData(STREAMER_TYPE_OBJECT, objectid, E_STREAMER_EXTRA_ID, data);

		        mysql_format(mysql, query, sizeof(query), "UPDATE `furniture` SET FurnitureX=%f, FurnitureY=%f, FurnitureZ=%f, FurnitureRX=%f, FurnitureRY=%f, FurnitureRZ=%f WHERE ID=%d", data[furnitureX], data[furnitureY], data[furnitureZ], data[furnitureRX], data[furnitureRY], data[furnitureRZ], data[SQLID]);
		        mysql_tquery(mysql, query, "", "");

		        EditingFurniture[playerid] = false;
			}
		}
	}

	return 1;
}

hook OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	if(dialogid == APARTMENT_DIALOG)
    {
        if(!response) return TogglePlayerControllable(playerid, 1);

        if(response)
        {
            foreach(new i : Apartments)
            {
                if( i == listitem )
				{
				    if(aptInfo[i][apt_onsale] == 1)
		            {
		                SendClientMessage(playerid, RED, "This apartment is currently for sale.. you cannot enter it");
                  		TogglePlayerControllable(playerid, 1);
						return 1;
					}
					else
					{
					    if(aptInfo[i][apt_locked] == 1)
			            {
		                    if(strcmp(Name[playerid], aptInfo[i][apt_owner], true) != 0)
							{
								SendClientMessage(playerid, RED, "This apartment is currently locked.. you do not have a key");
	                            TogglePlayerControllable(playerid, 1);
								return 1;
			          		}
			          		else
			          		{
			          		    PutPlayerInApartment(playerid, i);
					    		SendClientMessage(playerid, COLOR_HOUSE, "Apartment: {FFFFFF}You have entered an apartment, please use /exita to leave.");
							}
	   					}
	   					else
	   					{
					    	PutPlayerInApartment(playerid, i);
					    	SendClientMessage(playerid, COLOR_HOUSE, "Apartment: {FFFFFF}You have entered an apartment, please use /exita to leave.");
						}
					}
				}
			}
		}
	}
	if(dialogid == APARTMENT_MENU && response==1)
    {
        new query[150],
			aID = CurrentAptID[playerid];

        switch(listitem)
        {
            case 0:
            {
            }
            case 1:
            {
            	if(aptInfo[aID][apt_locked] == 0)
	            {
	                aptInfo[aID][apt_locked] = 1;
					mysql_format(mysql, query, sizeof(query), "UPDATE `"ApartmentTable"` SET `Locked`=%i WHERE `ID` = '%i'", aptInfo[aID][apt_locked], aID);
					mysql_tquery(mysql, query, "", "");
					ShowApartmentMenu(playerid);
	            }
	            else if(aptInfo[aID][apt_locked] == 1)
	            {
	                aptInfo[aID][apt_locked] = 0;
	                mysql_format(mysql, query, sizeof(query), "UPDATE `"ApartmentTable"` SET `Locked`=%i WHERE `ID` = '%i'", aptInfo[aID][apt_locked], aID);
					mysql_tquery(mysql, query, "", "");
					ShowApartmentMenu(playerid);
	            }
            }
            case 2:
            {
				ShowPlayerDialog(playerid, DIALOG_SAFE_MENU, DIALOG_STYLE_LIST, "{D3DCE3}Safe", "{FFFFFF}Deposit\nWithdraw", "Choose", "Back");
            }
            case 3:
            {

            }
            case 4:
            {
                ShowPlayerDialog(playerid, DIALOG_FURNITURE_MENU, DIALOG_STYLE_LIST, "{D3DCE3}Furniture", "{FFFFFF}Buy Furniture\nEdit Furniture\nSell Furniture\nSell All Furniture", "Choose", "Back");
            }
			case 5:
            {
				SendClientMessage(playerid, COLOR_HOUSE, "Apartment: {FFFFFF}To sell your apartment, please contact an administrator.");
				ShowApartmentMenu(playerid);
			}
		}
	}
	if(dialogid == DIALOG_FURNITURE_MENU)
	{
	    if(!response) return ShowApartmentMenu(playerid);
	    
        new id = CurrentAptID[playerid];
		if(listitem == 0)
		{
		    new list[512];
		    format(list, sizeof(list), "#\tFurniture Name\tPrice\n");
		    for(new i; i < sizeof(HouseFurnitures); ++i)
		    {
		        format(list, sizeof(list), "%s%d\t%s\t$%s\n", list, i+1, HouseFurnitures[i][FurnitureName], AddCommas(HouseFurnitures[i][Price]));
		    }

		    ShowPlayerDialog(playerid, DIALOG_FURNITURE_BUY, DIALOG_STYLE_TABLIST_HEADERS, "{D3DCE3}Buy Furniture", list, "Buy", "Back");
		}

		if(listitem == 1)
		{
			SelectMode[playerid] = SELECT_MODE_EDIT;
		    SelectObject(playerid);
		    SendClientMessage(playerid, COLOR_HOUSE, "Apartment: {FFFFFF}Please select the furniture you would like to edit.");
		}

		if(listitem == 2)
		{
		    SelectMode[playerid] = SELECT_MODE_SELL;
		    SelectObject(playerid);
		    SendClientMessage(playerid, COLOR_HOUSE, "Apartment: {FFFFFF}Please select the furniture you would like to sell.");
		}

		if(listitem == 3)
		{
		    new money, sold, data[e_furniture], query[64];
		    for(new i; i < Streamer_GetUpperBound(STREAMER_TYPE_OBJECT); ++i)
		    {
		        if(!IsValidDynamicObject(i)) continue;
				Streamer_GetArrayData(STREAMER_TYPE_OBJECT, i, E_STREAMER_EXTRA_ID, data);
				if(data[SQLID] > 0 && data[HouseID] == id)
				{
				    sold++;
				    money += HouseFurnitures[ data[ArrayID] ][Price];
					DestroyDynamicObject(i);
				}
		    }

		    new string[64];
		    format(string, sizeof(string), "Apartment: {FFFFFF}Sold %d furniture for $%s.", sold, AddCommas(money));
		    SendClientMessage(playerid, COLOR_HOUSE, string);
		    GivePlayerCash(playerid, money);

		    mysql_format(mysql, query, sizeof(query), "DELETE FROM `furniture` WHERE HouseID=%d", id);
		    mysql_tquery(mysql, query, "", "");
		}

	    return 1;
	}

	if(dialogid == DIALOG_FURNITURE_BUY)
	{
	    if(!response) return ShowApartmentMenu(playerid);
	    
        new id = CurrentAptID[playerid];
        
		if( HouseFurnitures[listitem][Price] > GetPlayerCash( playerid ) )
			return Error(playerid, "You cannot afford to purchase this furniture.");
			
		GivePlayerCash(playerid, -HouseFurnitures[listitem][Price]);
		
		new Float: x, Float: y, Float: z;
		GetPlayerPos(playerid, x, y, z);
        GetXYInFrontOfPlayer(playerid, x, y, 3.0);
        
        new objectid = CreateDynamicObject(HouseFurnitures[listitem][ModelID], x, y, z, 0.0, 0.0, 0.0, GetPlayerVirtualWorld(playerid), GetPlayerInterior(playerid)), query[256];
		mysql_format(mysql, query, sizeof(query), "INSERT INTO `furniture` SET HouseID=%d, FurnitureID=%d, FurnitureX=%f, FurnitureY=%f, FurnitureZ=%f, FurnitureVW=%d, FurnitureInt=%d", id, listitem, x, y, z, GetPlayerVirtualWorld(playerid), GetPlayerInterior(playerid));
        new Cache: add = mysql_query(mysql, query), data[e_furniture];
        data[SQLID] = cache_insert_id();
		data[HouseID] = id;
        data[ArrayID] = listitem;
		data[furnitureX] = x;
		data[furnitureY] = y;
		data[furnitureZ] = z;
		data[furnitureRX] = 0.0;
		data[furnitureRY] = 0.0;
		data[furnitureRZ] = 0.0;
		cache_delete(add);
		Streamer_SetArrayData(STREAMER_TYPE_OBJECT, objectid, E_STREAMER_EXTRA_ID, data);

		EditingFurniture[playerid] = true;
		EditDynamicObject(playerid, objectid);
		return 1;
	}

	if(dialogid == DIALOG_FURNITURE_SELL)
	{
	    if(!response) return ShowApartmentMenu(playerid);
	    
		new objectid = GetPVarInt(playerid, "SelectedFurniture"), query[64], data[e_furniture];
		Streamer_GetArrayData(STREAMER_TYPE_OBJECT, objectid, E_STREAMER_EXTRA_ID, data);
		GivePlayerCash(playerid, HouseFurnitures[ data[ArrayID] ][Price]);
		mysql_format(mysql, query, sizeof(query), "DELETE FROM `furniture` WHERE ID=%d", data[SQLID]);
		mysql_tquery(mysql, query, "", "");
		DestroyDynamicObject(objectid);
		DeletePVar(playerid, "SelectedFurniture");
		return 1;
	}
	
	if(dialogid == DIALOG_SAFE_MENU)
	{
	    if(!response) return ShowApartmentMenu(playerid);
	    
		new str[128];
	    
	    switch( listitem )
	    {
	        case 0:
			{
			    format(str, sizeof(str), "{FFFFFF}Please enter the amount you would like to deposit into your safe.\n\nCurrent Amount: $%s", AddCommas(aptInfo[CurrentAptID[playerid]][apt_safe]));
				ShowPlayerDialog(playerid, DIALOG_SAFE_DEPOSIT, DIALOG_STYLE_INPUT, "{D3DCE3}Safe - Deposit", str, "Deposit", "Back");
			}
			case 1:
			{
			    format(str, sizeof(str), "{FFFFFF}Please enter the amount you would like to withdraw from your safe.\n\nCurrent Amount: $%s", AddCommas(aptInfo[CurrentAptID[playerid]][apt_safe]));
				ShowPlayerDialog(playerid, DIALOG_SAFE_WITHDRAW, DIALOG_STYLE_INPUT, "{D3DCE3}Safe - Withdraw", str, "Withdraw", "Back");
			}
		}
	}
	if(dialogid == DIALOG_SAFE_DEPOSIT)
	{
	    if(!response) return ShowApartmentMenu(playerid);

		new amount = strval(inputtext);
        
		if(!(1 <= amount <= 500000))
			return Error(playerid, "You can only deposit a maximum of $500,000 at a time"), ShowApartmentMenu(playerid);

  		if(amount > GetPlayerCash(playerid))
			return Error(playerid, "You do not have that much cash on you"), ShowApartmentMenu(playerid);
			
    	GivePlayerCash(playerid, -amount);
		aptInfo[CurrentAptID[playerid]][apt_safe] += amount;
			
        new query[128];
		
		mysql_format(mysql, query, sizeof(query), "UPDATE `"ApartmentTable"` SET `Safe`=%d WHERE `ID` = '%d'", aptInfo[CurrentAptID[playerid]][apt_safe], aptInfo[CurrentAptID[playerid]][apt_id]);
		mysql_tquery(mysql, query, "", "");

		format(query, sizeof(query), "Apartment: {FFFFFF}You have have successfully deposited $%s into your safe.", AddCommas(amount));
		SendClientMessage(playerid, COLOR_HOUSE, query);
		
		ShowApartmentMenu(playerid);
	}
	if(dialogid == DIALOG_SAFE_WITHDRAW)
	{
	    if(!response) return ShowApartmentMenu(playerid);

        new amount = strval(inputtext);

		if(!(1 <= amount <= 500000))
			return Error(playerid, "You can only withdraw a maximum of $500,000 at a time"), ShowApartmentMenu(playerid);

		if(amount > aptInfo[CurrentAptID[playerid]][apt_safe])
			return Error(playerid, "You do not have that much cash in your safe"), ShowApartmentMenu(playerid);

    	GivePlayerCash(playerid, amount);
		aptInfo[CurrentAptID[playerid]][apt_safe] -= amount;

        new query[128];

		mysql_format(mysql, query, sizeof(query), "UPDATE `"ApartmentTable"` SET `Safe`=%d WHERE `ID` = '%d'", aptInfo[CurrentAptID[playerid]][apt_safe], aptInfo[CurrentAptID[playerid]][apt_id]);
		mysql_tquery(mysql, query, "", "");

		format(query, sizeof(query), "Apartment: {FFFFFF}You have have successfully withdrawn $%s from your safe.", AddCommas(amount));
		SendClientMessage(playerid, COLOR_HOUSE, query);

		ShowApartmentMenu(playerid);
	
	}
	return 1;
}

stock PutPlayerInApartment(playerid, id)
{
    if(!Iter_Contains(Apartments, id)) return 0;

    SetPlayerPos(playerid, 1429.8752, -1221.1287, 152.8182);
	SetPlayerFacingAngle(playerid, 262.4679);
	SetCameraBehindPlayer(playerid);
	SetPlayerInterior(playerid, 1);
 	SetPlayerVirtualWorld(playerid, aptInfo[id][apt_id]);
	CurrentAptID[playerid] = id;
	TogglePlayerControllable(playerid, 1);
	return 1;
}

stock KickFromApartment(playerid)
{
    SetPlayerPos(playerid, 1786.5645, -1303.6823, 13.7655);
	SetPlayerFacingAngle(playerid, 0.3015);
	SetCameraBehindPlayer(playerid);
	SetPlayerInterior(playerid, 0);
	SetPlayerVirtualWorld(playerid, 0);
	CurrentAptID[playerid] = INVALID_APARTMENT_ID;
	return 1;
}

CMD:entergarage(playerid, params[])
{
    if(!IsPlayerInDynamicCP(playerid, garageEntrance))
	    return Error(playerid, "You are not at the garage checkpoint");

	if(!IsPlayerInAnyVehicle(playerid))
	    return Error(playerid, "You must be in a vehicle to use this command");

    if(GetPlayerState(playerid) != PLAYER_STATE_DRIVER)
        return Error(playerid, "You must be the driver of a vehicle");

    if( GetWantedLevel(playerid) >= 1)
		return Error(playerid, "You cannot enter your garage whilst wanted");

	new bool: owning_apartment;

    if(IsPlayerInDynamicCP(playerid, garageEntrance))
	{
 		if( GetPlayerState( playerid ) == PLAYER_STATE_DRIVER )
		{
	  		foreach(new i : Apartments)
			{
	            if(strcmp(Name[playerid], aptInfo[i][apt_owner], true) == 0)
				{
			 	    new vehicleid = GetPlayerVehicleID(playerid);
					SetVehiclePos(vehicleid, 1415.5319,-1213.0896,152.0932);
					SetVehicleZAngle(vehicleid, 89.7280);
			  		LinkVehicleToInterior(vehicleid, 1);
					SetVehicleVirtualWorld(GetPlayerVehicleID(playerid), aptInfo[i][apt_id]);

					SetPlayerInterior(playerid, 1);
					SetPlayerVirtualWorld(playerid, aptInfo[i][apt_id]);
					PutPlayerInVehicle(playerid, vehicleid, 0);

					CurrentAptID[playerid] = i;

					SendClientMessage(playerid, COLOR_HOUSE, "Apartment: {FFFFFF}You have successfully entered your garage, use /exitgarage to leave.");
					
                    SetTimerEx("FadeOut", 5, false, "id", playerid, 0);
					owning_apartment = true;
					break;
				}
			}
		}
	}
	
	if (!owning_apartment)
	{
		Error(playerid, "You do not own an apartment here");
	}
	return 1;
}


CMD:exitgarage(playerid, params[])
{
    if(CurrentAptID[playerid] == INVALID_APARTMENT_ID )
	    return Error(playerid, "You must be in a house");

   	if(!IsPlayerInAnyVehicle(playerid))
	    return Error(playerid, "You must be in a vehicle to use this command");

    if(GetPlayerState(playerid) != PLAYER_STATE_DRIVER)
        return Error(playerid, "You must be the driver of a vehicle");

    if(!IsPlayerInRangeOfPoint(playerid, 10.0, 1409.0686, -1213.0741, 151.7402))
		return Error(playerid, "You must be in the garage");

    if(strcmp(Name[playerid], aptInfo[CurrentAptID[playerid]][apt_owner], true) != 0)
	    return Error(playerid, "You are not the owner of this apartment");


    if( GetPlayerState( playerid ) == PLAYER_STATE_DRIVER )
 	{
	    new vehicleid = GetPlayerVehicleID(playerid);
		SetVehiclePos(vehicleid, 1804.5197, -1286.8676, 13.5102);
  		SetVehicleZAngle(vehicleid, 41.9934);
  		LinkVehicleToInterior(vehicleid, 0);
		SetVehicleVirtualWorld(GetPlayerVehicleID(playerid), 0);
		
		SetPlayerInterior(playerid, 0);
		SetPlayerVirtualWorld(playerid, 0);
		PutPlayerInVehicle(playerid, vehicleid, 0);
  		
		CurrentAptID[playerid] = INVALID_APARTMENT_ID;

		TogglePlayerControllable(playerid, 1);

		SendClientMessage(playerid, COLOR_HOUSE, "Apartment: {FFFFFF}You have successfully exited your garage.");
	}
	return 1;
}

CMD:apartment(playerid, params[])
{
	if( CurrentAptID[playerid] == INVALID_APARTMENT_ID )
	    return Error(playerid, "You must be in your apartment");

    if( strcmp(Name[playerid], aptInfo[CurrentAptID[playerid]][apt_owner], true) != 0)
	    return Error(playerid, "You are not the owner of this apartment");

	ShowApartmentMenu(playerid);
	return 1;
}

CMD:exita(playerid, params[])
{
	if( CurrentAptID[playerid] == -1)
	    return Error(playerid, "You are not inside an apartment");

	SendClientMessage(playerid, COLOR_HOUSE, "Apartment: {FFFFFF}You have left the apartment.");

	KickFromApartment(playerid);
	return 1;
}

stock ShowApartmentMenu(playerid)
{
	new str[300];
	strcat_format(str, sizeof(str), "Apartment Owner: [{D3DCE3}%s{FFFFFF}]\n", aptInfo[CurrentAptID[playerid]][apt_owner]);
    strcat_format(str, sizeof(str), "Locked: [{D3DCE3}%s{FFFFFF}]\n", (aptInfo[CurrentAptID[playerid]][apt_locked]) ? ("Yes") : ("No"));
    strcat_format(str, sizeof(str), "Safe: [{D3DCE3}$%s{FFFFFF}]\n \n", AddCommas(aptInfo[CurrentAptID[playerid]][apt_safe]));
    strcat_format(str, sizeof(str), "[Furniture]\n");
    strcat_format(str, sizeof(str), "[Sell property]");
    ShowPlayerDialog( playerid, APARTMENT_MENU, DIALOG_STYLE_LIST, "{D3DCE3}Property Configuration", str, "Select", "Close");
    return 1;
}
