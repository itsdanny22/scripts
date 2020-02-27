/*A vehicle scrappage system linked to the vehicle system, where players can drop off abandoned vehicles and recieve a
reward depending on the value of the vehicle. Abandonded vehicles are vehicles that have been spawned but the owner has disconnected (logged off)
*/

#include <YSI\y_hooks>

new scrapVehicle[MAX_VEHICLES];

hook OnPlayerStateChange(playerid, newstate, oldstate)
{
    if(newstate == PLAYER_STATE_DRIVER)
    {
		new vehicleid = GetPlayerVehicleID(playerid);
		if(scrapVehicle[vehicleid] == 1)
		{
		    SendClientMessage(playerid, SERVER_MESSAGE, "You have found an abandoned vehicle.");
		    SendClientMessage(playerid, SERVER_MESSAGE, "You can return this vehicle to a vehicle scrapyard, using a tow truck, for a cash reward.");
		    RemovePlayerFromVehicle(playerid);
		}
	}
	return 1;
}

hook OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if(( newkeys == KEY_HANDBRAKE ) && (IsPlayerInAnyVehicle( playerid )) && (GetPlayerState( playerid ) == PLAYER_STATE_DRIVER ) ) //attach vehicle to towtruck
	{
		if (GetVehicleModel(GetPlayerVehicleID(playerid)) == 525)
		{
			new
				Float:pX,Float:pY,Float:pZ,
				Float:vX,Float:vY,Float:vZ,
				Found=0,
				vid=0;

			GetPlayerPos(playerid,pX,pY,pZ);

			while((vid<MAX_VEHICLES)&&(!Found))
			{
				vid++;
				GetVehiclePos(vid, vX, vY, vZ);
				if ((floatabs(pX-vX)<5.0)&&(floatabs(pY-vY)<7.0)&&(floatabs(pZ-vZ)<7.0)&&(vid!=GetPlayerVehicleID(playerid)))
				{
					Found=1;
					if(IsTrailerAttachedToVehicle(GetPlayerVehicleID(playerid)))
					{
						DetachTrailerFromVehicle(GetPlayerVehicleID(playerid));
					}
					AttachTrailerToVehicle(vid,GetPlayerVehicleID(playerid));
				}
			}
		}
	}
	return 1;
}

hook OnVehicleDeath(vehicleid, killerid)
{
	for(new i = 1, j = GetVehiclePoolSize(); i <= j; i ++)
	{
	    if(scrapVehicle[i] == 1)
	    {
			scrapVehicle[i] = 0;
			DestroyVehicle(scrapVehicle[i]);
		}
	}
	return 1;
}

CMD:scrap(playerid, params[])
{
	if(!IsPlayerInDynamicCP(playerid, scrapyardCP))
	    return Error(playerid, "You must be at the scrap yard checkpoint");

	if(!IsPlayerInAnyVehicle(playerid))
	    return Error(playerid, "You must be in a vehicle to use this command");

    if(GetPlayerState(playerid) != PLAYER_STATE_DRIVER)
        return Error(playerid, "You must be the driver of a vehicle");

	if(GetVehicleModel(GetPlayerVehicleID(playerid)) != 525)
	    return Error(playerid, "You must be in a tow truck");

	if(GetPlayerScore(playerid) < 100)
	    return Error(playerid, "You must have atleast 100 score to use this command");

	if(!IsTrailerAttachedToVehicle(GetPlayerVehicleID(playerid)))
	    return Error(playerid, "You do not have any vehicles attached to your truck");

	if(scrapVehicle[GetVehicleTrailer(GetPlayerVehicleID(playerid))] != 1)
	    return Error(playerid, "This vehicle is not wanted for scrapping");

	new reward, str[128];

	for(new i = 0; i != sizeof(Dealership); ++i)
	{
	    if(Dealership[i][dealerModel] == GetVehicleModel(GetVehicleTrailer(GetPlayerVehicleID(playerid))))
    	{
    	    reward = floatround(Dealership[i][dealerPrice]/85);
		}
	}

	GivePlayerCash(playerid, reward);
	SetPlayerScore(playerid, GetPlayerScore(playerid)+1);
	format(str, sizeof(str), "You have successfully scrapped the %s and received $%d and 1 score!", GetVehicleName(GetVehicleModel(GetVehicleTrailer(GetPlayerVehicleID(playerid)))), reward);
	SendClientMessage(playerid, -1, str);

	scrapVehicle[GetVehicleTrailer(GetPlayerVehicleID(playerid))] = 0;
	DestroyVehicle(GetVehicleTrailer(GetPlayerVehicleID(playerid)));
	return 1;
}

