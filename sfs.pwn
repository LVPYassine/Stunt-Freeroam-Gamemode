/**
 * Copyright (c) 2017 Stunt Freeroam Server
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program.
 * If not, see <http://www.gnu.org/licenses/>.
*/

 /*AUTHOR ***********************
  @Yassine - SA-MP Scripter
 ********************************/

#include <a_samp>

/*
	New Functions on this gamemode:
		- Command processor for discord DCCMD:cmd(channel[], user[], params[])
		- IRC_Reply(ERROR/SUCCESS/USAGE, channel[], msg[])
		- Support SQLite/MySQL saving system.
*/

/* TO DO:
        - Add Derbys
        - fix the discord crash problem
*/

#include <sscanf2>
#include <streamer>
#include <YSI\y_iterate>
#include <AFKManager>

native gpci(playerid, string[], length);
native IsValidVehicle(vehicleid);
native WP_Hash(buffer[], len, const str[]);

#define INVALID_DIALOG_ID 99999
#define GetPlayerClientId gpci
#define IsPlayerSpawned(%0) PlayerInfo[%0][Spawned]

// Gamemode Configuration
#undef MAX_PLAYERS
	#define MAX_PLAYERS 100

#define USE_COMMAND_PROCESSOR 1
	#if USE_COMMAND_PROCESSOR == 1
		#include <zcmd>
	#endif

#define USE_SAVING_SYSTEM 1
	#if USE_SAVING_SYSTEM == 1

        #define USE_MYSQL 1
        #define USE_SQLITE 0

		#if USE_MYSQL == 1 && USE_SQLITE == 1
			#error "Error(2): Saving mode conflis (possiblity both enabled)"
		#endif
		#if USE_MYSQL == 0 && USE_SQLITE == 0
			#error "Error(3): Saving mode conflis (possiblity both disabled)"
		#endif

		#if USE_MYSQL == 1
			#include <a_mysql>

			static MySQL:Database;
			#define MYSQL_HOST "db4free.net"
			#define MYSQL_USER "yassine_sap2"
			#define MYSQL_PASS "yassine23"
			#define MYSQL_DATA "saplayground_2"
            #define MYSQL_PORT 3307

        #if !defined MYSQL_HOST || !defined MYSQL_USER || !defined MYSQL_DATA 
			#error "Error(4): Mysql saving mode enabled but MySQL informations are not defined."
		#endif 

		#endif

		#if USE_SQLITE == 1

			static DB:Database;
			#define SQLITE_DATABASE ""

		#endif
	#endif

	#if USE_SAVING_SYSTEM == 0
		#error "Error(6): No saving mode selected."
	#endif

#define USE_EXTERN_CHAT 1
	#if USE_EXTERN_CHAT == 1

        #define USE_IRC 1
        #define USE_DISCORD 0
        #define USE_TS3 0

		#if USE_IRC == 1
			#include <irc>

			#define IRC_SERVER "irc.gtanet.com"
			#define IRC_PORT 6667

			#define IRC_BOT_1 "StrikerX"
			#define IRC_BOT_2 "EliteX"
			#define IRC_BOT_3 "ZanderX"

			#define IRC_ECHO "#sfs.echo"
			#define IRC_PASS "yassine23" // ident password leave it like this if you wont use it

		#endif

		#if USE_DISCORD == 1
			#include <discord-connector>

			#define DISCORD_TOKEN "MzIxNzg3NDI4NDg0NTQ2NTc0.DBjHcQ.SUbjZVMfR-1Y5fth2b4rj3kGykw"

			#define DISCORD_ECHO "echo_channel"

            // Channel Command System

            #define DCC_COMMAND_PREFIX '!'

            #define DCCMD:%1(%2) \
                forward dccmd_%1(%2); \
                public dccmd_%1(%2)

            #define dccmd(%1,%2,%3) \
                DCCMD:%1(%2, %3, %4)

            static bool:DCC_g_OCM = false;

            public OnGameModeInit()
            {
                DCC_g_OCM = funcidx("DCC_OUS") != -1;
                if (funcidx("DCC_OnGameModeInit") != -1)
                {
                    return CallLocalFunction("DCC_OnGameModeInit", "");
                }
                return 1;
            }

            #if defined _ALS_OnGameModeInit
                #undef OnGameModeInit
            #else
                #define _ALS_OnGameModeInit
            #endif
            #define OnGameModeInit DCC_OnGameModeInit

            forward DCC_OnGameModeInit();

            public DCC_OnChannelMessage(DCC_Channel:channel, const author[], const message[])
            {
                new channeln[24];
                DCC_GetChannelName(channel, channeln, sizeof(channeln));
                if (message[0] == DCC_COMMAND_PREFIX)
                {
                    new function[32], pos = 0;
                    while (message[++pos] > ' ')
                    {
                        function[pos - 1] = tolower(message[pos]);
                        if (pos > (sizeof(function) - 1))
                        {
                            break;
                        }
                    } 
                    format(function, sizeof(function), "dccmd_%s", function);
                    while (message[pos] == ' ')
                    {
                        pos++;
                    }
                    if (!message[pos])
                    {
                        CallLocalFunction(function, "sss", channeln, author, "\1");
                    }
                    else
                    {
                        CallLocalFunction(function, "sss", channeln, author, message[pos]);
                    }
                }
                if (DCC_g_OCM)
                {
                    return CallLocalFunction("DCC_OCM", "sss", channeln, author, message);
                }
                return 1;
            }

            #if defined _ALS_DCC_OnChannelMessage
                #undef IRC_DCC_OnChannelMessage
            #else
                #define _ALS_DCC_OnChannelMessage
            #endif
            #define DCC_OnChannelMessage DCC_OCM

            forward DCC_OCM(DCC_Channel:channel, const author[], const message[]);

		#endif

		#if USE_TS3 == 1
			#include <tsconnector>

			#define TS3_SERVER ""
			#define TS3_PORT  9987

			#define TS3_ADMIN ""
			#define TS3_PASWD ""
			#define TS3_NICK ""

		#endif

		#if USE_IRC == 0 && USE_DISCORD == 0 && USE_TS3 == 0
			#error "Error(7): USE_EXTERN_CHAT enabled but there no extern chat mode enabled."
		#endif
	#endif

#define MAX_MONEYBAGS 150 
#define MB_DELAY 120 

#define MAX_MONEYBAG_MONEY 37000
#define MIN_MONEYBAG_MONEY 13000

#define WEAPONS_BOUNS

#if defined WEAPONS_BOUNS

#define MAX_WEAPONS_AMMO 1500 
#define MIN_WEAPONS_AMMO 200 

#define MAX_HOUSES 100
#define MAX_HOUSE_NAME 48
#define MAX_HOUSE_PASSWORD 16
#define MAX_HOUSE_ADDRESS 48
#define MAX_INT_NAME 32
#define INVALID_HOUSE_ID -1
#define HOUSE_COOLDOWN 6
#define LIMIT_PER_PLAYER 3

#define NEWS "Server has been opened to public!"

new WeaponsBouns[] = 
{
	9,  // Chainsaw
	16, // Grenade
	24, // Desert Eagle
	26, // Shotgun Sawn-off
	27, // Combat-Shotgun
	29, // MP5
	31, // M4
	34  // Sniper Rifle
};

#if MAX_WEAPONS_AMMO < MIN_WEAPONS_AMMO
	#error Fail: MAX_* must be highter than MIN_*
#endif

#endif

#if MAX_MONEYBAG_MONEY < MIN_MONEYBAG_MONEY
	#error Fail: MAX_* must be highter than MIN_*
#endif

#define MAX_CHAT_SIZE 120

/* Some functions */
#define ERROR 0
#define WARNING 1
#define USAGE 2
#define SUCCESS 3

// Gamemode Variables
enum    _:e_lockmodes
{
	LOCK_MODE_NOLOCK,
	LOCK_MODE_PASSWORD,
	LOCK_MODE_KEYS,
	LOCK_MODE_OWNER
}

enum    _:e_selectmodes
{
	SELECT_MODE_NONE,
	SELECT_MODE_EDIT,
	SELECT_MODE_SELL
}

enum ENUM_PLAYER_INFO
{
	Name[MAX_PLAYER_NAME],
	Password[129],
	IP[16],
	Admin,
	bool:VIP,
	Deaths,
	Kills,
	Skin,
	Time,
	AccountId,
	Money,
    Color,
    Vehicle,
	ClientId[41],
	bool:Spawned,
    bool:Jailed,
    JailTimer,
    bool:Muted,
    MuteTimer,
    LoginAttemps,
    bool:Stunt,
    bool:CreatedRamp,
    Ramp,
    Pers,
    Fighting,
    bool:InDM,
    DmZone,
    Teleport,
    Given
};

enum 
{
    DIALOG_REGISTER = 0,
    DIALOG_LOGIN,
    DIALOG_DM,
    DIALOG_TELEPORTS,
    DIALOG_STATS,
    DIALOG_BUY_HOUSE,
	DIALOG_HOUSE_PASSWORD,
	DIALOG_HOUSE_MENU,
	DIALOG_HOUSE_NAME,
	DIALOG_HOUSE_NEW_PASSWORD,
	DIALOG_HOUSE_LOCK,
	DIALOG_SAFE_MENU,
	DIALOG_SAFE_TAKE,
	DIALOG_SAFE_PUT,
	DIALOG_GUNS_MENU,
	DIALOG_GUNS_TAKE,
	DIALOG_FURNITURE_MENU,
	DIALOG_FURNITURE_BUY,
	DIALOG_FURNITURE_SELL,
	DIALOG_VISITORS_MENU,
	DIALOG_VISITORS,
	DIALOG_KEYS_MENU,
	DIALOG_KEYS,
	DIALOG_SAFE_HISTORY,
	DIALOG_MY_KEYS,
	DIALOG_BUY_HOUSE_FROM_OWNER,
	DIALOG_SELL_HOUSE,
	DIALOG_SELLING_PRICE
};

enum ENUM_MB_INFO
{
    Float:XPOS,
    Float:YPOS,
    Float:ZPOS,
    Name[24]
};

enum    e_house
{
	Name[MAX_HOUSE_NAME],
	Owner[MAX_PLAYER_NAME],
	Password[MAX_HOUSE_PASSWORD],
	Address[MAX_HOUSE_ADDRESS],
	Float: houseX,
	Float: houseY,
	Float: houseZ,
	Price,
	SalePrice,
	Interior,
	LockMode,
	SafeMoney,
	LastEntered,
	Text3D: HouseLabel,
	HousePickup,
	HouseIcon,
	bool: Save
};

enum    e_interior
{
	IntName[MAX_INT_NAME],
	Float: intX,
	Float: intY,
	Float: intZ,
	intID,
	Text3D: intLabel,
	intPickup
};

enum    e_furnituredata
{
	ModelID,
	Name[32],
	Price
};

enum    e_furniture
{
	SQLID,
	HouseID,
	ArrayID,
	Float: furnitureX,
	Float: furnitureY,
	Float: furnitureZ,
	Float: furnitureRX,
	Float: furnitureRY,
	Float: furnitureRZ
};

enum    e_sazone
{
    SAZONE_NAME[28],
    Float: SAZONE_AREA[6]
};

new 

    #if USE_EXTERN_CHAT == 1
        starttime,
        #if USE_IRC == 1
            IRCBots[4], 
            GroupId,
        #endif
        #if USE_DISCORD == 1
            DCC_Channel:DDC_Echo_Channel,
        #endif
    #endif
	PlayerInfo[MAX_PLAYERS][ENUM_PLAYER_INFO],
    reconnect_[MAX_PLAYERS],
    VehicleNames[][] =
    {
        "Landstalker", "Bravura", "Buffalo", "Linerunner", "Perrenial", "Sentinel",
        "Dumper", "Firetruck", "Trashmaster", "Stretch", "Manana", "Infernus",
        "Voodoo", "Pony", "Mule", "Cheetah", "Ambulance", "Leviathan", "Moonbeam",
        "Esperanto", "Taxi", "Washington", "Bobcat", "Whoopee", "BF Injection",
        "Hunter", "Premier", "Enforcer", "Securicar", "Banshee", "Predator", "Bus",
        "Rhino", "Barracks", "Hotknife", "Trailer", "Previon", "Coach", "Cabbie",
        "Stallion", "Rumpo", "RC Bandit", "Romero", "Packer", "Monster", "Admiral",
        "Squalo", "Seasparrow", "Pizzaboy", "Tram", "Trailer", "Turismo", "Speeder",
        "Reefer", "Tropic", "Flatbed", "Yankee", "Caddy", "Solair", "Berkley's RC Van",
        "Skimmer", "PCJ-600", "Faggio", "Freeway", "RC Baron", "RC Raider", "Glendale",
        "Oceanic","Sanchez", "Sparrow", "Patriot", "Quad", "Coastguard", "Dinghy",
        "Hermes", "Sabre", "Rustler", "ZR-350", "Walton", "Regina", "Comet", "BMX",
        "Burrito", "Camper", "Marquis", "Baggage", "Dozer", "Maverick", "News Chopper",
        "Rancher", "FBI Rancher", "Virgo", "Greenwood", "Jetmax", "Hotring", "Sandking",
        "Blista Compact", "Police Maverick", "Boxville", "Benson", "Mesa", "RC Goblin",
        "Hotring Racer A", "Hotring Racer B", "Bloodring Banger", "Rancher", "Super GT",
        "Elegant", "Journey", "Bike", "Mountain Bike", "Beagle", "Cropduster", "Stunt",
        "Tanker", "Roadtrain", "Nebula", "Majestic", "Buccaneer", "Shamal", "Hydra",
        "FCR-900", "NRG-500", "HPV1000", "Cement Truck", "Tow Truck", "Fortune",
        "Cadrona", "FBI Truck", "Willard", "Forklift", "Tractor", "Combine", "Feltzer",
        "Remington", "Slamvan", "Blade", "Freight", "Streak", "Vortex", "Vincent",
        "Bullet", "Clover", "Sadler", "Firetruck", "Hustler", "Intruder", "Primo",
        "Cargobob", "Tampa", "Sunrise", "Merit", "Utility", "Nevada", "Yosemite",
        "Windsor", "Monster", "Monster", "Uranus", "Jester", "Sultan", "Stratium",
        "Elegy", "Raindance", "RC Tiger", "Flash", "Tahoma", "Savanna", "Bandito",
        "Freight Flat", "Streak Carriage", "Kart", "Mower", "Dune", "Sweeper",
        "Broadway", "Tornado", "AT-400", "DFT-30", "Huntley", "Stafford", "BF-400",
        "News Van", "Tug", "Trailer", "Emperor", "Wayfarer", "Euros", "Hotdog", "Club",
        "Freight Box", "Trailer", "Andromada", "Dodo", "RC Cam", "Launch", "Police Car",
        "Police Car", "Police Car", "Police Ranger", "Picador", "S.W.A.T", "Alpha",
        "Phoenix", "Glendale", "Sadler", "Luggage", "Luggage", "Stairs", "Boxville",
        "Tiller", "Utility Trailer"
    },

    SPAWN_WEAPONS[][] =
    {
        //{weaponid, ammo}
        {24, 800},
        {26, 900},
        {28, 500},
        {30, 700}
    },
    PlayerColors[200] =
    {
        0xFF8C13FF,0xC715FFFF,0x20B2AAFF,0xDC143CFF,0x6495EDFF,0xf0e68cFF,0x778899FF,0xFF1493FF,0xF4A460FF,
        0xEE82EEFF,0xFFD720FF,0x8b4513FF,0x4949A0FF,0x148b8bFF,0x14ff7fFF,0x556b2fFF,0x0FD9FAFF,0x10DC29FF,
        0x534081FF,0x0495CDFF,0xEF6CE8FF,0xBD34DAFF,0x247C1BFF,0x0C8E5DFF,0x635B03FF,0xCB7ED3FF,0x65ADEBFF,
        0x5C1ACCFF,0xF2F853FF,0x11F891FF,0x7B39AAFF,0x53EB10FF,0x54137DFF,0x275222FF,0xF09F5BFF,0x3D0A4FFF,
        0x22F767FF,0xD63034FF,0x9A6980FF,0xDFB935FF,0x3793FAFF,0x90239DFF,0xE9AB2FFF,0xAF2FF3FF,0x057F94FF,
        0xB98519FF,0x388EEAFF,0x028151FF,0xA55043FF,0x0DE018FF,0x93AB1CFF,0x95BAF0FF,0x369976FF,0x18F71FFF,
        0x4B8987FF,0x491B9EFF,0x829DC7FF,0xBCE635FF,0xCEA6DFFF,0x20D4ADFF,0x2D74FDFF,0x3C1C0DFF,0x12D6D4FF,
        0x48C000FF,0x2A51E2FF,0xE3AC12FF,0xFC42A8FF,0x2FC827FF,0x1A30BFFF,0xB740C2FF,0x42ACF5FF,0x2FD9DEFF,
        0xFAFB71FF,0x05D1CDFF,0xC471BDFF,0x94436EFF,0xC1F7ECFF,0xCE79EEFF,0xBD1EF2FF,0x93B7E4FF,0x3214AAFF,
        0x184D3BFF,0xAE4B99FF,0x7E49D7FF,0x4C436EFF,0xFA24CCFF,0xCE76BEFF,0xA04E0AFF,0x9F945CFF,0xDCDE3DFF,
        0x10C9C5FF,0x70524DFF,0x0BE472FF,0x8A2CD7FF,0x6152C2FF,0xCF72A9FF,0xE59338FF,0xEEDC2DFF,0xD8C762FF,
        0xD8C762FF,0xFF8C13FF,0xC715FFFF,0x20B2AAFF,0xDC143CFF,0x6495EDFF,0xf0e68cFF,0x778899FF,0xFF1493FF,
        0xF4A460FF,0xEE82EEFF,0xFFD720FF,0x8b4513FF,0x4949A0FF,0x148b8bFF,0x14ff7fFF,0x556b2fFF,0x0FD9FAFF,
        0x10DC29FF,0x534081FF,0x0495CDFF,0xEF6CE8FF,0xBD34DAFF,0x247C1BFF,0x0C8E5DFF,0x635B03FF,0xCB7ED3FF,
        0x65ADEBFF,0x5C1ACCFF,0xF2F853FF,0x11F891FF,0x7B39AAFF,0x53EB10FF,0x54137DFF,0x275222FF,0xF09F5BFF,
        0x3D0A4FFF,0x22F767FF,0xD63034FF,0x9A6980FF,0xDFB935FF,0x3793FAFF,0x90239DFF,0xE9AB2FFF,0xAF2FF3FF,
        0x057F94FF,0xB98519FF,0x388EEAFF,0x028151FF,0xA55043FF,0x0DE018FF,0x93AB1CFF,0x95BAF0FF,0x369976FF,
        0x18F71FFF,0x4B8987FF,0x491B9EFF,0x829DC7FF,0xBCE635FF,0xCEA6DFFF,0x20D4ADFF,0x2D74FDFF,0x3C1C0DFF,
        0x12D6D4FF,0x48C000FF,0x2A51E2FF,0xE3AC12FF,0xFC42A8FF,0x2FC827FF,0x1A30BFFF,0xB740C2FF,0x42ACF5FF,
        0x2FD9DEFF,0xFAFB71FF,0x05D1CDFF,0xC471BDFF,0x94436EFF,0xC1F7ECFF,0xCE79EEFF,0xBD1EF2FF,0x93B7E4FF,
        0x3214AAFF,0x184D3BFF,0xAE4B99FF,0x7E49D7FF,0x4C436EFF,0xFA24CCFF,0xCE76BEFF,0xA04E0AFF,0x9F945CFF,
        0xDCDE3DFF,0x10C9C5FF,0x70524DFF,0x0BE472FF,0x8A2CD7FF,0x6152C2FF,0xCF72A9FF,0xE59338FF,0xEEDC2DFF,
        0xD8C762FF,0xD8C762FF
    },
    NPCCars[10],
    NPCIds = 0,
    NPCTimer,
    vehicles = 0,
    amessage[][] =
    {
        "Catched a hacker? report him now! with using /report [playerid] [reason]",
        "Racists or flamming any kind of insult is forbideen.",
        "VIP Membership has been opened, use /donate for more informations.",
        "Any kind of mods or hacks will get you banned from server.",
        "You are new at server? use /cmds or pm and admin that can guide you using @ [text].",
        "PLEASE DONT USE CAPS, we can see your message.",
        "Be a always connected with our server, wity creating a new account at our forum www.sfs.ml.",
        "Join our irc if you are busy! stay always connected with players! at pool.irc.tl #sfs.echo"
    },
	m_Location[24],
	m_Pickup, 
	m_Timer,
	m_Count = 0,
	MBInfo[MAX_MONEYBAGS][ENUM_MB_INFO],
	bool:m_Found = true,
	bool:m_Toggle = false,
    Text:Connect[7],
    Text:RequestClass[2],
    Text:Death[3],
    PlayerText:StatusBar,
    Float:RandomSpawns[][] = 
    {
      //  Float:X    Float:Y   Float:Z  Float:A
        {1958.3783, 1343.1572, 15.3746, 270.1425},
        {1958.3783, 1343.1572, 15.3746, 270.1425},
        {2004.7198, 1544.6941, 13.5908, 269.9990},
        {2164.8130, 1900.1031, 10.8203, 138.8320}, 
        {2162.7280, 2162.8359, 10.8203, 151.2920}, 
        {2533.3838, 2089.9836, 10.8203, 119.0750}, 
        {2094.6301, 1550.2998, 10.8203, 123.7136}, 
        {1958.3783, 1343.1572, 15.3746, 269.1425},
        {-1590.5083, 716.0220, -5.2422, 269.2736}, 
        {2193.7366, 2007.4865, 12.2894, 358.2378}
    },
    AdminGate[3],
    bool:AdminGate_Status[3],
    g_Characters[][] =
    {
        "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
        "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
        "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
        "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"
    },
    g_Chars[16] = "",
    g_Cash,
    bool: g_TestBusy,
 	HouseData[MAX_HOUSES][e_house],
	InHouse[MAX_PLAYERS] = {INVALID_HOUSE_ID, ...},
	SelectMode[MAX_PLAYERS] = {SELECT_MODE_NONE, ...},
	LastVisitedHouse[MAX_PLAYERS] = {INVALID_HOUSE_ID, ...},
	ListPage[MAX_PLAYERS] = {0, ...},
	bool: EditingFurniture[MAX_PLAYERS] = {false, ...},
    bool:IsSnowy,
    snowObject[MAX_PLAYERS][20+1],
    snowActive[MAX_PLAYERS],
    HouseInteriors[][e_interior] = {
    // int name, x, y, z, intid
		{"Interior 1", 2233.4900, -1114.4435, 1050.8828, 5},
		{"Interior 2", 2196.3943, -1204.1359, 1049.0234, 6},
		{"Interior 3", 2318.1616, -1026.3762, 1050.2109, 9},
		{"Interior 4", 421.8333, 2536.9814, 10.0000, 10},
		{"Interior 5", 225.5707, 1240.0643, 1082.1406, 2},
		{"Interior 6", 2496.2087, -1692.3149, 1014.7422, 3},
		{"Interior 7", 226.7545, 1114.4180, 1080.9952, 5},
		{"Interior 8", 2269.9636, -1210.3275, 1047.5625, 10}
    },
    HouseFurnitures[][e_furnituredata] = {
	// modelid, furniture name, price
	    {3111, "Building Plan", 500},
	    {2894, "Book", 20},
	    {2277, "Cat Picture", 100},
	    {1753, "Leather Couch", 150},
	    {1703, "Black Couch", 200},
	    {1255, "Lounger", 75},
	    {19581, "Frying Pan", 10},
	    {19584, "Sauce Pan", 12},
	    {19590, "Woozie's Sword", 1000},
	    {19525, "Wedding Cake", 50},
	    {1742, "Bookshelf", 80},
	    {1518, "TV 1", 130},
	    {19609, "Drum Kit", 500},
		{19787, "Small LCD TV", 2000},
		{19786, "Big LCD TV", 4000},
		{2627, "Treadmill", 130}
	},
    SAZones[][e_sazone] = {
		{"The Big Ear",	                {-410.00,1403.30,-3.00,-137.90,1681.20,200.00}},
		{"Aldea Malvada",               {-1372.10,2498.50,0.00,-1277.50,2615.30,200.00}},
		{"Angel Pine",                  {-2324.90,-2584.20,-6.10,-1964.20,-2212.10,200.00}},
		{"Arco del Oeste",              {-901.10,2221.80,0.00,-592.00,2571.90,200.00}},
		{"Avispa Country Club",         {-2646.40,-355.40,0.00,-2270.00,-222.50,200.00}},
		{"Avispa Country Club",         {-2831.80,-430.20,-6.10,-2646.40,-222.50,200.00}},
		{"Avispa Country Club",         {-2361.50,-417.10,0.00,-2270.00,-355.40,200.00}},
		{"Avispa Country Club",         {-2667.80,-302.10,-28.80,-2646.40,-262.30,71.10}},
		{"Avispa Country Club",         {-2470.00,-355.40,0.00,-2270.00,-318.40,46.10}},
		{"Avispa Country Club",         {-2550.00,-355.40,0.00,-2470.00,-318.40,39.70}},
		{"Back o Beyond",               {-1166.90,-2641.10,0.00,-321.70,-1856.00,200.00}},
		{"Battery Point",               {-2741.00,1268.40,-4.50,-2533.00,1490.40,200.00}},
		{"Bayside",                     {-2741.00,2175.10,0.00,-2353.10,2722.70,200.00}},
		{"Bayside Marina",              {-2353.10,2275.70,0.00,-2153.10,2475.70,200.00}},
		{"Beacon Hill",                 {-399.60,-1075.50,-1.40,-319.00,-977.50,198.50}},
		{"Blackfield",                  {964.30,1203.20,-89.00,1197.30,1403.20,110.90}},
		{"Blackfield",                  {964.30,1403.20,-89.00,1197.30,1726.20,110.90}},
		{"Blackfield Chapel",           {1375.60,596.30,-89.00,1558.00,823.20,110.90}},
		{"Blackfield Chapel",           {1325.60,596.30,-89.00,1375.60,795.00,110.90}},
		{"Blackfield Intersection",     {1197.30,1044.60,-89.00,1277.00,1163.30,110.90}},
		{"Blackfield Intersection",     {1166.50,795.00,-89.00,1375.60,1044.60,110.90}},
		{"Blackfield Intersection",     {1277.00,1044.60,-89.00,1315.30,1087.60,110.90}},
		{"Blackfield Intersection",     {1375.60,823.20,-89.00,1457.30,919.40,110.90}},
		{"Blueberry",                   {104.50,-220.10,2.30,349.60,152.20,200.00}},
		{"Blueberry",                   {19.60,-404.10,3.80,349.60,-220.10,200.00}},
		{"Blueberry Acres",             {-319.60,-220.10,0.00,104.50,293.30,200.00}},
		{"Caligula's Palace",           {2087.30,1543.20,-89.00,2437.30,1703.20,110.90}},
		{"Caligula's Palace",           {2137.40,1703.20,-89.00,2437.30,1783.20,110.90}},
		{"Calton Heights",              {-2274.10,744.10,-6.10,-1982.30,1358.90,200.00}},
		{"Chinatown",                   {-2274.10,578.30,-7.60,-2078.60,744.10,200.00}},
		{"City Hall",                   {-2867.80,277.40,-9.10,-2593.40,458.40,200.00}},
		{"Come-A-Lot",                  {2087.30,943.20,-89.00,2623.10,1203.20,110.90}},
		{"Commerce",                    {1323.90,-1842.20,-89.00,1701.90,-1722.20,110.90}},
		{"Commerce",                    {1323.90,-1722.20,-89.00,1440.90,-1577.50,110.90}},
		{"Commerce",                    {1370.80,-1577.50,-89.00,1463.90,-1384.90,110.90}},
		{"Commerce",                    {1463.90,-1577.50,-89.00,1667.90,-1430.80,110.90}},
		{"Commerce",                    {1583.50,-1722.20,-89.00,1758.90,-1577.50,110.90}},
		{"Commerce",                    {1667.90,-1577.50,-89.00,1812.60,-1430.80,110.90}},
		{"Conference Center",           {1046.10,-1804.20,-89.00,1323.90,-1722.20,110.90}},
		{"Conference Center",           {1073.20,-1842.20,-89.00,1323.90,-1804.20,110.90}},
		{"Cranberry Station",           {-2007.80,56.30,0.00,-1922.00,224.70,100.00}},
		{"Creek",                       {2749.90,1937.20,-89.00,2921.60,2669.70,110.90}},
		{"Dillimore",                   {580.70,-674.80,-9.50,861.00,-404.70,200.00}},
		{"Doherty",                     {-2270.00,-324.10,-0.00,-1794.90,-222.50,200.00}},
		{"Doherty",                     {-2173.00,-222.50,-0.00,-1794.90,265.20,200.00}},
		{"Downtown",                    {-1982.30,744.10,-6.10,-1871.70,1274.20,200.00}},
		{"Downtown",                    {-1871.70,1176.40,-4.50,-1620.30,1274.20,200.00}},
		{"Downtown",                    {-1700.00,744.20,-6.10,-1580.00,1176.50,200.00}},
		{"Downtown",                    {-1580.00,744.20,-6.10,-1499.80,1025.90,200.00}},
		{"Downtown",                    {-2078.60,578.30,-7.60,-1499.80,744.20,200.00}},
		{"Downtown",                    {-1993.20,265.20,-9.10,-1794.90,578.30,200.00}},
		{"Downtown Los Santos",         {1463.90,-1430.80,-89.00,1724.70,-1290.80,110.90}},
		{"Downtown Los Santos",         {1724.70,-1430.80,-89.00,1812.60,-1250.90,110.90}},
		{"Downtown Los Santos",         {1463.90,-1290.80,-89.00,1724.70,-1150.80,110.90}},
		{"Downtown Los Santos",         {1370.80,-1384.90,-89.00,1463.90,-1170.80,110.90}},
		{"Downtown Los Santos",         {1724.70,-1250.90,-89.00,1812.60,-1150.80,110.90}},
		{"Downtown Los Santos",         {1370.80,-1170.80,-89.00,1463.90,-1130.80,110.90}},
		{"Downtown Los Santos",         {1378.30,-1130.80,-89.00,1463.90,-1026.30,110.90}},
		{"Downtown Los Santos",         {1391.00,-1026.30,-89.00,1463.90,-926.90,110.90}},
		{"Downtown Los Santos",         {1507.50,-1385.20,110.90,1582.50,-1325.30,335.90}},
		{"East Beach",                  {2632.80,-1852.80,-89.00,2959.30,-1668.10,110.90}},
		{"East Beach",                  {2632.80,-1668.10,-89.00,2747.70,-1393.40,110.90}},
		{"East Beach",                  {2747.70,-1668.10,-89.00,2959.30,-1498.60,110.90}},
		{"East Beach",                  {2747.70,-1498.60,-89.00,2959.30,-1120.00,110.90}},
		{"East Los Santos",             {2421.00,-1628.50,-89.00,2632.80,-1454.30,110.90}},
		{"East Los Santos",             {2222.50,-1628.50,-89.00,2421.00,-1494.00,110.90}},
		{"East Los Santos",             {2266.20,-1494.00,-89.00,2381.60,-1372.00,110.90}},
		{"East Los Santos",             {2381.60,-1494.00,-89.00,2421.00,-1454.30,110.90}},
		{"East Los Santos",             {2281.40,-1372.00,-89.00,2381.60,-1135.00,110.90}},
		{"East Los Santos",             {2381.60,-1454.30,-89.00,2462.10,-1135.00,110.90}},
		{"East Los Santos",             {2462.10,-1454.30,-89.00,2581.70,-1135.00,110.90}},
		{"Easter Basin",                {-1794.90,249.90,-9.10,-1242.90,578.30,200.00}},
		{"Easter Basin",                {-1794.90,-50.00,-0.00,-1499.80,249.90,200.00}},
		{"Easter Bay Airport",          {-1499.80,-50.00,-0.00,-1242.90,249.90,200.00}},
		{"Easter Bay Airport",          {-1794.90,-730.10,-3.00,-1213.90,-50.00,200.00}},
		{"Easter Bay Airport",          {-1213.90,-730.10,0.00,-1132.80,-50.00,200.00}},
		{"Easter Bay Airport",          {-1242.90,-50.00,0.00,-1213.90,578.30,200.00}},
		{"Easter Bay Airport",          {-1213.90,-50.00,-4.50,-947.90,578.30,200.00}},
		{"Easter Bay Airport",          {-1315.40,-405.30,15.40,-1264.40,-209.50,25.40}},
		{"Easter Bay Airport",          {-1354.30,-287.30,15.40,-1315.40,-209.50,25.40}},
		{"Easter Bay Airport",          {-1490.30,-209.50,15.40,-1264.40,-148.30,25.40}},
		{"Easter Bay Chemicals",        {-1132.80,-768.00,0.00,-956.40,-578.10,200.00}},
		{"Easter Bay Chemicals",        {-1132.80,-787.30,0.00,-956.40,-768.00,200.00}},
		{"El Castillo del Diablo",      {-464.50,2217.60,0.00,-208.50,2580.30,200.00}},
		{"El Castillo del Diablo",      {-208.50,2123.00,-7.60,114.00,2337.10,200.00}},
		{"El Castillo del Diablo",      {-208.50,2337.10,0.00,8.40,2487.10,200.00}},
		{"El Corona",                   {1812.60,-2179.20,-89.00,1970.60,-1852.80,110.90}},
		{"El Corona",                   {1692.60,-2179.20,-89.00,1812.60,-1842.20,110.90}},
		{"El Quebrados",                {-1645.20,2498.50,0.00,-1372.10,2777.80,200.00}},
		{"Esplanade East",              {-1620.30,1176.50,-4.50,-1580.00,1274.20,200.00}},
		{"Esplanade East",              {-1580.00,1025.90,-6.10,-1499.80,1274.20,200.00}},
		{"Esplanade East",              {-1499.80,578.30,-79.60,-1339.80,1274.20,20.30}},
		{"Esplanade North",             {-2533.00,1358.90,-4.50,-1996.60,1501.20,200.00}},
		{"Esplanade North",             {-1996.60,1358.90,-4.50,-1524.20,1592.50,200.00}},
		{"Esplanade North",             {-1982.30,1274.20,-4.50,-1524.20,1358.90,200.00}},
		{"Fallen Tree",                 {-792.20,-698.50,-5.30,-452.40,-380.00,200.00}},
		{"Fallow Bridge",               {434.30,366.50,0.00,603.00,555.60,200.00}},
		{"Fern Ridge",                  {508.10,-139.20,0.00,1306.60,119.50,200.00}},
		{"Financial",                   {-1871.70,744.10,-6.10,-1701.30,1176.40,300.00}},
		{"Fisher's Lagoon",             {1916.90,-233.30,-100.00,2131.70,13.80,200.00}},
		{"Flint Intersection",          {-187.70,-1596.70,-89.00,17.00,-1276.60,110.90}},
		{"Flint Range",                 {-594.10,-1648.50,0.00,-187.70,-1276.60,200.00}},
		{"Fort Carson",                 {-376.20,826.30,-3.00,123.70,1220.40,200.00}},
		{"Foster Valley",               {-2270.00,-430.20,-0.00,-2178.60,-324.10,200.00}},
		{"Foster Valley",               {-2178.60,-599.80,-0.00,-1794.90,-324.10,200.00}},
		{"Foster Valley",               {-2178.60,-1115.50,0.00,-1794.90,-599.80,200.00}},
		{"Foster Valley",               {-2178.60,-1250.90,0.00,-1794.90,-1115.50,200.00}},
		{"Frederick Bridge",            {2759.20,296.50,0.00,2774.20,594.70,200.00}},
		{"Gant Bridge",                 {-2741.40,1659.60,-6.10,-2616.40,2175.10,200.00}},
		{"Gant Bridge",                 {-2741.00,1490.40,-6.10,-2616.40,1659.60,200.00}},
		{"Ganton",                      {2222.50,-1852.80,-89.00,2632.80,-1722.30,110.90}},
		{"Ganton",                      {2222.50,-1722.30,-89.00,2632.80,-1628.50,110.90}},
		{"Garcia",                      {-2411.20,-222.50,-0.00,-2173.00,265.20,200.00}},
		{"Garcia",                      {-2395.10,-222.50,-5.30,-2354.00,-204.70,200.00}},
		{"Garver Bridge",               {-1339.80,828.10,-89.00,-1213.90,1057.00,110.90}},
		{"Garver Bridge",               {-1213.90,950.00,-89.00,-1087.90,1178.90,110.90}},
		{"Garver Bridge",               {-1499.80,696.40,-179.60,-1339.80,925.30,20.30}},
		{"Glen Park",                   {1812.60,-1449.60,-89.00,1996.90,-1350.70,110.90}},
		{"Glen Park",                   {1812.60,-1100.80,-89.00,1994.30,-973.30,110.90}},
		{"Glen Park",                   {1812.60,-1350.70,-89.00,2056.80,-1100.80,110.90}},
		{"Green Palms",                 {176.50,1305.40,-3.00,338.60,1520.70,200.00}},
		{"Greenglass College",          {964.30,1044.60,-89.00,1197.30,1203.20,110.90}},
		{"Greenglass College",          {964.30,930.80,-89.00,1166.50,1044.60,110.90}},
		{"Hampton Barns",               {603.00,264.30,0.00,761.90,366.50,200.00}},
		{"Hankypanky Point",            {2576.90,62.10,0.00,2759.20,385.50,200.00}},
		{"Harry Gold Parkway",          {1777.30,863.20,-89.00,1817.30,2342.80,110.90}},
		{"Hashbury",                    {-2593.40,-222.50,-0.00,-2411.20,54.70,200.00}},
		{"Hilltop Farm",                {967.30,-450.30,-3.00,1176.70,-217.90,200.00}},
		{"Hunter Quarry",               {337.20,710.80,-115.20,860.50,1031.70,203.70}},
		{"Idlewood",                    {1812.60,-1852.80,-89.00,1971.60,-1742.30,110.90}},
		{"Idlewood",                    {1812.60,-1742.30,-89.00,1951.60,-1602.30,110.90}},
		{"Idlewood",                    {1951.60,-1742.30,-89.00,2124.60,-1602.30,110.90}},
		{"Idlewood",                    {1812.60,-1602.30,-89.00,2124.60,-1449.60,110.90}},
		{"Idlewood",                    {2124.60,-1742.30,-89.00,2222.50,-1494.00,110.90}},
		{"Idlewood",                    {1971.60,-1852.80,-89.00,2222.50,-1742.30,110.90}},
		{"Jefferson",                   {1996.90,-1449.60,-89.00,2056.80,-1350.70,110.90}},
		{"Jefferson",                   {2124.60,-1494.00,-89.00,2266.20,-1449.60,110.90}},
		{"Jefferson",                   {2056.80,-1372.00,-89.00,2281.40,-1210.70,110.90}},
		{"Jefferson",                   {2056.80,-1210.70,-89.00,2185.30,-1126.30,110.90}},
		{"Jefferson",                   {2185.30,-1210.70,-89.00,2281.40,-1154.50,110.90}},
		{"Jefferson",                   {2056.80,-1449.60,-89.00,2266.20,-1372.00,110.90}},
		{"Julius Thruway East",         {2623.10,943.20,-89.00,2749.90,1055.90,110.90}},
		{"Julius Thruway East",         {2685.10,1055.90,-89.00,2749.90,2626.50,110.90}},
		{"Julius Thruway East",         {2536.40,2442.50,-89.00,2685.10,2542.50,110.90}},
		{"Julius Thruway East",         {2625.10,2202.70,-89.00,2685.10,2442.50,110.90}},
		{"Julius Thruway North",        {2498.20,2542.50,-89.00,2685.10,2626.50,110.90}},
		{"Julius Thruway North",        {2237.40,2542.50,-89.00,2498.20,2663.10,110.90}},
		{"Julius Thruway North",        {2121.40,2508.20,-89.00,2237.40,2663.10,110.90}},
		{"Julius Thruway North",        {1938.80,2508.20,-89.00,2121.40,2624.20,110.90}},
		{"Julius Thruway North",        {1534.50,2433.20,-89.00,1848.40,2583.20,110.90}},
		{"Julius Thruway North",        {1848.40,2478.40,-89.00,1938.80,2553.40,110.90}},
		{"Julius Thruway North",        {1704.50,2342.80,-89.00,1848.40,2433.20,110.90}},
		{"Julius Thruway North",        {1377.30,2433.20,-89.00,1534.50,2507.20,110.90}},
		{"Julius Thruway South",        {1457.30,823.20,-89.00,2377.30,863.20,110.90}},
		{"Julius Thruway South",        {2377.30,788.80,-89.00,2537.30,897.90,110.90}},
		{"Julius Thruway West",         {1197.30,1163.30,-89.00,1236.60,2243.20,110.90}},
		{"Julius Thruway West",         {1236.60,2142.80,-89.00,1297.40,2243.20,110.90}},
		{"Juniper Hill",                {-2533.00,578.30,-7.60,-2274.10,968.30,200.00}},
		{"Juniper Hollow",              {-2533.00,968.30,-6.10,-2274.10,1358.90,200.00}},
		{"K.A.C.C. Military Fuels",     {2498.20,2626.50,-89.00,2749.90,2861.50,110.90}},
		{"Kincaid Bridge",              {-1339.80,599.20,-89.00,-1213.90,828.10,110.90}},
		{"Kincaid Bridge",              {-1213.90,721.10,-89.00,-1087.90,950.00,110.90}},
		{"Kincaid Bridge",              {-1087.90,855.30,-89.00,-961.90,986.20,110.90}},
		{"King's",                      {-2329.30,458.40,-7.60,-1993.20,578.30,200.00}},
		{"King's",                      {-2411.20,265.20,-9.10,-1993.20,373.50,200.00}},
		{"King's",                      {-2253.50,373.50,-9.10,-1993.20,458.40,200.00}},
		{"LVA Freight Depot",           {1457.30,863.20,-89.00,1777.40,1143.20,110.90}},
		{"LVA Freight Depot",           {1375.60,919.40,-89.00,1457.30,1203.20,110.90}},
		{"LVA Freight Depot",           {1277.00,1087.60,-89.00,1375.60,1203.20,110.90}},
		{"LVA Freight Depot",           {1315.30,1044.60,-89.00,1375.60,1087.60,110.90}},
		{"LVA Freight Depot",           {1236.60,1163.40,-89.00,1277.00,1203.20,110.90}},
		{"Las Barrancas",               {-926.10,1398.70,-3.00,-719.20,1634.60,200.00}},
		{"Las Brujas",                  {-365.10,2123.00,-3.00,-208.50,2217.60,200.00}},
		{"Las Colinas",                 {1994.30,-1100.80,-89.00,2056.80,-920.80,110.90}},
		{"Las Colinas",                 {2056.80,-1126.30,-89.00,2126.80,-920.80,110.90}},
		{"Las Colinas",                 {2185.30,-1154.50,-89.00,2281.40,-934.40,110.90}},
		{"Las Colinas",                 {2126.80,-1126.30,-89.00,2185.30,-934.40,110.90}},
		{"Las Colinas",                 {2747.70,-1120.00,-89.00,2959.30,-945.00,110.90}},
		{"Las Colinas",                 {2632.70,-1135.00,-89.00,2747.70,-945.00,110.90}},
		{"Las Colinas",                 {2281.40,-1135.00,-89.00,2632.70,-945.00,110.90}},
		{"Las Payasadas",               {-354.30,2580.30,2.00,-133.60,2816.80,200.00}},
		{"Las Venturas Airport",        {1236.60,1203.20,-89.00,1457.30,1883.10,110.90}},
		{"Las Venturas Airport",        {1457.30,1203.20,-89.00,1777.30,1883.10,110.90}},
		{"Las Venturas Airport",        {1457.30,1143.20,-89.00,1777.40,1203.20,110.90}},
		{"Las Venturas Airport",        {1515.80,1586.40,-12.50,1729.90,1714.50,87.50}},
		{"Last Dime Motel",             {1823.00,596.30,-89.00,1997.20,823.20,110.90}},
		{"Leafy Hollow",                {-1166.90,-1856.00,0.00,-815.60,-1602.00,200.00}},
		{"Liberty City",                {-1000.00,400.00,1300.00,-700.00,600.00,1400.00}},
		{"Lil' Probe Inn",              {-90.20,1286.80,-3.00,153.80,1554.10,200.00}},
		{"Linden Side",                 {2749.90,943.20,-89.00,2923.30,1198.90,110.90}},
		{"Linden Station",              {2749.90,1198.90,-89.00,2923.30,1548.90,110.90}},
		{"Linden Station",              {2811.20,1229.50,-39.50,2861.20,1407.50,60.40}},
		{"Little Mexico",               {1701.90,-1842.20,-89.00,1812.60,-1722.20,110.90}},
		{"Little Mexico",               {1758.90,-1722.20,-89.00,1812.60,-1577.50,110.90}},
		{"Los Flores",                  {2581.70,-1454.30,-89.00,2632.80,-1393.40,110.90}},
		{"Los Flores",                  {2581.70,-1393.40,-89.00,2747.70,-1135.00,110.90}},
		{"Los Santos International",    {1249.60,-2394.30,-89.00,1852.00,-2179.20,110.90}},
		{"Los Santos International",    {1852.00,-2394.30,-89.00,2089.00,-2179.20,110.90}},
		{"Los Santos International",    {1382.70,-2730.80,-89.00,2201.80,-2394.30,110.90}},
		{"Los Santos International",    {1974.60,-2394.30,-39.00,2089.00,-2256.50,60.90}},
		{"Los Santos International",    {1400.90,-2669.20,-39.00,2189.80,-2597.20,60.90}},
		{"Los Santos International",    {2051.60,-2597.20,-39.00,2152.40,-2394.30,60.90}},
		{"Marina",                      {647.70,-1804.20,-89.00,851.40,-1577.50,110.90}},
		{"Marina",                      {647.70,-1577.50,-89.00,807.90,-1416.20,110.90}},
		{"Marina",                      {807.90,-1577.50,-89.00,926.90,-1416.20,110.90}},
		{"Market",                      {787.40,-1416.20,-89.00,1072.60,-1310.20,110.90}},
		{"Market",                      {952.60,-1310.20,-89.00,1072.60,-1130.80,110.90}},
		{"Market",                      {1072.60,-1416.20,-89.00,1370.80,-1130.80,110.90}},
		{"Market",                      {926.90,-1577.50,-89.00,1370.80,-1416.20,110.90}},
		{"Market Station",              {787.40,-1410.90,-34.10,866.00,-1310.20,65.80}},
		{"Martin Bridge",               {-222.10,293.30,0.00,-122.10,476.40,200.00}},
		{"Missionary Hill",             {-2994.40,-811.20,0.00,-2178.60,-430.20,200.00}},
		{"Montgomery",                  {1119.50,119.50,-3.00,1451.40,493.30,200.00}},
		{"Montgomery",                  {1451.40,347.40,-6.10,1582.40,420.80,200.00}},
		{"Montgomery Intersection",     {1546.60,208.10,0.00,1745.80,347.40,200.00}},
		{"Montgomery Intersection",     {1582.40,347.40,0.00,1664.60,401.70,200.00}},
		{"Mulholland",                  {1414.00,-768.00,-89.00,1667.60,-452.40,110.90}},
		{"Mulholland",                  {1281.10,-452.40,-89.00,1641.10,-290.90,110.90}},
		{"Mulholland",                  {1269.10,-768.00,-89.00,1414.00,-452.40,110.90}},
		{"Mulholland",                  {1357.00,-926.90,-89.00,1463.90,-768.00,110.90}},
		{"Mulholland",                  {1318.10,-910.10,-89.00,1357.00,-768.00,110.90}},
		{"Mulholland",                  {1169.10,-910.10,-89.00,1318.10,-768.00,110.90}},
		{"Mulholland",                  {768.60,-954.60,-89.00,952.60,-860.60,110.90}},
		{"Mulholland",                  {687.80,-860.60,-89.00,911.80,-768.00,110.90}},
		{"Mulholland",                  {737.50,-768.00,-89.00,1142.20,-674.80,110.90}},
		{"Mulholland",                  {1096.40,-910.10,-89.00,1169.10,-768.00,110.90}},
		{"Mulholland",                  {952.60,-937.10,-89.00,1096.40,-860.60,110.90}},
		{"Mulholland",                  {911.80,-860.60,-89.00,1096.40,-768.00,110.90}},
		{"Mulholland",                  {861.00,-674.80,-89.00,1156.50,-600.80,110.90}},
		{"Mulholland Intersection",     {1463.90,-1150.80,-89.00,1812.60,-768.00,110.90}},
		{"North Rock",                  {2285.30,-768.00,0.00,2770.50,-269.70,200.00}},
		{"Ocean Docks",                 {2373.70,-2697.00,-89.00,2809.20,-2330.40,110.90}},
		{"Ocean Docks",                 {2201.80,-2418.30,-89.00,2324.00,-2095.00,110.90}},
		{"Ocean Docks",                 {2324.00,-2302.30,-89.00,2703.50,-2145.10,110.90}},
		{"Ocean Docks",                 {2089.00,-2394.30,-89.00,2201.80,-2235.80,110.90}},
		{"Ocean Docks",                 {2201.80,-2730.80,-89.00,2324.00,-2418.30,110.90}},
		{"Ocean Docks",                 {2703.50,-2302.30,-89.00,2959.30,-2126.90,110.90}},
		{"Ocean Docks",                 {2324.00,-2145.10,-89.00,2703.50,-2059.20,110.90}},
		{"Ocean Flats",                 {-2994.40,277.40,-9.10,-2867.80,458.40,200.00}},
		{"Ocean Flats",                 {-2994.40,-222.50,-0.00,-2593.40,277.40,200.00}},
		{"Ocean Flats",                 {-2994.40,-430.20,-0.00,-2831.80,-222.50,200.00}},
		{"Octane Springs",              {338.60,1228.50,0.00,664.30,1655.00,200.00}},
		{"Old Venturas Strip",          {2162.30,2012.10,-89.00,2685.10,2202.70,110.90}},
		{"Palisades",                   {-2994.40,458.40,-6.10,-2741.00,1339.60,200.00}},
		{"Palomino Creek",              {2160.20,-149.00,0.00,2576.90,228.30,200.00}},
		{"Paradiso",                    {-2741.00,793.40,-6.10,-2533.00,1268.40,200.00}},
		{"Pershing Square",             {1440.90,-1722.20,-89.00,1583.50,-1577.50,110.90}},
		{"Pilgrim",                     {2437.30,1383.20,-89.00,2624.40,1783.20,110.90}},
		{"Pilgrim",                     {2624.40,1383.20,-89.00,2685.10,1783.20,110.90}},
		{"Pilson Intersection",         {1098.30,2243.20,-89.00,1377.30,2507.20,110.90}},
		{"Pirates in Men's Pants",      {1817.30,1469.20,-89.00,2027.40,1703.20,110.90}},
		{"Playa del Seville",           {2703.50,-2126.90,-89.00,2959.30,-1852.80,110.90}},
		{"Prickle Pine",                {1534.50,2583.20,-89.00,1848.40,2863.20,110.90}},
		{"Prickle Pine",                {1117.40,2507.20,-89.00,1534.50,2723.20,110.90}},
		{"Prickle Pine",                {1848.40,2553.40,-89.00,1938.80,2863.20,110.90}},
		{"Prickle Pine",                {1938.80,2624.20,-89.00,2121.40,2861.50,110.90}},
		{"Queens",                      {-2533.00,458.40,0.00,-2329.30,578.30,200.00}},
		{"Queens",                      {-2593.40,54.70,0.00,-2411.20,458.40,200.00}},
		{"Queens",                      {-2411.20,373.50,0.00,-2253.50,458.40,200.00}},
		{"Randolph Industrial Estate",  {1558.00,596.30,-89.00,1823.00,823.20,110.90}},
		{"Redsands East",               {1817.30,2011.80,-89.00,2106.70,2202.70,110.90}},
		{"Redsands East",               {1817.30,2202.70,-89.00,2011.90,2342.80,110.90}},
		{"Redsands East",               {1848.40,2342.80,-89.00,2011.90,2478.40,110.90}},
		{"Redsands West",               {1236.60,1883.10,-89.00,1777.30,2142.80,110.90}},
		{"Redsands West",               {1297.40,2142.80,-89.00,1777.30,2243.20,110.90}},
		{"Redsands West",               {1377.30,2243.20,-89.00,1704.50,2433.20,110.90}},
		{"Redsands West",               {1704.50,2243.20,-89.00,1777.30,2342.80,110.90}},
		{"Regular Tom",                 {-405.70,1712.80,-3.00,-276.70,1892.70,200.00}},
		{"Richman",                     {647.50,-1118.20,-89.00,787.40,-954.60,110.90}},
		{"Richman",                     {647.50,-954.60,-89.00,768.60,-860.60,110.90}},
		{"Richman",                     {225.10,-1369.60,-89.00,334.50,-1292.00,110.90}},
		{"Richman",                     {225.10,-1292.00,-89.00,466.20,-1235.00,110.90}},
		{"Richman",                     {72.60,-1404.90,-89.00,225.10,-1235.00,110.90}},
		{"Richman",                     {72.60,-1235.00,-89.00,321.30,-1008.10,110.90}},
		{"Richman",                     {321.30,-1235.00,-89.00,647.50,-1044.00,110.90}},
		{"Richman",                     {321.30,-1044.00,-89.00,647.50,-860.60,110.90}},
		{"Richman",                     {321.30,-860.60,-89.00,687.80,-768.00,110.90}},
		{"Richman",                     {321.30,-768.00,-89.00,700.70,-674.80,110.90}},
		{"Robada Intersection",         {-1119.00,1178.90,-89.00,-862.00,1351.40,110.90}},
		{"Roca Escalante",              {2237.40,2202.70,-89.00,2536.40,2542.50,110.90}},
		{"Roca Escalante",              {2536.40,2202.70,-89.00,2625.10,2442.50,110.90}},
		{"Rockshore East",              {2537.30,676.50,-89.00,2902.30,943.20,110.90}},
		{"Rockshore West",              {1997.20,596.30,-89.00,2377.30,823.20,110.90}},
		{"Rockshore West",              {2377.30,596.30,-89.00,2537.30,788.80,110.90}},
		{"Rodeo",                       {72.60,-1684.60,-89.00,225.10,-1544.10,110.90}},
		{"Rodeo",                       {72.60,-1544.10,-89.00,225.10,-1404.90,110.90}},
		{"Rodeo",                       {225.10,-1684.60,-89.00,312.80,-1501.90,110.90}},
		{"Rodeo",                       {225.10,-1501.90,-89.00,334.50,-1369.60,110.90}},
		{"Rodeo",                       {334.50,-1501.90,-89.00,422.60,-1406.00,110.90}},
		{"Rodeo",                       {312.80,-1684.60,-89.00,422.60,-1501.90,110.90}},
		{"Rodeo",                       {422.60,-1684.60,-89.00,558.00,-1570.20,110.90}},
		{"Rodeo",                       {558.00,-1684.60,-89.00,647.50,-1384.90,110.90}},
		{"Rodeo",                       {466.20,-1570.20,-89.00,558.00,-1385.00,110.90}},
		{"Rodeo",                       {422.60,-1570.20,-89.00,466.20,-1406.00,110.90}},
		{"Rodeo",                       {466.20,-1385.00,-89.00,647.50,-1235.00,110.90}},
		{"Rodeo",                       {334.50,-1406.00,-89.00,466.20,-1292.00,110.90}},
		{"Royal Casino",                {2087.30,1383.20,-89.00,2437.30,1543.20,110.90}},
		{"San Andreas Sound",           {2450.30,385.50,-100.00,2759.20,562.30,200.00}},
		{"Santa Flora",                 {-2741.00,458.40,-7.60,-2533.00,793.40,200.00}},
		{"Santa Maria Beach",           {342.60,-2173.20,-89.00,647.70,-1684.60,110.90}},
		{"Santa Maria Beach",           {72.60,-2173.20,-89.00,342.60,-1684.60,110.90}},
		{"Shady Cabin",                 {-1632.80,-2263.40,-3.00,-1601.30,-2231.70,200.00}},
		{"Shady Creeks",                {-1820.60,-2643.60,-8.00,-1226.70,-1771.60,200.00}},
		{"Shady Creeks",                {-2030.10,-2174.80,-6.10,-1820.60,-1771.60,200.00}},
		{"Sobell Rail Yards",           {2749.90,1548.90,-89.00,2923.30,1937.20,110.90}},
		{"Spinybed",                    {2121.40,2663.10,-89.00,2498.20,2861.50,110.90}},
		{"Starfish Casino",             {2437.30,1783.20,-89.00,2685.10,2012.10,110.90}},
		{"Starfish Casino",             {2437.30,1858.10,-39.00,2495.00,1970.80,60.90}},
		{"Starfish Casino",             {2162.30,1883.20,-89.00,2437.30,2012.10,110.90}},
		{"Temple",                      {1252.30,-1130.80,-89.00,1378.30,-1026.30,110.90}},
		{"Temple",                      {1252.30,-1026.30,-89.00,1391.00,-926.90,110.90}},
		{"Temple",                      {1252.30,-926.90,-89.00,1357.00,-910.10,110.90}},
		{"Temple",                      {952.60,-1130.80,-89.00,1096.40,-937.10,110.90}},
		{"Temple",                      {1096.40,-1130.80,-89.00,1252.30,-1026.30,110.90}},
		{"Temple",                      {1096.40,-1026.30,-89.00,1252.30,-910.10,110.90}},
		{"The Camel's Toe",             {2087.30,1203.20,-89.00,2640.40,1383.20,110.90}},
		{"The Clown's Pocket",          {2162.30,1783.20,-89.00,2437.30,1883.20,110.90}},
		{"The Emerald Isle",            {2011.90,2202.70,-89.00,2237.40,2508.20,110.90}},
		{"The Farm",                    {-1209.60,-1317.10,114.90,-908.10,-787.30,251.90}},
		{"The Four Dragons Casino",     {1817.30,863.20,-89.00,2027.30,1083.20,110.90}},
		{"The High Roller",             {1817.30,1283.20,-89.00,2027.30,1469.20,110.90}},
		{"The Mako Span",               {1664.60,401.70,0.00,1785.10,567.20,200.00}},
		{"The Panopticon",              {-947.90,-304.30,-1.10,-319.60,327.00,200.00}},
		{"The Pink Swan",               {1817.30,1083.20,-89.00,2027.30,1283.20,110.90}},
		{"The Sherman Dam",             {-968.70,1929.40,-3.00,-481.10,2155.20,200.00}},
		{"The Strip",                   {2027.40,863.20,-89.00,2087.30,1703.20,110.90}},
		{"The Strip",                   {2106.70,1863.20,-89.00,2162.30,2202.70,110.90}},
		{"The Strip",                   {2027.40,1783.20,-89.00,2162.30,1863.20,110.90}},
		{"The Strip",                   {2027.40,1703.20,-89.00,2137.40,1783.20,110.90}},
		{"The Visage",                  {1817.30,1863.20,-89.00,2106.70,2011.80,110.90}},
		{"The Visage",                  {1817.30,1703.20,-89.00,2027.40,1863.20,110.90}},
		{"Unity Station",               {1692.60,-1971.80,-20.40,1812.60,-1932.80,79.50}},
		{"Valle Ocultado",              {-936.60,2611.40,2.00,-715.90,2847.90,200.00}},
		{"Verdant Bluffs",              {930.20,-2488.40,-89.00,1249.60,-2006.70,110.90}},
		{"Verdant Bluffs",              {1073.20,-2006.70,-89.00,1249.60,-1842.20,110.90}},
		{"Verdant Bluffs",              {1249.60,-2179.20,-89.00,1692.60,-1842.20,110.90}},
		{"Verdant Meadows",             {37.00,2337.10,-3.00,435.90,2677.90,200.00}},
		{"Verona Beach",                {647.70,-2173.20,-89.00,930.20,-1804.20,110.90}},
		{"Verona Beach",                {930.20,-2006.70,-89.00,1073.20,-1804.20,110.90}},
		{"Verona Beach",                {851.40,-1804.20,-89.00,1046.10,-1577.50,110.90}},
		{"Verona Beach",                {1161.50,-1722.20,-89.00,1323.90,-1577.50,110.90}},
		{"Verona Beach",                {1046.10,-1722.20,-89.00,1161.50,-1577.50,110.90}},
		{"Vinewood",                    {787.40,-1310.20,-89.00,952.60,-1130.80,110.90}},
		{"Vinewood",                    {787.40,-1130.80,-89.00,952.60,-954.60,110.90}},
		{"Vinewood",                    {647.50,-1227.20,-89.00,787.40,-1118.20,110.90}},
		{"Vinewood",                    {647.70,-1416.20,-89.00,787.40,-1227.20,110.90}},
		{"Whitewood Estates",           {883.30,1726.20,-89.00,1098.30,2507.20,110.90}},
		{"Whitewood Estates",           {1098.30,1726.20,-89.00,1197.30,2243.20,110.90}},
		{"Willowfield",                 {1970.60,-2179.20,-89.00,2089.00,-1852.80,110.90}},
		{"Willowfield",                 {2089.00,-2235.80,-89.00,2201.80,-1989.90,110.90}},
		{"Willowfield",                 {2089.00,-1989.90,-89.00,2324.00,-1852.80,110.90}},
		{"Willowfield",                 {2201.80,-2095.00,-89.00,2324.00,-1989.90,110.90}},
		{"Willowfield",                 {2541.70,-1941.40,-89.00,2703.50,-1852.80,110.90}},
		{"Willowfield",                 {2324.00,-2059.20,-89.00,2541.70,-1852.80,110.90}},
		{"Willowfield",                 {2541.70,-2059.20,-89.00,2703.50,-1941.40,110.90}},
		{"Yellow Bell Station",         {1377.40,2600.40,-21.90,1492.40,2687.30,78.00}},
		{"Los Santos",                  {44.60,-2892.90,-242.90,2997.00,-768.00,900.00}},
		{"Las Venturas",                {869.40,596.30,-242.90,2997.00,2993.80,900.00}},
		{"Bone County",                 {-480.50,596.30,-242.90,869.40,2993.80,900.00}},
		{"Tierra Robada",               {-2997.40,1659.60,-242.90,-480.50,2993.80,900.00}},
		{"Tierra Robada",               {-1213.90,596.30,-242.90,-480.50,1659.60,900.00}},
		{"San Fierro",                  {-2997.40,-1115.50,-242.90,-1213.90,1659.60,900.00}},
		{"Red County",                  {-1213.90,-768.00,-242.90,2997.00,596.30,900.00}},
		{"Flint County",                {-1213.90,-2892.90,-242.90,44.60,-768.00,900.00}},
		{"Whetstone",                   {-2997.40,-2892.90,-242.90,-1213.90,-1115.50,900.00}}
	},
    LockNames[4][32] = {"{2ECC71}Not Locked", "{E74C3C}Password Locked", "{E74C3C}Requires Keys", "{E74C3C}Owner Only"},
	TransactionNames[2][16] = {"{E74C3C}Taken", "{2ECC71}Added"},
    Float:RandomSpawnsDE[][] =
    {
        {242.5503,176.5623,1003.0300,93.6148},
        {240.5619,195.8680,1008.1719,91.7114},
        {253.4729,190.7446,1008.1719,115.2117},
        {288.745971, 169.350997, 1007.171875}
    },
    Float:RandomSpawnsRW[][] =
    {
        {1360.0864,-21.3368,1007.8828,183.3211},
        {1402.2295,-33.9128,1007.8819,273.5619},
        {253.4729,190.7446,1008.1719,115.2117}, 
        {1361.5745,-47.8980,1000.9238,104.6970}

    },
    Float:RandomSpawnsSOS[][] =
    {
        {-1053.9221,1022.5436,1343.1633,286.6894},
        {-975.975708,1060.983032,1345.671875},
        {-1131.4167,1042.4703,1345.7369,230.2888}
    },
    Float:RandomSpawnsSNIPE[][] =
    {
        {-2640.762939, 1406.682006, 906.460937},
        {-2664.6062,1392.3625,912.4063,60.4372},    
        {-2670.5549,1425.4402,912.4063,179.1681}
    },
    Float:RandomSpawnsSOS2[][] =
    {
        {1322.2629,2753.8525,10.8203,67.4993},
        {1197.6454,2795.0579,10.8203,13.2921},
        {1365.6454,2809.0579,10.8203,13.2921}
    },
    Float:RandomSpawnsSHOT[][] =
    {
        {2205.2983,1553.3098,1008.3852,275.1326},
        {2172.6226,1577.2854,999.9670,186.4819},
        {2188.4739,1619.3770,999.9766,0.0467},
        {2218.1841,1615.2228,999.9827,334.6665}
    },
    Float:RandomSpawnsSNIPE2[][] =
    {
        {2209.0427,1063.0984,71.3284,328.9798 },
        {2217.0649,1091.5931,29.5850,346.5500 },
        {2286.3674,1171.7701,85.9375,151.3414 },
        {2289.5737,1054.5160,26.7031,240.9556 }
    },
    Float:RandomSpawnsMINI[][] =
    {
        {-2356.9077,1539.1139,26.0469,84.7713 },
        {-2367.2000,1541.5798,17.3281,10.1972  },
        {-2388.3159,1543.0730,26.0469,185.8829 },
        {-2411.0122,1547.8350,26.0469,280.8965 },
        {-2423.4104,1547.9592,23.1406,96.9681},
        {-2434.5415,1544.7043,8.3984,289.0432},
        {-2392.1448,1548.3545,2.1172,183.7622 },
        {-2435.7583,1538.8330,11.7656,274.9664},
        {-2373.3687,1551.5563,2.1172,133.3617},
        {-2372.2913,1537.6198,10.8209,28.3940}
    },
    Float:RandomSpawnsWZ[][] =
    {
        {241.3928,1873.1758,11.4531,273.7038},
        {254.0595,1861.3322,8.7578,140.2225},
        {253.7986,1817.8022,4.7175,82.2553},
        {243.0909,1802.6503,7.4141,45.5949},
        {217.8072,1823.2727,6.4141,246.4435},
        {264.9873,1843.3636,7.5076,50.9452},
        {245.5841,1824.6747,7.5547,280.2840},
        {314.2634,1847.7885,7.7266,284.6707},
        {261.1926,1883.6488,8.4375,272.7639},
        {271.4502,1878.3483,-2.4125,41.3287},
        {267.2027,1878.4490,-22.9237,358.2578},
        {268.9091,1883.4457,-30.0938,224.7766},
        {273.5457,1855.9456,8.7649,61.2620},
        {274.8059,1871.2070,8.7578,227.9569},
        {296.7946,1865.6255,8.6411,223.1364}
    },
    Float:RandomSpawnsSHIP[][] =
    {
        {-1334.0657,512.9581,11.1953,51.5368},
        {-1342.2621,498.1203,11.1953,274.9456},
        {-1296.5226,505.3504,11.1953,133.9676},
        {-1368.6232,517.2023,11.1971,44.0400},
        {-1396.0570,498.9916,11.2026,322.5726}
    }
;

static 
    Iterator: Houses<MAX_HOUSES>,
	Iterator: HouseKeys[MAX_PLAYERS]<MAX_HOUSES>
;

main() {}

// Gamemode Script
public OnGameModeInit()
{   
    for(new i; i < MAX_HOUSES; ++i)
	{
		HouseData[i][HouseLabel] = Text3D: INVALID_3DTEXT_ID;
		HouseData[i][HousePickup] = -1;
		HouseData[i][HouseIcon] = -1;
		HouseData[i][Save] = false;
	}

	for(new i; i < sizeof(HouseInteriors); ++i)
	{
	    HouseInteriors[i][intLabel] = CreateDynamic3DTextLabel("Leave House", 0xE67E22FF, HouseInteriors[i][intX], HouseInteriors[i][intY], HouseInteriors[i][intZ]+0.35, 10.0, .testlos = 1, .interiorid = HouseInteriors[i][intID]);
		HouseInteriors[i][intPickup] = CreateDynamicPickup(1318, 1, HouseInteriors[i][intX], HouseInteriors[i][intY], HouseInteriors[i][intZ], .interiorid = HouseInteriors[i][intID]);
	}

	Iter_Init(HouseKeys);
	DisableInteriorEnterExits();

    UsePlayerPedAnims();
    for(new i = 0; i < 301; i++) AddPlayerClass(i, 1958.33, 1343.12, 15.36, 269.15, 0, 0, 0, 0, 0, 0);
	print("[Gamemode]: Global gamemode initialization.");
    print("[Gamemode::Configurations]: Gamemode Configurations load...");

    SetGameModeText("Stunts/Freeroam/DM/Minigames");
    print("[Gamemode::Configurations]: Gamemodetext has been changed to `Stunts/Freeroam/DM/Minigames`");
    SetTimer("HostnameManager", 2, true);
    print("[Gamemode::Timer]: Global 'HostnameManager' Timer has been started.");
    SetTimer("Announcements", 3*60*1000, true);
    print("[Gamemode::Timer]: Global 'Announcements' Timer has been started.");
    print("[Gamemode::Configurations]: Hostname Management loaded.");
    print("[Gamemode::Configurations]: Gamemode Configurations Loaded.");

	SetTimer("InServerTimer", 1000, true);
	print("[Gamemode::Timer]: Global 'InServerTimer' Timer has been started.");
    m_Timer = SetTimer("OnMoneyBagUpdate", MB_DELAY*1000, true);
    print("[Gamemode::Timer]: Global 'OnMoneyBagUpdate' Timer has been started.");
    SetTimer("OnAdminHouseGateUpdate", 1000, true);
    print("[Gamemode::Timer]: Global 'OnAdminHouseGateUpdate' Timer has been started.");
    SetTimer("OnReactionTestStart", 60*2*1000, 0);
    print("[Gamemode::Timer]: Global 'OnReactionTestStart' Timer has been started.");
    SetTimer("OnEventDiveRolled", 5*60*1000, false);
    print("[Gamemode::Timer]: Global 'OnEventDiveRolled' Timer has been started.");
    SetTimer("OnAntiCheatUpdate", 1500, true);
    print("[Gamemode::Timer]: Global 'OnAntiCheatUpdate' Timer has been started.");
	#if USE_EXTERN_CHAT == 1
        starttime = GetTickCount();
		print("[Gamemode::ExternChat]: Loading...");
		#if USE_IRC == 1

			IRCBots[0] = IRC_Connect(IRC_SERVER, IRC_PORT, IRC_BOT_1, "SFS IRC Bot", "SFS IRC Bot");
			IRC_SetIntData(IRCBots[0], E_IRC_CONNECT_DELAY, 10);

			IRCBots[1] = IRC_Connect(IRC_SERVER, IRC_PORT, IRC_BOT_2, "SFS IRC Bot", "SFS IRC Bot");
			IRC_SetIntData(IRCBots[1], E_IRC_CONNECT_DELAY, 20);

			IRCBots[2] = IRC_Connect(IRC_SERVER, IRC_PORT, IRC_BOT_3, "SFS IRC Bot", "SFS IRC Bot");
			IRC_SetIntData(IRCBots[2], E_IRC_CONNECT_DELAY, 30);

			IRCBots[3] = IRC_Connect(IRC_SERVER, IRC_PORT, "SFS", "SFS IRC Management Bot", "SFS IRC Bot");
			IRC_SetIntData(IRCBots[2], E_IRC_CONNECT_DELAY, 30);

			GroupId = IRC_CreateGroup();
			print("[Gamemode::IRC]: Connecting Bots to IRC Server "IRC_SERVER".");

		#elseif USE_DISCORD == 1

			DCC_Connect(DISCORD_TOKEN);

			DDC_Echo_Channel = DCC_FindChannelByName(DISCORD_ECHO);
			print("[Gamemode::Discord]: Bot has been connected to "DISCORD_ECHO".");

		#elseif USE_TS3 == 1

			TSC_Connect(TS3_ADMIN, TS3_PASWD, TS3_SERVER, TS3_PORT);
			TSC_ChangeNickname(TS3_NICK);

			print("[Gamemode::TS3]: Bot "TS3_NICK" has been connected to "TS3_SERVER".");

		#endif

	#endif

	#if USE_SAVING_SYSTEM == 1

		print("[Gamemode::SavingSystem]: Loading....");

		#if USE_SQLITE == 1

			Database = db_open(SQLITE_DATABASE);
			if(Database)
			{
				print("[Gamemode::SQLite]: Connected to database "SQLITE_DATABASE"");
				db_query(Database, "CREATE TABLE IF NOT EXISTS `Accounts` (`UserId` INT, `Name` VARCHAR(24), `IP` VARCHAR(16), `Password` VARCHAR(129), `ClientId` VARCHAR(50), `Admin` INT, `VIP` INT, `Money` INT, `Deaths` INT, `Kills` INT, `Skin` INT, `Time` INT, `Color` INT)");
				db_query(Database, "CREATE TABLE IF NOT EXISTS `BanList` (`BanId` INT, `Name` VARCHAR(24), `IP` VARCHAR(16), `ClientId` VARCHAR(50), `Admin` VARCHAR(24), `Reason` VARCHAR(30), `Date` VARCHAR(50))");

                db_query(Database, "PRAGMA synchronous = OFF");
                db_query(Database, "CREATE TABLE IF NOT EXISTS `MoneyBag` (`Name` VARCHAR(24), `PosX` FLOAT(10), `PosY` FLOAT(10), `PosZ` FLOAT(10))");

                print("[Gamemode::MoneyBag]: Tables created.");

                #if defined WEAPONS_BOUNS
                    print("[Gamemode::MoneyBag]: Weapons Bouns has been Activated.");
                #endif

                print("[Gamemode::MoneyBag]: Loading Moneybags Names and Positions");
                LoadMoneyBags();
            }
			else print("[Gamemode::SQLite]: Failed connecting to database "SQLITE_DATABASE"");

		#elseif USE_MYSQL == 1

            mysql_log(ALL);
            new MySQLOpt:options = mysql_init_options();
            mysql_set_option(options, SERVER_PORT, MYSQL_PORT);
			Database = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_DATA, options);
			if(!mysql_errno())
			{

				print("[Gamemode::MySQL]: Connected to database "MYSQL_DATA"");
				mysql_query(Database, "CREATE TABLE IF NOT EXISTS `Accounts` (`UserId` INT, `Name` VARCHAR(24), `IP` VARCHAR(16), `Password` VARCHAR(129), `ClientId` VARCHAR(50), `Admin` INT, `VIP` INT, `Money` INT, `Deaths` INT, `Kills` INT, `Skin` INT, `Time` INT, `Color` INT)");
				mysql_query(Database, "CREATE TABLE IF NOT EXISTS `BanList` (`BanId` INT, `Name` VARCHAR(24), `IP` VARCHAR(16), `ClientId` VARCHAR(50), `Admin` VARCHAR(24), `Reason` VARCHAR(30), `Date` VARCHAR(50))");

                mysql_query(Database, "CREATE TABLE IF NOT EXISTS `MoneyBag` (`Name` VARCHAR(24), `PosX` FLOAT(10), `PosY` FLOAT(10), `PosZ` FLOAT(10))");

                new query[1024];
                strcat(query, "CREATE TABLE IF NOT EXISTS `houses` (\
                  `ID` int(11) NOT NULL,\
                  `HouseName` varchar(48) NOT NULL default 'House For Sale',\
                  `HouseOwner` varchar(24) NOT NULL default '-',\
                  `HousePassword` varchar(16) NOT NULL default '-',\
                  `HouseX` float NOT NULL,\
                  `HouseY` float NOT NULL,\
                  `HouseZ` float NOT NULL,\
                  `HousePrice` int(11) NOT NULL,\
                  `HouseInterior` tinyint(4) NOT NULL default '0',\
                  `HouseLock` tinyint(4) NOT NULL default '0',\
                  `HouseMoney` int(11) NOT NULL default '0',"
                );

                strcat(query, "`LastEntered` int(11) NOT NULL,\
                      PRIMARY KEY  (`ID`),\
                      UNIQUE KEY `ID_2` (`ID`),\
                      KEY `ID` (`ID`)\
                    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;"
                );

                mysql_query(Database, query);

                mysql_query(Database, "CREATE TABLE IF NOT EXISTS `housefurnitures` (\
                  `ID` int(11) NOT NULL auto_increment,\
                  `HouseID` int(11) NOT NULL,\
                  `FurnitureID` tinyint(11) NOT NULL,\
                  `FurnitureX` float NOT NULL,\
                  `FurnitureY` float NOT NULL,\
                  `FurnitureZ` float NOT NULL,\
                  `FurnitureRX` float NOT NULL,\
                  `FurnitureRY` float NOT NULL,\
                  `FurnitureRZ` float NOT NULL,\
                  `FurnitureVW` int(11) NOT NULL,\
                  `FurnitureInt` int(11) NOT NULL,\
                  PRIMARY KEY  (`ID`)\
                ) ENGINE=MyISAM DEFAULT CHARSET=utf8;");

                mysql_query(Database, "CREATE TABLE IF NOT EXISTS `houseguns` (\
                  `HouseID` int(11) NOT NULL,\
                  `WeaponID` tinyint(4) NOT NULL,\
                  `Ammo` int(11) NOT NULL,\
                  UNIQUE KEY `HouseID_2` (`HouseID`,`WeaponID`),\
                  KEY `HouseID` (`HouseID`),\
                  CONSTRAINT `houseguns_ibfk_1` FOREIGN KEY (`HouseID`) REFERENCES `houses` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE\
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8;");

                mysql_query(Database, "CREATE TABLE IF NOT EXISTS `housevisitors` (\
                  `HouseID` int(11) NOT NULL,\
                  `Visitor` varchar(24) NOT NULL,\
                  `Date` int(11) NOT NULL\
                ) ENGINE=MyISAM DEFAULT CHARSET=utf8;");

                mysql_tquery(Database, "CREATE TABLE IF NOT EXISTS `housekeys` (\
                  `HouseID` int(11) NOT NULL,\
                  `Player` varchar(24) NOT NULL,\
                  `Date` int(11) NOT NULL\
                ) ENGINE=MyISAM DEFAULT CHARSET=utf8;");

                mysql_query(Database, "CREATE TABLE IF NOT EXISTS `housesafelogs` (\
                  `HouseID` int(11) NOT NULL,\
                  `Type` int(11) NOT NULL,\
                  `Amount` int(11) NOT NULL,\
                  `Date` int(11) NOT NULL\
                ) ENGINE=MyISAM DEFAULT CHARSET=utf8;");

                mysql_query(Database, "CREATE TABLE IF NOT EXISTS `housesales` (\
                  `ID` int(11) NOT NULL AUTO_INCREMENT,\
                  `OldOwner` varchar(24) NOT NULL,\
                  `NewOwner` varchar(24) NOT NULL,\
                  `Price` int(11) NOT NULL,\
                  PRIMARY KEY (`ID`)\
                ) ENGINE=MyISAM DEFAULT CHARSET=utf8;");

                // 1.3 update, add HouseSalePrice to the houses table
                if(!fexist("house_updated.txt"))
                {
                    mysql_tquery(Database, "ALTER TABLE houses ADD HouseSalePrice INT(11) AFTER HousePrice");

                    new File: updateFile = fopen("house_updated.txt", io_append);
                    if(updateFile)
                    {
                        fwrite(updateFile, "Don't remove this file.");
                        fclose(updateFile);
                    }
                }

                /* Loading & Stuff */
                mysql_tquery(Database, "SELECT * FROM houses", "LoadHouses", "");
                mysql_tquery(Database, "SELECT * FROM housefurnitures", "LoadFurnitures", "");
                foreach(new i : Player) House_PlayerInit(i);
                SetTimer("ResetAndSaveHouses", 10 * 60000, true);

                print("[Gamemode::MoneyBag]: Tables created.");

                #if defined WEAPONS_BOUNS
                    print("[Gamemode::MoneyBag]: Weapons Bouns has been Activated.");
                #endif

                print("[Gamemode::MoneyBag]: Loading Moneybags Names and Positions");
                LoadMoneyBags();
            }
			else print("[Gamemode::MySQL]: Failed connecting to database "MYSQL_DATA"");

		#else 

			print("[Gamemode]: Seems Something wrrong in gamemode configurations.");
			SendRconCommand("exit");

		#endif

	#endif
    print("[Gamemode::Objects]: Loading...");
    CreateObject(8493, -1589.00000, 7820.00000, 1357.00000,   0.00000, 0.00000, 0.00000);
    CreateObject(846, -1541.37317, 1396.21094, -0.10476,   0.00000, 0.00000, 0.00000);
    CreateObject(8493, 6086.78613, 7715.87158, 614.88239,   0.00000, 0.00000, 0.00000);
    CreateObject(8493, -1615.00000, 2161.00000, 1333.00000,   0.00000, 4200.00000, 0.00000);
    CreateObject(8493, -1643.98804, 1324.68665, 20.42485,   -1.74000, -1.20001, 43.50002);
    CreateObject(3524, 6049.48926, 8064.37207, 2935.74585,   0.00000, 0.00000, 0.00000);
    CreateObject(3524, -1637.17407, 1309.99182, 10.33141,   0.00000, 0.00000, -40.32003);
    CreateObject(3524, -1643.64319, 1317.20569, 10.22290,   0.00000, 0.00000, -36.06002);
    CreateObject(10183, -1667.77478, 1327.03357, 5.93331,   0.00000, 0.00000, 0.54000);
    CreateObject(10183, -1667.95618, 1295.43176, 5.75090,   0.00000, 0.00000, 0.00000);
    CreateObject(1503, -1635.27148, 1317.69714, 9.14691,   7.13998, -2.70000, -45.06000);
    CreateObject(9159, -1644.03320, 1324.73401, 20.36553,   -1.92000, -0.65999, 42.11996);
    CreateObject(1955, -1639.83838, 1312.87500, 8.43487,   0.00000, 0.00000, 0.00000);
    CreateObject(19577, -1664.25513, 1460.24561, 8.44141,   0.00000, 0.00000, 0.00000);
    CreateObject(8493, -1644.16089, 1324.49133, 20.42485,   -1.74000, -1.20001, 43.50002);
    CreateObject(9174, -1558.22021, 1342.86060, 4.08927,   0.00000, 0.00000, -133.98009);
    CreateObject(3434, -1661.65674, 1313.66821, 19.00621,   -0.54000, 0.48000, 37.20001);
    CreateObject(8423, -1662.72290, 1315.05994, 16.81797,   0.00000, 0.00000, 43.73999);
    CreateObject(3524, -1649.24609, 1310.20935, 6.11818,   0.00000, 0.00000, -52.07998);
    CreateObject(3524, -1647.80298, 1309.47729, 8.44711,   0.00000, 0.00000, -52.07998);
    CreateObject(3524, -1643.49292, 1305.03442, 8.71351,   0.00000, 0.00000, -52.07998);
    CreateObject(3524, -1642.13965, 1303.72913, 8.83382,   0.00000, 0.00000, -52.07998);
    CreateObject(3524, -1644.90918, 1306.48108, 8.71351,   0.00000, 0.00000, -52.07998);
    CreateObject(3524, -1646.38586, 1307.89417, 8.71351,   0.00000, 0.00000, -52.07998);
    CreateObject(3524, -1642.65820, 1303.24280, 6.11818,   0.00000, 0.00000, -52.07998);
    CreateObject(3524, -1658.56873, 1315.33203, 6.11818,   0.00000, 0.00000, -52.07998);
    CreateObject(3524, -1655.70923, 1317.75806, 6.11818,   0.00000, 0.00000, -52.07998);
    CreateObject(3524, -1660.44434, 1313.43359, 6.11818,   0.00000, 0.00000, -52.07998);
    CreateObject(3524, -1653.56750, 1306.15198, 6.11818,   0.00000, 0.00000, -52.07998);
    CreateObject(3524, -1651.59509, 1308.29175, 6.11818,   0.00000, 0.00000, -52.07998);
    CreateObject(3524, -1655.70923, 1317.75806, 6.11818,   0.00000, 0.00000, -52.07998);
    CreateObject(3524, -1652.26990, 1314.83752, 6.11818,   0.00000, 0.00000, -52.07998);
    CreateObject(1655, -1686.97180, 1339.90125, 10.77704,   0.42000, 0.42000, -41.22000);
    CreateObject(1655, -1685.63770, 1328.17920, 7.49277,   0.54000, -0.90000, -41.22000);
    CreateObject(1655, -1692.15796, 1334.03430, 7.49277,   0.00000, 0.30000, -41.22000);
    CreateObject(1655, -1680.46753, 1334.00610, 10.77704,   0.42000, 0.42000, -41.22000);
    CreateObject(16357, -1615.48022, 1399.13660, 15.36312,   0.00000, 0.00000, 41.82004);
    CreateObject(16357, -1394.63293, 1596.82410, 15.36312,   0.00000, 0.00000, 41.82004);
    CreateObject(16357, -1501.57727, 1501.08105, 15.36312,   0.00000, 0.00000, 41.82004);
    CreateObject(1655, -1352.91492, 1633.96216, 17.17991,   3.65999, -1.38001, -49.85994);
    print("[Gamemode::Objects]: Request Class objects has been loaded.");

    CreateDynamicObject(3094,2313.8000000,998.4000200,9.8000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(3094,2313.8000000,998.4000200,11.8000000,0.0000000,180.0000000,270.0000000, 1); //
    CreateDynamicObject(3094,2313.8000000,1000.4000000,9.8000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(3094,2313.8000000,1000.4000000,11.8000000,0.0000000,180.0000000,270.0000000, 1); //
    CreateDynamicObject(3094,2313.7998000,1002.4004000,9.8000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(3042,2313.8999000,998.9000200,12.3000000,0.0000000,180.0000000,180.0000000, 1); //
    CreateDynamicObject(3094,2312.6001000,998.4000200,9.8000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(3094,2312.6001000,998.4000200,11.8000000,0.0000000,179.9950000,270.0000000, 1); //
    CreateDynamicObject(3042,2312.6001000,999.0000000,12.3000000,0.0000000,179.9950000,179.9950000, 1); //
    CreateDynamicObject(3094,2312.6001000,1000.4000000,9.8000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(3094,2312.6001000,1000.4000000,11.8000000,0.0000000,180.0000000,270.0000000, 1); //
    CreateDynamicObject(3094,2312.6001000,1002.4000000,9.8000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(3533,2313.2000000,1002.5000000,8.1000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2960,2314.3000000,999.7000100,10.9000000,90.0000000,180.0000000,270.0000000, 1); //
    CreateDynamicObject(1354,2314.3000000,998.2999900,10.1000000,0.0000000,0.0000000,90.0000000, 1); //
    CreateDynamicObject(2366,2313.5000000,998.0000000,10.3000000,0.0000000,90.0000000,0.0000000, 1); //
    CreateDynamicObject(2366,2313.6001000,999.7000100,10.3000000,0.0000000,90.0000000,0.0000000, 1); //
    CreateDynamicObject(2366,2313.6001000,1001.4000000,10.9200000,0.0000000,90.0000000,0.0000000, 1); //
    CreateDynamicObject(1354,2314.3999000,1000.0000000,10.1000000,0.0000000,0.0000000,90.0000000, 1); //
    CreateDynamicObject(1354,2314.3999000,1001.7000000,10.6000000,0.0000000,0.0000000,90.0000000, 1); //
    CreateDynamicObject(3877,2313.8000500,999.4000200,10.3000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3877,2312.6006000,999.4003900,10.3000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3872,2313.3000000,989.7999900,9.0000000,0.0000000,22.0000000,90.0000000, 1); //
    CreateDynamicObject(3872,2313.2998000,989.7998000,9.0000000,0.0000000,21.9950000,90.0000000, 1); //
    CreateDynamicObject(3256,2313.3000000,999.0999800,-26.0000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1451,2313.3999000,1002.1000000,11.8000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2098,2313.1999500,1003.2000100,11.8000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2755,2313.2000000,1003.2000000,11.4000000,0.0000000,0.0000000,180.0000000, 1); //
    CreateDynamicObject(3094,2313.7996000,1004.4008000,9.8000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(3094,2313.7993000,1006.4011000,9.8000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(3094,2313.7991000,1008.4015000,9.8000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(2098,2313.2000000,1009.2000000,11.8000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3094,2312.6006000,1004.4004000,9.8000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(3094,2312.6006000,1006.4004000,9.8000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(3094,2312.6001000,1008.4000000,9.8000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(1408,2314.6001000,1006.3000000,10.1000000,0.0000000,0.0000000,90.0000000, 1); //
    CreateDynamicObject(1408,2311.8999000,1006.3000000,10.1000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(3047,2313.8000000,1005.1000000,10.8000000,0.0000000,270.0000000,0.0000000, 1); //
    CreateDynamicObject(3047,2312.6001000,1005.1000000,10.8000000,0.0000000,270.0000000,180.0000000, 1); //
    CreateDynamicObject(3047,2312.6001000,1007.2000000,10.8000000,0.0000000,270.0000000,179.9950000, 1); //
    CreateDynamicObject(3047,2313.8000000,1007.2000000,10.8000000,0.0000000,270.0000000,0.0000000, 1); //
    CreateDynamicObject(3047,2313.8000000,1005.1000000,11.3000000,0.0000000,270.0000000,0.0000000, 1); //
    CreateDynamicObject(3047,2312.6001000,1005.1000000,11.3000000,0.0000000,270.0000000,179.9950000, 1); //
    CreateDynamicObject(3047,2313.8000000,1007.2000000,11.3000000,0.0000000,270.0000000,0.0000000, 1); //
    CreateDynamicObject(3047,2312.6001000,1007.2000000,11.3000000,0.0000000,270.0000000,179.9950000, 1); //
    CreateDynamicObject(2926,2313.3000000,1009.3000000,10.8000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2925,2313.3000000,1009.3000000,10.8000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1408,2296.3000000,985.0000000,10.1000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1408,2301.6001000,985.0000000,10.1000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1408,2306.9001000,985.0000000,10.1000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1408,2312.2002000,985.0000000,10.1000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1408,2317.5002000,985.0000000,10.1000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1408,2322.8003000,985.0000000,10.1000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1408,2328.1003000,985.0000000,10.1000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1408,2333.4004000,985.0000000,10.1000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1408,2289.8999000,987.5000000,10.1000000,0.0000000,0.0000000,315.0000000, 1); //
    CreateDynamicObject(1408,2286.2000000,991.2000100,10.1000000,0.0000000,0.0000000,314.9950000, 1); //
    CreateDynamicObject(1408,2282.5000000,994.9003900,10.1000000,0.0000000,0.0000000,314.9840000, 1); //
    CreateDynamicObject(1408,2278.8000000,998.6000400,10.1000000,0.0000000,0.0000000,314.9840000, 1); //
    CreateDynamicObject(1408,2275.1001000,1002.3000000,10.1000000,0.0000000,0.0000000,314.9780000, 1); //
    CreateDynamicObject(1408,2271.4001000,1006.0001000,10.1000000,0.0000000,0.0000000,314.9730000, 1); //
    CreateDynamicObject(1408,2335.8999000,988.9000200,10.1000000,0.0000000,0.0000000,90.0000000, 1); //
    CreateDynamicObject(1408,2335.8999000,994.2000100,10.1000000,0.0000000,0.0000000,90.0000000, 1); //
    CreateDynamicObject(1408,2335.8999000,999.5000000,10.1000000,0.0000000,0.0000000,90.0000000, 1); //
    CreateDynamicObject(1408,2335.8999000,1004.8000000,10.1000000,0.0000000,0.0000000,90.0000000, 1); //
    CreateDynamicObject(1408,2335.8999000,1010.1000000,10.1000000,0.0000000,0.0000000,90.0000000, 1); //
    CreateDynamicObject(1408,2335.8999000,1015.4000000,10.1000000,0.0000000,0.0000000,90.0000000, 1); //
    CreateDynamicObject(1408,2335.8999000,1020.7000000,10.1000000,0.0000000,0.0000000,90.0000000, 1); //
    CreateDynamicObject(645,2316.3000000,1019.7000000,4.8000000,0.0000000,0.0000000,179.9950000, 1); //
    CreateDynamicObject(2366,2312.8999000,998.5999800,10.3000000,0.0000000,90.0000000,180.0000000, 1); //
    CreateDynamicObject(2366,2312.8000000,1000.3000000,10.3000000,0.0000000,90.0000000,179.9950000, 1); //
    CreateDynamicObject(2366,2312.8000000,1002.0000000,10.9000000,0.0000000,90.0000000,180.0000000, 1); //
    CreateDynamicObject(1354,2312.1001000,998.2999900,10.1000000,0.0000000,0.0000000,268.0000000, 1); //
    CreateDynamicObject(1354,2312.0000000,1000.0000000,10.1000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(1354,2312.0000000,1001.7000000,10.6000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(2960,2312.3000000,999.5999800,10.9000000,90.0000000,180.0000000,89.9950000, 1); //
    CreateDynamicObject(1407,2313.2000000,1011.4000000,9.9000000,90.0000000,180.0000000,270.0000000, 1); //
    CreateDynamicObject(1407,2313.2000000,1015.9000000,9.9000000,90.0000000,179.9950000,270.0000000, 1); //
    CreateDynamicObject(1407,2313.2998000,995.2002000,9.9000000,90.0000000,179.9950000,270.0000000, 1); //
    CreateDynamicObject(1407,2313.3000000,990.5000000,9.9000000,90.0000000,179.9950000,270.0000000, 1); //
    CreateDynamicObject(1407,2313.3000000,987.5000000,9.9000000,90.0000000,179.9950000,270.0000000, 1); //
    CreateDynamicObject(1407,2313.2000000,1020.5000000,9.9000000,90.0000000,179.9950000,270.0000000, 1); //
    CreateDynamicObject(1407,2314.7000000,1011.4000000,9.9000000,90.0000000,179.9950000,270.0000000, 1); //
    CreateDynamicObject(1407,2311.7000000,1011.4000000,9.9000000,90.0000000,179.9950000,270.0000000, 1); //
    CreateDynamicObject(1407,2314.7000000,1015.9000000,9.9000000,90.0000000,179.9950000,270.0000000, 1); //
    CreateDynamicObject(1407,2311.7000000,1015.9000000,9.9000000,90.0000000,179.9950000,270.0000000, 1); //
    CreateDynamicObject(1407,2314.7000000,1020.5000000,9.9000000,90.0000000,179.9950000,270.0000000, 1); //
    CreateDynamicObject(1407,2311.7000000,1020.5000000,9.9000000,90.0000000,179.9950000,270.0000000, 1); //
    CreateDynamicObject(1408,2313.6001000,1012.0000000,9.4000000,0.0000000,0.0000000,90.0000000, 1); //
    CreateDynamicObject(1408,2313.6001000,1017.5000000,9.4000000,0.0000000,0.0000000,90.0000000, 1); //
    CreateDynamicObject(1408,2312.7000000,1012.0000000,9.4000000,0.0000000,0.0000000,90.0000000, 1); //
    CreateDynamicObject(1408,2312.7000000,1017.5000000,9.4000000,0.0000000,0.0000000,90.0000000, 1); //
    CreateDynamicObject(3920,2316.0000000,1000.9000000,13.8000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(1451,2312.9500000,1002.1000000,11.8000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(645,2316.0000000,994.7999900,4.8000000,0.0000000,0.0000000,191.9970000, 1); //
    CreateDynamicObject(3920,2316.1001000,1013.1000000,13.8000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(645,2316.2998000,1019.7002000,4.8000000,0.0000000,0.0000000,55.9950000, 1); //
    CreateDynamicObject(645,2316.0000000,994.7998000,4.8000000,0.0000000,0.0000000,147.9970000, 1); //
    CreateDynamicObject(1597,2315.3999000,989.7999900,12.3000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1597,2305.8000000,1016.2000000,12.3000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(13649,2098.0000000,1097.7000000,12.3000000,0.0000000,90.0000000,180.0000000, 1); //
    CreateDynamicObject(13649,2098.0000000,1091.7000000,12.3000000,0.0000000,90.0000000,179.9950000, 1); //
    CreateDynamicObject(847,2096.8999000,1092.8000000,12.6000000,0.0000000,94.0000000,268.0000000, 1); //
    CreateDynamicObject(847,2097.2000000,1096.6000000,12.6000000,0.0000000,90.0000000,87.9960000, 1); //
    CreateDynamicObject(847,2097.3000000,1092.8000000,11.9000000,0.0000000,270.0000000,89.9900000, 1); //
    CreateDynamicObject(847,2103.1001000,1096.8000000,11.9000000,10.0000000,270.0000000,270.0000000, 1); //
    CreateDynamicObject(13649,2098.0000000,1097.7002000,12.3000000,0.0000000,90.0000000,359.9950000, 1); //
    CreateDynamicObject(13649,2098.0000000,1091.7002000,12.3000000,0.0000000,90.0000000,359.9950000, 1); //
    CreateDynamicObject(13649,2102.3000000,1097.7000000,12.3000000,0.0000000,90.0000000,179.9950000, 1); //
    CreateDynamicObject(3862,2100.2000000,1092.7000000,15.0000000,0.0000000,0.0000000,180.0000000, 1); //
    CreateDynamicObject(13649,2102.3000000,1091.7002000,12.3000000,0.0000000,90.0000000,179.9950000, 1); //
    CreateDynamicObject(13649,2102.2998000,1091.7002000,12.3000000,0.0000000,90.0000000,359.9950000, 1); //
    CreateDynamicObject(13649,2102.2998000,1097.7002000,12.3000000,0.0000000,90.0000000,359.9950000, 1); //
    CreateDynamicObject(847,2103.6001000,1096.6000000,12.6000000,0.0000000,90.0000000,87.9950000, 1); //
    CreateDynamicObject(847,2097.0000000,1096.6000000,11.9000000,0.0000000,270.0000000,269.9880000, 1); //
    CreateDynamicObject(847,2103.1001000,1092.8000000,12.6000000,0.0000000,93.9990000,267.9950000, 1); //
    CreateDynamicObject(847,2103.5000000,1092.8000000,11.9000000,0.0000000,273.9990000,87.9900000, 1); //
    CreateDynamicObject(1480,2107.0000000,1583.5000000,10.8000000,0.0000000,90.0000000,90.0000000, 1); //
    CreateDynamicObject(1480,2107.7000000,1583.5000000,10.8000000,0.0000000,90.0000000,90.0000000, 1); //
    CreateDynamicObject(1480,2108.4004000,1583.5000000,10.8000000,0.0000000,90.0000000,90.0000000, 1); //
    CreateDynamicObject(1480,2109.0996000,1583.5000000,10.8000000,0.0000000,90.0000000,90.0000000, 1); //
    CreateDynamicObject(1480,2109.0996000,1581.2000000,10.8000000,0.0000000,270.0000000,90.0000000, 1); //
    CreateDynamicObject(1480,2107.0000000,1581.2002000,10.8000000,0.0000000,270.0000000,90.0000000, 1); //
    CreateDynamicObject(2628,2108.3999000,1583.2000000,11.7000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2628,2107.7002000,1583.2002000,11.7000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2629,2108.1001000,1582.9000000,11.7000000,0.0000000,0.0000000,180.0000000, 1); //
    CreateDynamicObject(2917,2108.0000000,1577.4004000,10.9000000,77.9970000,179.9950000,179.9950000, 1); //
    CreateDynamicObject(2960,2108.0000000,1576.7000000,10.7000000,90.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2960,2108.0000000,1576.6700000,11.0500000,78.0000000,180.0000000,180.0000000, 1); //
    CreateDynamicObject(2960,2108.0000000,1576.5601000,11.4000000,65.9970000,179.9970000,179.9920000, 1); //
    CreateDynamicObject(2960,2108.0000000,1576.6600000,10.3500000,78.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2960,2108.0000000,1576.5430000,10.0000000,65.9950000,0.0050000,359.9730000, 1); //
    CreateDynamicObject(2960,2108.0000000,1576.4139000,11.7000000,61.9950000,179.9950000,179.9880000, 1); //
    CreateDynamicObject(2960,2108.0000000,1576.3906000,9.7000000,61.9960000,0.0000000,359.9730000, 1); //
    CreateDynamicObject(1131,2108.0498000,1582.2002000,13.6000000,0.0000000,0.0000000,179.9950000, 1); //
    CreateDynamicObject(1408,2087.5000000,1094.3000000,10.1000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(1408,2087.5000000,1099.7000000,10.1000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(1408,2087.5000000,1105.0999000,10.1000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(1408,2087.5000000,1110.4998000,10.1000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(1408,2087.5000000,1115.8997000,10.1000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(1408,2087.5000000,1121.2996000,10.1000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(1408,2087.5000000,1126.6995000,10.1000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(1408,2087.5000000,1132.0996000,10.1000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(1408,2087.5000000,1137.4993000,10.1000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(1408,2087.5000000,1142.8994000,10.1000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(1408,2087.5000000,1148.2991000,10.1000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(1408,2087.5000000,1153.6990000,10.1000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(1408,2087.5000000,1088.9001000,10.1000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(1408,2087.5000000,1083.5002000,10.1000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(1408,2087.5000000,1078.1003000,10.1000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(1408,2087.5000000,1072.7004000,10.1000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(1408,2087.5000000,1067.3005000,10.1000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(1408,2087.5000000,1061.9006000,10.1000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(1408,2087.5000000,1056.5007000,10.1000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(1408,2087.5000000,1051.1008000,10.1000000,0.0000000,0.0000000,270.0000000, 1); //
    AddStaticVehicleEx(411,2074.3999000,1244.2000000,10.5000000,0.0000000,-1,-1,15, 1); //Infernus
    CreateDynamicObject(9046,2004.5996000,1623.2002000,8.9000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(9047,2004.4004000,1623.2002000,8.4000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2755,2431.1001000,1905.9000000,3.7000000,0.0000000,180.0000000,180.0000000, 1); //
    CreateDynamicObject(2755,2431.1006000,1905.9004000,3.7000000,348.0000000,179.9940000,179.9930000, 1); //
    CreateDynamicObject(2755,2431.1006000,1905.9004000,3.7000000,335.9970000,179.9880000,179.9870000, 1); //
    CreateDynamicObject(2755,2431.1006000,1905.9004000,3.7000000,323.9950000,179.9810000,179.9790000, 1); //
    CreateDynamicObject(2755,2431.1006000,1905.9004000,3.7000000,311.9920000,179.9730000,179.9710000, 1); //
    CreateDynamicObject(2755,2431.1001000,1906.3000000,3.7000000,0.0000000,179.9950000,179.9950000, 1); //
    CreateDynamicObject(2755,2431.1001000,1906.7001000,3.7000000,0.0000000,179.9890000,179.9890000, 1); //
    CreateDynamicObject(2755,2431.1001000,1907.1001000,3.7000000,0.0000000,179.9840000,179.9840000, 1); //
    CreateDynamicObject(2755,2431.1006000,1907.5000000,3.7000000,0.0000000,179.9730000,179.9730000, 1); //
    CreateDynamicObject(2755,2431.1001000,1907.9001000,3.7000000,0.0000000,179.9730000,179.9730000, 1); //
    CreateDynamicObject(2755,2431.1001000,1908.3002000,3.7000000,0.0000000,179.9670000,179.9670000, 1); //
    CreateDynamicObject(2755,2431.1001000,1908.7002000,3.7000000,0.0000000,179.9620000,179.9620000, 1); //
    CreateDynamicObject(2755,2431.1001000,1909.1002000,3.7000000,0.0000000,179.9560000,179.9560000, 1); //
    CreateDynamicObject(2755,2431.1006000,1909.5000000,3.7000000,0.0000000,179.9450000,179.9450000, 1); //
    CreateDynamicObject(2755,2431.1006000,1909.5000000,3.7000000,12.0000000,179.9440000,179.9570000, 1); //
    CreateDynamicObject(2755,2431.1006000,1909.5000000,3.7000000,23.9970000,179.9350000,179.9700000, 1); //
    CreateDynamicObject(2755,2431.1006000,1909.5000000,3.7000000,35.9940000,179.9260000,179.9840000, 1); //
    CreateDynamicObject(2755,2431.1006000,1909.5000000,3.7000000,47.9910000,179.9070000,180.0070000, 1); //
    CreateDynamicObject(920,2428.8000000,1906.6000000,5.5000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(920,2428.8000000,1908.8000000,5.5000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2755,2413.0000000,1906.5000000,6.4000000,0.0000000,270.0000000,270.0000000, 1); //
    CreateDynamicObject(2755,2413.0000000,1910.0000000,6.4000000,0.0000000,90.0000000,270.0000000, 1); //
    CreateDynamicObject(2755,2414.1001000,1910.0000000,9.0000000,315.0000000,90.0000000,270.0000000, 1); //
    CreateDynamicObject(2755,2416.6001000,1910.0000000,9.0000000,315.0000000,270.0000000,90.0000000, 1); //
    CreateDynamicObject(2755,2417.6001000,1910.0000000,6.4000000,0.0000000,90.0000000,270.0000000, 1); //
    CreateDynamicObject(2755,2417.6001000,1906.5000000,6.4000000,0.0000000,270.0000000,270.0000000, 1); //
    CreateDynamicObject(2755,2416.6001000,1906.5000000,9.0000000,314.9950000,270.0000000,90.0000000, 1); //
    CreateDynamicObject(2755,2414.1001000,1906.5000000,9.0000000,315.0000000,90.0000000,270.0000000, 1); //
    CreateDynamicObject(2395,2429.7000000,1910.9000000,5.0000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1661,2417.3000000,1909.9000000,6.3500000,0.0000000,270.0000000,0.0000000, 1); //
    CreateDynamicObject(2987,2416.8000000,1911.2000000,6.2000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2987,2413.8000000,1911.2000000,6.2000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3439,2057.3999000,1359.0000000,14.6000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3439,2057.3999000,987.0000000,14.6000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1318,2081.5000000,1043.2998000,16.9000000,270.0000000,179.9950000,270.0000000, 1); //
    CreateDynamicObject(2755,1986.5000000,1619.0000000,12.9000000,0.0000000,270.0000000,0.0000000, 1); //
    CreateDynamicObject(2755,1986.5000000,1627.2000000,12.9000000,0.0000000,270.0000000,0.0000000, 1); //
    CreateDynamicObject(2755,1986.5000000,1626.1000000,15.5000000,45.0000000,270.0000000,0.0000000, 1); //
    CreateDynamicObject(2755,1986.5000000,1620.1000000,15.5000000,315.0050000,270.0000000,0.0000000, 1); //
    CreateDynamicObject(2755,1986.5000000,1621.6000000,17.0000000,315.0050000,270.0000000,0.0000000, 1); //
    CreateDynamicObject(2755,1986.5000000,1624.6000000,17.0000000,44.9950000,270.0000000,0.0000000, 1); //
    CreateDynamicObject(2755,1983.0000000,1619.0000000,12.9000000,0.0000000,270.0000000,0.0000000, 1); //
    CreateDynamicObject(2755,1983.0000000,1620.1000000,15.5000000,315.0050000,270.0000000,0.0000000, 1); //
    CreateDynamicObject(2755,1983.0000000,1621.6000000,17.0000000,315.0050000,270.0000000,0.0000000, 1); //
    CreateDynamicObject(2755,1983.0000000,1626.1000000,15.5000000,44.9950000,270.0000000,0.0000000, 1); //
    CreateDynamicObject(2755,1983.0000000,1624.5996000,17.0000000,44.9950000,270.0000000,0.0000000, 1); //
    CreateDynamicObject(2755,1983.0000000,1627.2002000,12.9000000,0.0000000,270.0000000,0.0000000, 1); //
    CreateDynamicObject(1451,2094.8000000,1666.5000000,10.6000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(645,1969.7000000,1618.2000000,20.8000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(645,1998.1000000,1607.7000000,6.7000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3877,2000.8000000,1667.4000000,18.0000000,0.0000000,78.0000000,0.0000000, 1); //
    CreateDynamicObject(3877,2000.3000000,1671.8000000,18.0000000,0.0000000,77.9970000,0.0000000, 1); //
    CreateDynamicObject(3531,1984.6000000,1650.1000000,13.1000000,0.0000000,179.9950000,291.0000000, 1); //
    CreateDynamicObject(3531,1984.5996000,1650.0996000,16.6000000,0.0000000,0.0000000,290.9950000, 1); //
    CreateDynamicObject(2755,1984.4000000,1650.5000000,13.8000000,0.0000000,179.9950000,20.0000000, 1); //
    CreateDynamicObject(2755,1984.4000000,1650.5000000,15.9000000,0.0000000,359.9950000,19.9950000, 1); //
    CreateDynamicObject(10632,2160.8999000,944.7000100,15.8000000,0.0000000,0.0000000,180.0000000, 1); //
    CreateDynamicObject(2898,2017.3000000,1117.0000000,9.8000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2898,2021.3000000,1117.0000000,9.8000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2898,2025.3000000,1117.0000000,9.8000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2898,2017.3000000,1122.4000000,9.8000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2898,2021.3000000,1122.4004000,9.8000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2898,2025.2998000,1122.4004000,9.8000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2898,2017.2998000,1127.7998000,9.8000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2898,2021.2998000,1127.8008000,9.8000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2898,2025.2998000,1127.8008000,9.8000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2898,2017.2996000,1133.1996000,9.8000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2898,2017.2993000,1138.5994000,9.8000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2898,2021.2996000,1133.2012000,9.8000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2898,2021.2993000,1138.6016000,9.8000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2898,2025.2996000,1133.2012000,9.8000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2898,2025.2998000,1138.6015600,9.8000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2985,2021.2000000,1114.7000000,9.8000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2985,2021.2000000,1140.9000000,9.8000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2951,2017.7000000,1138.5000000,14.4000000,80.0000000,180.0000000,270.0000000, 1); //
    CreateDynamicObject(2951,2017.7002000,1132.9004000,14.4000000,79.9970000,179.9950000,270.0000000, 1); //
    CreateDynamicObject(2951,2017.7002000,1127.2998000,14.4000000,79.9910000,179.9840000,270.0000000, 1); //
    CreateDynamicObject(2951,2017.7002000,1121.7002000,14.4000000,79.9860000,179.9840000,270.0000000, 1); //
    CreateDynamicObject(2951,2017.8000000,1117.2000000,14.4000000,79.9860000,179.9840000,270.0000000, 1); //
    CreateDynamicObject(1408,2019.4000000,1141.3000000,10.1000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1408,2024.6000000,1141.3000000,10.1000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1408,2019.4000000,1114.3000000,10.1000000,0.0000000,0.0000000,180.0000000, 1); //
    CreateDynamicObject(1408,2024.6000000,1114.2998000,10.1000000,0.0000000,0.0000000,179.9950000, 1); //
    CreateDynamicObject(2898,2203.3999000,1259.6000000,9.8000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2898,2199.3999000,1259.6000000,9.8000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2898,2211.3999000,1259.6000000,9.8000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2898,2215.3999000,1259.6000000,9.8000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2898,2207.3999000,1254.2000000,9.8000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2898,2207.3999000,1259.6000000,9.8000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2898,2203.4004000,1259.5996000,9.8000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6959,1318.2000000,2179.0000000,10.0700000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6959,2057.2998000,1003.2002000,9.7050000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6959,2057.3000500,1043.1999500,9.7050000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6959,2057.3000000,1083.2000000,9.7050000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6959,2057.2998000,1123.2002000,9.7050000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6959,2057.3000000,1163.1997000,9.7050000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6959,2057.3000000,1203.1997000,9.7050000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6959,2057.3000000,1243.1997000,9.7050000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6959,2057.3000000,1283.1996000,9.7050000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6959,2057.2998000,1323.1992000,9.7050000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6959,2057.2998000,1363.1992000,9.7050000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6959,2057.2998000,1403.1992000,9.7050000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6959,2057.2998000,1443.1992000,9.7050000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6959,2057.2998000,1483.1992000,9.7050000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6959,2057.2998000,1523.1992000,9.7050000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6959,2057.2998000,1563.1992000,9.7050000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6959,2057.2998000,1603.1992000,9.7050000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6959,2057.2998000,1643.1992000,9.7050000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6959,2057.2998000,1683.1992000,9.7050000,0.0000000,0.0000000,0.0000000, 1); //
    AddStaticVehicleEx(411,2039.4000000,1089.5000000,10.5000000,0.0000000,-1,-1,15, 1); //Infernus
    CreateDynamicObject(6959,2062.0000000,1712.5996000,9.7080000,0.0000000,0.0000000,333.9900000, 1); //
    CreateDynamicObject(6959,2079.4004000,1748.4004000,9.7060000,0.0000000,0.0000000,333.9900000, 1); //
    CreateDynamicObject(6959,2096.8999000,1784.3000000,9.7060000,0.0000000,0.0000000,333.9950000, 1); //
    CreateDynamicObject(6959,2137.3999000,1885.7000000,9.7080000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6959,2114.3999000,1820.2000000,9.7060000,0.0000000,0.0000000,333.9900000, 1); //
    CreateDynamicObject(6959,2131.8999000,1856.1000000,9.7060000,0.0000000,0.0000000,333.9900000, 1); //
    CreateDynamicObject(6959,2137.3999000,1925.7000000,9.7080000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6959,2137.4004000,1965.7002000,9.7080000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6959,2137.4004000,2005.7002000,9.7080000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6959,2137.4004000,2045.7002000,9.7080000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6959,2137.4004000,2085.7002000,9.7080000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6959,2137.4004000,2125.7002000,9.7080000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6959,2137.4004000,2165.7002000,9.7080000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6959,2137.4004000,2205.7002000,9.7080000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6959,2137.4004000,2245.7002000,9.7080000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6959,2137.4004000,2285.7002000,9.7080000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6959,2086.9004000,2082.7998000,10.0000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(7246,2079.2002000,1043.5996000,14.0000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(941,2017.4000000,1128.0000000,10.3000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(941,2017.4000000,1125.5000000,10.3000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(941,2017.4000000,1123.0000000,10.3000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(941,2017.4000000,1130.5000000,10.3000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(941,2017.4000000,1133.0000000,10.3000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(2035,2017.4000000,1128.7000000,10.8000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2035,2017.4000000,1128.5000000,10.8000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2035,2017.4000000,1128.3000000,10.8000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2035,2017.4000000,1128.1000000,10.8000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2035,2017.4000000,1127.5000000,10.8000000,0.0000000,179.9950000,179.9950000, 1); //
    CreateDynamicObject(2035,2017.4000000,1127.3000000,10.8000000,0.0000000,179.9950000,179.9950000, 1); //
    CreateDynamicObject(2035,2017.4000000,1127.1000000,10.8000000,0.0000000,179.9950000,179.9950000, 1); //
    CreateDynamicObject(2035,2017.4000000,1126.9000000,10.8000000,0.0000000,179.9950000,179.9950000, 1); //
    CreateDynamicObject(2036,2017.1000000,1129.8000000,10.8000000,0.0000000,0.0000000,90.0000000, 1); //
    CreateDynamicObject(2036,2017.4000000,1130.5000000,10.8000000,0.0000000,0.0000000,90.0000000, 1); //
    CreateDynamicObject(2036,2017.8000000,1129.8000000,10.8000000,0.0000000,0.0000000,90.0000000, 1); //
    CreateDynamicObject(2044,2017.7000000,1131.8000000,10.8000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2044,2017.2000000,1131.8000000,10.8000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2044,2017.2000000,1132.3000000,10.8000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2044,2017.7000000,1132.3000000,10.8000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2044,2017.7000000,1132.8000000,10.8000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2044,2017.2000000,1132.8000000,10.8000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2044,2017.2000000,1133.3000000,10.8000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2044,2017.7000000,1133.3000000,10.8000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2045,2017.2000000,1124.6000000,10.9000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2045,2017.7000000,1124.6000000,10.9000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2045,2017.7000000,1125.8000000,10.9000000,0.0000000,0.0000000,180.0000000, 1); //
    CreateDynamicObject(2045,2017.2000000,1125.8000000,10.9000000,0.0000000,0.0000000,179.9950000, 1); //
    CreateDynamicObject(2034,2017.8000000,1121.9000000,10.8000000,0.0000000,0.0000000,90.0000000, 1); //
    CreateDynamicObject(2034,2017.5000000,1121.9000000,10.8000000,0.0000000,0.0000000,90.0000000, 1); //
    CreateDynamicObject(2034,2017.2000000,1121.9000000,10.8000000,0.0000000,0.0000000,90.0000000, 1); //
    CreateDynamicObject(2034,2017.2000000,1122.4000000,10.8000000,0.0000000,0.0000000,90.0000000, 1); //
    CreateDynamicObject(2034,2017.2000000,1122.9000000,10.8000000,0.0000000,0.0000000,90.0000000, 1); //
    CreateDynamicObject(2034,2017.2000000,1123.4000000,10.8000000,0.0000000,0.0000000,90.0000000, 1); //
    CreateDynamicObject(2034,2017.5000000,1122.4000000,10.8000000,0.0000000,0.0000000,90.0000000, 1); //
    CreateDynamicObject(2034,2017.5000000,1122.9000000,10.8000000,0.0000000,0.0000000,90.0000000, 1); //
    CreateDynamicObject(2034,2017.5000000,1123.4000000,10.8000000,0.0000000,0.0000000,90.0000000, 1); //
    CreateDynamicObject(2034,2017.8000000,1122.4000000,10.8000000,0.0000000,0.0000000,90.0000000, 1); //
    CreateDynamicObject(2034,2017.8000000,1122.9000000,10.8000000,0.0000000,0.0000000,90.0000000, 1); //
    CreateDynamicObject(2034,2017.8000000,1123.4000000,10.8000000,0.0000000,0.0000000,90.0000000, 1); //
    CreateDynamicObject(7246,2079.2002000,1202.2000000,14.0000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1318,2081.5000000,1201.9000000,17.0000000,270.0000000,179.9950000,270.0000000, 1); //
    CreateDynamicObject(7246,2079.2002000,1383.5996000,14.0000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1318,2081.5000000,1383.2998000,17.0000000,270.0000000,179.9950000,270.0000000, 1); //
    CreateDynamicObject(6959,2107.9004000,1403.2002000,9.8550000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6959,2149.2000000,1403.2000000,9.8550000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6959,2190.5000000,1403.2002000,9.8550000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6959,2216.7002000,1403.2002000,9.8550000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6959,2107.9004000,1443.2002000,9.8550000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(10378,2162.1006000,1453.0000000,9.8700000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6959,2216.7002000,1443.2002000,9.8550000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6959,2107.8999000,1483.2000000,9.8550000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6959,2107.9004000,1503.2998000,9.8560000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6959,2149.2012000,1503.2998000,9.8550000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6959,2190.5000000,1503.2998000,9.8550000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6959,2216.7002000,1483.2002000,9.8550000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6959,2216.7012000,1503.2998000,9.8560000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2755,2000.4000000,1555.5000000,13.5000000,88.0000000,180.0000000,179.9890000, 1); //
    CreateDynamicObject(2395,2017.9000000,992.9000200,38.8000000,270.0000000,270.0000000,0.0000000, 1); //
    CreateDynamicObject(2395,2021.8000000,992.9000200,38.3000000,270.0000000,270.0000000,0.0000000, 1); //
    CreateDynamicObject(9046,1985.5996000,1503.2002000,9.4000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(9046,1933.0996000,1503.5000000,9.3950000,0.0000000,0.0000000,179.9950000, 1); //
    CreateDynamicObject(1290,1959.8000000,1503.2000000,15.4000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1290,1959.7998000,1503.2002000,15.4000000,0.0000000,0.0000000,92.0000000, 1); //
    CreateDynamicObject(3472,1928.2002000,1519.0000000,9.4000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(9047,1984.1999500,1503.3000500,8.6000000,0.0000000,0.0000000,180.0000000, 1); //
    CreateDynamicObject(9047,1933.4004000,1503.5000000,8.6000000,0.0000000,0.0000000,179.9950000, 1); //
    CreateDynamicObject(3472,1929.6000000,1487.7000000,9.4000000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(10309,1868.0000000,1528.3000500,8.7000000,0.0000000,0.0000000,45.0000000, 1); //
    CreateDynamicObject(14582,1960.7002000,1524.5000000,12.9000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(14868,2024.7000000,1116.8000000,10.5000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(14868,2024.7000000,1116.8000000,12.3000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(14868,2024.7000000,1121.8000000,12.3000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(14868,2024.7000000,1121.8000000,10.5000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(14868,2024.7000000,1126.9000000,10.5000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(14868,2024.7000000,1126.9000000,12.3000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(14868,2024.7000000,1131.9000000,12.3000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(14868,2024.7000000,1131.9000000,10.5000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(14868,2024.8000000,1136.9000000,10.5000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(14868,2024.8000000,1136.9000000,12.3000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(14868,2024.7000000,1141.9000000,12.3000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(14868,2024.7000000,1141.9000000,10.5000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(7246,2079.2002000,1543.2000000,14.0000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1318,2081.5000000,1542.9000000,16.9000000,270.0000000,179.9950000,270.0000000, 1); //
    CreateDynamicObject(7246,2079.2002000,1651.8000000,14.0000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1318,2081.5000000,1651.5000000,16.9000000,270.0000000,179.9950000,270.0000000, 1); //
    CreateDynamicObject(7246,2044.2000000,1721.3000000,14.0000000,0.0000000,0.0000000,178.0000000, 1); //
    CreateDynamicObject(7246,2034.9000000,1463.2000000,14.0000000,0.0000000,0.0000000,177.9950000, 1); //
    CreateDynamicObject(7246,2034.9000000,1283.1000000,14.0000000,0.0000000,0.0000000,177.9950000, 1); //
    CreateDynamicObject(7246,2034.9000000,1103.2000000,14.0000000,0.0000000,0.0000000,177.9950000, 1); //
    CreateDynamicObject(1318,2041.9000000,1721.7000000,16.9000000,90.0000000,90.0000000,0.0000000, 1); //
    CreateDynamicObject(1318,2032.7000000,1463.6000000,16.9000000,90.0000000,90.0000000,0.0000000, 1); //
    CreateDynamicObject(1318,2032.6000000,1283.5000000,17.0000000,90.0000000,90.0000000,0.0000000, 1); //
    CreateDynamicObject(1318,2032.6000000,1103.6000000,16.9000000,90.0000000,90.0000000,0.0000000, 1); //
    CreateDynamicObject(1290,2025.4000000,1298.3000000,13.1000000,0.0000000,0.0000000,34.0000000, 1); //
    CreateDynamicObject(1290,2023.8000000,1302.5000000,14.6000000,0.0000000,0.0000000,31.9970000, 1); //
    CreateDynamicObject(1290,2023.2000000,1307.1000000,16.4000000,0.0000000,0.0000000,21.9920000, 1); //
    CreateDynamicObject(1290,2022.6000000,1311.8000000,17.9000000,0.0000000,0.0000000,17.9890000, 1); //
    CreateDynamicObject(1290,2022.4000000,1316.1000000,19.4000000,0.0000000,0.0000000,5.9850000, 1); //
    CreateDynamicObject(1290,2022.1000000,1320.7000000,21.1000000,0.0000000,0.0000000,5.9820000, 1); //
    CreateDynamicObject(1290,2022.2000000,1325.1000000,22.6000000,0.0000000,0.0000000,5.9820000, 1); //
    CreateDynamicObject(1290,2022.6000000,1329.4000000,24.1000000,0.0000000,0.0000000,5.9820000, 1); //
    CreateDynamicObject(1290,2022.6000000,1356.6000000,24.1000000,0.0000000,0.0000000,354.0180000, 1); //
    CreateDynamicObject(1290,2022.3000000,1361.0000000,22.6000000,0.0000000,0.0000000,354.0180000, 1); //
    CreateDynamicObject(1290,2022.4000000,1365.3000000,21.1000000,0.0000000,0.0000000,354.0180000, 1); //
    CreateDynamicObject(1290,2022.4000000,1369.9000000,19.4000000,0.0000000,0.0000000,354.0180000, 1); //
    CreateDynamicObject(1290,2022.6000000,1374.3000000,17.9000000,0.0000000,0.0000000,342.0150000, 1); //
    CreateDynamicObject(1290,2023.1000000,1378.9000000,16.4000000,0.0000000,0.0000000,338.0110000, 1); //
    CreateDynamicObject(1290,2023.8000000,1383.5000000,14.6000000,0.0000000,0.0000000,328.0080000, 1); //
    CreateDynamicObject(1290,2025.4000000,1387.5000000,13.1000000,0.0000000,0.0000000,326.0030000, 1); //
    CreateDynamicObject(16009,2056.5000000,1246.4000000,8.2000000,0.0000000,0.0000000,16.5000000, 1); //
    CreateDynamicObject(16009,2056.5000000,1408.2000000,8.2000000,0.0000000,0.0000000,16.5000000, 1); //
    CreateDynamicObject(16009,2056.5000000,1668.1000000,8.2000000,0.0000000,0.0000000,16.5000000, 1); //
    CreateDynamicObject(11423,1997.7000000,1623.4000000,12.4000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(11423,1980.9000200,1503.4000200,13.3000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3877,2088.8000000,1406.4000000,28.8000000,0.0000000,18.0000000,0.0000000, 1); //
    CreateDynamicObject(3877,2103.3999000,1406.4000000,27.8000000,0.0000000,35.9960000,0.0000000, 1); //
    CreateDynamicObject(3877,2087.1001000,1406.4000000,23.3000000,0.0000000,197.9950000,0.0000000, 1); //
    CreateDynamicObject(3877,2095.0000000,1406.4000000,16.2100000,0.0000000,215.9910000,0.0000000, 1); //
    CreateDynamicObject(3877,2025.6000000,1406.4000000,28.8000000,0.0000000,336.0040000,0.0000000, 1); //
    CreateDynamicObject(3877,2010.0000000,1406.4000000,27.8000000,0.0000000,320.0090000,0.0000000, 1); //
    CreateDynamicObject(3877,2020.1000000,1406.4000000,16.2000000,0.0000000,138.0140000,0.0000000, 1); //
    CreateDynamicObject(3877,2028.1000000,1406.4000000,23.3000000,0.0000000,154.0100000,0.0000000, 1); //
    CreateDynamicObject(3877,2088.8000000,1419.1000000,28.8000000,0.0000000,17.9960000,0.0000000, 1); //
    CreateDynamicObject(3877,2103.3999000,1257.4000000,27.8000000,0.0000000,35.9960000,0.0000000, 1); //
    CreateDynamicObject(3877,2087.1001000,1419.1000000,23.3000000,0.0000000,197.9900000,0.0000000, 1); //
    CreateDynamicObject(3877,2095.0000000,1419.1000000,16.2000000,0.0000000,215.9860000,0.0000000, 1); //
    CreateDynamicObject(3877,2028.0996000,1419.1000000,23.3000000,0.0000000,154.0060000,0.0000000, 1); //
    CreateDynamicObject(3877,2025.5996000,1419.1000000,28.8000000,0.0000000,336.0000000,0.0000000, 1); //
    CreateDynamicObject(3877,2010.0000000,1419.1000000,27.8000000,0.0000000,320.0040000,0.0000000, 1); //
    CreateDynamicObject(3877,2020.0996000,1419.1000000,16.2000000,0.0000000,138.0100000,0.0000000, 1); //
    CreateDynamicObject(3877,2025.5996000,1257.4000000,28.8000000,0.0000000,336.0000000,0.0000000, 1); //
    CreateDynamicObject(3877,2028.0996000,1257.4000000,23.3000000,0.0000000,154.0060000,0.0000000, 1); //
    CreateDynamicObject(3877,2010.0000000,1257.4000000,27.8000000,0.0000000,320.0040000,0.0000000, 1); //
    CreateDynamicObject(3877,2020.0996000,1257.4000000,16.2000000,0.0000000,138.0100000,0.0000000, 1); //
    CreateDynamicObject(3877,2087.1006000,1257.4000000,23.3000000,0.0000000,197.9900000,0.0000000, 1); //
    CreateDynamicObject(3877,2088.7998000,1257.4000000,28.8000000,0.0000000,17.9960000,0.0000000, 1); //
    CreateDynamicObject(3877,2095.0000000,1257.4000000,16.2000000,0.0000000,215.9860000,0.0000000, 1); //
    CreateDynamicObject(3877,2025.5996000,1244.6000000,28.8000000,0.0000000,336.0000000,0.0000000, 1); //
    CreateDynamicObject(3877,2010.0000000,1244.6000000,27.8000000,0.0000000,320.0040000,0.0000000, 1); //
    CreateDynamicObject(3877,2020.0996000,1244.6000000,16.2000000,0.0000000,138.0100000,0.0000000, 1); //
    CreateDynamicObject(3877,2028.0996000,1244.6000000,23.3000000,0.0000000,154.0060000,0.0000000, 1); //
    CreateDynamicObject(3877,2087.1006000,1244.6000000,23.3000000,0.0000000,197.9900000,0.0000000, 1); //
    CreateDynamicObject(3877,2095.0000000,1244.6000000,16.2000000,0.0000000,215.9860000,0.0000000, 1); //
    CreateDynamicObject(3877,2088.7998000,1244.6000000,28.8000000,0.0000000,17.9960000,0.0000000, 1); //
    CreateDynamicObject(3877,2103.4004000,1244.6000000,27.8000000,0.0000000,35.9910000,0.0000000, 1); //
    CreateDynamicObject(3877,2103.4004000,1419.1000000,27.8000000,0.0000000,35.9910000,0.0000000, 1); //
    CreateDynamicObject(3877,2088.8000000,1666.3000000,28.8000000,0.0000000,17.9960000,0.0000000, 1); //
    CreateDynamicObject(3877,2088.8000000,1679.0000000,28.8000000,0.0000000,17.9960000,0.0000000, 1); //
    CreateDynamicObject(3877,2087.1006000,1666.3000000,23.3000000,0.0000000,197.9900000,0.0000000, 1); //
    CreateDynamicObject(3877,2103.4004000,1666.3000000,27.8000000,0.0000000,35.9910000,0.0000000, 1); //
    CreateDynamicObject(3877,2095.0000000,1666.3000000,16.2100000,0.0000000,215.9860000,0.0000000, 1); //
    CreateDynamicObject(3877,2028.0996000,1666.3000000,23.3000000,0.0000000,154.0060000,0.0000000, 1); //
    CreateDynamicObject(3877,2025.5996000,1666.3000000,28.8000000,0.0000000,336.0000000,0.0000000, 1); //
    CreateDynamicObject(3877,2010.0000000,1666.3000000,27.8000000,0.0000000,320.0040000,0.0000000, 1); //
    CreateDynamicObject(3877,2020.0996000,1666.3000000,16.2000000,0.0000000,138.0100000,0.0000000, 1); //
    CreateDynamicObject(3877,2103.4004000,1679.0000000,27.8000000,0.0000000,35.9910000,0.0000000, 1); //
    CreateDynamicObject(3877,2095.0000000,1679.0000000,16.2000000,0.0000000,215.9860000,0.0000000, 1); //
    CreateDynamicObject(3877,2087.1006000,1679.0000000,23.3000000,0.0000000,197.9900000,0.0000000, 1); //
    CreateDynamicObject(3877,2028.0996000,1679.0000000,23.3000000,0.0000000,154.0060000,0.0000000, 1); //
    CreateDynamicObject(3877,2020.0996000,1679.0000000,16.2000000,0.0000000,138.0100000,0.0000000, 1); //
    CreateDynamicObject(3877,2010.0000000,1679.0000000,27.8000000,0.0000000,320.0040000,0.0000000, 1); //
    CreateDynamicObject(3877,2025.5996000,1679.0000000,28.8000000,0.0000000,336.0000000,0.0000000, 1); //
    CreateDynamicObject(5243,1908.3000000,1514.9000000,13.4000000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6959,2086.9004000,2052.3999000,9.9500000,0.0000000,0.0000000,0.0000000, 1); //
    print("[Gamemode::Objects]: New las venturas objects has been loaded.");

    CreateDynamicObject(6522,421.2878720,2550.9572750,23.7943270,0.0000000,0.0000000,180.0000000, 1); //static house
    CreateDynamicObject(8040,1091.7049560,2502.4074710,294.2457580,0.0000000,0.0000000,180.0000000, 1); //static for /aajump
    CreateDynamicObject(1655,252.2971500,2516.0688480,16.7180690,0.0000000,0.0000000,89.9999813, 1); //
    CreateDynamicObject(1655,252.3057860,2524.7907710,16.7143150,0.0000000,0.0000000,89.9999813, 1); //
    CreateDynamicObject(1655,245.2717590,2516.0649410,20.9115450,16.3292972,0.0000000,89.9999813, 1); //
    CreateDynamicObject(1655,245.2659450,2524.7634280,20.9196610,16.3292972,0.0000000,89.9999813, 1); //
    CreateDynamicObject(16776,233.8013920,2520.2978520,17.4384370,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1655,213.6095280,2515.5363770,16.7138940,0.0000000,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(1655,213.6083830,2524.2055660,16.7057250,0.0000000,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(1655,220.6318360,2515.5417480,20.9444480,16.3292972,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(1655,220.6297610,2524.1062010,20.9258000,16.3292972,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(16304,233.5603940,2519.7141110,19.6206820,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(13641,276.0351560,2490.2517090,17.1286200,0.0000000,0.0000000,-181.7188359, 1); //
    CreateDynamicObject(13641,250.7765500,2489.7329100,17.1036210,0.0000000,0.0000000,-361.7188558, 1); //
    CreateDynamicObject(10379,240.0676270,2545.8642580,24.1613790,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(8881,365.6042180,2595.5541990,49.7411500,0.0000000,0.0000000,-63.2028025, 1); //
    CreateDynamicObject(978,340.5581970,2555.0803220,16.5140400,0.0000000,0.0000000,-157.4999672, 1); //
    CreateDynamicObject(979,389.7102360,2557.7644040,16.3790490,0.0000000,0.0000000,-168.7499362, 1); //
    CreateDynamicObject(979,396.9901730,2559.2299800,16.3613700,0.0000000,0.0000000,-168.7499362, 1); //
    CreateDynamicObject(2405,356.3997500,2558.1538090,23.0996460,0.0000000,36.9557778,0.0000000, 1); //
    CreateDynamicObject(2405,356.4088130,2558.1401370,21.3051410,0.0000000,-38.6746512,0.0000000, 1); //
    CreateDynamicObject(2405,356.4770810,2558.1259770,19.5289380,0.0000000,36.9557778,0.0000000, 1); //
    CreateDynamicObject(2405,359.3681640,2558.1220700,22.7844490,0.0000000,-0.8594367,0.0000000, 1); //
    CreateDynamicObject(2405,359.4001770,2558.0896000,20.3243960,0.0000000,-0.8594367,0.0000000, 1); //
    CreateDynamicObject(2405,360.4607240,2558.1362300,23.8110490,0.0000000,-89.3814160,0.8594367, 1); //
    CreateDynamicObject(2405,360.3874510,2558.1159670,21.4822080,0.0000000,-89.3814160,0.8594367, 1); //
    CreateDynamicObject(2405,360.4557190,2558.0886230,19.2049850,0.0000000,-89.3814160,0.8594367, 1); //
    CreateDynamicObject(2405,365.6058040,2558.1127930,19.7805920,0.0000000,-143.5260423,0.8594367, 1); //
    CreateDynamicObject(2405,364.3010860,2558.0732420,19.8405900,0.0000000,-209.7028968,0.8594367, 1); //
    CreateDynamicObject(2405,368.4699400,2558.0854490,23.4652440,0.0000000,-269.8631788,0.8594367, 1); //
    CreateDynamicObject(13592,364.6592710,2477.9926760,26.7300130,-48.9878342,-32.6588235,0.9367860, 1); //
    CreateDynamicObject(13592,363.9357910,2473.0886230,31.5432640,-48.9878342,-32.6588235,0.9367860, 1); //
    CreateDynamicObject(13592,363.1276250,2468.1018070,36.3976750,-48.9878342,-32.6588235,0.9367860, 1); //
    CreateDynamicObject(13592,362.3266600,2463.4099120,41.0432430,-48.9878342,-32.6588235,0.9367860, 1); //
    CreateDynamicObject(13592,361.5557860,2458.4641110,45.8765980,-48.9878342,-32.6588235,0.9367860, 1); //
    CreateDynamicObject(13592,360.8029170,2453.5056150,50.7339630,-48.9878342,-32.6588235,0.9367860, 1); //
    CreateDynamicObject(13592,360.0373540,2448.4960940,55.6518330,-48.9878342,-32.6588235,0.9367860, 1); //
    CreateDynamicObject(7092,380.4837950,2558.1945800,31.1834890,0.0000000,0.0000000,89.9999813, 1); //
    CreateDynamicObject(7092,387.8651730,2475.7285160,24.8125950,0.0000000,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(8423,364.3757320,2557.8840330,30.4599340,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(8357,252.2503050,2457.7795410,20.6959130,0.0000000,-20.6264806,-89.9999813, 1); //
    CreateDynamicObject(8357,51.6166530,2457.7514650,20.7037580,0.0000000,-20.6264806,-89.9999813, 1); //
    CreateDynamicObject(8357,-87.8899770,2457.8024900,20.6774600,0.0000000,-20.6264806,-89.9999813, 1); //
    CreateDynamicObject(4867,252.6747440,2347.5063480,27.6604580,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(4867,40.2340850,2347.4948730,27.6853620,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(4867,-86.3587190,2347.4919430,27.7073170,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(13592,359.2206730,2443.4577640,60.5647130,-48.9878342,-32.6588235,0.9367860, 1); //
    CreateDynamicObject(13592,358.4740910,2438.6101070,65.3362880,-48.9878342,-32.6588235,0.9367860, 1); //
    CreateDynamicObject(4867,358.2048030,2347.5842290,-79.1186900,0.0000000,90.2408527,0.0000000, 1); //
    CreateDynamicObject(9907,338.5668640,2406.4919430,8.6091750,0.0000000,18.0481705,0.0000000, 1); //
    CreateDynamicObject(8171,491.5917050,2502.5271000,43.3723140,24.0642274,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(8171,365.9913020,2502.5400390,-8.2208490,20.6264806,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(8171,615.9389040,2502.5712890,98.8841930,24.0642274,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(8171,739.9841920,2502.5976560,154.2696530,24.0642274,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(8171,863.3182370,2502.6083980,209.3468930,24.0642274,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(8171,988.6848140,2502.6198730,265.3071590,24.0642274,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(1655,783.5501100,2502.4897460,173.8002780,-35.2369044,0.0000000,89.9999813, 1); //
    CreateDynamicObject(1655,775.8311770,2502.4946290,173.5571900,-15.4698605,0.0000000,89.9999813, 1); //
    CreateDynamicObject(1655,767.9823000,2502.4982910,175.7188110,0.8594367,0.0000000,89.9999813, 1); //
    CreateDynamicObject(1655,761.0449830,2502.5058590,180.2858120,19.7670439,0.0000000,89.9999813, 1); //
    CreateDynamicObject(1655,755.8480830,2502.5134280,186.7832030,36.9557205,0.0000000,89.9999813, 1); //
    CreateDynamicObject(6189,641.8563230,2501.8613280,178.6911010,0.0000000,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(1655,600.2898560,2487.9062500,91.9957960,-35.2369044,0.0000000,89.9999813, 1); //
    CreateDynamicObject(5005,500.5596920,2521.8911130,50.4717560,0.0000000,-24.0642274,0.0000000, 1); //
    CreateDynamicObject(5005,649.1944580,2521.8342290,116.8509830,0.0000000,-24.0642274,0.0000000, 1); //
    CreateDynamicObject(5005,797.7779540,2521.7902830,183.2002720,0.0000000,-24.0642274,0.0000000, 1); //
    CreateDynamicObject(5005,946.3821410,2521.7438960,249.5704040,0.0000000,-24.0642274,0.0000000, 1); //
    CreateDynamicObject(5005,974.6026610,2521.7626950,262.1935120,0.0000000,-24.0642274,0.0000000, 1); //
    CreateDynamicObject(5005,500.5528560,2483.0605470,50.5060200,0.0000000,-24.0642274,0.0000000, 1); //
    CreateDynamicObject(5005,649.1245120,2483.0058590,116.8376240,0.0000000,-24.0642274,0.0000000, 1); //
    CreateDynamicObject(5005,797.6738280,2482.9560550,183.1721500,0.0000000,-24.0642274,0.0000000, 1); //
    CreateDynamicObject(5005,946.3334350,2482.8947750,249.5606080,0.0000000,-24.0642274,0.0000000, 1); //
    CreateDynamicObject(5005,974.5729980,2482.9230960,262.1986390,0.0000000,-24.0642274,0.0000000, 1); //
    CreateDynamicObject(8040,1091.7901610,2502.9082030,300.2009280,0.0000000,-179.6224407,-360.0000397, 1); //
    CreateDynamicObject(1655,592.0264890,2487.9028320,91.4458010,-18.0481705,0.0000000,89.9999813, 1); //
    CreateDynamicObject(1655,583.9429930,2487.8959960,93.2317050,-2.5783101,0.0000000,89.9999813, 1); //
    CreateDynamicObject(1655,576.5737920,2487.9003910,97.1203540,12.8915504,0.0000000,89.9999813, 1); //
    CreateDynamicObject(1655,487.3106690,2516.9345700,41.5855670,-35.2369044,0.0000000,89.9999813, 1); //
    CreateDynamicObject(1655,478.7615970,2516.9440920,41.4053920,-13.7509871,0.0000000,89.9999813, 1); //
    CreateDynamicObject(1655,470.9108890,2516.9528810,43.8541110,2.5783101,0.0000000,89.9999813, 1); //
    CreateDynamicObject(1655,416.1291200,2502.5251460,16.5594900,0.0000000,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(1655,423.0247500,2502.5202640,20.4638750,13.7509871,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(1655,438.3301390,2502.4431150,20.3777100,-21.4859173,0.0000000,-269.9999438, 1); //
    CreateDynamicObject(1655,429.9784240,2502.4489750,21.6844920,-6.0160568,0.0000000,-269.9999438, 1); //
    CreateDynamicObject(6189,512.0573730,2501.8769530,178.6931610,0.0000000,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(1655,451.4633790,2502.1459960,194.2261510,0.0000000,0.0000000,89.9999813, 1); //
    CreateDynamicObject(1655,445.5448610,2502.1608890,197.7567290,15.4698605,0.0000000,89.9999813, 1); //
    CreateDynamicObject(3434,450.6030270,2490.9548340,200.7460630,0.0000000,0.0000000,89.9999813, 1); //
    CreateDynamicObject(3434,450.5018310,2513.6340330,200.7460020,0.0000000,0.0000000,89.9999813, 1); //
    CreateDynamicObject(3434,307.7679750,2531.6818850,29.5853020,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1655,318.7531430,2406.4152830,28.7385220,0.0000000,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(1655,325.8792110,2406.4174800,32.6859780,12.8915504,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(1655,331.8559270,2406.4191890,38.3228450,28.3614109,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(16395,247.8724980,2446.8957520,43.9666440,0.0000000,-12.8915504,-9.6084449, 1); //
    CreateDynamicObject(1634,136.1422120,2467.2883300,44.4009280,0.0000000,0.0000000,78.7500123, 1); //
    CreateDynamicObject(8391,317.3923340,2308.2416990,49.2437670,0.0000000,0.0000000,101.2500076, 1); //
    CreateDynamicObject(17310,329.9812930,2307.7163090,36.4599800,0.0000000,-229.4697115,-24.9236641, 1); //
    CreateDynamicObject(13666,294.1717220,2475.9858400,20.2824150,-0.8594367,0.0000000,-44.9999906, 1); //
    CreateDynamicObject(1655,102.6069640,2496.4094240,16.5344910,0.0000000,0.0000000,-270.0000011, 1); //
    CreateDynamicObject(1655,96.0283050,2495.9670410,20.4771630,16.3292972,0.0000000,-270.0000011, 1); //
    CreateDynamicObject(1655,90.6525420,2495.4902340,25.9738560,30.0802842,0.0000000,-270.0000011, 1); //
    CreateDynamicObject(1655,87.0476990,2494.9831540,32.4113620,46.4095241,0.0000000,-270.0000011, 1); //
    CreateDynamicObject(1655,85.5916210,2494.5981450,39.3181230,64.4576947,0.0000000,-270.0000011, 1); //
    CreateDynamicObject(1655,86.4529420,2494.1054690,45.9963490,82.5058652,0.0000000,-270.0000011, 1); //
    CreateDynamicObject(1655,89.3029860,2493.7243650,52.5613860,98.8351624,0.0000000,-270.0000011, 1); //
    CreateDynamicObject(1655,94.3158870,2493.2739260,58.3848880,117.7427696,0.0000000,-270.0000011, 1); //
    CreateDynamicObject(1655,100.7257840,2492.8466800,61.9332280,138.3693648,0.0000000,-270.0000011, 1); //
    CreateDynamicObject(1655,108.0199430,2492.4111330,63.3957020,153.8393399,0.0000000,-270.0000011, 1); //
    CreateDynamicObject(1655,115.6458820,2491.9179690,62.5319820,173.6064984,0.0000000,-270.0000011, 1); //
    CreateDynamicObject(1655,122.4359050,2491.3947750,59.6554260,187.3576001,0.0000000,-270.0000011, 1); //
    CreateDynamicObject(1655,128.1582340,2490.9616700,55.3178060,201.9681384,0.0000000,-270.0000011, 1); //
    CreateDynamicObject(1655,132.3630980,2490.5312500,49.6456760,220.0164236,0.0000000,-270.0000011, 1); //
    CreateDynamicObject(1655,134.5752110,2489.9902340,43.3815570,236.3457207,0.0000000,-270.0000011, 1); //
    CreateDynamicObject(1655,134.8574520,2489.4021000,36.2212030,254.3937194,0.0000000,-270.0000011, 1); //
    CreateDynamicObject(1655,132.8946230,2488.9299320,29.4487760,273.3011548,0.0000000,-270.0000011, 1); //
    CreateDynamicObject(1655,129.3544460,2488.5222170,23.7657600,285.3331539,0.0000000,-270.0000011, 1); //
    CreateDynamicObject(1655,124.9291460,2488.1530760,19.2988720,299.0840264,0.0000000,-270.0000011, 1); //
    CreateDynamicObject(1655,119.2620930,2487.4926760,15.7213760,311.9754622,0.0000000,-270.0000011, 1); //
    CreateDynamicObject(1655,118.9084780,2487.5014650,16.0033930,319.7103351,0.0000000,-270.0000011, 1); //
    CreateDynamicObject(1655,172.6773830,2531.0986330,16.7395920,0.0000000,0.0000000,-67.4999860, 1); //
    CreateDynamicObject(9907,39.2192460,2405.9128420,26.6561280,0.0000000,53.2850177,-180.0000198, 1); //
    CreateDynamicObject(1655,13.6526910,2405.8959960,64.1072460,22.3453540,0.0000000,-270.0000011, 1); //
    CreateDynamicObject(1655,8.9613980,2405.8996580,70.4833910,39.5340879,0.0000000,-270.0000011, 1); //
    CreateDynamicObject(1655,6.4231050,2405.9211430,78.0410310,57.5822011,0.0000000,-270.0000011, 1); //
    CreateDynamicObject(1655,6.3623530,2405.9357910,86.4622120,75.6303717,0.0000000,-270.0000011, 1); //
    CreateDynamicObject(17310,39.1096730,2424.4960940,48.7927860,0.0000000,-246.6582735,-179.8453212, 1); //
    CreateDynamicObject(17310,38.9428670,2387.3791500,48.9450610,0.0000000,-246.6582735,-179.8453212, 1); //
    CreateDynamicObject(621,61.9656600,2381.7580570,27.0353300,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(621,62.0386810,2429.2807620,27.3387810,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(16133,226.6152040,2283.8916020,25.7652260,0.0000000,0.0000000,-85.6254485, 1); //
    CreateDynamicObject(16133,178.8560940,2297.0378420,27.2652190,0.0000000,0.0000000,-130.6254391, 1); //
    CreateDynamicObject(16120,161.9450990,2566.6325680,13.4188080,0.0000000,0.0000000,-123.7499456, 1); //
    CreateDynamicObject(16120,366.3159180,2436.9499510,8.5813480,0.0000000,0.0000000,-208.5160720, 1); //
    CreateDynamicObject(8493,225.1131290,2284.8149410,59.9993930,0.0000000,1.7188734,-89.9999813, 1); //
    CreateDynamicObject(8397,185.1450350,2431.5134280,38.1667860,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1632,185.2762150,2443.8564450,28.7922760,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(8881,88.5440220,2289.5554200,56.1615870,0.0000000,0.0000000,88.3584572, 1); //
    CreateDynamicObject(13641,160.2684020,2365.3603520,29.3826500,0.0000000,0.0000000,-179.9999626, 1); //
    CreateDynamicObject(13641,160.2824400,2351.1752930,29.4326500,0.0000000,0.0000000,-179.9999626, 1); //
    CreateDynamicObject(13641,135.0537410,2349.7771000,29.3796040,0.0000000,0.0000000,-359.9999824, 1); //
    CreateDynamicObject(13641,135.0333400,2363.9943850,29.3576510,0.0000000,0.0000000,-359.9999824, 1); //
    CreateDynamicObject(16430,-61.4641950,2358.3107910,45.7781110,0.0000000,16.3292972,0.0000000, 1); //
    CreateDynamicObject(18450,-160.0079350,2358.3203130,80.0137330,0.0000000,29.2208476,0.0000000, 1); //
    CreateDynamicObject(1655,177.9562380,2533.2775880,20.3679960,18.9076072,0.0000000,-67.4999860, 1); //
    CreateDynamicObject(1655,137.1979060,2531.6779790,16.8458420,0.0000000,0.0000000,56.2500169, 1); //
    CreateDynamicObject(1655,131.2233730,2535.6784670,21.2390920,17.1887339,0.0000000,56.2500169, 1); //
    CreateDynamicObject(1655,126.5314640,2538.8166500,27.4118750,32.6585943,0.0000000,56.2500169, 1); //
    CreateDynamicObject(1655,123.4827190,2540.8542480,34.9431690,49.8472709,0.0000000,56.2500169, 1); //
    CreateDynamicObject(1655,122.3386610,2541.6174320,42.9402660,65.3171313,0.0000000,56.2500169, 1); //
    CreateDynamicObject(4023,69.1444240,2551.1269530,23.4494820,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(16120,116.1644820,2567.6105960,10.1936990,0.0000000,0.0000000,-123.7499456, 1); //
    CreateDynamicObject(13666,263.3660890,2434.5673830,32.5437050,0.0000000,0.0000000,134.9999719, 1); //
    CreateDynamicObject(17310,139.2086790,2319.8173830,32.7069660,0.0000000,-215.7186099,-148.6736097, 1); //
    CreateDynamicObject(17310,41.5030250,2327.4436040,32.3069570,0.0000000,-215.7186099,-33.5953230, 1); //
    CreateDynamicObject(8040,-592.1285400,2503.7490230,228.5551760,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1655,-380.7670590,2503.4602050,150.9521180,-37.8152145,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(1655,-372.4146120,2503.4453130,150.2213590,-18.0481705,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(1655,-364.3675840,2503.4621580,152.1894990,0.0000000,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(1655,-357.3008120,2503.4685060,156.2445680,14.6104238,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(1655,-351.6267700,2503.4724120,162.2986600,33.5180310,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(16430,-229.2491460,2503.4929200,190.1252140,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(16430,-69.7916410,2503.5102540,190.1116940,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1655,9.8994980,2503.5947270,191.5056150,0.0000000,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(17310,-175.7224270,2492.9833980,61.7825780,0.0000000,-180.4817055,-359.8453411, 1); //
    CreateDynamicObject(17310,-154.1479950,2493.1086430,70.6184620,0.0000000,-224.3132633,-359.8453411, 1); //
    CreateDynamicObject(1655,-80.6412510,2515.7050780,16.9474740,-37.8152145,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(1655,-72.4095690,2515.7172850,16.1448780,-18.9076072,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(1655,-64.3528370,2515.7358400,18.0974330,0.0000000,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(1655,-57.3253330,2515.7414550,22.4667930,18.0481705,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(1655,-51.7736090,2515.7380370,28.8605350,34.3774104,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(1655,-281.7252200,2515.6901860,106.7342220,-37.8152145,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(1655,-274.6364440,2515.6931150,105.9457630,-20.6264806,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(1655,-266.9908140,2515.6958010,107.5043870,-2.5783101,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(16430,-26.3452570,2471.1767580,19.2521130,0.0000000,14.6104238,27.6566155, 1); //
    CreateDynamicObject(16430,-136.0616000,2413.6442870,67.5047680,0.0000000,25.7831008,27.6566155, 1); //
    CreateDynamicObject(1655,213.1553960,2474.8491210,16.5344910,0.0000000,0.0000000,-236.2499795, 1); //
    CreateDynamicObject(1655,207.5002290,2471.0729980,20.7962530,18.0481705,0.0000000,-236.2499795, 1); //
    CreateDynamicObject(1655,202.8901210,2467.9960940,27.1480330,34.3774677,0.0000000,-236.2499795, 1); //
    CreateDynamicObject(1655,200.2018280,2466.1936040,34.5180740,52.4255810,0.0000000,-236.2499795, 1); //
    CreateDynamicObject(1655,199.4424290,2465.6933590,42.7186620,69.6143148,0.0000000,-236.2499795, 1); //
    CreateDynamicObject(1655,174.3156130,2476.0002440,16.5344910,0.0000000,0.0000000,-134.9999719, 1); //
    CreateDynamicObject(1655,179.2740330,2471.0302730,20.8959060,18.0481705,0.0000000,-134.9999719, 1); //
    CreateDynamicObject(1655,183.0962220,2467.2182620,27.0901450,34.3774677,0.0000000,-134.9999719, 1); //
    CreateDynamicObject(1655,185.5057530,2464.8125000,34.7796820,52.4255810,0.0000000,-134.9999719, 1); //
    CreateDynamicObject(1655,186.1116180,2464.1921390,42.9389500,69.6143148,0.0000000,-134.9999719, 1); //
    CreateDynamicObject(17310,106.4261470,2538.4155270,19.9732360,0.0000000,-213.1402998,53.8263482, 1); //
    CreateDynamicObject(8171,-71.0868230,2580.4172360,43.3652730,24.0642274,0.0000000,-326.2500181, 1); //
    CreateDynamicObject(8171,-140.8212280,2684.7583010,99.4112170,24.0642274,0.0000000,-326.2500181, 1); //
    CreateDynamicObject(8040,-197.8078610,2770.6157230,128.3689270,0.0000000,0.0000000,-56.2500169, 1); //
    CreateDynamicObject(1655,-127.1723180,2636.2985840,77.9131240,-37.8152145,0.0000000,-146.2499982, 1); //
    CreateDynamicObject(1655,-122.5613780,2629.4235840,77.0518800,-19.7670439,0.0000000,-146.2499982, 1); //
    CreateDynamicObject(1655,-117.8541030,2622.3618160,78.9511800,-0.8594367,0.0000000,-146.2499982, 1); //
    CreateDynamicObject(1655,-27.1858810,2543.0349120,18.4467450,-37.8152145,0.0000000,-146.2499982, 1); //
    CreateDynamicObject(1655,-22.4486750,2535.9621580,17.7841840,-17.1887339,0.0000000,-146.2499982, 1); //
    CreateDynamicObject(1655,-17.8318820,2529.0524900,19.8868850,0.0000000,0.0000000,-146.2499982, 1); //
    CreateDynamicObject(1655,-13.7059730,2522.8640140,24.3332840,16.3292972,0.0000000,-146.2499982, 1); //
    CreateDynamicObject(1655,-10.5855690,2518.1811520,30.7624610,35.2368471,0.0000000,-146.2499982, 1); //
    CreateDynamicObject(17310,32.8495560,2465.5383300,19.8672870,0.0000000,-213.1402998,-58.6736284, 1); //
    CreateDynamicObject(17310,55.1857300,2465.3203130,19.8809870,0.0000000,-213.1402998,-125.3141777, 1); //
    CreateDynamicObject(5767,-110.4486080,2393.7490230,64.5049740,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(18450,-144.7523190,2286.4448240,109.8927000,0.0000000,12.0321137,-191.2499889, 1); //
    CreateDynamicObject(18450,-206.6770630,2298.7575680,98.7357790,0.0000000,6.8754935,-191.2499889, 1); //
    CreateDynamicObject(18450,-23.7693410,2252.5720210,120.0180740,0.0000000,2.5783101,-191.2499889, 1); //
    CreateDynamicObject(16430,117.4151920,2312.6123050,98.5842130,0.0000000,16.3292972,44.9999906, 1); //
    CreateDynamicObject(1655,172.2501070,2367.7216800,77.3358460,-15.4698605,0.0000000,-44.9999906, 1); //
    CreateDynamicObject(1655,177.5025330,2372.9809570,79.4146800,0.8594367,0.0000000,-44.9999906, 1); //
    CreateDynamicObject(1655,23.9914020,2529.6757810,16.5344910,0.0000000,0.0000000,-56.2499596, 1); //
    CreateDynamicObject(1655,29.2197530,2533.1650390,20.4388240,17.1887339,0.0000000,-56.2499596, 1); //
    CreateDynamicObject(1655,33.2522090,2535.8581540,25.9520490,34.3774677,0.0000000,-56.2499596, 1); //
    CreateDynamicObject(13666,216.3768920,2436.2385250,32.5436900,0.0000000,0.0000000,134.9999719, 1); //
    CreateDynamicObject(1655,-100.3003920,2503.4638670,25.7003000,-37.8152145,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(1655,-56.1267930,2503.0720210,16.5344910,0.0000000,0.0000000,-269.9999438, 1); //
    CreateDynamicObject(1655,-75.3997650,2477.0112300,16.4844910,0.0000000,0.0000000,-239.7650756, 1); //
    CreateDynamicObject(1655,-81.4844280,2473.4694820,20.6282750,15.4698605,0.0000000,-239.7650756, 1); //
    CreateDynamicObject(1655,-86.5564420,2470.5227050,26.5975480,30.0802842,0.0000000,-239.7650756, 1); //
    CreateDynamicObject(1655,-90.0956120,2468.4699710,33.8959660,45.5500874,0.0000000,-239.7650756, 1); //
    CreateDynamicObject(1655,-91.7855450,2467.4863280,41.9910390,61.8793846,0.0000000,-239.7650756, 1); //
    CreateDynamicObject(1655,-91.3745350,2467.7263180,50.3834270,79.0681184,0.0000000,-239.7650756, 1); //
    CreateDynamicObject(8620,-70.0046080,2480.3210450,38.5500950,0.0000000,0.0000000,-56.2500169, 1); //
    CreateDynamicObject(16120,5.9930610,2556.3339840,12.6391490,0.0000000,0.0000000,-123.7499456, 1); //
    CreateDynamicObject(13641,12.7757150,2499.3876950,17.0786130,0.0000000,0.0000000,-539.9999450, 1); //
    CreateDynamicObject(13641,-12.4602050,2497.9887700,17.1806740,0.0000000,0.0000000,-719.9997929, 1); //
    CreateDynamicObject(1655,-63.4237940,2503.0722660,20.8252640,15.4698605,0.0000000,-269.9999438, 1); //
    CreateDynamicObject(1655,-69.0486450,2503.0664060,27.1279580,35.2369044,0.0000000,-269.9999438, 1); //
    CreateDynamicObject(1655,-92.1025770,2503.4431150,25.0811730,-17.1887339,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(1655,-84.0563660,2503.4460450,27.3012500,2.5783101,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(1655,-79.7226100,2503.4379880,29.8617860,14.6104238,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(726,336.1349180,2558.7897950,15.0647130,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(726,391.1689760,2562.5808110,14.7647090,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3851,113.9138720,2517.3564450,17.6401330,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3851,86.5519260,2516.9602050,17.5019110,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3851,64.9603810,2516.3513180,17.4843750,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3851,29.6247650,2516.4130860,17.4843750,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3851,45.7196160,2516.5468750,17.4921800,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3851,138.2801970,2517.2556150,17.6093250,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3851,221.4475710,2393.6950680,29.7134060,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3851,181.8953550,2394.3032230,29.7134060,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3851,199.7305150,2394.0275880,29.7134060,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3851,165.0695190,2394.3837890,29.6604580,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3851,146.4866180,2394.3852540,29.6604580,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3851,125.1733400,2394.2602540,29.6853620,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2918,395.4209290,2534.4360350,18.1840710,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2918,399.3528750,2529.4606930,17.9504390,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2918,299.4443970,2477.9423830,17.2235090,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2918,353.4714360,2458.4216310,23.0429970,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2918,356.4463500,2477.6765140,17.9281120,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2918,155.5728910,2479.3286130,17.0056800,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2918,146.2091670,2474.3820800,17.3689630,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2918,221.4469600,2438.4748540,29.5495890,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2918,91.3343660,2530.6831050,18.4344200,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2918,-69.9974060,2486.4685060,17.4907210,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2918,-64.1392140,2477.6315920,17.4750820,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2918,47.4210550,2530.7617190,17.7138330,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2918,63.4850960,2382.5009770,29.4209670,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2918,63.5883710,2429.5715330,29.2316890,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2918,314.0655820,2533.1088870,17.1226390,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,233.8083650,2519.5637210,27.6592250,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,233.8609920,2516.8842770,27.9660470,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,233.7750240,2523.9038090,27.9597030,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,233.7796940,2521.7529300,27.7967300,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,263.5283510,2489.9414060,21.2713830,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,263.2910460,2484.7392580,26.9259110,0.0000000,90.2409100,-85.6254485, 1); //
    CreateDynamicObject(1225,263.7232970,2495.6062010,26.6988740,0.0000000,90.2409100,-85.6254485, 1); //
    CreateDynamicObject(2918,378.3983150,2479.7761230,17.7519630,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(16133,347.8987430,2348.7033690,9.6372720,0.0000000,0.0000000,-14.5330745, 1); //
    CreateDynamicObject(1655,376.7511900,2358.7355960,25.1146050,0.0000000,0.0000000,-271.7188745, 1); //
    CreateDynamicObject(13831,362.6183470,2558.7375490,41.1767960,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2714,404.8209840,2476.8100590,23.6986680,0.0000000,0.0000000,-180.0000198, 1); //
    CreateDynamicObject(10281,404.5187990,2476.9230960,26.1513060,0.0000000,0.0000000,-180.0000198, 1); //
    CreateDynamicObject(1828,400.4436340,2551.2070310,19.5092330,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1383,191.5562900,2550.6914060,47.9858780,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1384,191.4141540,2550.7653810,80.1134030,0.0000000,0.0000000,-213.7499842, 1); //
    CreateDynamicObject(1383,128.9138790,2433.5378420,56.1156620,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1384,128.9050450,2433.5078130,88.6419750,0.0000000,0.0000000,-326.2500181, 1); //
    CreateDynamicObject(3361,385.7073360,2551.2319340,17.7883990,0.0000000,4.2971835,-180.0000198, 1); //
    CreateDynamicObject(17310,216.9962920,2307.6037600,32.8070720,0.0000000,-215.7186099,-92.4236500, 1); //
    CreateDynamicObject(2918,268.4962460,2436.7451170,29.4048860,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3528,404.1803280,2473.9399410,25.7803210,0.0000000,0.0000000,-94.5379789, 1); //
    CreateDynamicObject(978,375.0564880,2476.5119630,16.3245940,0.0000000,0.0000000,-6.0160568, 1); //
    CreateDynamicObject(13593,403.1907350,2531.4477540,19.9043790,0.0000000,0.0000000,-182.2005216, 1); //
    CreateDynamicObject(2745,404.7575070,2536.9201660,20.7451320,0.0000000,0.0000000,-92.8963975, 1); //
    CreateDynamicObject(8644,404.1031190,2433.8044430,23.2742420,0.0000000,0.0000000,-63.5982580, 1); //
    CreateDynamicObject(3505,378.1003420,2478.8725590,15.2538510,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2404,399.4530640,2553.9243160,20.9833970,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6869,230.7251740,2590.8352050,14.3287140,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1238,405.3430790,2536.8881840,20.9361230,0.0000000,-54.1444543,0.8594367, 1); //
    CreateDynamicObject(2738,394.1399230,2551.1452640,31.8577900,0.0000000,0.0000000,-91.9596688, 1); //
    CreateDynamicObject(10757,403.8189390,2472.6069340,31.0670470,0.0000000,0.0000000,-179.6224980, 1); //
    CreateDynamicObject(3528,390.7669980,2551.5966800,28.3915080,0.0000000,0.0000000,-185.6387840, 1); //
    CreateDynamicObject(3505,261.3819580,2472.2880860,15.0119680,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1655,239.0472720,2434.8872070,28.7105730,0.0000000,0.0000000,-44.9999906, 1); //
    CreateDynamicObject(1383,268.2009280,2305.2385250,60.1407130,0.0000000,0.0000000,33.7500216, 1); //
    CreateDynamicObject(1384,268.1823430,2305.2658690,92.1666340,0.0000000,0.0000000,-303.7500228, 1); //
    CreateDynamicObject(17310,-55.5870290,2421.0368650,32.7538800,0.0000000,-215.7186099,-146.0952996, 1); //
    CreateDynamicObject(1655,334.6689760,2483.1135250,16.4844910,0.0000000,0.0000000,236.2499795, 1); //
    CreateDynamicObject(1655,340.6565860,2479.1184080,20.9321350,18.0481705,0.0000000,236.2499795, 1); //
    CreateDynamicObject(1655,345.4206240,2475.9411620,27.1850240,31.7991576,0.0000000,236.2499795, 1); //
    CreateDynamicObject(1655,348.5699770,2473.8413090,34.9520570,50.7067076,0.0000000,236.2499795, 1); //
    CreateDynamicObject(13641,348.9084470,2473.6752930,43.1837920,0.0000000,-67.8954414,-394.6094407, 1); //
    CreateDynamicObject(2918,277.4049680,2532.0817870,17.0336740,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3505,324.9969180,2472.0129390,15.2038540,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1655,412.3895870,2520.5537110,17.6748030,2.5783101,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(1655,419.5342710,2520.5625000,22.3157290,18.0481705,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(1655,425.1636350,2520.5737300,28.8862780,35.2369044,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(1655,428.5551150,2520.5683590,36.7720830,52.4255810,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(1655,429.5889890,2520.5788570,44.9772220,67.8954414,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(1655,428.1704410,2520.5732420,53.6445730,85.0841753,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(1655,404.5809940,2520.5380860,15.2257860,-12.8915504,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(1655,365.2205510,2476.3017580,16.0844940,-3.4377468,0.8594367,179.9999626, 1); //
    CreateDynamicObject(17310,141.9268800,2426.5571290,32.8819620,0.0000000,-215.7186099,-238.6737056, 1); //
    CreateDynamicObject(17310,116.4924320,2425.3564450,32.8819470,0.0000000,-215.7186099,-295.7831592, 1); //
    CreateDynamicObject(13666,151.3271480,2476.8742680,20.2600250,-1.7188734,0.8594367,-38.9065845, 1); //
    CreateDynamicObject(2918,269.9707030,2311.1186520,29.5495930,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(978,240.1972660,2532.3303220,16.5508880,0.0000000,0.0000000,-179.9999626, 1); //
    CreateDynamicObject(14780,380.4954530,2472.5224610,25.0063740,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(16708,-93.4037170,2549.3293460,16.3933810,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(14416,392.9118040,2551.1794430,18.2068600,-20.6264806,0.0000000,89.3813587, 1); //
    CreateDynamicObject(6189,-141.7397310,2503.5283200,28.4888570,-24.0642274,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(6189,-260.7621460,2503.5305180,81.6356350,-24.0642274,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(6189,-380.0004880,2503.5319820,134.8888700,-24.0642274,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(6189,-499.3376770,2503.5346680,188.1720430,-24.0642274,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(2405,369.5523070,2558.0483400,22.3107850,0.0000000,-179.6223834,0.8594367, 1); //
    CreateDynamicObject(2405,368.4849240,2558.0659180,21.1202070,0.0000000,-91.1001175,0.8594367, 1); //
    CreateDynamicObject(2405,367.4859010,2558.0964360,19.9853000,0.0000000,180.4821065,0.8594367, 1); //
    CreateDynamicObject(2405,368.6196900,2558.0949710,18.8914430,0.0000000,-269.8631788,0.8594367, 1); //
    CreateDynamicObject(8881,457.8103330,2443.7304690,48.4056240,0.0000000,0.0000000,120.1576148, 1); //
    CreateDynamicObject(656,391.8336790,2529.7929690,15.5936430,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3472,392.0719300,2529.4558110,18.2290080,0.0000000,0.0000000,22.4999953, 1); //
    CreateDynamicObject(3472,392.0282290,2529.5156250,15.7926500,0.0000000,0.0000000,-44.9999906, 1); //
    CreateDynamicObject(3472,392.0544740,2529.4760740,20.1702120,0.0000000,0.0000000,-168.7499935, 1); //
    CreateDynamicObject(3472,392.0780030,2529.6005860,22.9322380,0.0000000,0.0000000,-292.5000537, 1); //
    CreateDynamicObject(3472,392.0972290,2529.4301760,26.0104500,0.0000000,0.0000000,-360.0000397, 1); //
    CreateDynamicObject(7666,392.1219180,2529.2790530,41.4999200,0.0000000,0.0000000,33.7500216, 1); //
    CreateDynamicObject(2479,392.1919250,2530.8786620,15.6704290,0.0000000,0.0000000,-146.2499982, 1); //
    CreateDynamicObject(2478,390.3710330,2530.0891110,15.7947660,0.0000000,0.0000000,-67.4999860, 1); //
    CreateDynamicObject(2480,391.2162480,2531.6582030,15.6588520,-91.9596688,0.8594367,-157.4999672, 1); //
    CreateDynamicObject(3525,389.9585880,2528.9641110,15.0268120,0.0000000,0.0000000,-134.9999719, 1); //
    CreateDynamicObject(3525,394.2493290,2529.0874020,15.0213490,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3525,392.1354060,2527.2111820,15.0058400,0.0000000,0.0000000,0.0000000, 1); //
    print("[Gamemode::Objects]: AAirport objects has been loaded.");


    CreateDynamicObject(1634,1985.1811520,-2565.4699710,13.5942040,0.0000000,0.0000000,89.9994000, 1); //
    CreateDynamicObject(1634,1979.9971920,-2565.5102540,18.3355010,32.6578000,357.4217000,89.9994000, 1); //
    CreateDynamicObject(18450,2019.6551510,-2544.9677730,45.2988010,2.5775000,0.0000000,334.9216000, 1); //
    CreateDynamicObject(18450,2024.0716550,-2535.9428710,48.0620000,28.3606000,0.0000000,334.9216000, 1); //
    CreateDynamicObject(18450,2015.0688480,-2554.5234380,48.0303990,30.9389000,0.0000000,154.9212000, 1); //
    CreateDynamicObject(1632,2054.3327640,-2558.1296390,46.6931000,0.0000000,0.0000000,247.4997000, 1); //
    CreateDynamicObject(1632,2052.7910160,-2561.9951170,46.7309990,0.0000000,0.0000000,247.4997000, 1); //
    CreateDynamicObject(1632,2051.2265630,-2565.8310550,46.7369000,0.0000000,0.0000000,247.4997000, 1); //
    CreateDynamicObject(1632,2056.6979980,-2563.5898440,50.6856990,29.2200000,0.0000000,247.4997000, 1); //
    CreateDynamicObject(1632,2055.1120610,-2567.4111330,50.6940960,29.2200000,0.0000000,247.4997000, 1); //
    CreateDynamicObject(1632,2058.2663570,-2559.7587890,50.6850970,29.2200000,0.0000000,247.4997000, 1); //
    CreateDynamicObject(1634,1937.5327150,-2507.6572270,13.8364000,0.0000000,0.0000000,348.7528000, 1); //
    CreateDynamicObject(1634,1937.6657710,-2507.0087890,15.5364000,22.3445000,0.0000000,348.7528000, 1); //
    CreateDynamicObject(1634,1938.0432130,-2505.1457520,18.0995010,35.2361000,0.0000000,348.7528000, 1); //
    CreateDynamicObject(13641,1861.5067140,-2616.0300290,14.2661000,0.0000000,0.0000000,213.7525000, 1); //
    CreateDynamicObject(3851,1853.2360840,-2622.2946780,21.7807040,0.8586000,359.1406000,216.3308000, 1); //
    CreateDynamicObject(3851,1853.2552490,-2622.2316890,25.6310010,0.8586000,359.1406000,216.3308000, 1); //
    CreateDynamicObject(13604,1789.5657960,-2539.4831540,14.0048960,0.0000000,0.0000000,355.7028000, 1); //
    CreateDynamicObject(16139,1768.4893800,-2617.4511720,10.6801200,0.0000000,7.7341000,343.5962000, 1); //
    CreateDynamicObject(16139,1755.8658450,-2592.6840820,11.0799450,0.0000000,9.4530000,165.3892000, 1); //
    CreateDynamicObject(18450,1756.7618410,-2604.4062500,18.6085000,0.0000000,9.4530000,0.0000000, 1); //
    CreateDynamicObject(619,1795.4448240,-2611.4267580,12.8699000,0.0000000,0.0000000,292.4998000, 1); //
    CreateDynamicObject(619,1796.3463130,-2596.5539550,12.9287000,0.0000000,0.0000000,11.2520000, 1); //
    CreateDynamicObject(3461,1794.4481200,-2597.8884280,14.4615000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3461,1794.4025880,-2610.5681150,14.4691000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(16776,1707.5902100,-2526.6342770,12.2977300,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1633,1692.6975100,-2529.1269530,13.8472000,0.0000000,0.0000000,269.9998000, 1); //
    CreateDynamicObject(1633,1695.3256840,-2529.1389160,16.1205010,24.0634000,0.0000000,269.9998000, 1); //
    CreateDynamicObject(7392,1739.3486330,-2523.8239750,20.7169990,0.0000000,0.0000000,169.9954000, 1); //
    CreateDynamicObject(7392,1740.0480960,-2561.4313960,20.9920010,0.0000000,0.0000000,1.9532000, 1); //
    CreateDynamicObject(1211,1749.1958010,-2556.4604490,13.1577000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(18450,1743.9694820,-2604.4106450,26.1839180,0.0000000,17.1878000,0.0000000, 1); //
    CreateDynamicObject(1634,1979.5949710,-2565.5915530,25.2080460,81.6455000,0.0000000,89.9994000, 1); //
    CreateDynamicObject(17310,1409.1507570,-2457.2832030,17.6262970,0.0000000,220.7711000,339.3736000, 1); //
    CreateDynamicObject(1655,1551.9127200,-2604.4738770,13.5219920,0.0000000,0.0000000,90.0000000, 1); //
    CreateDynamicObject(1655,1545.5032960,-2604.4636230,17.5555110,18.9076000,0.0000000,90.0000000, 1); //
    CreateDynamicObject(1655,1540.5533450,-2604.4875490,23.2805120,34.3775000,0.0000000,90.0000000, 1); //
    CreateDynamicObject(1655,1537.6586910,-2604.4841310,30.7527730,57.5822000,0.0000000,90.0000000, 1); //
    CreateDynamicObject(1655,1764.5670170,-2458.4633790,13.5548040,0.0000000,0.0000000,45.0000000, 1); //
    CreateDynamicObject(1655,1760.1444090,-2454.0529790,17.1424180,14.6104000,0.0000000,45.0000000, 1); //
    CreateDynamicObject(13590,2029.5268550,-2617.9958500,13.5977230,0.0000000,0.0000000,90.0000000, 1); //
    CreateDynamicObject(3374,2037.1219480,-2571.3479000,14.0408520,0.0000000,0.0000000,326.2500000, 1); //
    CreateDynamicObject(3374,2037.1079100,-2571.3562010,16.9042740,0.0000000,0.0000000,326.2500000, 1); //
    CreateDynamicObject(3374,2037.0982670,-2571.3715820,19.7963030,0.0000000,0.0000000,326.2500000, 1); //
    CreateDynamicObject(3374,2037.0599370,-2571.3532710,22.7213040,0.0000000,0.0000000,326.2500000, 1); //
    CreateDynamicObject(3374,2039.1606450,-2568.1630860,14.0028750,0.0000000,0.0000000,326.2500000, 1); //
    CreateDynamicObject(3374,2047.7211910,-2557.6291500,13.9408530,0.0000000,0.0000000,326.2500000, 1); //
    CreateDynamicObject(3374,2045.5961910,-2560.7458500,13.9605500,0.0000000,0.0000000,326.2500000, 1); //
    CreateDynamicObject(3374,2047.7894290,-2557.6787110,16.8855360,0.0000000,0.0000000,326.2500000, 1); //
    CreateDynamicObject(3374,2045.7915040,-2560.5852050,19.8307800,0.0000000,0.0000000,326.2500000, 1); //
    CreateDynamicObject(3374,2047.7246090,-2557.6699220,19.8178310,0.0000000,0.0000000,326.2500000, 1); //
    CreateDynamicObject(3374,2045.7678220,-2560.5751950,22.5557840,0.0000000,0.0000000,326.2500000, 1); //
    CreateDynamicObject(3374,2045.6781010,-2560.5107420,25.3993340,0.0000000,0.0000000,326.2500000, 1); //
    CreateDynamicObject(3374,2047.4697270,-2557.4282230,25.3906750,0.0000000,0.0000000,326.2500000, 1); //
    CreateDynamicObject(3374,2036.9368900,-2571.2753910,25.4811670,0.0000000,0.0000000,326.2500000, 1); //
    CreateDynamicObject(3374,2061.0212400,-2552.3889160,14.0408520,0.0000000,0.0000000,309.0613000, 1); //
    CreateDynamicObject(3374,2061.9965820,-2551.4982910,16.7158340,0.0000000,0.0000000,309.0613000, 1); //
    CreateDynamicObject(3374,2062.7436520,-2550.7719730,19.0408520,0.0000000,0.0000000,309.0613000, 1); //
    CreateDynamicObject(3374,2063.5073240,-2550.1140140,21.4239140,0.0000000,0.0000000,309.0613000, 1); //
    CreateDynamicObject(3374,2064.1662600,-2549.5422360,24.1225150,0.0000000,0.0000000,309.0613000, 1); //
    CreateDynamicObject(3374,2067.2243650,-2547.0607910,24.1365550,0.0000000,0.0000000,309.0613000, 1); //
    CreateDynamicObject(3374,2068.0168460,-2546.3708500,21.4301830,0.0000000,0.0000000,309.0613000, 1); //
    CreateDynamicObject(3374,2068.7509770,-2545.7788090,18.9627060,0.0000000,0.0000000,309.0613000, 1); //
    CreateDynamicObject(3374,2069.4184570,-2545.2155760,15.9930190,0.0000000,0.0000000,309.0613000, 1); //
    CreateDynamicObject(3374,2070.3886720,-2544.4487300,13.5408590,0.0000000,0.0000000,309.0613000, 1); //
    CreateDynamicObject(3374,2065.6782230,-2548.2763670,19.0226550,0.0000000,0.0000000,309.0613000, 1); //
    CreateDynamicObject(3374,2081.0222170,-2541.9353030,13.9158540,0.0000000,0.0000000,299.6075000, 1); //
    CreateDynamicObject(3374,2080.9965820,-2541.9033200,16.6158580,0.0000000,0.0000000,299.6075000, 1); //
    CreateDynamicObject(3374,2081.0231930,-2541.8791500,19.2692390,0.0000000,0.0000000,299.6075000, 1); //
    CreateDynamicObject(3374,2081.0244140,-2541.8027340,22.2434230,0.0000000,0.0000000,299.6075000, 1); //
    CreateDynamicObject(3374,2080.9765630,-2541.7414550,24.2720450,0.0000000,0.0000000,299.6075000, 1); //
    CreateDynamicObject(3374,2092.4160160,-2540.9663090,14.0408520,0.0000000,0.0000000,285.8565000, 1); //
    CreateDynamicObject(3374,2092.3737790,-2540.8103030,16.8158550,0.0000000,0.0000000,285.8565000, 1); //
    CreateDynamicObject(3374,2092.3762210,-2540.7897950,19.6563930,0.0000000,0.0000000,285.8565000, 1); //
    CreateDynamicObject(3374,2092.3737790,-2540.7678220,22.1909480,0.0000000,0.0000000,285.8565000, 1); //
    CreateDynamicObject(3374,2092.3459470,-2540.7927250,24.2658880,0.0000000,0.0000000,285.8565000, 1); //
    CreateDynamicObject(3374,2095.4855960,-2539.7971190,24.2421630,0.0000000,0.0000000,285.8565000, 1); //
    CreateDynamicObject(3374,2097.9655760,-2539.1005860,24.2444920,0.0000000,0.0000000,285.8565000, 1); //
    CreateDynamicObject(3374,2097.9475100,-2539.0295410,21.7528840,0.0000000,0.0000000,285.8565000, 1); //
    CreateDynamicObject(3374,2095.6418460,-2539.8227540,18.3730660,39.5341000,0.0000000,285.8565000, 1); //
    CreateDynamicObject(3374,2097.4580080,-2539.1489260,20.1234840,39.5341000,0.0000000,285.8565000, 1); //
    CreateDynamicObject(3374,2095.6433110,-2539.8845210,15.3908500,153.8392000,0.8594000,285.8565000, 1); //
    CreateDynamicObject(3374,2098.6652830,-2538.8530270,13.8459530,153.8392000,0.8594000,285.8565000, 1); //
    CreateDynamicObject(7980,1922.0645750,-2616.4204100,14.5338430,0.0000000,0.0000000,359.1406000, 1); //
    CreateDynamicObject(1378,2132.2285160,-2538.5625000,34.5593800,0.0000000,0.0000000,91.9597000, 1); //
    CreateDynamicObject(1632,1522.1613770,-2622.2475590,14.4719950,10.3125000,0.0000000,179.5183000, 1); //
    CreateDynamicObject(3287,2044.6914060,-2596.2419430,17.2359010,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3287,2053.2407230,-2596.2971190,17.0911010,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6928,1976.2774660,-2644.8337400,14.4132000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(13593,2061.3398440,-2597.9016110,13.4081000,10.3124000,0.0000000,89.2774000, 1); //
    CreateDynamicObject(13592,1409.4921880,-2593.0117190,21.6425000,274.0563000,0.0000000,354.8434000, 1); //
    CreateDynamicObject(13592,1408.3780520,-2593.4357910,28.7675000,274.0563000,0.0000000,354.8434000, 1); //
    CreateDynamicObject(13592,1407.3537600,-2593.8059080,35.3424990,274.0563000,0.0000000,354.8434000, 1); //
    CreateDynamicObject(13592,1406.2087400,-2594.2055660,42.5964010,274.0563000,0.0000000,354.8434000, 1); //
    CreateDynamicObject(13592,1405.1011960,-2594.6135250,49.8590010,274.0563000,0.0000000,354.8434000, 1); //
    CreateDynamicObject(13592,1403.9801030,-2595.0312500,57.1115000,274.0563000,0.0000000,354.8434000, 1); //
    CreateDynamicObject(1655,1394.8033450,-2603.2500000,66.8318020,358.2811000,85.9428000,84.2240000, 1); //
    CreateDynamicObject(1632,1415.9493410,-2601.7277830,14.1970000,10.3124000,29.2200000,127.1958000, 1); //
    CreateDynamicObject(18450,1827.5482180,-2381.7697750,24.2227990,0.8586000,18.0473000,290.3856000, 1); //
    CreateDynamicObject(18450,1801.2487790,-2312.2050780,48.4443020,0.8586000,18.0473000,290.3856000, 1); //
    CreateDynamicObject(8420,1754.5964360,-2267.7272950,61.2593990,0.0000000,0.0000000,110.0071000, 1); //
    CreateDynamicObject(1655,1752.6357420,-2308.7370610,63.1153980,11.1718000,0.0000000,171.7834000, 1); //
    CreateDynamicObject(3749,1786.8469240,-2274.8413090,66.7193980,0.0000000,0.0000000,19.7662000, 1); //
    CreateDynamicObject(17565,1653.4580080,-2595.7978520,14.6556060,0.0000000,0.0000000,269.7591000, 1); //
    CreateDynamicObject(13640,1765.0620120,-2235.1027830,61.9311980,0.0000000,0.0000000,21.4851000, 1); //
    CreateDynamicObject(13640,1744.0218510,-2243.5769040,62.2312010,0.0000000,0.0000000,21.4851000, 1); //
    CreateDynamicObject(8420,1698.6826170,-2288.0734860,61.0652010,0.0000000,0.0000000,289.5262000, 1); //
    CreateDynamicObject(13647,1698.9702150,-2285.4362790,61.0378000,0.0000000,0.0000000,20.6256000, 1); //
    CreateDynamicObject(13648,1735.0952150,-2272.0551760,61.0318980,0.0000000,0.0000000,110.0071000, 1); //
    CreateDynamicObject(16304,1661.4892580,-2274.0463870,66.0802000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(13638,1711.5341800,-2316.4523930,63.5642010,0.0000000,0.0000000,109.1476000, 1); //
    CreateDynamicObject(13636,1706.5357670,-2254.1159670,63.3222010,0.0000000,0.0000000,19.0099000, 1); //
    CreateDynamicObject(11395,1379.2742920,-2561.0214840,69.8164980,0.0000000,0.0000000,356.5623000, 1); //
    CreateDynamicObject(13592,1819.9014890,-2568.9086910,22.0925010,359.9992000,1.7180000,99.6938000, 1); //
    CreateDynamicObject(13592,1813.1264650,-2569.1350100,22.0674990,359.9992000,1.7180000,99.6938000, 1); //
    CreateDynamicObject(13592,1806.3298340,-2569.2683110,22.0175000,359.9992000,1.7180000,99.6938000, 1); //
    CreateDynamicObject(13592,1799.5603030,-2569.4287110,22.0175000,359.9992000,1.7180000,99.6938000, 1); //
    CreateDynamicObject(1655,1795.9042970,-2565.6586910,14.3720000,10.3124000,0.0000000,3.4369000, 1); //
    CreateDynamicObject(1634,1402.6846920,-2660.9553220,13.5250000,0.0000000,0.0000000,340.2330000, 1); //
    CreateDynamicObject(1634,1347.7879640,-2551.6384280,13.4223000,0.0000000,0.0000000,271.4780000, 1); //
    CreateDynamicObject(8391,1395.7747800,-2431.3249510,28.9601000,0.0000000,0.0000000,270.6186000, 1); //
    CreateDynamicObject(1655,1385.6042480,-2422.6875000,14.2548010,8.5935000,0.0000000,86.8023000, 1); //
    CreateDynamicObject(1655,1365.3494870,-2453.8583980,48.6521000,13.7501000,0.0000000,184.7780000, 1); //
    CreateDynamicObject(1655,1427.3532710,-2408.7548830,48.6020930,13.7501000,0.8594000,272.4406000, 1); //
    CreateDynamicObject(10948,1905.3707280,-2250.6579590,62.3933980,0.0000000,0.0000000,89.2774000, 1); //
    CreateDynamicObject(5001,1947.1947020,-2290.4809570,32.9187010,80.7862000,312.7310000,133.2118000, 1); //
    CreateDynamicObject(1633,1951.4947510,-2272.3796390,13.0586000,354.8434000,358.2811000,357.4217000, 1); //
    CreateDynamicObject(1632,1890.5047610,-2273.5844730,59.1997990,16.3285000,0.0000000,87.6617000, 1); //
    CreateDynamicObject(1632,1886.0028080,-2273.4018550,65.1167980,42.1116000,0.0000000,87.6617000, 1); //
    CreateDynamicObject(1632,1884.5913090,-2273.3603520,71.9893040,67.8947000,0.0000000,87.6617000, 1); //
    CreateDynamicObject(1632,1885.8024900,-2273.2524410,79.7828980,85.9428000,0.0000000,94.5372000, 1); //
    CreateDynamicObject(1632,1911.1649170,-2211.9255370,83.1747970,16.3285000,0.0000000,1.7180000, 1); //
    CreateDynamicObject(1632,1911.1114500,-2207.3425290,89.1723020,42.1116000,0.0000000,1.7180000, 1); //
    CreateDynamicObject(1632,1911.1430660,-2205.3061520,96.6624980,61.8786000,0.0000000,358.2811000, 1); //
    CreateDynamicObject(1655,1847.4841310,-2245.5437010,105.7248000,0.0000000,0.0000000,104.7473000, 1); //
    CreateDynamicObject(13638,1704.0998540,-2331.6972660,71.6819990,0.0000000,0.0000000,109.1476000, 1); //
    CreateDynamicObject(13592,1402.8209230,-2595.4497070,64.3668980,274.0563000,0.0000000,354.8434000, 1); //
    CreateDynamicObject(4113,1378.9577640,-2579.2812500,26.2754780,0.0000000,0.0000000,278.3535000, 1); //
    CreateDynamicObject(1684,1886.1833500,-2195.4611820,103.2395020,0.0000000,0.0000000,269.7591000, 1); //
    CreateDynamicObject(1684,1886.1469730,-2205.5058590,103.2395020,0.0000000,0.0000000,269.7591000, 1); //
    CreateDynamicObject(1684,1886.1008300,-2215.5512700,103.2453000,0.0000000,0.0000000,269.7591000, 1); //
    CreateDynamicObject(13638,1688.6693120,-2333.5048830,79.7685010,0.0000000,0.0000000,18.9068000, 1); //
    CreateDynamicObject(7073,1977.4674070,-2628.2858890,49.4401250,0.0000000,6.0161000,88.5211000, 1); //
    CreateDynamicObject(13722,2045.7214360,-2638.5004880,21.9834000,0.0000000,0.0000000,180.3777000, 1); //
    CreateDynamicObject(13831,2045.7052000,-2638.5134280,21.9632000,0.0000000,0.0000000,180.3777000, 1); //
    CreateDynamicObject(1267,2139.7282710,-2489.1035160,28.6116010,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(6066,2111.7189940,-2493.4143070,14.4973090,0.0000000,0.0000000,184.7780000, 1); //
    CreateDynamicObject(1655,2105.7897950,-2493.8894040,13.6892000,2.5775000,0.0000000,274.9158000, 1); //
    CreateDynamicObject(9237,2095.3100590,-2638.3825680,20.5323010,0.0000000,0.0000000,282.6507000, 1); //
    CreateDynamicObject(1632,1392.4246830,-2560.3420410,63.1708950,4.2963000,0.0000000,325.6225000, 1); //
    CreateDynamicObject(11111,1439.0646970,-2496.9870610,2.4297010,329.0603000,0.0000000,269.7591000, 1); //
    CreateDynamicObject(1378,2036.9343260,-2373.8576660,36.6130980,0.0000000,0.0000000,312.7310000, 1); //
    CreateDynamicObject(1632,1983.8981930,-2421.1467290,13.8470000,4.2963000,0.0000000,310.9090000, 1); //
    CreateDynamicObject(1632,1981.2323000,-2418.0397950,13.8470000,4.2963000,0.0000000,310.9090000, 1); //
    CreateDynamicObject(1655,1985.7019040,-2416.7033690,17.1150000,30.0794000,0.0000000,311.0121000, 1); //
    CreateDynamicObject(1632,2020.6383060,-2389.0981450,44.2426990,23.2039000,0.0000000,310.9090000, 1); //
    CreateDynamicObject(13592,1508.3505860,-2495.1928710,21.7753300,359.9992000,1.7180000,7.3565000, 1); //
    CreateDynamicObject(1655,1798.0690920,-2434.8930660,13.5047970,0.0000000,0.0000000,66.7201000, 1); //
    CreateDynamicObject(1632,2062.0302730,-2622.8420410,13.4719920,0.0000000,359.1406000,112.5674000, 1); //
    CreateDynamicObject(1632,2059.2260740,-2624.0402830,16.1969930,24.9229000,359.1406000,112.5675000, 1); //
    CreateDynamicObject(1655,1894.1684570,-2547.3388670,13.5469910,0.0000000,0.0000000,89.9994000, 1); //
    CreateDynamicObject(1655,1894.1684570,-2538.5888670,13.5469910,0.0000000,0.0000000,89.9994000, 1); //
    CreateDynamicObject(1655,1874.9079590,-2538.6508790,13.6469900,0.0000000,0.0000000,269.9998000, 1); //
    CreateDynamicObject(1655,1874.9079590,-2547.9008790,13.6469900,0.0000000,0.0000000,269.9998000, 1); //
    CreateDynamicObject(1225,1887.5711670,-2539.2741700,12.9526300,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,1887.1892090,-2536.9260250,12.9526300,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,1881.6647950,-2536.7053220,12.9526300,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,1881.6369630,-2539.6113280,12.9526300,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,1886.6369630,-2546.8613280,12.9526300,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,1886.6369630,-2549.3613280,12.9526300,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,1880.6369630,-2548.3613280,12.9526300,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,1882.3869630,-2546.1113280,12.9526300,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,1882.3869630,-2549.8613280,12.9526300,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1655,1834.8227540,-2543.0007320,13.8469870,0.0000000,0.0000000,89.9994000, 1); //
    CreateDynamicObject(1655,1831.8472900,-2543.0007320,15.4469810,7.7341000,0.0000000,89.9994000, 1); //
    CreateDynamicObject(1655,1827.3472900,-2543.0007320,18.7219540,18.9068000,0.0000000,89.9994000, 1); //
    CreateDynamicObject(1655,1825.3970950,-2543.0007320,20.6969510,25.7823000,0.0000000,89.9994000, 1); //
    CreateDynamicObject(1655,1822.0217290,-2543.0007320,25.1469360,35.2361000,0.0000000,89.9994000, 1); //
    CreateDynamicObject(1655,1662.8402100,-2547.3872070,13.4719920,0.8586000,0.0000000,90.0796000, 1); //
    CreateDynamicObject(1655,1662.7569580,-2538.5222170,13.4719920,0.8586000,0.0000000,90.0796000, 1); //
    CreateDynamicObject(18450,1765.6126710,-2543.6464840,38.6332930,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(18450,1708.5905760,-2543.6081540,38.6900250,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(18450,1615.4207760,-2544.0134280,51.9366610,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(18449,1542.5430910,-2544.0234380,51.9334030,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(13666,1575.1713870,-2544.1567380,54.5574650,0.0000000,0.0000000,12.8907000, 1); //
    CreateDynamicObject(13666,1562.4213870,-2544.1567380,54.5574650,0.0000000,0.0000000,12.8907000, 1); //
    CreateDynamicObject(13666,1550.1713870,-2544.1567380,54.5574650,0.0000000,0.0000000,12.8907000, 1); //
    CreateDynamicObject(13666,1538.4213870,-2544.1567380,54.5574650,0.0000000,0.0000000,12.8907000, 1); //
    CreateDynamicObject(1632,1501.5187990,-2546.1359860,52.6655350,0.0000000,0.0000000,89.0653000, 1); //
    CreateDynamicObject(1632,1501.5695800,-2542.0651860,52.6655350,0.0000000,0.0000000,89.9248000, 1); //
    CreateDynamicObject(1655,1688.3431400,-2544.0227050,40.0088690,0.0000000,0.0000000,90.2400000, 1); //
    CreateDynamicObject(1655,1683.0931400,-2544.0227050,43.2588690,17.1879000,0.0000000,90.2400000, 1); //
    CreateDynamicObject(17565,1776.0086670,-2491.7397460,14.5634010,0.0000000,0.0000000,90.2400000, 1); //
    CreateDynamicObject(5126,1953.0826420,-2657.0100100,26.4962460,0.0000000,0.0000000,89.3806000, 1); //
    CreateDynamicObject(1632,1953.6004640,-2612.5734860,13.3469870,0.0000000,0.0000000,178.4354000, 1); //
    CreateDynamicObject(1632,1953.4753420,-2616.8991700,15.8469870,13.7501000,0.0000000,178.4354000, 1); //
    CreateDynamicObject(619,1576.5646970,-2536.9687500,52.0567700,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(619,1555.9896240,-2536.8193360,52.0567700,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(619,1539.4901120,-2536.9687500,52.0567700,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1632,1492.2718510,-2426.5786130,13.8547990,7.7341000,0.0000000,290.7065000, 1); //
    CreateDynamicObject(1655,1794.3691410,-2433.2934570,15.7547970,13.7501000,0.0000000,66.7201000, 1); //
    CreateDynamicObject(3110,1392.5900880,-2545.9670410,9.7916780,0.0000000,0.0000000,110.0071000, 1); //
    CreateDynamicObject(7388,2095.2448730,-2637.4741210,14.1530800,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1655,1379.4476320,-2422.5583500,19.5751860,25.7821000,0.0000000,86.8023000, 1); //
    CreateDynamicObject(1655,1374.9306640,-2422.4812010,26.4845890,42.1113000,0.0000000,88.5211000, 1); //
    CreateDynamicObject(1655,1372.7653810,-2422.5441890,34.7671130,63.5970000,0.0000000,88.5211000, 1); //
    CreateDynamicObject(1655,1373.8135990,-2422.5373540,43.0549200,83.3638000,0.0000000,89.3806000, 1); //
    CreateDynamicObject(11111,1389.2736820,-2496.7749020,32.7580640,328.2008000,0.0000000,269.7591000, 1); //
    CreateDynamicObject(11111,1340.1213380,-2496.6811520,62.8217620,329.0603000,0.0000000,269.7591000, 1); //
    CreateDynamicObject(11111,1289.7272950,-2496.4794920,93.1455310,329.0603000,0.0000000,269.7591000, 1); //
    CreateDynamicObject(11111,1234.0957030,-2496.2619630,110.2682190,356.5623000,0.0000000,269.7591000, 1); //
    CreateDynamicObject(11111,1446.9802250,-2497.0207520,5.1655100,341.9518000,0.0000000,269.7591000, 1); //
    CreateDynamicObject(1632,1406.0563960,-2497.2141110,20.7730960,320.4659000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(1632,1414.6558840,-2497.2297360,19.5423370,336.7952000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(1632,1422.7379150,-2497.2470700,20.7001840,353.9839000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(1632,1430.3789060,-2497.2561040,24.1824340,11.1727000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(1632,1436.7183840,-2497.2614750,29.7187290,25.7831000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(13593,2035.8612060,-2597.8698730,13.2897340,10.3124000,0.0000000,269.2774000, 1); //
    CreateDynamicObject(1655,2021.9542240,-2493.8361820,13.6142330,0.0000000,0.0000000,269.9998000, 1); //
    CreateDynamicObject(1655,2029.2563480,-2493.8330080,17.8999960,15.4699000,0.0000000,269.9998000, 1); //
    CreateDynamicObject(1655,2035.2304690,-2493.8459470,23.8480190,29.2208000,0.0000000,269.9998000, 1); //
    CreateDynamicObject(1655,2039.5021970,-2493.8503420,31.0138930,43.8313000,0.0000000,269.9998000, 1); //
    CreateDynamicObject(1655,2041.8853760,-2493.8540040,39.1829380,58.4416000,0.0000000,269.9998000, 1); //
    CreateDynamicObject(1655,2041.9151610,-2493.8369140,47.7392920,75.6304000,0.0000000,269.9998000, 1); //
    CreateDynamicObject(1655,2039.6140140,-2493.8432620,55.9914280,90.2408000,0.0000000,269.9998000, 1); //
    CreateDynamicObject(1655,2035.3387450,-2493.8488770,63.2212030,105.7106000,0.0000000,269.9998000, 1); //
    CreateDynamicObject(1632,1977.0468750,-2614.9472660,13.4719940,0.0000000,0.0000000,178.4354000, 1); //
    CreateDynamicObject(1632,1976.8768310,-2621.2448730,17.2729570,17.1887000,0.0000000,178.4354000, 1); //
    CreateDynamicObject(1632,1976.7467040,-2626.1489260,22.8873520,35.2369000,0.0000000,178.4354000, 1); //
    CreateDynamicObject(1632,1976.6711430,-2629.2004390,30.0782640,53.2850000,0.0000000,178.4354000, 1); //
    CreateDynamicObject(1632,1976.6467290,-2629.9636230,37.4702800,69.6143000,0.0000000,178.4354000, 1); //
    CreateDynamicObject(13641,1858.2347410,-2618.4243160,16.1101400,0.0000000,343.6707000,213.7525000, 1); //
    CreateDynamicObject(13638,1702.4273680,-2317.5295410,63.5641780,0.0000000,0.0000000,199.3885000, 1); //
    CreateDynamicObject(3374,2037.0665280,-2571.3381350,13.9869300,0.0000000,0.0000000,326.2500000, 1); //
    CreateDynamicObject(17310,1980.0994870,-2526.4284670,13.9469300,0.0000000,202.7229000,335.0763000, 1); //
    CreateDynamicObject(17310,1966.8222660,-2520.6474610,31.3660390,358.2811000,96.1525000,158.1366000, 1); //
    CreateDynamicObject(8620,2015.6917720,-2493.9384770,35.5354460,0.0000000,0.0000000,271.4781000, 1); //
    CreateDynamicObject(8493,1791.5272220,-2569.6484380,51.7548900,0.0000000,0.0000000,91.9597000, 1); //
    CreateDynamicObject(3851,1547.7670900,-2544.9372560,14.5468750,0.8586000,358.2811000,180.2343000, 1); //
    CreateDynamicObject(3851,1528.7164310,-2545.7082520,14.4607980,0.8586000,359.1406000,181.6441000, 1); //
    CreateDynamicObject(3851,1507.4869380,-2546.0605470,14.5468750,0.8586000,359.1406000,180.7847000, 1); //
    CreateDynamicObject(3851,1480.4630130,-2546.8642580,14.5468750,0.8586000,359.1406000,181.6441000, 1); //
    CreateDynamicObject(3851,1994.7832030,-2595.2316890,14.7968750,0.8586000,1.7189000,182.5036000, 1); //
    CreateDynamicObject(3851,1929.0305180,-2594.4975590,14.5468750,0.8586000,359.1406000,178.2064000, 1); //
    CreateDynamicObject(3851,1961.1523440,-2594.3527830,14.5468740,0.8586000,359.1406000,180.7847000, 1); //
    CreateDynamicObject(3851,2014.6547850,-2595.3181150,14.5468750,0.8586000,359.1406000,179.9253000, 1); //
    CreateDynamicObject(676,2063.5615230,-2564.6860350,12.5458720,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(676,2077.3796390,-2549.7517090,12.5458720,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(16061,1746.5346680,-2596.5283200,25.9873680,16.3293000,0.0000000,90.2408000, 1); //
    CreateDynamicObject(16061,1747.7755130,-2612.6020510,25.5004100,16.3293000,0.0000000,90.2408000, 1); //
    CreateDynamicObject(1655,1642.7935790,-2538.8178710,14.0469840,5.1557000,0.0000000,270.5611000, 1); //
    CreateDynamicObject(1655,1706.6715090,-2608.7048340,37.5565950,359.1398000,0.0000000,90.2393000, 1); //
    CreateDynamicObject(1655,1706.6285400,-2600.2419430,37.5644570,359.1398000,0.0000000,90.2393000, 1); //
    CreateDynamicObject(16776,1610.4179690,-2493.2287600,10.1555750,0.0000000,0.0000000,1.7187000, 1); //
    CreateDynamicObject(16776,1628.8316650,-2494.3085940,10.6555370,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(16061,2023.8321530,-2472.4228520,12.2343040,0.0000000,0.0000000,90.2408000, 1); //
    CreateDynamicObject(16061,1388.6834720,-2497.8271480,12.5468750,0.0000000,0.0000000,173.6062000, 1); //
    CreateDynamicObject(16061,1593.8630370,-2627.9604490,12.5468750,0.0000000,3.4377000,85.9436000, 1); //
    CreateDynamicObject(16061,1661.1925050,-2627.2126460,11.3842980,0.0000000,0.0000000,91.1002000, 1); //
    CreateDynamicObject(16061,1892.2860110,-2515.3806150,12.1342980,0.0000000,0.0000000,90.2407000, 1); //
    CreateDynamicObject(16061,1425.0609130,-2633.5197750,12.1342980,0.0000000,3.4377000,85.9436000, 1); //
    CreateDynamicObject(16061,1471.2595210,-2410.6838380,12.3171200,0.8594000,0.0000000,268.8997000, 1); //
    CreateDynamicObject(16061,1568.0729980,-2395.5817870,11.8921110,0.0000000,3.4377000,85.9436000, 1); //
    CreateDynamicObject(16061,1642.7827150,-2395.1433110,11.5921150,0.0000000,3.4377000,88.5219000, 1); //
    CreateDynamicObject(16061,1723.9777830,-2396.4848630,12.6421130,0.0000000,3.4377000,96.2569000, 1); //
    CreateDynamicObject(16061,1997.7929690,-2315.8671880,12.4593090,0.0000000,0.0000000,2.5783000, 1); //
    CreateDynamicObject(1632,1647.3508300,-2507.4309080,13.5047990,6.0161000,0.0000000,90.2409000, 1); //
    CreateDynamicObject(1632,1647.3227540,-2503.3012700,13.5106810,6.0161000,0.0000000,90.2409000, 1); //
    CreateDynamicObject(1632,1647.3560790,-2499.2756350,13.5048010,6.0161000,0.0000000,88.5220000, 1); //
    CreateDynamicObject(1632,1647.5104980,-2495.1516110,13.5071640,6.0161000,0.0000000,88.5220000, 1); //
    CreateDynamicObject(1632,1647.6096190,-2490.9968260,13.5188620,6.0161000,0.0000000,88.5220000, 1); //
    CreateDynamicObject(1632,1647.6920170,-2486.9965820,13.5298040,6.0161000,0.0000000,88.5220000, 1); //
    CreateDynamicObject(1632,1647.7858890,-2482.8854980,13.5548040,6.0161000,0.0000000,88.5220000, 1); //
    CreateDynamicObject(16776,1620.0350340,-2493.2458500,10.0555310,0.0000000,0.0000000,1.7187000, 1); //
    CreateDynamicObject(1632,1592.6290280,-2483.1496580,13.5797770,4.2972000,0.0000000,268.8997000, 1); //
    CreateDynamicObject(1632,1592.5435790,-2487.2890630,13.5798030,4.2972000,0.0000000,268.8997000, 1); //
    CreateDynamicObject(1632,1592.4655760,-2495.4958500,13.5798030,4.2972000,0.0000000,268.8997000, 1); //
    CreateDynamicObject(1632,1592.4986570,-2491.3593750,13.5798030,4.2972000,0.0000000,269.7591000, 1); //
    CreateDynamicObject(1632,1592.3052980,-2503.6584470,13.5798030,4.2972000,0.0000000,268.8997000, 1); //
    CreateDynamicObject(1632,1592.3737790,-2499.6430660,13.5809380,4.2972000,0.0000000,268.8997000, 1); //
    CreateDynamicObject(1632,1592.2218020,-2507.7580570,13.5798030,4.2972000,0.0000000,268.8997000, 1); //
    CreateDynamicObject(3851,1965.6422120,-2490.8989260,15.0390800,138.3674000,359.1406000,182.8126000, 1); //
    CreateDynamicObject(3851,1957.1044920,-2491.6694340,15.5452730,46.4083000,359.1406000,182.8126000, 1); //
    CreateDynamicObject(3851,1986.6052250,-2491.3200680,14.5391180,46.4083000,359.1406000,182.8126000, 1); //
    CreateDynamicObject(3851,1978.7766110,-2490.0495610,14.6391200,140.9457000,359.1406000,182.8126000, 1); //
    CreateDynamicObject(3851,1972.9697270,-2491.3444820,14.5391180,46.4083000,359.1406000,182.8126000, 1); //
    CreateDynamicObject(3851,1951.3022460,-2490.5000000,15.9391190,46.4083000,359.1406000,5.8728000, 1); //
    CreateDynamicObject(3851,1945.3394780,-2491.1433110,14.5391180,121.1786000,359.1406000,5.8728000, 1); //
    CreateDynamicObject(3851,1938.4627690,-2491.1166990,14.5391180,46.4083000,359.1406000,5.8728000, 1); //
    CreateDynamicObject(3851,1931.0695800,-2490.8376460,14.5391180,127.1950000,359.1406000,5.8728000, 1); //
    CreateDynamicObject(3851,1922.6157230,-2489.4589840,15.4391040,46.4083000,359.1406000,5.8728000, 1); //
    CreateDynamicObject(3851,1762.4010010,-2604.4221190,22.8425060,0.8586000,359.1406000,178.2064000, 1); //
    CreateDynamicObject(3851,1729.2239990,-2604.7172850,33.8780780,0.8586000,359.1406000,178.2064000, 1); //
    CreateDynamicObject(3851,1771.1751710,-2604.2902830,20.1284920,0.8586000,359.1406000,178.2064000, 1); //
    CreateDynamicObject(3851,1749.6414790,-2604.8337400,26.7892650,0.8586000,359.1406000,178.2064000, 1); //
    CreateDynamicObject(1225,1669.7397460,-2543.4123540,39.4395290,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,1669.7771000,-2537.5803220,39.4395290,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,1669.7497560,-2540.3073730,39.4395290,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,1669.7347410,-2546.7717290,39.4395290,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,1669.7854000,-2549.8195800,39.4395290,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3505,2056.2834470,-2555.0173340,12.5413480,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3505,2035.8323970,-2576.2016600,12.5413480,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3505,2073.5942380,-2537.8110350,12.5413480,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3505,2102.4409180,-2535.4248050,12.5413480,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1655,1642.8360600,-2547.3374020,14.0229990,5.1557000,0.0000000,270.5611000, 1); //
    CreateDynamicObject(1655,1658.7794190,-2547.2885740,16.0299630,18.0472000,0.0000000,90.0796000, 1); //
    CreateDynamicObject(1655,1658.7624510,-2538.5981450,16.0418150,18.0472000,0.0000000,90.0796000, 1); //
    CreateDynamicObject(1655,1646.2290040,-2547.2980960,16.5470100,18.0472000,0.0000000,270.0796000, 1); //
    CreateDynamicObject(1655,1646.2524410,-2538.8027340,16.5654640,18.0472000,0.0000000,270.0796000, 1); //
    CreateDynamicObject(1655,1839.4055180,-2414.1582030,12.7598040,350.5462000,0.0000000,20.6265000, 1); //
    CreateDynamicObject(16304,1706.9378660,-2542.0708010,15.1821560,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(16061,1495.8529050,-2640.9301760,12.1342980,0.0000000,3.4377000,92.8191000, 1); //
    CreateDynamicObject(8357,1451.6506350,-2629.0087890,38.2912370,327.3414000,0.0000000,315.0000000, 1); //
    CreateDynamicObject(8357,1326.9573970,-2753.7443850,151.3443600,327.3414000,0.0000000,315.0000000, 1); //
    CreateDynamicObject(8357,1207.1578370,-2873.5456540,259.9202880,327.3414000,0.0000000,315.0000000, 1); //
    CreateDynamicObject(8040,1115.3138430,-2964.8503420,318.0757750,0.0000000,0.0000000,45.0000000, 1); //
    CreateDynamicObject(1655,1146.6409910,-2933.5119630,314.7980040,317.8876000,0.0000000,315.0000000, 1); //
    CreateDynamicObject(1655,1150.7683110,-2929.5642090,310.8847050,26.6425000,0.0000000,135.0000000, 1); //
    CreateDynamicObject(1655,1213.1776120,-2884.4155270,261.7593380,311.8715000,0.0000000,315.0000000, 1); //
    CreateDynamicObject(1655,1218.7625730,-2878.8466800,259.7941890,334.2169000,0.0000000,315.0000000, 1); //
    CreateDynamicObject(1655,1224.3331300,-2873.2766110,260.9981080,357.4217000,0.0000000,315.0000000, 1); //
    CreateDynamicObject(1655,1273.7728270,-2806.7072750,200.5362850,329.9197000,0.0000000,315.0000000, 1); //
    CreateDynamicObject(1655,1279.2174070,-2801.2829590,200.8095090,348.8273000,0.0000000,315.0000000, 1); //
    CreateDynamicObject(1655,1284.4777830,-2796.0290530,203.7708740,8.5943000,0.0000000,315.0000000, 1); //
    CreateDynamicObject(1655,1288.7082520,-2791.8173830,209.1170500,28.3614000,0.0000000,315.0000000, 1); //
    CreateDynamicObject(17310,1400.1662600,-2700.2629390,97.3430250,359.1406000,177.7992000,226.0141000, 1); //
    CreateDynamicObject(17310,1425.4705810,-2635.0803220,56.5612490,359.1406000,177.7992000,226.0141000, 1); //
    CreateDynamicObject(18450,1351.6148680,-2729.2250980,199.8587800,0.0000000,0.0000000,45.0000000, 1); //
    CreateDynamicObject(18450,1407.1575930,-2673.6853030,199.8455810,0.0000000,0.0000000,45.0000000, 1); //
    CreateDynamicObject(1655,1434.5837400,-2646.2126460,200.6894530,356.5623000,0.0000000,315.0000000, 1); //
    CreateDynamicObject(1632,1522.1197510,-2628.0156250,19.4643610,25.7822000,0.0000000,179.5183000, 1); //
    CreateDynamicObject(1632,1522.0792240,-2632.1799320,26.0596350,43.8302000,0.0000000,179.5183000, 1); //
    CreateDynamicObject(1632,1522.0732420,-2634.0268550,33.6037140,62.7376000,0.0000000,179.5183000, 1); //
    CreateDynamicObject(1632,1522.1051030,-2633.3972170,41.5669360,80.7857000,0.0000000,179.5183000, 1); //
    CreateDynamicObject(3851,1622.5363770,-2587.3842770,14.5468750,0.8586000,359.1406000,178.2064000, 1); //
    CreateDynamicObject(3851,1596.0571290,-2587.5566410,14.5468750,0.8586000,359.1406000,178.2064000, 1); //
    CreateDynamicObject(3851,1595.6939700,-2598.7407230,14.6968730,0.8586000,359.1406000,178.2064000, 1); //
    CreateDynamicObject(3851,1570.0418700,-2587.7226560,14.5468750,0.8586000,359.1406000,179.9253000, 1); //
    CreateDynamicObject(3851,1622.1838380,-2598.5842290,14.6968730,0.8586000,359.1406000,178.2064000, 1); //
    CreateDynamicObject(3851,1546.5527340,-2586.2167970,14.5468750,0.8586000,359.1406000,178.2064000, 1); //
    CreateDynamicObject(1655,1492.4649660,-2610.3854980,12.2719960,347.1084000,0.0000000,135.0000000, 1); //
    CreateDynamicObject(1655,1486.3140870,-2604.2426760,12.2779940,347.1084000,0.0000000,135.0000000, 1); //
    CreateDynamicObject(1655,1480.1809080,-2598.1052250,12.2742980,347.1084000,0.0000000,135.0000000, 1); //
    CreateDynamicObject(1655,1474.2427980,-2592.0258790,12.2719800,347.1084000,0.0000000,135.0000000, 1); //
    CreateDynamicObject(1655,1489.0228270,-2613.8361820,13.9772760,5.1566000,0.0000000,135.0000000, 1); //
    CreateDynamicObject(1655,1482.8732910,-2607.6877440,13.9736180,5.1566000,0.0000000,135.0000000, 1); //
    CreateDynamicObject(1655,1476.7939450,-2601.6115720,13.9719850,5.1566000,0.0000000,135.0000000, 1); //
    CreateDynamicObject(1655,1470.7565920,-2595.5683590,13.9719850,5.1566000,0.0000000,135.0000000, 1); //
    CreateDynamicObject(8618,2147.2177730,-2587.2226560,25.5527780,0.0000000,0.0000000,87.6625000, 1); //
    CreateDynamicObject(2898,2094.2785640,-2633.3923340,12.6007600,0.0000000,0.0000000,11.1727000, 1); //
    CreateDynamicObject(2985,2092.4079590,-2631.3522950,12.5783820,0.0000000,0.0000000,197.6705000, 1); //
    CreateDynamicObject(3092,2094.8334960,-2635.1855470,13.9069530,0.0000000,0.0000000,0.0000000, 1); //
    print("[Gamemode::Objects]: Los santos airport objects has been loaded.");

    CreateDynamicObject(16133,-2367.7333980,-1603.6143800,475.6005550,0.0000000,335.0763000,160.0784000, 1); //
    CreateDynamicObject(16133,-2372.9951170,-1609.0197750,478.6929020,0.0000000,352.2651000,172.9698000, 1); //
    CreateDynamicObject(4867,-2401.9877930,-1539.0441890,477.3510740,0.0000000,0.0000000,276.1708000, 1); //
    CreateDynamicObject(16141,-2445.3369140,-1581.4415280,467.5700380,0.0000000,0.0000000,292.5000000, 1); //
    CreateDynamicObject(5005,-2318.8190920,-1456.9964600,480.5526730,0.0000000,0.0000000,276.0934000, 1); //
    CreateDynamicObject(4867,-2406.9345700,-1493.2948000,477.3480220,0.0000000,0.0000000,276.1708000, 1); //
    CreateDynamicObject(5005,-2405.9082030,-1386.4187010,480.5746150,0.0000000,0.0000000,186.0934000, 1); //
    CreateDynamicObject(5005,-2426.6220700,-1388.6112060,480.5789790,0.0000000,0.0000000,186.0934000, 1); //
    CreateDynamicObject(5005,-2500.0073240,-1479.6378170,480.6026610,0.0000000,0.0000000,96.0933000, 1); //
    CreateDynamicObject(5005,-2489.8374020,-1575.8896480,480.6026610,0.0000000,0.0000000,96.0933000, 1); //
    CreateDynamicObject(1655,-2359.7077640,-1412.5878910,478.3981930,0.0000000,0.0000000,5.1566000, 1); //
    CreateDynamicObject(1655,-2360.3562010,-1405.5255130,482.6340330,16.3293000,0.0000000,5.1566000, 1); //
    CreateDynamicObject(1655,-2360.8369140,-1400.0283200,488.7246400,33.5180000,0.0000000,5.1566000, 1); //
    CreateDynamicObject(1655,-2361.0864260,-1396.8812260,496.2305300,54.1445000,0.0000000,5.1566000, 1); //
    CreateDynamicObject(1655,-2361.1279300,-1396.4769290,504.5408630,73.9115000,0.0000000,5.1566000, 1); //
    CreateDynamicObject(13592,-2402.9289550,-1408.9910890,487.7435610,0.0000000,345.3896000,101.2500000, 1); //
    CreateDynamicObject(13592,-2411.4670410,-1405.4421390,488.4511110,0.0000000,345.3896000,101.2500000, 1); //
    CreateDynamicObject(13592,-2420.0249020,-1401.7622070,489.4227290,0.0000000,345.3896000,101.2500000, 1); //
    CreateDynamicObject(1632,-2424.1000980,-1402.5712890,480.3526310,339.3735000,0.0000000,6.0161000, 1); //
    CreateDynamicObject(1632,-2424.6335450,-1397.5279540,481.5430600,358.2811000,0.0000000,6.0161000, 1); //
    CreateDynamicObject(1632,-2425.0998540,-1393.0222170,484.4472960,18.9076000,0.0000000,6.0161000, 1); //
    CreateDynamicObject(13831,-2433.2319340,-1586.0909420,499.3876950,0.0000000,0.0000000,211.1717000, 1); //
    CreateDynamicObject(13722,-2433.1091310,-1585.5423580,499.3674620,0.0000000,0.0000000,211.1717000, 1); //
    CreateDynamicObject(1655,-2459.9565430,-1442.6992190,478.3762510,0.0000000,0.0000000,65.3172000, 1); //
    CreateDynamicObject(1655,-2464.2824710,-1440.7221680,481.3320010,19.7670000,0.0000000,65.3172000, 1); //
    CreateDynamicObject(1655,-2468.9467770,-1531.2178960,478.3762510,0.0000000,0.0000000,144.0671000, 1); //
    CreateDynamicObject(1655,-2472.1254880,-1535.6302490,481.6322940,17.1887000,0.0000000,144.0671000, 1); //
    CreateDynamicObject(16133,-2482.7448730,-1487.6146240,477.3529050,0.0000000,347.1084000,160.0784000, 1); //
    CreateDynamicObject(16133,-2324.2871090,-1489.3408200,475.9028930,0.0000000,347.1084000,12.2556000, 1); //
    CreateDynamicObject(16133,-2386.0937500,-1573.1529540,482.0455320,0.0000000,327.3414000,268.2640000, 1); //
    CreateDynamicObject(16133,-2452.6040040,-1400.9110110,477.3998410,0.0000000,335.0763000,112.7063000, 1); //
    CreateDynamicObject(16037,-2233.2258300,-1588.5480960,482.9154970,0.0000000,5.1566000,21.6406000, 1); //
    CreateDynamicObject(16037,-2123.1132810,-1544.8819580,461.0697020,0.0000000,15.4699000,21.6406000, 1); //
    CreateDynamicObject(16037,-2016.9067380,-1502.7147220,429.3961180,0.0000000,15.4699000,21.6406000, 1); //
    CreateDynamicObject(3502,-2282.9011230,-1660.6234130,483.1766050,0.0000000,0.0000000,263.1245000, 1); //
    CreateDynamicObject(3502,-2273.9899900,-1661.8908690,483.2159730,0.0000000,0.0000000,263.1245000, 1); //
    CreateDynamicObject(3502,-2265.2485350,-1663.1335450,482.8676450,354.8434000,341.9518000,260.5462000, 1); //
    CreateDynamicObject(3502,-2259.7011720,-1664.1851810,481.8146060,346.2490000,357.4217000,259.6868000, 1); //
    CreateDynamicObject(3502,-2251.6459960,-1665.3603520,479.9256590,348.8273000,0.0000000,262.2651000, 1); //
    CreateDynamicObject(3502,-2244.3122560,-1666.3115230,480.1397090,12.0321000,357.4217000,263.9840000, 1); //
    CreateDynamicObject(3502,-2225.4963380,-1668.4279790,484.0326230,6.8755000,0.0000000,263.1245000, 1); //
    CreateDynamicObject(3502,-2217.8317870,-1669.2233890,484.9665220,6.8755000,0.0000000,263.1245000, 1); //
    CreateDynamicObject(3502,-2210.4599610,-1670.0936280,485.8232120,6.8755000,0.0000000,263.1245000, 1); //
    CreateDynamicObject(3502,-2203.3281250,-1671.0635990,486.7222900,6.8755000,0.0000000,263.1245000, 1); //
    CreateDynamicObject(3502,-2197.3605960,-1671.7744140,487.5437620,6.8755000,0.0000000,263.1245000, 1); //
    CreateDynamicObject(3554,-2283.5329590,-1660.5687260,491.4270630,0.0000000,0.0000000,82.7466000, 1); //
    CreateDynamicObject(726,-2317.4755860,-1523.2635500,476.7486270,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(726,-2262.2463380,-1687.0433350,478.7172850,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(13831,-2371.4995120,-1609.1262210,510.3518980,0.0000000,0.8594000,78.8274000, 1); //
    CreateDynamicObject(16133,-2271.3291020,-1725.6975100,467.9266660,0.0000000,347.1084000,205.0009000, 1); //
    CreateDynamicObject(726,-2244.6777340,-1751.0203860,479.2530520,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(726,-2332.6999510,-1395.8000490,476.5955510,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(726,-2456.0375980,-1415.9877930,478.8392330,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(726,-2475.0192870,-1500.0153810,483.2350460,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(726,-2401.3005370,-1556.4224850,476.9783630,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(726,-2474.9460450,-1602.2797850,476.5487980,0.0000000,0.0000000,348.8273000, 1); //
    CreateDynamicObject(13641,-2296.2861330,-1598.3979490,481.6576840,359.1406000,17.1887000,29.5301000, 1); //
    CreateDynamicObject(1655,-2237.6071780,-1732.9912110,480.5975040,1.7189000,0.8594000,210.2350000, 1); //
    CreateDynamicObject(4853,-2273.5026860,-1563.0952150,479.0131840,0.0000000,358.2811000,45.0000000, 1); //
    CreateDynamicObject(733,-2328.6289060,-1685.1379390,481.2633360,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(735,-2359.9621580,-1646.8964840,480.8231810,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(16127,-2346.4843750,-1683.9179690,486.5352780,346.2490000,0.8594000,292.5000000, 1); //
    CreateDynamicObject(16127,-2316.8852540,-1707.4289550,485.2940980,349.6868000,0.0000000,321.7209000, 1); //
    CreateDynamicObject(1655,-2287.5368650,-1640.0134280,483.2904050,359.1406000,0.8594000,271.8735000, 1); //
    CreateDynamicObject(1655,-2287.7043460,-1631.8526610,483.3433230,359.1406000,0.0000000,270.1547000, 1); //
    CreateDynamicObject(9685,-2282.9450680,-1531.1125490,536.9564210,0.0000000,0.0000000,320.2340000, 1); //
    CreateDynamicObject(9685,-2196.8762210,-1427.7484130,545.7092900,0.0000000,0.0000000,320.2341000, 1); //
    CreateDynamicObject(9685,-2110.6821290,-1324.2585450,554.4740600,0.0000000,0.0000000,320.2341000, 1); //
    CreateDynamicObject(1655,-1897.7393800,-1056.2344970,523.4464110,0.0000000,0.0000000,321.0934000, 1); //
    CreateDynamicObject(7916,-2362.4956050,-1613.5217290,497.1754760,28.3614000,0.0000000,77.0311000, 1); //
    CreateDynamicObject(7916,-2355.7802730,-1657.3208010,495.5509030,29.2208000,359.1406000,109.0622000, 1); //
    CreateDynamicObject(16127,-2363.8041990,-1645.9522710,482.3836060,346.2490000,0.8594000,292.5000000, 1); //
    CreateDynamicObject(16133,-2384.8005370,-1575.7351070,485.2052920,350.5462000,332.4980000,254.5129000, 1); //
    CreateDynamicObject(11435,-2310.0244140,-1584.2767330,485.4064940,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(7392,-2287.5964360,-1672.0661620,491.2100520,0.0000000,0.0000000,353.1245000, 1); //
    CreateDynamicObject(8483,-2354.7600100,-1579.3789060,490.0266720,358.2811000,357.4217000,331.6386000, 1); //
    CreateDynamicObject(13562,-2288.0422360,-1654.2196040,483.4286800,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(16776,-2309.8317870,-1695.0225830,481.2638550,0.0000000,0.0000000,135.7911000, 1); //
    CreateDynamicObject(1655,-2293.2639160,-1607.7830810,483.3318480,358.2811000,359.1406000,290.7811000, 1); //
    CreateDynamicObject(1655,-2290.2087400,-1615.8308110,483.3783870,358.2811000,0.0000000,290.7811000, 1); //
    CreateDynamicObject(1655,-1746.0576170,-1395.1051030,356.6891480,344.5301000,0.0000000,292.5000000, 1); //
    CreateDynamicObject(1655,-1738.8334960,-1392.1024170,358.8645940,0.8594000,0.0000000,292.5000000, 1); //
    CreateDynamicObject(1655,-1732.1280520,-1389.3441160,363.1152650,14.6104000,0.0000000,292.5000000, 1); //
    CreateDynamicObject(1655,-2344.1777340,-1555.5362550,479.0258480,8.5944000,0.0000000,189.4538000, 1); //
    CreateDynamicObject(1655,-2340.2363280,-1571.6898190,483.5012820,12.8916000,0.0000000,12.8916000, 1); //
    CreateDynamicObject(10838,-2321.3193360,-1576.8386230,497.2077640,359.1406000,358.2811000,48.1285000, 1); //
    CreateDynamicObject(3502,-2236.0166020,-1667.0858150,481.9785160,12.0321000,357.4217000,263.9840000, 1); //
    CreateDynamicObject(3502,-2231.7429200,-1667.5393070,483.0795290,12.0321000,357.4217000,263.9840000, 1); //
    CreateDynamicObject(3502,-2189.5480960,-1672.9091800,488.4751280,6.8755000,0.0000000,259.6868000, 1); //
    CreateDynamicObject(3502,-2182.2478030,-1674.7917480,489.4249270,6.8755000,0.0000000,249.3735000, 1); //
    CreateDynamicObject(3502,-2175.3969730,-1678.2021480,490.3304750,6.8755000,0.0000000,235.6225000, 1); //
    CreateDynamicObject(3502,-2169.1154790,-1682.4392090,490.7020870,359.1406000,1.7189000,235.6225000, 1); //
    CreateDynamicObject(3502,-2162.8095700,-1687.2613530,490.5827030,359.1406000,1.7189000,227.0281000, 1); //
    CreateDynamicObject(3502,-2157.6577150,-1693.1750490,490.4357600,359.1406000,1.7189000,212.4175000, 1); //
    CreateDynamicObject(3502,-2153.7050780,-1699.3436280,490.1125790,354.8434000,0.0000000,212.4175000, 1); //
    CreateDynamicObject(3502,-2150.3618160,-1705.5943600,489.4564210,354.8434000,0.0000000,200.3854000, 1); //
    CreateDynamicObject(3502,-2148.3923340,-1712.5202640,488.7866820,354.8434000,0.0000000,188.3531000, 1); //
    CreateDynamicObject(3502,-2147.9604490,-1719.5205080,488.1383970,354.8434000,0.0000000,176.3210000, 1); //
    CreateDynamicObject(3502,-2148.9348140,-1726.6425780,487.4865420,354.8434000,0.0000000,165.1482000, 1); //
    CreateDynamicObject(3502,-2150.7170410,-1733.4836430,486.5904540,349.6868000,0.0000000,165.1482000, 1); //
    CreateDynamicObject(3502,-2153.0158690,-1739.3671880,485.4017030,349.6868000,0.0000000,153.9754000, 1); //
    CreateDynamicObject(3502,-2156.8371580,-1745.6822510,484.0709840,349.6868000,0.0000000,141.9433000, 1); //
    CreateDynamicObject(3502,-2161.2739260,-1750.5728760,482.8876340,349.6868000,0.0000000,129.9110000, 1); //
    CreateDynamicObject(3502,-2167.0239260,-1754.2979740,481.6376040,349.6868000,0.0000000,115.3008000, 1); //
    CreateDynamicObject(3502,-2173.9982910,-1756.7771000,480.3060000,349.6868000,0.0000000,102.4093000, 1); //
    CreateDynamicObject(3502,-2181.3281250,-1757.5694580,478.9200440,349.6868000,0.0000000,87.7990000, 1); //
    CreateDynamicObject(3502,-2188.5371090,-1756.4328610,477.5937190,349.6868000,0.0000000,74.0482000, 1); //
    CreateDynamicObject(3502,-2195.4606930,-1753.2320560,476.2187190,349.6868000,0.0000000,56.0002000, 1); //
    CreateDynamicObject(3502,-2201.5815430,-1748.0119630,474.6691280,349.6868000,0.0000000,42.2493000, 1); //
    CreateDynamicObject(3502,-2205.8608400,-1742.1065670,473.3596800,349.6868000,0.0000000,27.6390000, 1); //
    CreateDynamicObject(3502,-2208.1865230,-1735.1075440,471.9981380,349.6868000,0.0000000,8.7316000, 1); //
    CreateDynamicObject(3502,-2208.3330080,-1727.4351810,470.6082760,349.6868000,0.0000000,352.4024000, 1); //
    CreateDynamicObject(3502,-2206.1843260,-1719.6542970,469.1242370,349.6868000,0.0000000,337.7921000, 1); //
    CreateDynamicObject(3502,-2202.0893550,-1713.1318360,467.7962040,349.6868000,0.0000000,318.0252000, 1); //
    CreateDynamicObject(3502,-2196.1381840,-1708.3482670,466.4063110,349.6868000,0.0000000,299.9772000, 1); //
    CreateDynamicObject(3502,-2189.0437010,-1705.4870610,465.0603940,349.6868000,0.0000000,283.6481000, 1); //
    CreateDynamicObject(3502,-2181.0290530,-1704.2194820,463.6279600,349.6868000,0.0000000,273.3349000, 1); //
    CreateDynamicObject(3502,-2173.1389160,-1703.7169190,462.1586300,349.6868000,0.0000000,273.3349000, 1); //
    CreateDynamicObject(3502,-2166.2416990,-1703.2469480,460.8514710,349.6868000,0.0000000,273.3349000, 1); //
    CreateDynamicObject(3502,-2158.8193360,-1702.7738040,459.4605710,349.6868000,0.0000000,273.3349000, 1); //
    CreateDynamicObject(3502,-2151.5180660,-1702.3350830,458.1130070,349.6868000,0.0000000,273.3349000, 1); //
    CreateDynamicObject(3502,-2144.2338870,-1701.8862300,456.7620850,349.6868000,0.0000000,273.3349000, 1); //
    CreateDynamicObject(13641,-2148.5041500,-1700.9993900,446.6018070,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(13641,-2142.5859380,-1700.9748540,446.3691100,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1655,-1810.5782470,-1636.1523440,443.5719300,351.4056000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(1655,-1802.6086430,-1636.1582030,446.3617550,2.5783000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(1655,-1796.5751950,-1636.1146240,450.2648620,17.1887000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(1655,-1790.4885250,-1636.0953370,456.1107180,25.7831000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(6986,-2349.0822750,-1572.6645510,499.1721190,0.0000000,0.0000000,303.2772000, 1); //
    CreateDynamicObject(2918,-1893.1734620,-1063.1026610,524.1887210,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2918,-2403.6926270,-1416.8315430,481.0900880,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2918,-2402.5078130,-1416.5926510,481.0208440,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2918,-2404.8884280,-1416.9497070,481.0432740,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(16133,-2382.1613770,-1605.6300050,488.9461360,0.0000000,334.2169000,136.8732000, 1); //
    CreateDynamicObject(16127,-2363.8212890,-1674.4335940,499.3169860,346.2490000,0.8594000,292.5000000, 1); //
    CreateDynamicObject(8618,-2355.6596680,-1591.1744380,499.2211910,0.0000000,0.0000000,24.9237000, 1); //
    CreateDynamicObject(3715,-2287.5156250,-1636.5799560,491.1558840,0.0000000,0.0000000,270.6186000, 1); //
    CreateDynamicObject(1655,-2245.1821290,-1737.3256840,480.6164550,1.7189000,359.1406000,209.3755000, 1); //
    CreateDynamicObject(13641,-2235.3413090,-1746.5479740,489.8213810,0.8594000,341.9518000,299.8395000, 1); //
    CreateDynamicObject(13722,-2371.5227050,-1609.1257320,510.7880250,0.0000000,0.0000000,78.8183000, 1); //
    CreateDynamicObject(16133,-2391.1799320,-1617.6015630,504.4227290,0.0000000,352.2651000,172.1104000, 1); //
    CreateDynamicObject(10281,-2360.6667480,-1667.8966060,507.0808110,0.0000000,358.2811000,116.0238000, 1); //
    CreateDynamicObject(16480,-2272.7255860,-1686.8920900,482.3297120,0.0000000,0.0000000,262.8837000, 1); //
    CreateDynamicObject(3528,-2287.6420900,-1635.9146730,496.5692140,1.7189000,0.0000000,180.3774000, 1); //
    CreateDynamicObject(13667,-2224.7041020,-1497.7193600,503.3662410,0.8594000,0.0000000,243.9762000, 1); //
    CreateDynamicObject(9685,-2024.5137940,-1220.6041260,563.3328250,0.0000000,0.0000000,320.2341000, 1); //
    CreateDynamicObject(9685,-1937.9780270,-1116.6407470,572.1401370,0.0000000,0.0000000,320.2341000, 1); //
    CreateDynamicObject(1655,-1885.7634280,-1065.6293950,523.4960940,0.0000000,0.0000000,320.2340000, 1); //
    CreateDynamicObject(1655,-1893.6386720,-1051.2141110,527.0731200,12.0321000,0.0000000,321.0934000, 1); //
    CreateDynamicObject(1655,-1891.2189940,-1048.1365970,530.2481080,21.4859000,0.0000000,321.0934000, 1); //
    CreateDynamicObject(1655,-1882.0469970,-1061.1240230,526.6574100,12.0321000,0.0000000,320.2340000, 1); //
    CreateDynamicObject(1655,-1878.9763180,-1057.2401120,530.9520260,23.2048000,0.0000000,320.2340000, 1); //
    CreateDynamicObject(2918,-1814.7561040,-1630.9235840,444.3989560,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2918,-1814.2330320,-1642.5666500,444.2142640,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2918,-1814.3601070,-1641.3347170,444.0114750,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2918,-1814.2855220,-1629.3540040,444.2766110,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2918,-1751.8911130,-1390.1185300,357.9586790,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2918,-1751.5806880,-1391.6907960,357.6389770,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2918,-1748.3222660,-1401.5557860,358.2543950,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2918,-1746.5729980,-1402.6433110,358.2071230,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(2918,-2307.1655270,-1589.9428710,485.2686770,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(4853,-2210.4924320,-1500.0544430,481.6705020,0.0000000,358.2811000,45.0000000, 1); //
    CreateDynamicObject(4853,-2150.0383300,-1439.5437010,483.5390930,0.0000000,359.1406000,45.0000000, 1); //
    CreateDynamicObject(4853,-2087.6904300,-1377.1608890,484.8284610,0.0000000,359.1406000,45.0000000, 1); //
    CreateDynamicObject(4853,-2025.6046140,-1315.1275630,484.1293330,0.0000000,1.7189000,45.0000000, 1); //
    CreateDynamicObject(4853,-1962.2485350,-1251.7774660,481.4486690,0.0000000,1.7189000,45.0000000, 1); //
    CreateDynamicObject(4853,-1904.2015380,-1193.6995850,479.6180420,0.8594000,0.8594000,45.0000000, 1); //
    CreateDynamicObject(1655,-1871.2771000,-1160.8541260,483.5673520,4.2972000,0.0000000,313.9859000, 1); //
    CreateDynamicObject(2918,-2285.1914060,-1664.5332030,483.9259030,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(18449,-2245.0295410,-1636.0566410,484.8465880,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(18449,-2165.4072270,-1636.0614010,484.8336180,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(18449,-2086.0461430,-1636.0963130,484.8455200,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(18449,-2007.1293950,-1636.0953370,477.7577510,0.0000000,10.3132000,0.0000000, 1); //
    CreateDynamicObject(18449,-1929.0631100,-1636.0926510,463.5944210,0.0000000,10.3132000,0.0000000, 1); //
    CreateDynamicObject(18449,-1852.8768310,-1636.0806880,449.7349550,0.0000000,10.3132000,0.0000000, 1); //
    CreateDynamicObject(18449,-1928.7353520,-1467.1607670,400.4543150,0.0000000,12.8916000,21.4859000, 1); //
    CreateDynamicObject(18449,-1856.4019780,-1438.6633300,382.6882630,0.0000000,12.8916000,21.4859000, 1); //
    CreateDynamicObject(18449,-1784.2385250,-1410.2503660,364.9492800,0.0000000,12.8916000,21.4859000, 1); //
    CreateDynamicObject(1655,-2234.1730960,-1738.9683840,484.5168460,11.1727000,1.7189000,210.2349000, 1); //
    CreateDynamicObject(1655,-2241.7468260,-1743.2922360,484.2451480,11.1727000,1.7189000,210.2349000, 1); //
    print("[Gamemode::Objects]: Chilliad objects has been loaded.");

    CreateDynamicObject(13592,-1482.6498000,315.1741000,63.7315000,54.1437000,0.0000000,302.4177000, 1); //
    CreateDynamicObject(13592,-1478.4904000,316.5262000,69.5630000,54.1437000,0.0000000,302.4177000, 1); //
    CreateDynamicObject(13592,-1474.3959000,317.8482000,75.3187000,54.1437000,0.0000000,302.4177000, 1); //
    CreateDynamicObject(13592,-1470.1570000,319.2551000,81.3043000,54.1437000,0.0000000,302.4177000, 1); //
    CreateDynamicObject(13592,-1466.0641000,320.5925000,87.0558000,54.1437000,0.0000000,302.4177000, 1); //
    CreateDynamicObject(13592,-1461.9872000,321.8880000,92.7495000,54.1437000,0.0000000,302.4177000, 1); //
    CreateDynamicObject(13592,-1457.7817000,323.2847000,98.7443000,54.1437000,0.0000000,302.4177000, 1); //
    CreateDynamicObject(13592,-1453.6246000,324.6290000,104.5753000,54.1437000,0.0000000,302.4177000, 1); //
    CreateDynamicObject(13592,-1437.3291000,312.0690000,102.9812000,0.0000000,0.0000000,29.2200000, 1); //
    CreateDynamicObject(13592,-1434.9281000,305.7288000,102.9819000,0.0000000,0.0000000,29.2200000, 1); //
    CreateDynamicObject(13592,-1432.2690000,298.8354000,102.9670000,0.0000000,0.0000000,29.2200000, 1); //
    CreateDynamicObject(13592,-1429.7708000,292.3646000,102.9672000,0.0000000,0.0000000,29.2200000, 1); //
    CreateDynamicObject(13592,-1427.3120000,285.9176000,102.9613000,0.0000000,0.0000000,29.2200000, 1); //
    CreateDynamicObject(13592,-1424.7782000,279.3105000,102.9262000,0.0000000,0.0000000,29.2200000, 1); //
    CreateDynamicObject(978,-1433.1239000,271.2357000,92.9468000,90.2400000,0.8586000,18.9068000, 1); //
    CreateDynamicObject(978,-1441.8000000,268.1161000,92.9611000,90.2400000,0.8586000,18.9068000, 1); //
    CreateDynamicObject(3502,-1450.4141000,264.8135000,94.7904000,0.0000000,0.0000000,111.7259000, 1); //
    CreateDynamicObject(3502,-1457.5614000,261.9041000,95.7608000,15.4690000,0.0000000,111.7259000, 1); //
    CreateDynamicObject(3502,-1465.0588000,258.9264000,97.9994000,15.4690000,0.0000000,111.7259000, 1); //
    CreateDynamicObject(3502,-1472.6351000,255.9111000,100.2496000,15.4690000,0.0000000,111.7259000, 1); //
    CreateDynamicObject(3502,-1479.8755000,253.0298000,102.4125000,15.4690000,0.0000000,111.7259000, 1); //
    CreateDynamicObject(3502,-1486.1093000,250.5503000,104.2604000,15.4690000,0.0000000,111.7259000, 1); //
    CreateDynamicObject(3502,-1493.0542000,247.7970000,104.9259000,359.1406000,358.2811000,111.7259000, 1); //
    CreateDynamicObject(3458,-1515.5295000,238.9086000,101.7790000,0.0000000,0.0000000,22.4992000, 1); //
    CreateDynamicObject(3458,-1551.7482000,223.9013000,107.6290000,0.0000000,17.1879000,22.4992000, 1); //
    CreateDynamicObject(3458,-1587.7445000,208.9849000,113.5001000,0.0000000,0.0000000,22.4992000, 1); //
    CreateDynamicObject(3458,-1597.3059000,185.9674000,113.5001000,0.0000000,0.0000000,292.4998000, 1); //
    CreateDynamicObject(13592,-1590.1340000,171.8217000,125.5992000,54.1437000,0.0000000,221.6307000, 1); //
    CreateDynamicObject(13592,-1588.1809000,167.9931000,131.3642000,54.1437000,0.0000000,221.6307000, 1); //
    CreateDynamicObject(13592,-1586.1893000,164.1618000,137.1671000,54.1437000,0.0000000,221.6307000, 1); //
    CreateDynamicObject(13592,-1584.2078000,160.3155000,142.9594000,54.1437000,0.0000000,221.6307000, 1); //
    CreateDynamicObject(18450,-1618.3466000,139.1673000,132.9482000,0.0000000,0.0000000,188.1127000, 1); //
    CreateDynamicObject(3502,-1661.9823000,132.7181000,134.8457000,0.0000000,0.0000000,280.9318000, 1); //
    CreateDynamicObject(3502,-1668.8746000,130.0312000,134.8171000,0.0000000,0.0000000,298.1206000, 1); //
    CreateDynamicObject(3502,-1674.0715000,124.8950000,134.7969000,0.0000000,0.0000000,325.6225000, 1); //
    CreateDynamicObject(3502,-1676.9863000,117.5173000,134.7515000,0.0000000,0.0000000,348.1226000, 1); //
    CreateDynamicObject(3502,-1676.2292000,110.2670000,134.7135000,0.0000000,0.0000000,18.4369000, 1); //
    CreateDynamicObject(3502,-1671.9010000,104.0859000,134.6499000,0.0000000,0.0000000,49.6058000, 1); //
    CreateDynamicObject(3502,-1665.3119000,101.4027000,134.4431000,0.0000000,0.0000000,80.7805000, 1); //
    CreateDynamicObject(3502,-1656.9816000,100.9862000,134.4451000,0.0000000,0.0000000,92.0276000, 1); //
    CreateDynamicObject(18450,-1613.3578000,106.7691000,132.4772000,0.0000000,0.0000000,188.1127000, 1); //
    CreateDynamicObject(13592,-1568.7700000,114.8223000,142.5664000,0.0000000,0.0000000,15.3945000, 1); //
    CreateDynamicObject(3458,-1542.7598000,124.0097000,130.7990000,0.0000000,0.8586000,9.5332000, 1); //
    CreateDynamicObject(971,-1520.8634000,125.6905000,134.6622000,42.1116000,6.0152000,113.4448000, 1); //
    CreateDynamicObject(971,-1519.4379000,118.2624000,135.3414000,42.1116000,6.0152000,79.6976000, 1); //
    CreateDynamicObject(18450,-1530.0110000,77.4339000,132.7756000,0.0000000,0.0000000,75.6124000, 1); //
    CreateDynamicObject(18367,-1539.7407000,39.1936000,132.6517000,0.0000000,0.0000000,345.3896000, 1); //
    CreateDynamicObject(18367,-1547.9686000,10.2316000,135.9563000,1.7180000,5.1558000,22.3445000, 1); //
    CreateDynamicObject(978,-1534.1760000,-22.4162000,138.6904000,85.9428000,0.0000000,292.4998000, 1); //
    CreateDynamicObject(978,-1528.2936000,-28.2726000,138.5715000,85.9428000,0.0000000,337.4999000, 1); //
    CreateDynamicObject(978,-1520.0652000,-28.2563000,138.5154000,85.9428000,0.0000000,22.4992000, 1); //
    CreateDynamicObject(971,-1512.1543000,-26.0511000,140.8718000,314.4499000,0.0000000,334.2169000, 1); //
    CreateDynamicObject(971,-1505.0659000,-29.4816000,140.8346000,314.4499000,0.0000000,334.2169000, 1); //
    CreateDynamicObject(3458,-1485.8580000,-43.4223000,136.8210000,0.0000000,0.0000000,330.6245000, 1); //
    CreateDynamicObject(13592,-1462.1942000,-52.2576000,148.1200000,0.0000000,0.0000000,338.9896000, 1); //
    CreateDynamicObject(3458,-1436.4250000,-59.5436000,136.7270000,0.0000000,0.0000000,335.7811000, 1); //
    CreateDynamicObject(18450,-1383.0313000,-84.2627000,137.8986000,0.0000000,0.0000000,335.7066000, 1); //
    CreateDynamicObject(18450,-1375.8707000,-87.4825000,140.8106000,0.0000000,347.1084000,335.7066000, 1); //
    CreateDynamicObject(18450,-1375.5665000,-87.6239000,142.7345000,0.0000000,335.9358000,335.7066000, 1); //
    CreateDynamicObject(18450,-1306.0597000,-119.0349000,158.9855000,0.0000000,0.0000000,335.7066000, 1); //
    CreateDynamicObject(18450,-1234.1652000,-151.5097000,158.9724000,0.0000000,0.0000000,335.7066000, 1); //
    CreateDynamicObject(18450,-1188.7202000,-174.0716000,161.8843000,0.0000000,349.6868000,328.8311000, 1); //
    CreateDynamicObject(18450,-1189.2427000,-173.7524000,163.4872000,0.0000000,341.9518000,328.8311000, 1); //
    CreateDynamicObject(18450,-1188.2627000,-174.7284000,165.1157000,0.0000000,335.9358000,327.1122000, 1); //
    CreateDynamicObject(18450,-1188.7780000,-175.0285000,165.4731000,0.0000000,332.4980000,321.9556000, 1); //
    CreateDynamicObject(18450,-1188.4125000,-175.2870000,165.9007000,0.0000000,325.6225000,321.9556000, 1); //
    CreateDynamicObject(18450,-1183.6334000,-179.0258000,170.4477000,0.0000000,319.6065000,321.9556000, 1); //
    CreateDynamicObject(18450,-1181.1272000,-181.0056000,173.7395000,0.0000000,312.7310000,321.9556000, 1); //
    CreateDynamicObject(18450,-1179.9181000,-181.9550000,175.8776000,0.0000000,303.2772000,321.9556000, 1); //
    CreateDynamicObject(18450,-1178.2118000,-183.2112000,179.5289000,0.0000000,293.8234000,321.9556000, 1); //
    CreateDynamicObject(18450,-1177.2762000,-183.9698000,185.0289000,0.0000000,280.0724000,321.9556000, 1); //
    CreateDynamicObject(18450,-1177.7494000,-183.7518000,185.2439000,0.0000000,268.0403000,313.3612000, 1); //
    CreateDynamicObject(18450,-1178.6573000,-182.9985000,191.3458000,0.0000000,259.4459000,313.3612000, 1); //
    CreateDynamicObject(18450,-1179.0327000,-182.4543000,192.7614000,0.0000000,252.5704000,313.3612000, 1); //
    CreateDynamicObject(18450,-1179.4570000,-182.0605000,193.6188000,0.0000000,244.8355000,313.3612000, 1); //
    CreateDynamicObject(18450,-1177.4917000,-184.1529000,192.1600000,0.0000000,227.6467000,313.3612000, 1); //
    CreateDynamicObject(18450,-1222.7394000,-160.1506000,190.1332000,0.0000000,0.0000000,335.7066000, 1); //
    CreateDynamicObject(3865,-1263.1746000,-144.3366000,191.9360000,0.0000000,0.0000000,95.3966000, 1); //
    CreateDynamicObject(18450,-1302.4229000,-145.1083000,170.6230000,0.0000000,330.7792000,0.6294000, 1); //
    CreateDynamicObject(18450,-1371.5422000,-145.8466000,131.9615000,0.0000000,330.7792000,0.6294000, 1); //
    CreateDynamicObject(18450,-1439.9751000,-146.5860000,93.6785000,0.0000000,330.7792000,0.6294000, 1); //
    CreateDynamicObject(1655,-1477.5842000,-143.8461000,73.6248000,324.7631000,0.0000000,89.9994000, 1); //
    CreateDynamicObject(1655,-1477.6226000,-150.1319000,73.6206000,324.7631000,0.0000000,89.9994000, 1); //
    CreateDynamicObject(1655,-1483.6510000,-150.1381000,73.4100000,344.5301000,0.0000000,89.9994000, 1); //
    CreateDynamicObject(1655,-1483.6561000,-143.8543000,73.4011000,344.5301000,0.0000000,89.9994000, 1); //
    CreateDynamicObject(1655,-1490.2113000,-150.1362000,75.2944000,1.7180000,0.0000000,89.9994000, 1); //
    CreateDynamicObject(1655,-1490.1979000,-143.8583000,75.2783000,1.7180000,0.0000000,89.9994000, 1); //
    CreateDynamicObject(1655,-1494.5361000,-150.1142000,77.9074000,18.9068000,0.0000000,89.9994000, 1); //
    CreateDynamicObject(1655,-1494.5234000,-143.8307000,77.8810000,18.9068000,0.0000000,89.9994000, 1); //
    CreateDynamicObject(1655,-1499.2264000,-150.1168000,83.3669000,34.3766000,0.0000000,89.9994000, 1); //
    CreateDynamicObject(1655,-1499.2256000,-143.8392000,83.3539000,34.3766000,0.0000000,89.9994000, 1); //
    CreateDynamicObject(1655,-1479.9207000,318.2781000,53.5645000,5.1558000,28.3606000,239.6789000, 1); //
    CreateDynamicObject(1655,-1589.8204000,168.0965000,115.5950000,5.1558000,28.3606000,158.0324000, 1); //
    print("[Gamemode::Objects]: Bike Skills 1 objects has been loaded.");

	CreateDynamicObject(13592,836.1622310,-2065.0322270,23.5491640,318.7470000,356.5623000,11.2500000, 1); //
    CreateDynamicObject(13592,836.2541500,-2070.2180180,28.0386100,318.7470000,356.5623000,11.2500000, 1); //
    CreateDynamicObject(13592,836.2667850,-2075.5659180,32.5571750,318.7470000,356.5623000,11.2500000, 1); //
    CreateDynamicObject(13592,836.2958980,-2080.8793950,37.0570260,318.7470000,356.5623000,11.2500000, 1); //
    CreateDynamicObject(13592,836.3429570,-2085.3708500,40.8990250,318.7470000,356.5623000,11.2500000, 1); //
    CreateDynamicObject(13592,836.4059450,-2090.3129880,45.0812840,318.7470000,356.5623000,11.2500000, 1); //
    CreateDynamicObject(13592,836.3270260,-2095.0119630,48.9378090,318.7470000,356.5623000,5.2339000, 1); //
    CreateDynamicObject(13592,835.7269290,-2099.6628420,52.7425460,318.7470000,356.5623000,356.6395000, 1); //
    CreateDynamicObject(13592,834.2881470,-2104.4348140,56.5331840,318.7470000,356.5623000,347.1857000, 1); //
    CreateDynamicObject(13592,832.3843380,-2108.2939450,60.3335880,318.7470000,356.5623000,338.5914000, 1); //
    CreateDynamicObject(13592,829.8471070,-2111.8491210,64.3094480,318.7470000,356.5623000,329.1376000, 1); //
    CreateDynamicObject(13592,827.0601810,-2114.8923340,68.2342070,318.7470000,356.5623000,322.2621000, 1); //
    CreateDynamicObject(13592,814.0044560,-2119.2097170,69.7305980,0.0000000,0.0000000,315.0000000, 1); //
    CreateDynamicObject(13592,808.5905150,-2123.3459470,69.6855010,0.0000000,0.0000000,315.0000000, 1); //
    CreateDynamicObject(13592,803.1182250,-2127.5485840,69.6336750,0.0000000,0.0000000,315.0000000, 1); //
    CreateDynamicObject(13592,797.5533450,-2131.7641600,69.5989070,0.0000000,0.0000000,315.0000000, 1); //
    CreateDynamicObject(18450,770.1151730,-2096.3498540,59.5489650,0.0000000,0.0000000,303.7500000, 1); //
    CreateDynamicObject(13592,749.9543460,-2065.7929690,69.2633590,359.1406000,343.6707000,131.5623000, 1); //
    CreateDynamicObject(1655,740.7467040,-2060.3105470,62.7168770,11.1727000,0.0000000,33.7500000, 1); //
    CreateDynamicObject(1655,751.5987550,-2060.9692380,60.0766790,358.2811000,0.0000000,33.7500000, 1); //
    CreateDynamicObject(18450,706.7754520,-2039.6655270,61.3113100,0.0000000,0.0000000,33.7500000, 1); //
    CreateDynamicObject(18450,703.2922970,-2034.5140380,64.2232510,90.2408000,0.0000000,33.7500000, 1); //
    CreateDynamicObject(13592,678.0515750,-2068.3762210,70.9256670,0.0000000,0.0000000,217.1878000, 1); //
    CreateDynamicObject(18367,677.0086670,-2074.2419430,60.8577080,0.0000000,0.0000000,303.7500000, 1); //
    CreateDynamicObject(18367,651.9425660,-2090.9042970,64.2294310,0.0000000,0.0000000,303.7500000, 1); //
    CreateDynamicObject(13641,626.5773320,-2107.9816890,69.0705870,0.0000000,0.0000000,213.7500000, 1); //
    CreateDynamicObject(13592,606.3330690,-2125.8864750,82.4247670,0.0000000,0.0000000,219.7662000, 1); //
    CreateDynamicObject(13592,610.1948850,-2132.1748050,82.4139330,0.0000000,0.0000000,219.7662000, 1); //
    CreateDynamicObject(13592,613.7775880,-2137.9787600,82.4136890,0.0000000,0.0000000,219.7662000, 1); //
    CreateDynamicObject(13592,617.5789180,-2144.0197750,82.4104460,0.0000000,0.0000000,219.7662000, 1); //
    CreateDynamicObject(13592,620.9057620,-2149.4367680,82.4313960,0.0000000,0.0000000,219.7662000, 1); //
    CreateDynamicObject(18450,585.1787720,-2177.7141110,72.1928250,0.0000000,0.0000000,33.7500000, 1); //
    CreateDynamicObject(6052,552.8283080,-2208.7258300,74.8611760,0.0000000,0.0000000,315.0000000, 1); //
    CreateDynamicObject(6052,552.7321780,-2234.1896970,74.8633350,0.0000000,0.0000000,135.0001000, 1); //
    CreateDynamicObject(978,550.5615840,-2244.7155760,73.2580720,83.3654000,359.1406000,33.7500000, 1); //
    CreateDynamicObject(978,543.5225830,-2249.2727050,73.2623140,85.0842000,359.1406000,33.7500000, 1); //
    CreateDynamicObject(13592,536.7958370,-2253.5839840,84.4568710,18.9076000,0.0000000,130.5482000, 1); //
    CreateDynamicObject(13592,531.2724610,-2257.0527340,86.6537860,18.9076000,0.0000000,130.5482000, 1); //
    CreateDynamicObject(13592,525.3175660,-2260.8332520,88.9846040,18.9076000,0.0000000,130.5482000, 1); //
    CreateDynamicObject(18450,491.6936040,-2227.4860840,80.1039430,0.0000000,0.0000000,303.7500000, 1); //
    CreateDynamicObject(18450,448.1901550,-2162.3864750,80.0658870,0.0000000,0.0000000,303.7500000, 1); //
    CreateDynamicObject(1655,424.9264530,-2127.6269530,81.3597260,0.0000000,0.0000000,33.7500000, 1); //
    CreateDynamicObject(1655,421.1477660,-2121.9626460,85.7925110,20.6265000,0.0000000,33.7500000, 1); //
    CreateDynamicObject(1655,418.5566710,-2118.0798340,92.3772960,42.1124000,0.0000000,33.7500000, 1); //
    CreateDynamicObject(1655,417.5028380,-2116.5056150,100.2018280,64.4577000,0.0000000,33.7500000, 1); //
    CreateDynamicObject(1655,417.9870000,-2117.2041020,108.3361130,81.6464000,0.0000000,33.7500000, 1); //
    CreateDynamicObject(1655,419.8135380,-2119.9174800,115.9668960,98.8352000,0.0000000,33.7500000, 1); //
    CreateDynamicObject(18450,446.9006040,-2161.1665040,107.9710080,0.0000000,0.0000000,303.7500000, 1); //
    CreateDynamicObject(13641,471.3910520,-2197.7712400,109.8839950,0.0000000,0.0000000,303.7500000, 1); //
    CreateDynamicObject(18450,514.7814330,-2263.1479490,110.9491420,0.0000000,0.0000000,303.7500000, 1); //
    CreateDynamicObject(1225,479.7650150,-2207.4511720,114.0015950,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,483.7211000,-2204.9704590,120.3834000,90.2409000,0.0000000,320.4659000, 1); //
    CreateDynamicObject(1225,474.6252750,-2210.7463380,120.4808880,90.2409000,0.0000000,320.4659000, 1); //
    CreateDynamicObject(1655,538.2375490,-2298.0803220,112.2679820,0.0000000,0.0000000,213.7501000, 1); //
    CreateDynamicObject(1655,542.2205200,-2304.0295410,116.7839200,18.9076000,0.0000000,213.7501000, 1); //
    CreateDynamicObject(1655,545.0706180,-2308.3251950,123.2199630,37.8152000,0.0000000,213.7501000, 1); //
    CreateDynamicObject(1655,546.3931880,-2310.3071290,131.3262330,62.7388000,0.0000000,213.7501000, 1); //
    CreateDynamicObject(1655,545.8032230,-2309.4614260,139.6380620,85.0842000,0.0000000,213.7501000, 1); //
    CreateDynamicObject(1655,543.3994140,-2305.8767090,147.0870510,108.2889000,0.0000000,213.7501000, 1); //
    CreateDynamicObject(18450,518.0454100,-2268.0029300,132.8323820,0.0000000,0.0000000,303.7500000, 1); //
    CreateDynamicObject(1655,493.9266970,-2231.9870610,133.9762420,0.0000000,0.0000000,33.7500000, 1); //
    CreateDynamicObject(1655,491.6593630,-2228.5793460,136.4824830,15.4699000,0.0000000,33.7500000, 1); //
    CreateDynamicObject(18450,460.8605960,-2182.4843750,139.8044890,0.0000000,0.0000000,303.7500000, 1); //
    CreateDynamicObject(1225,492.2643130,-2237.4841310,133.3319550,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,499.8855590,-2232.4392090,133.1819310,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(13592,436.3114930,-2149.7231450,149.7189030,0.0000000,0.0000000,129.7661000, 1); //
    CreateDynamicObject(969,441.7087710,-2148.7639160,140.4967800,0.0000000,0.0000000,337.5000000, 1); //
    CreateDynamicObject(18450,406.8594060,-2114.3776860,139.5163420,0.0000000,0.0000000,303.7500000, 1); //
    CreateDynamicObject(1225,617.0222170,-2116.7006840,73.1920320,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,615.6279910,-2114.3718260,73.2046510,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,478.0705570,-2208.6159670,114.0302730,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,442.0620730,-2158.5566410,140.5040130,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(18450,362.6340940,-2048.1694340,139.5033870,0.0000000,0.0000000,303.7500000, 1); //
    CreateDynamicObject(13592,339.5614010,-2010.5354000,149.3179470,0.0000000,0.0000000,39.7662000, 1); //
    CreateDynamicObject(13592,335.7479250,-2004.4259030,149.2660520,0.0000000,0.0000000,39.7662000, 1); //
    CreateDynamicObject(13592,332.0532840,-1998.5595700,149.1676790,0.0000000,0.0000000,39.7662000, 1); //
    CreateDynamicObject(13592,329.9021000,-1994.1333010,148.9617920,0.0000000,0.0000000,33.7502000, 1); //
    CreateDynamicObject(13592,327.7428590,-1988.3116460,148.4205780,0.0000000,0.0000000,26.8747000, 1); //
    CreateDynamicObject(13592,326.0603940,-1982.9000240,148.2221530,0.0000000,0.0000000,18.2804000, 1); //
    CreateDynamicObject(13592,325.4433590,-1978.5592040,148.1854400,0.0000000,0.0000000,7.1078000, 1); //
    CreateDynamicObject(13592,325.7138670,-1972.6363530,148.1492610,0.0000000,0.0000000,358.5135000, 1); //
    CreateDynamicObject(13592,326.1387940,-1968.8116460,148.1245270,0.0000000,0.0000000,346.4815000, 1); //
    CreateDynamicObject(13592,328.5740360,-1963.5478520,148.0652160,0.0000000,0.0000000,337.8872000, 1); //
    CreateDynamicObject(13592,331.5780330,-1958.8178710,147.9854430,0.0000000,0.0000000,330.1524000, 1); //
    CreateDynamicObject(13592,334.0914610,-1955.4321290,147.7849270,0.0000000,0.0000000,316.4015000, 1); //
    CreateDynamicObject(13592,337.0014340,-1953.0174560,147.6433870,0.0000000,0.0000000,310.3855000, 1); //
    CreateDynamicObject(18450,373.6827700,-1934.0108640,137.6764980,0.0000000,0.0000000,213.7500000, 1); //
    CreateDynamicObject(18450,437.7957150,-1891.1817630,137.7134700,0.0000000,0.0000000,213.7500000, 1); //
    CreateDynamicObject(13641,397.1915590,-1917.9721680,139.5895230,0.0000000,0.0000000,32.8906000, 1); //
    CreateDynamicObject(971,387.7517090,-1917.5616460,141.5151820,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(971,393.9819030,-1926.9348140,141.5404210,0.0000000,0.0000000,247.5000000, 1); //
    CreateDynamicObject(1655,469.9703370,-1869.6459960,139.0572810,0.0000000,0.0000000,303.7500000, 1); //
    CreateDynamicObject(1655,472.1872560,-1868.1895750,140.7989350,13.7510000,0.0000000,303.7500000, 1); //
    CreateDynamicObject(1225,406.7163390,-1909.5544430,143.6907200,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,408.0376890,-1911.5897220,143.7096560,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,472.1824950,-1863.3089600,143.6625520,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,476.7991030,-1870.0433350,143.4823760,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(971,790.9880370,-2135.5568850,63.0413550,0.0000000,0.0000000,308.5200000, 1); //
    print("[Gamemode::Objects]: Bike Skills 2 objects has been loaded.");

	CreateDynamicObject(18450,1334.1573490,-1203.1503910,201.0937960,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(18450,1328.2165530,-1172.9417720,201.1056520,0.0000000,0.0000000,22.5000000, 1); //
    CreateDynamicObject(18450,1311.0499270,-1147.3566890,200.9927830,0.0000000,0.0000000,45.0000000, 1); //
    CreateDynamicObject(18450,1285.5004880,-1130.2486570,201.0546880,0.0000000,0.0000000,67.5000000, 1); //
    CreateDynamicObject(18450,1255.3553470,-1124.1196290,201.0419160,0.0000000,0.0000000,90.0000000, 1); //
    CreateDynamicObject(18450,1225.2097170,-1130.0417480,201.0559390,0.0000000,0.0000000,112.5000000, 1); //
    CreateDynamicObject(18450,1199.5729980,-1147.0462650,201.0682830,0.0000000,0.0000000,135.0000000, 1); //
    CreateDynamicObject(18450,1182.4886470,-1172.7047120,201.0552060,0.0000000,0.0000000,157.5000000, 1); //
    CreateDynamicObject(18450,1176.4324950,-1202.9119870,201.0169530,0.0000000,0.0000000,180.0000000, 1); //
    CreateDynamicObject(18450,1182.4202880,-1233.1121830,201.0041200,0.0000000,0.0000000,202.5000000, 1); //
    CreateDynamicObject(18450,1199.4677730,-1258.7353520,200.9911040,0.0000000,0.0000000,225.0000000, 1); //
    CreateDynamicObject(18450,1225.0366210,-1275.8363040,200.9533390,0.0000000,0.0000000,247.5000000, 1); //
    CreateDynamicObject(18450,1255.2558590,-1281.7983400,200.9408720,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(18450,1285.4309080,-1275.7875980,200.9279790,0.0000000,0.0000000,292.5001000, 1); //
    CreateDynamicObject(18450,1311.0552980,-1258.7435300,200.9150240,0.0000000,0.0000000,315.0000000, 1); //
    CreateDynamicObject(18450,1328.1965330,-1233.2288820,200.9017640,0.0000000,0.0000000,337.5000000, 1); //
    CreateDynamicObject(8357,1277.0596920,-1211.3990480,201.1670380,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(8357,1233.8336180,-1211.0820310,201.2051090,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(8357,1260.3514400,-1224.4481200,201.1957700,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(8357,1260.4766850,-1181.0628660,201.1457820,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(3502,1255.3043210,-1202.6945800,203.2180940,272.3375000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(2931,1295.5673830,-1203.2231450,201.3959810,0.0000000,0.0000000,89.1405000, 1); //
    CreateDynamicObject(1245,1293.0255130,-1217.5014650,202.5831300,0.0000000,0.0000000,337.5000000, 1); //
    CreateDynamicObject(1503,1284.8059080,-1232.6573490,201.4779360,0.0000000,0.0000000,45.0000000, 1); //
    CreateDynamicObject(1631,1296.9700930,-1187.1638180,201.6882320,0.0000000,0.0000000,112.5000000, 1); //
    CreateDynamicObject(1632,1287.2735600,-1171.0189210,202.4116970,0.0000000,0.0000000,135.0000000, 1); //
    CreateDynamicObject(1634,1255.1773680,-1158.2468260,202.4580380,0.0000000,0.0000000,180.0000000, 1); //
    CreateDynamicObject(1660,1274.9678960,-1155.3789060,201.1457370,0.0000000,0.0000000,157.5000000, 1); //
    CreateDynamicObject(1697,1238.3574220,-1161.7012940,202.5766750,0.0000000,0.0000000,22.5000000, 1); //
    CreateDynamicObject(1697,1237.4993900,-1159.6157230,201.4733430,14.6104000,0.0000000,22.5000000, 1); //
    CreateDynamicObject(1655,1222.7431640,-1170.2351070,202.4622040,0.0000000,0.0000000,225.0000000, 1); //
    CreateDynamicObject(16401,1214.6209720,-1186.3441160,201.3178710,0.0000000,0.0000000,337.5000000, 1); //
    CreateDynamicObject(8302,1208.4647220,-1202.8740230,203.1110530,0.0000000,0.0000000,285.5472000, 1); //
    CreateDynamicObject(13593,1214.9473880,-1218.1353760,202.0907290,0.0000000,0.0000000,292.5000000, 1); //
    CreateDynamicObject(13593,1216.0446780,-1220.5581050,202.0979610,0.0000000,0.0000000,292.5000000, 1); //
    CreateDynamicObject(13593,1217.3836670,-1217.0476070,203.4833530,15.4699000,0.0000000,292.5000000, 1); //
    CreateDynamicObject(13593,1218.4512940,-1219.5096440,203.5036160,15.4699000,0.0000000,292.5000000, 1); //
    CreateDynamicObject(13641,1220.8874510,-1237.3640140,202.8291470,0.0000000,0.0000000,43.2811000, 1); //
    CreateDynamicObject(16367,1239.2050780,-1243.8417970,202.9060060,0.0000000,0.0000000,247.5000000, 1); //
    CreateDynamicObject(1633,1255.2529300,-1240.8631590,202.3304750,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1633,1255.2501220,-1234.7696530,204.3937380,4.2972000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(18451,1270.9803470,-1241.1020510,201.7591550,0.0000000,0.0000000,23.3594000, 1); //
    CreateDynamicObject(3502,1255.5994870,-1202.6417240,194.4091950,272.3375000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(3502,1255.9202880,-1202.6411130,186.5337220,272.3375000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(17310,1257.0214840,-1202.2420650,171.7306980,182.9559000,70.4738000,343.6707000, 1); //
    CreateDynamicObject(17310,1257.0611570,-1197.0479740,171.1692960,182.9559000,70.4738000,12.0321000, 1); //
    CreateDynamicObject(17310,1254.3195800,-1190.2995610,171.7084200,182.9559000,70.4738000,27.5020000, 1); //
    CreateDynamicObject(17310,1252.9531250,-1210.1350100,171.3619230,182.9559000,70.4738000,317.8876000, 1); //
    CreateDynamicObject(17310,1250.4310300,-1185.9500730,171.1978910,182.9559000,70.4738000,48.1284000, 1); //
    CreateDynamicObject(17310,1248.4245610,-1214.3929440,170.9305270,182.9559000,70.4738000,304.9961000, 1); //
    CreateDynamicObject(17310,1243.3216550,-1217.5018310,170.9897460,182.9559000,70.4738000,290.3857000, 1); //
    CreateDynamicObject(17310,1235.1251220,-1219.2553710,170.7727360,182.9559000,70.4738000,266.3215000, 1); //
    CreateDynamicObject(17310,1225.1508790,-1217.3873290,170.3877720,182.9559000,70.4738000,247.4139000, 1); //
    CreateDynamicObject(17310,1243.6860350,-1181.8702390,170.9729770,182.9559000,70.4738000,66.1766000, 1); //
    CreateDynamicObject(17310,1238.2989500,-1180.6761470,170.7115780,182.9559000,70.4738000,89.3814000, 1); //
    CreateDynamicObject(17310,1230.2203370,-1181.4471440,170.9109190,182.9559000,70.4738000,103.9918000, 1); //
    CreateDynamicObject(17310,1221.6331790,-1185.4442140,170.6802220,182.9559000,70.4738000,124.6183000, 1); //
    CreateDynamicObject(17310,1215.4508060,-1191.3747560,171.0735320,182.9559000,70.4738000,145.2449000, 1); //
    CreateDynamicObject(17310,1211.7333980,-1200.9704590,171.2334900,182.9559000,70.4738000,170.1688000, 1); //
    CreateDynamicObject(17310,1217.7304690,-1212.8642580,170.1501460,182.9559000,70.4738000,226.0323000, 1); //
    CreateDynamicObject(17310,1213.3942870,-1208.5493160,169.9919590,182.9559000,70.4738000,209.7029000, 1); //
    CreateDynamicObject(1225,1227.1362300,-1196.4801030,158.8442690,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,1236.7019040,-1201.5412600,159.0736080,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,1224.3719480,-1200.1723630,157.6844790,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,1224.7719730,-1202.6976320,159.2594300,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,1232.0130620,-1198.8526610,159.2867430,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,1227.7274170,-1204.2238770,158.6155550,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,1231.2275390,-1202.9738770,158.6155400,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,1235.1069340,-1207.4008790,158.3500210,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,1227.8569340,-1199.9008790,158.3500210,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,1238.8569340,-1204.9008790,158.3500210,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,1241.6069340,-1197.9008790,158.3500210,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,1236.6069340,-1195.1508790,158.3500210,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,1232.1069340,-1193.6508790,158.3500210,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,1234.8569340,-1204.1508790,158.3500210,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,1231.1069340,-1206.8010250,158.3500210,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,1243.4243160,-1201.8131100,158.4095000,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,1241.2469480,-1194.2421880,157.7960360,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,1240.9481200,-1201.8972170,156.1403960,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,1229.8032230,-1196.4940190,158.5145570,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(980,1146.8750000,-1157.9124760,204.1723480,0.0000000,0.0000000,247.5000000, 1); //
    CreateDynamicObject(980,1137.4525150,-1202.8242190,204.1091000,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(980,1145.9163820,-1248.2086180,204.0962680,0.0000000,0.0000000,292.5000000, 1); //
    CreateDynamicObject(980,1171.3662110,-1286.7093510,204.1082460,0.0000000,0.0000000,315.0000000, 1); //
    CreateDynamicObject(980,1209.9102780,-1312.4359130,204.0704800,0.0000000,0.0000000,337.5000000, 1); //
    CreateDynamicObject(980,1255.3470460,-1321.5035400,204.0580140,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(980,1300.4971920,-1312.2954100,204.0451200,0.0000000,0.0000000,22.5000000, 1); //
    CreateDynamicObject(980,1339.0596920,-1286.7937010,204.0321660,0.0000000,0.0000000,45.0000000, 1); //
    CreateDynamicObject(980,1364.8244630,-1248.3475340,204.0189060,0.0000000,0.0000000,67.5000000, 1); //
    CreateDynamicObject(980,1364.6782230,-1157.7637940,204.1978000,0.0000000,0.0000000,112.5000000, 1); //
    CreateDynamicObject(980,1339.0958250,-1119.2645260,204.1849060,0.0000000,0.0000000,135.0000000, 1); //
    CreateDynamicObject(980,1300.7039790,-1093.6425780,204.1468350,0.0000000,0.0000000,157.5000000, 1); //
    CreateDynamicObject(980,1255.2944340,-1084.3236080,204.1340640,0.0000000,0.0000000,180.0000000, 1); //
    CreateDynamicObject(980,1210.0983890,-1093.3403320,204.1480870,0.0000000,0.0000000,202.5000000, 1); //
    CreateDynamicObject(980,1171.4089360,-1119.2468260,204.1604310,0.0000000,0.0000000,225.0000000, 1); //
    CreateDynamicObject(672,1322.4119870,-1215.3251950,201.9609830,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(672,1322.8331300,-1189.8278810,201.9109950,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(672,1312.2218020,-1164.6094970,201.8860020,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(672,1292.6896970,-1147.0509030,201.9322510,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(672,1269.9130860,-1131.5102540,201.9244380,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(672,1241.1337890,-1127.8535160,201.9453280,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(672,1216.3215330,-1141.6666260,201.8875270,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(672,1197.9694820,-1164.8820800,201.8282010,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(672,1186.5489500,-1187.4577640,201.7282260,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(672,1186.5764160,-1215.6165770,201.8860020,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(672,1199.0819090,-1239.8830570,201.8781890,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(672,1218.0416260,-1259.2347410,201.8125460,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(672,1241.6220700,-1270.8697510,201.8875270,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(672,1269.0859380,-1272.8154300,201.8744510,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(672,1293.2857670,-1260.6776120,201.8994450,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(672,1311.9750980,-1239.1094970,201.9281770,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(619,1374.9241940,-1216.3723140,201.3197780,0.0000000,0.0000000,247.5000000, 1); //
    CreateDynamicObject(619,1374.9224850,-1190.1291500,201.5947110,0.0000000,0.0000000,56.2500000, 1); //
    CreateDynamicObject(13666,1366.8449710,-1203.6665040,204.3430790,0.0000000,0.0000000,7.8122000, 1); //
    CreateDynamicObject(13666,1351.5450440,-1203.6239010,204.3429570,0.0000000,0.0000000,7.8122000, 1); //
    CreateDynamicObject(13666,1334.0631100,-1203.6231690,204.3179630,0.0000000,0.0000000,7.8122000, 1); //
    CreateDynamicObject(13666,1317.2237550,-1203.6171880,204.3179020,0.0000000,0.0000000,7.8122000, 1); //
    CreateDynamicObject(13666,1301.5202640,-1203.5603030,204.3430180,0.0000000,0.0000000,7.8122000, 1); //
    CreateDynamicObject(1225,1228.9250490,-1201.7248540,158.3696140,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,1233.6500240,-1200.7248540,158.6445470,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,1236.4250490,-1198.4748540,158.2695770,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,1237.8706050,-1192.6324460,157.1889500,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,1233.9655760,-1195.9516600,159.3809360,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,1234.9653320,-1192.4515380,158.2310940,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,1242.1340330,-1203.8918460,158.6544950,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,1239.0496830,-1195.7558590,156.4938350,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,1245.7822270,-1197.7736820,157.1431120,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,1238.7867430,-1201.8048100,158.5916440,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,1239.5156250,-1198.3085940,157.6506650,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,1243.6490480,-1196.1247560,157.9898070,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1225,1245.0769040,-1200.8496090,157.3572850,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3502,1254.9114990,-1202.5841060,177.9737400,254.2893000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(3502,1251.8024900,-1202.5944820,170.2513280,240.5382000,0.0000000,270.0000000, 1); //
    print("[Gamemode::Objects]: NRG basket ball objects has been loaded.");

	CreateDynamicObject(4867,-2496.5031740,1493.9351810,6.2120460,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(4867,-2283.9257810,1493.9425050,6.2340030,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(4867,-2643.2680660,1540.5054930,6.2090010,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1655,-2593.5202640,1495.3034670,6.4371590,-9.4538036,0.0000000,86.8031060, 1); //
    CreateDynamicObject(1655,-2601.0451660,1495.7286380,9.7163730,10.3132403,0.0000000,86.8031060, 1); //
    CreateDynamicObject(1655,-2607.0021970,1496.0587160,15.5543650,31.7991576,0.0000000,86.8031060, 1); //
    CreateDynamicObject(1655,-2611.1386720,1496.2954100,23.0875840,45.5500874,0.0000000,86.8031060, 1); //
    CreateDynamicObject(1655,-2612.8593750,1496.3839110,31.3930090,65.3171313,0.0000000,86.8031060, 1); //
    CreateDynamicObject(1655,-2611.9443360,1496.3300780,39.8606870,81.6464285,0.0000000,86.8031060, 1); //
    CreateDynamicObject(1655,-2608.0668950,1496.1152340,47.6852990,104.8511619,0.0000000,86.8031060, 1); //
    CreateDynamicObject(1655,-2602.2678220,1495.8277590,53.2077220,122.8993898,0.0000000,86.8031060, 1); //
    CreateDynamicObject(1655,-2594.5878910,1495.3942870,56.5468180,144.3854790,0.0000000,86.8031060, 1); //
    CreateDynamicObject(5400,-2491.7504880,1378.0659180,16.1956830,-1.7188734,13.7509871,-269.0035129, 1); //
    CreateDynamicObject(5400,-2491.4694820,1368.9326170,16.3206880,0.0000000,11.1726770,-269.0035129, 1); //
    CreateDynamicObject(13592,-2436.1032710,1443.4312740,16.5326540,54.1444543,-0.8594367,-77.3493023, 1); //
    CreateDynamicObject(13592,-2431.6721190,1443.2613530,22.4652730,54.1444543,-0.8594367,-77.3493023, 1); //
    CreateDynamicObject(13592,-2427.2548830,1443.1115720,28.3538440,54.1444543,-0.8594367,-77.3493023, 1); //
    CreateDynamicObject(13592,-2422.8999020,1442.9674070,34.2181020,54.1444543,-0.8594367,-77.3493023, 1); //
    CreateDynamicObject(13592,-2418.6052250,1442.8389890,40.0085750,54.1444543,-0.8594367,-77.3493023, 1); //
    CreateDynamicObject(13592,-2414.4890140,1442.6900630,45.4908750,54.1444543,-0.8594367,-77.3493023, 1); //
    CreateDynamicObject(13592,-2410.0278320,1442.5438230,51.4561160,54.1444543,-0.8594367,-77.3493023, 1); //
    CreateDynamicObject(13592,-2405.9660640,1442.4357910,56.9433670,54.1444543,-0.8594367,-77.3493023, 1); //
    CreateDynamicObject(13592,-2401.8090820,1442.3204350,62.5584490,54.1444543,-0.8594367,-77.3493023, 1); //
    CreateDynamicObject(4113,-2385.2404790,1421.1894530,19.5126080,0.0000000,0.0000000,25.7831008, 1); //
    CreateDynamicObject(18450,-2440.8027340,1410.9107670,65.1072540,0.0000000,14.6104238,12.8915504, 1); //
    CreateDynamicObject(18450,-2410.7983400,1417.7807620,57.1198880,0.0000000,8.5943669,12.8915504, 1); //
    CreateDynamicObject(3458,-2498.1586910,1397.9890140,74.0217740,0.0000000,0.0000000,12.8915504, 1); //
    CreateDynamicObject(3458,-2536.6745610,1389.1776120,74.0217740,0.0000000,0.0000000,12.8915504, 1); //
    CreateDynamicObject(3458,-2562.2016600,1401.3109130,74.0218350,0.0000000,0.0000000,-74.7709923, 1); //
    CreateDynamicObject(3458,-2556.8154300,1435.7209470,74.0218510,0.0000000,0.0000000,-122.0400677, 1); //
    CreateDynamicObject(18450,-2539.9299320,1461.5271000,78.1185150,0.0000000,14.6104238,-122.8995044, 1); //
    CreateDynamicObject(18450,-2497.3090820,1527.3836670,87.5721050,0.0000000,-0.8594367,-122.8995044, 1); //
    CreateDynamicObject(13592,-2470.2592770,1565.7678220,96.4591830,0.0000000,4.2971835,-28.3614109, 1); //
    CreateDynamicObject(13592,-2466.0681150,1571.3634030,96.3940050,0.0000000,4.2971835,-28.3614109, 1); //
    CreateDynamicObject(13592,-2464.3518070,1573.5769040,96.4302060,0.0000000,4.2971835,-30.9397209, 1); //
    CreateDynamicObject(13592,-2460.5632320,1578.0975340,96.0383380,0.0000000,4.2971835,-37.8152145, 1); //
    CreateDynamicObject(13592,-2456.0061040,1581.8138430,96.1411970,0.0000000,4.2971835,-45.5501447, 1); //
    CreateDynamicObject(13592,-2451.6511230,1584.3779300,95.9541930,0.0000000,4.2971835,-53.2850177, 1); //
    CreateDynamicObject(13592,-2445.9738770,1587.1978760,95.6610790,0.0000000,4.2971835,-59.3010745, 1); //
    CreateDynamicObject(13592,-2440.6452640,1589.2293700,95.5009840,0.0000000,4.2971835,-68.7548781, 1); //
    CreateDynamicObject(13592,-2435.2758790,1590.3594970,95.3905940,0.0000000,4.2971835,-78.2086817, 1); //
    CreateDynamicObject(13592,-2430.0578610,1590.3496090,95.3244550,0.0000000,4.2971835,-89.3813587, 1); //
    CreateDynamicObject(13592,-2423.9716800,1589.3477780,95.1942440,0.0000000,4.2971835,-96.2568523, 1); //
    CreateDynamicObject(13592,-2418.8469240,1587.6828610,95.0493010,0.0000000,4.2971835,-107.4295293, 1); //
    CreateDynamicObject(13592,-2414.1726070,1585.2645260,94.9070360,0.0000000,4.2971835,-119.4616430, 1); //
    CreateDynamicObject(13592,-2410.3159180,1582.1010740,94.5133670,0.0000000,4.2971835,-127.1966305, 1); //
    CreateDynamicObject(3458,-2421.5227050,1559.3085940,82.9285960,0.0000000,0.0000000,-127.1966878, 1); //
    CreateDynamicObject(3458,-2444.5236820,1529.0140380,91.0036010,0.0000000,-24.0642274,-127.1966878, 1); //
    CreateDynamicObject(3458,-2466.6896970,1499.8070070,107.3819890,0.0000000,-24.0642274,-127.1966878, 1); //
    CreateDynamicObject(3458,-2489.6423340,1469.5736080,117.8911440,0.0000000,-6.8754935,-127.1966878, 1); //
    CreateDynamicObject(3865,-2509.7131350,1443.1402590,123.2767330,0.0000000,0.0000000,-37.8152145, 1); //
    CreateDynamicObject(978,-2504.4260250,1450.0953370,121.7120440,82.5058652,0.0000000,52.4256383, 1); //
    CreateDynamicObject(3865,-2514.8171390,1436.7025150,123.2835920,0.0000000,0.0000000,-37.8152145, 1); //
    CreateDynamicObject(3865,-2519.9450680,1430.1928710,124.1894840,-12.0321137,0.0000000,-37.8152145, 1); //
    CreateDynamicObject(3865,-2525.0810550,1423.7291260,125.9427800,-12.0321137,0.0000000,-37.8152145, 1); //
    CreateDynamicObject(18450,-2549.7548830,1386.6208500,124.4860080,0.0000000,0.8594367,-122.8995044, 1); //
    CreateDynamicObject(1655,-2577.2175290,1352.2241210,125.1857070,-0.8594367,0.0000000,-213.9999084, 1); //
    CreateDynamicObject(1655,-2570.1127930,1347.4254150,125.1839830,-0.8594367,0.0000000,-213.9999084, 1); //
    CreateDynamicObject(1655,-2352.5817870,1436.0217290,7.2091120,0.0000000,0.0000000,101.4135297, 1); //
    CreateDynamicObject(1655,-2359.2216800,1434.6837160,11.2850230,17.1887339,0.0000000,101.4135297, 1); //
    CreateDynamicObject(1655,-2364.0500490,1433.7171630,16.9398160,35.2369044,0.0000000,101.4135297, 1); //
    CreateDynamicObject(1655,-2367.0563960,1433.1103520,23.8138680,51.5661443,0.0000000,101.4135297, 1); //
    CreateDynamicObject(1655,-2368.3015140,1432.8969730,31.4308990,65.3171313,0.0000000,100.5540930, 1); //
    CreateDynamicObject(1655,-2440.1262210,1525.7668460,14.5371600,32.6585943,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1655,-2440.1306150,1520.7487790,9.1121540,16.3292972,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1655,-2440.1469730,1515.9896240,6.4638530,-4.2971835,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1655,-2448.9057620,1515.9931640,6.4621550,-4.2971835,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1655,-2448.9055180,1520.2347410,8.5904450,16.3292972,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1655,-2448.8872070,1525.6955570,14.4048540,32.6585943,0.0000000,0.0000000, 1); //
    CreateDynamicObject(18450,-2568.2629390,1560.4854740,5.0271910,0.0000000,5.1566202,0.0000000, 1); //
    CreateDynamicObject(18450,-2603.0034180,1560.5151370,9.9002140,0.0000000,13.7509871,0.0000000, 1); //
    CreateDynamicObject(18450,-2605.3464360,1560.5061040,12.0436310,0.0000000,22.3453540,0.0000000, 1); //
    CreateDynamicObject(18450,-2606.3479000,1560.5225830,13.5351500,0.0000000,31.7991576,0.0000000, 1); //
    CreateDynamicObject(18450,-2608.2297360,1560.4881590,15.3340790,0.0000000,41.2529612,0.0000000, 1); //
    CreateDynamicObject(18450,-2611.3540040,1560.5052490,18.6658590,0.0000000,53.2850177,0.0000000, 1); //
    CreateDynamicObject(18450,-2613.6804200,1560.5246580,21.5761380,0.0000000,62.7388213,0.0000000, 1); //
    CreateDynamicObject(18450,-2616.7355960,1560.5184330,26.4092750,0.0000000,73.0520616,0.0000000, 1); //
    CreateDynamicObject(18450,-2618.7031250,1560.4929200,31.6827620,0.0000000,84.2247386,0.0000000, 1); //
    CreateDynamicObject(18450,-2619.1533200,1560.5301510,43.6055870,0.0000000,92.8191055,0.0000000, 1); //
    CreateDynamicObject(18450,-2618.7165530,1560.5064700,48.0521350,0.0000000,99.6945991,0.0000000, 1); //
    CreateDynamicObject(18450,-2617.7099610,1560.5211180,53.0072560,0.0000000,108.2889087,0.0000000, 1); //
    CreateDynamicObject(18450,-2614.5441890,1560.5345460,60.8043060,0.0000000,115.1644022,0.0000000, 1); //
    CreateDynamicObject(18450,-2615.2895510,1560.5175780,59.8561670,0.0000000,122.8993898,0.0000000, 1); //
    CreateDynamicObject(18450,-2612.4550780,1560.5358890,64.6655580,0.0000000,132.3532507,0.0000000, 1); //
    CreateDynamicObject(18450,-2604.4982910,1560.5206300,72.4623570,0.0000000,141.8071689,0.0000000, 1); //
    CreateDynamicObject(18450,-2603.6794430,1560.5390630,73.0935060,0.0000000,152.9799032,0.0000000, 1); //
    CreateDynamicObject(18450,-2604.1130370,1560.5397950,73.4682160,0.0000000,160.7148907,0.0000000, 1); //
    CreateDynamicObject(18450,-2599.7875980,1560.5541990,75.7778700,0.0000000,172.7470617,0.0000000, 1); //
    CreateDynamicObject(18450,-2593.4213870,1560.2679440,76.8824770,0.0000000,179.6226125,6.0160568, 1); //
    CreateDynamicObject(18450,-2586.9331050,1560.9531250,77.1167830,0.0000000,187.3576001,6.0160568, 1); //
    CreateDynamicObject(17565,-2241.9597170,1462.3365480,8.2177210,0.0000000,0.0000000,-92.8191628, 1); //
    CreateDynamicObject(16304,-2291.1540530,1518.8953860,11.1942910,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(16304,-2272.3969730,1515.1809080,11.4192840,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(16304,-2280.8518070,1529.3562010,11.4192840,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(16304,-2283.6628420,1508.6931150,11.4441780,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(13641,-2331.4987790,1466.7023930,7.6532460,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(13636,-2285.3747560,1450.6502690,8.2143990,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(13604,-2231.2827150,1528.2584230,7.8670200,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(13590,-2210.4218750,1469.4346920,7.3348450,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(12956,-2520.4504390,1449.9765630,9.3402880,0.0000000,0.0000000,3.4377468, 1); //
    CreateDynamicObject(8375,-2375.9951170,1489.6723630,8.1427460,0.0000000,0.0000000,-91.1002894, 1); //
    CreateDynamicObject(1681,-2552.4895020,1422.1816410,10.6900710,30.9397209,-0.8594367,34.3774677, 1); //
    CreateDynamicObject(3627,-2446.7797850,1416.5800780,9.9515340,0.0000000,0.0000000,-127.1966878, 1); //
    CreateDynamicObject(1632,-2476.2133790,1444.6389160,7.2371570,0.0000000,0.0000000,-132.3534226, 1); //
    CreateDynamicObject(1632,-2472.1748050,1440.9505620,10.2328850,12.0321137,0.0000000,-132.3534226, 1); //
    CreateDynamicObject(8172,-2618.0632320,1645.2943120,10.7533590,0.0000000,-14.6104238,90.2408527, 1); //
    CreateDynamicObject(4867,-2644.5273440,1756.4133300,15.7715990,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(8172,-2458.4089360,1645.5327150,10.6042750,0.0000000,-14.6104238,90.2408527, 1); //
    CreateDynamicObject(4867,-2432.1140140,1756.4010010,15.7185540,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(8038,-2697.7863770,1707.5531010,35.5868760,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(8550,-2601.6037600,1716.8740230,19.7946850,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(10757,-2659.1208500,1693.4659420,18.1628720,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(10763,-2359.9140630,1701.5325930,47.5501210,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(10815,-2466.1657710,2144.3664550,-4.1131790,6.8754935,6.8754935,135.5501260, 1); //
    CreateDynamicObject(16098,-2529.9287110,1702.0512700,11.9820860,0.0000000,0.0000000,-91.1002894, 1); //
    CreateDynamicObject(1682,-2534.9206540,1736.6047360,22.1477700,0.0000000,0.0000000,-226.0320221, 1); //
    CreateDynamicObject(1655,-2684.3347170,1763.4107670,16.7217160,0.0000000,0.0000000,-204.5461620, 1); //
    CreateDynamicObject(1655,-2686.6391600,1758.3371580,20.2869830,21.4859173,0.0000000,-204.5461620, 1); //
    CreateDynamicObject(18284,-2743.9384770,1770.4642330,18.5914400,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(18284,-2743.9372560,1753.3460690,18.5914400,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(7617,-2565.8195800,1626.9177250,17.2182660,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(13592,-2658.0625000,1675.4272460,27.3422050,0.0000000,44.6907080,-19.7670439, 1); //
    CreateDynamicObject(13592,-2671.3405760,1736.4533690,27.3422050,0.0000000,44.6907080,22.3453540, 1); //
    CreateDynamicObject(1655,-2658.8508300,1679.3701170,16.6954980,0.0000000,0.0000000,69.6143721, 1); //
    CreateDynamicObject(1655,-2674.8295900,1738.9189450,16.6717170,0.0000000,0.0000000,111.7267128, 1); //
    CreateDynamicObject(1632,-2480.2861330,1698.5749510,16.6186660,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1632,-2416.1906740,1604.0295410,6.1058510,-9.4538036,0.0000000,-62.7388786, 1); //
    CreateDynamicObject(1632,-2409.6550290,1607.4002690,9.3700350,12.0321137,0.0000000,-62.7388786, 1); //
    CreateDynamicObject(1632,-2404.2138670,1610.2005620,14.8473070,26.6425375,0.0000000,-62.7388786, 1); //
    CreateDynamicObject(1632,-2400.6623540,1612.0344240,20.9655590,42.1123979,0.0000000,-62.7388786, 1); //
    CreateDynamicObject(1632,-2399.1049800,1612.8334960,26.3745140,55.0038910,0.0000000,-62.7388786, 1); //
    CreateDynamicObject(18450,-2565.2690430,1627.0469970,27.8866040,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1634,-2566.1660160,1682.6890870,16.5689160,0.0000000,0.0000000,-181.3412568, 1); //
    CreateDynamicObject(1634,-2566.2954100,1677.7856450,19.8070720,14.6104238,0.0000000,-181.3412568, 1); //
    CreateDynamicObject(3865,-2424.9934080,1680.7281490,19.0274660,-25.7831008,0.0000000,57.5822584, 1); //
    CreateDynamicObject(3865,-2429.1853030,1677.1062010,19.0274750,-25.7831008,0.0000000,24.0642274, 1); //
    CreateDynamicObject(3865,-2424.2331540,1687.3238530,19.0524730,-25.7831008,0.0000000,108.2890806, 1); //
    CreateDynamicObject(13592,-2350.5161130,1853.1427000,25.3126740,0.0000000,0.0000000,14.6877731, 1); //
    CreateDynamicObject(7073,-2397.6093750,1613.3093260,47.6636660,0.0000000,0.0000000,27.5019742, 1); //
    CreateDynamicObject(13592,-2580.5756840,1428.6433110,15.7826540,0.0000000,0.0000000,55.0039483, 1); //
    CreateDynamicObject(13592,-2286.9296880,1414.7869870,16.0296380,0.0000000,0.0000000,96.2569096, 1); //
    CreateDynamicObject(13592,-2280.6157230,1414.5020750,16.0790630,0.0000000,0.0000000,96.2569096, 1); //
    CreateDynamicObject(13592,-2273.6604000,1414.2148440,16.0607070,0.0000000,0.0000000,96.2569096, 1); //
    CreateDynamicObject(13592,-2266.4975590,1413.9322510,16.0522750,0.0000000,0.0000000,96.2569096, 1); //
    CreateDynamicObject(13592,-2259.1022950,1413.6180420,16.0350040,0.0000000,0.0000000,96.2569096, 1); //
    CreateDynamicObject(1632,-2256.9653320,1400.6737060,6.4591150,-6.0160568,0.0000000,-180.0000198, 1); //
    CreateDynamicObject(1632,-2253.5651860,1400.6752930,6.4591160,-6.0160568,0.0000000,-180.0000198, 1); //
    CreateDynamicObject(1632,-2256.9340820,1395.0559080,9.0239180,9.4538036,0.0000000,-180.0000198, 1); //
    CreateDynamicObject(1632,-2253.5803220,1395.0660400,9.0177560,9.4538036,0.0000000,-180.0000198, 1); //
    CreateDynamicObject(18450,-2563.0209960,1317.2760010,121.6167910,0.0000000,0.8594367,-33.5180883, 1); //
    CreateDynamicObject(18450,-2566.5896000,1311.9805910,124.7976150,-89.3814160,0.8594367,-32.6586516, 1); //
    CreateDynamicObject(18450,-2566.6813960,1311.9836430,138.6435700,-89.3814160,0.8594367,-32.6586516, 1); //
    CreateDynamicObject(13592,-2532.6381840,1300.1997070,131.1233830,61.8793846,46.4095814,-116.8833902, 1); //
    CreateDynamicObject(13592,-2529.4199220,1297.7331540,136.9609680,61.8793846,46.4095814,-116.8833902, 1); //
    CreateDynamicObject(13592,-2526.2900390,1295.3046880,142.6805730,61.8793846,46.4095814,-116.8833902, 1); //
    CreateDynamicObject(13592,-2522.9428710,1292.7587890,148.7077480,61.8793846,46.4095814,-116.8833902, 1); //
    CreateDynamicObject(4726,-2504.4914550,1274.4643550,139.3918910,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1655,-2431.5231930,1442.0893550,7.5121580,12.0321137,24.0642274,-134.9317326, 1); //
    CreateDynamicObject(1655,-2530.6367190,1295.9866940,121.9224850,0.0000000,6.8754935,-165.0120742, 1); //
    CreateDynamicObject(8172,-2289.5524900,1705.2286380,15.6379180,0.0000000,-0.8594367,33.9908931, 1); //
    CreateDynamicObject(16304,-2253.5139160,1621.3010250,18.4838200,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(16304,-2250.4230960,1599.8150630,18.6732670,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(16304,-2249.0734860,1580.0454100,13.3943000,17.1887339,1.7188734,0.0000000, 1); //
    CreateDynamicObject(16304,-2250.7639160,1567.2484130,10.1693030,6.0160568,2.5783101,0.0000000, 1); //
    CreateDynamicObject(16304,-2229.5700680,1633.5509030,20.2082100,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(16304,-2222.9289550,1611.9345700,19.7228260,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(16304,-2219.5986330,1589.0631100,18.8242230,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(16304,-2213.9230960,1574.1739500,15.3728310,6.0160568,2.5783101,2.5783101, 1); //
    CreateDynamicObject(16304,-2212.9729000,1558.5539550,10.0162540,0.8594367,0.8594367,2.5783101, 1); //
    CreateDynamicObject(4113,-2171.8947750,1421.3690190,13.2212300,0.0000000,0.0000000,-78.7500123, 1); //
    CreateDynamicObject(4113,-2170.4360350,1459.7440190,13.0876220,0.0000000,0.0000000,-78.7500123, 1); //
    CreateDynamicObject(8881,-2159.9675290,1507.6801760,32.7792660,0.0000000,0.0000000,-180.0000198, 1); //
    CreateDynamicObject(8881,-2163.2866210,1583.8912350,32.8602370,0.0000000,0.0000000,-112.4999766, 1); //
    CreateDynamicObject(9078,-2358.2958980,1644.7003170,20.5799480,0.0000000,0.0000000,-22.4999953, 1); //
    CreateDynamicObject(1655,-2335.5380860,1615.4183350,19.2634010,0.0000000,0.0000000,219.0701838, 1); //
    CreateDynamicObject(1655,-2295.7128910,1574.4885250,7.2841140,0.0000000,0.0000000,46.0230068, 1); //
    CreateDynamicObject(1655,-2299.5185550,1578.1501460,10.3091140,14.6104238,0.0000000,46.0230068, 1); //
    CreateDynamicObject(1655,-2228.0866700,1424.9791260,7.2341140,0.0000000,0.0000000,-89.8364591, 1); //
    CreateDynamicObject(1655,-2221.2602540,1425.0012210,11.3432480,16.3292972,0.0000000,-89.8364591, 1); //
    CreateDynamicObject(1655,-2215.5903320,1425.0297850,17.8042200,35.2369044,0.0000000,-89.8364591, 1); //
    CreateDynamicObject(1655,-2217.6831050,1521.4534910,7.2841140,0.0000000,0.0000000,-63.8213677, 1); //
    CreateDynamicObject(1655,-2212.5002440,1524.0279540,11.0900990,19.7670439,0.0000000,-63.8213677, 1); //
    CreateDynamicObject(3627,-2322.6772460,1703.6489260,19.5580410,0.8594367,85.9436693,-179.1494640, 1); //
    CreateDynamicObject(3627,-2342.8208010,1672.8453370,20.0830330,0.8594367,85.9436693,-246.6495073, 1); //
    CreateDynamicObject(981,-2750.0703130,1829.5941160,16.7230850,0.0000000,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(981,-2750.2548830,1797.7746580,16.6480870,0.0000000,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(981,-2750.0280760,1726.0429690,16.5980870,0.0000000,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(981,-2750.0043950,1689.2231450,16.6730860,0.0000000,0.0000000,-89.9999813, 1); //
    CreateDynamicObject(981,-2728.2470700,1666.2556150,16.6980860,0.0000000,0.0000000,-180.0000198, 1); //
    CreateDynamicObject(4113,-2207.8359380,1388.6425780,13.1657330,0.0000000,0.0000000,-168.7499935, 1); //
    CreateDynamicObject(5005,-2296.4658200,1584.8702390,9.6605220,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(5005,-2274.3342290,1717.0541990,19.3524910,0.0000000,0.0000000,-56.2500169, 1); //
    CreateDynamicObject(5005,-2304.5688480,1691.9565430,18.3481480,0.0000000,0.0000000,-56.2500169, 1); //
    CreateDynamicObject(4867,-2500.0566410,1636.0539550,6.1937040,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3998,-2381.7775880,1607.2690430,6.8060760,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(979,-2377.6286620,1631.6502690,7.6532740,-0.8594367,-14.6104238,89.9999813, 1); //
    CreateDynamicObject(979,-2377.6752930,1640.4748540,9.9425140,-0.8594367,-14.6104238,89.9999813, 1); //
    CreateDynamicObject(979,-2377.7263180,1649.3721920,12.2847190,-0.8594367,-14.6104238,89.9999813, 1); //
    CreateDynamicObject(4867,-2432.9921880,1938.8354490,15.7170370,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(5005,-2326.6547850,1860.8558350,19.0950720,0.0000000,0.0000000,-89.1405446, 1); //
    CreateDynamicObject(980,-2322.7854000,1780.0902100,18.5118290,0.0000000,0.0000000,33.7500216, 1); //
    CreateDynamicObject(5005,-2327.9116210,1950.8181150,19.0935570,0.0000000,0.0000000,-89.1405446, 1); //
    CreateDynamicObject(5005,-2668.1149900,1846.8370360,19.0716090,0.0000000,0.0000000,-180.0000198, 1); //
    CreateDynamicObject(18450,-2466.0681150,2185.4008790,2.5082980,0.0000000,0.0000000,89.9999813, 1); //
    CreateDynamicObject(1655,-2469.4382320,2212.6147460,3.6594840,-7.7349302,0.0000000,-179.9999626, 1); //
    CreateDynamicObject(1655,-2461.8879390,2212.5935060,3.6594860,-7.7349302,0.0000000,-179.9999626, 1); //
    CreateDynamicObject(1655,-2462.9604490,2205.6149900,3.3021580,-2.5783101,0.0000000,-359.9999824, 1); //
    CreateDynamicObject(1655,-2469.0419920,2205.6098630,3.3021590,-2.5783101,0.0000000,-359.9999824, 1); //
    CreateDynamicObject(5005,-2619.5122070,1846.7854000,19.0731160,0.0000000,0.0000000,-180.0000198, 1); //
    CreateDynamicObject(5005,-2539.3789060,1926.6843260,19.0685580,0.0000000,0.0000000,-270.0000584, 1); //
    CreateDynamicObject(5005,-2539.3708500,1947.1936040,19.1011280,0.0000000,0.0000000,-270.0000584, 1); //
    CreateDynamicObject(8881,-2514.2072750,2033.0168460,41.1682620,0.0000000,0.0000000,-56.2500169, 1); //
    CreateDynamicObject(5005,-2406.3254390,2029.9322510,19.1185490,0.0000000,0.0000000,-180.0000198, 1); //
    CreateDynamicObject(1655,-2466.0295410,2042.2574460,16.6757770,-2.5783101,0.0000000,-539.9999450, 1); //
    CreateDynamicObject(1655,-2457.5141600,2042.2553710,16.6702610,-2.5783101,0.0000000,-539.9999450, 1); //
    CreateDynamicObject(1655,-2474.6718750,2042.2475590,16.6839640,-2.5783101,0.0000000,-539.9999450, 1); //
    CreateDynamicObject(1655,-2457.5244140,2036.0028080,20.3468340,16.3292972,0.0000000,-539.9999450, 1); //
    CreateDynamicObject(1655,-2466.2072750,2035.9965820,20.3481330,16.3292972,0.0000000,-539.9999450, 1); //
    CreateDynamicObject(1655,-2474.6572270,2035.9986570,20.3472730,16.3292972,0.0000000,-539.9999450, 1); //
    CreateDynamicObject(1655,-2457.8886720,2017.7573240,16.5421560,-2.5783101,0.0000000,-719.9997356, 1); //
    CreateDynamicObject(1655,-2466.5996090,2017.7771000,16.5538600,-2.5783101,0.0000000,-719.9997356, 1); //
    CreateDynamicObject(1655,-2475.2687990,2017.7601320,16.5421490,-2.5783101,0.0000000,-719.9997356, 1); //
    CreateDynamicObject(1655,-2457.8576660,2024.6114500,20.5234380,16.3292972,0.0000000,-719.9997356, 1); //
    CreateDynamicObject(1655,-2466.5773930,2024.5983890,20.5131420,16.3292972,0.0000000,-719.9997356, 1); //
    CreateDynamicObject(1655,-2475.2956540,2024.5837400,20.4921380,16.3292972,0.0000000,-719.9997356, 1); //
    CreateDynamicObject(13592,-2351.3430180,1860.4636230,25.2492750,0.0000000,0.0000000,14.6877731, 1); //
    CreateDynamicObject(13592,-2352.1228030,1867.6099850,25.2132230,0.0000000,0.0000000,14.6877731, 1); //
    CreateDynamicObject(13592,-2352.9235840,1874.7716060,25.1980290,0.0000000,0.0000000,14.6877731, 1); //
    CreateDynamicObject(16141,-2370.0344240,1994.3770750,9.9360050,0.0000000,0.0000000,22.4999953, 1); //
    CreateDynamicObject(4113,-2348.9492190,2013.4587400,46.7456440,0.0000000,0.0000000,-29.3754889, 1); //
    CreateDynamicObject(1655,-2516.3681640,1908.4710690,16.7921520,0.0000000,0.0000000,-3.3514593, 1); //
    CreateDynamicObject(1655,-2515.9479980,1915.7932130,21.0961090,15.4698605,0.0000000,-3.3514593, 1); //
    CreateDynamicObject(1655,-2515.6198730,1921.5665280,27.2749120,32.6585943,0.0000000,-3.3514593, 1); //
    CreateDynamicObject(1655,-2515.4218750,1925.1741940,34.7522320,49.8472709,0.0000000,-3.3514593, 1); //
    CreateDynamicObject(1655,-2515.3608400,1926.4636230,42.7979160,66.1765680,0.0000000,-3.3514593, 1); //
    CreateDynamicObject(1655,-2515.4143070,1925.4892580,51.2484550,81.6464285,0.0000000,-3.3514593, 1); //
    CreateDynamicObject(1655,-2515.6020510,1922.2906490,58.7018470,98.8351624,0.0000000,-3.3514593, 1); //
    CreateDynamicObject(18450,-2515.0913090,1870.6965330,52.5466580,0.0000000,-0.8594367,-89.1494827, 1); //
    CreateDynamicObject(18450,-2513.9130860,1792.0175780,53.7242930,0.0000000,-0.8594367,-89.1494827, 1); //
    CreateDynamicObject(18450,-2512.7824710,1714.9038090,62.4397850,0.0000000,-12.0321137,-89.1494827, 1); //
    CreateDynamicObject(979,-2510.9533690,1591.2081300,72.1221620,88.5219793,0.8594367,89.9999813, 1); //
    CreateDynamicObject(18450,-2511.6105960,1635.8804930,71.3738400,0.0000000,-0.8594367,-89.1494827, 1); //
    CreateDynamicObject(1632,-2510.7917480,1582.3334960,73.2119520,0.0000000,0.0000000,-179.9999626, 1); //
    CreateDynamicObject(1632,-2510.7958980,1575.4034420,77.6848910,19.7670439,0.0000000,-179.9999626, 1); //
    CreateDynamicObject(17310,-2581.0605470,1815.8288570,20.8432080,0.0000000,-143.5259277,0.0000000, 1); //
    CreateDynamicObject(17310,-2618.9833980,1815.7126460,20.8432080,0.0000000,-143.5259277,-180.0000198, 1); //
    CreateDynamicObject(17310,-2411.8955080,1847.9055180,20.7901630,0.0000000,-143.5259277,-134.9999719, 1); //
    CreateDynamicObject(17310,-2508.0715330,1952.4602050,20.7886470,0.0000000,-143.5259277,-56.2499596, 1); //
    CreateDynamicObject(17310,-2385.4702150,1958.4295650,20.7886470,0.0000000,-143.5259277,-134.9999719, 1); //
    CreateDynamicObject(17310,-2538.5510250,1844.2198490,20.7901630,0.0000000,-143.5259277,-56.2499596, 1); //
    CreateDynamicObject(17310,-2390.3356930,1845.8819580,20.7901630,0.0000000,-143.5259277,-56.2499596, 1); //
    CreateDynamicObject(17310,-2545.4833980,1854.4255370,49.9068070,0.0000000,-82.5057506,-56.2499596, 1); //
    CreateDynamicObject(1632,-2480.3410640,1704.9807130,16.6436710,0.0000000,0.0000000,-179.9999626, 1); //
    CreateDynamicObject(5005,-2749.5351560,1548.7984620,9.3855230,0.0000000,0.0000000,-270.0000011, 1); //
    CreateDynamicObject(16304,-2741.2651370,1458.4334720,10.7090050,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(18450,-2451.8735350,1887.9725340,31.4102400,0.0000000,24.9236641,-100.3995090, 1); //
    CreateDynamicObject(18450,-2438.9521480,1958.4373780,64.6812740,0.0000000,24.9236641,-100.3995090, 1); //
    CreateDynamicObject(18450,-2425.9555660,2029.2917480,98.1307370,0.0000000,24.9236641,-100.3995090, 1); //
    CreateDynamicObject(18450,-2413.0197750,2099.8205570,131.4381710,0.0000000,24.9236641,-100.3995090, 1); //
    CreateDynamicObject(18450,-2400.1059570,2170.2536620,164.6983030,0.0000000,24.9236641,-100.3995090, 1); //
    CreateDynamicObject(8661,-2387.8178710,2214.8461910,181.8563230,0.0000000,0.0000000,-10.3905896, 1); //
    CreateDynamicObject(8661,-2385.9882810,2224.9248050,191.7545320,88.5219793,0.0000000,-10.3905896, 1); //
    CreateDynamicObject(18450,-2382.6787110,2164.2851560,181.4742580,0.0000000,0.0000000,-96.9528241, 1); //
    CreateDynamicObject(18450,-2390.8618160,2096.6320800,153.4111940,0.0000000,44.6907080,-96.9528241, 1); //
    CreateDynamicObject(18450,-2397.6083980,2041.1022950,98.0586090,0.0000000,44.6907080,-96.9528241, 1); //
    CreateDynamicObject(18450,-2401.2224120,2011.3554690,68.4366380,0.0000000,44.6907080,-96.9528241, 1); //
    CreateDynamicObject(1655,-2404.8271480,1979.5863040,37.1755940,-58.4416378,0.0000000,-186.7892259, 1); //
    CreateDynamicObject(1655,-2405.6962890,1972.1571040,33.2848050,-42.1123979,0.0000000,-186.7892259, 1); //
    CreateDynamicObject(1655,-2406.6730960,1963.8879390,31.6348610,-25.7831008,0.0000000,-186.7892259, 1); //
    CreateDynamicObject(1655,-2407.6894530,1955.3117680,32.7701680,-5.1566202,0.0000000,-186.7892259, 1); //
    CreateDynamicObject(1655,-2408.5935060,1947.6594240,36.4067840,10.3132403,0.0000000,-186.7892259, 1); //
    CreateDynamicObject(1655,-2409.3447270,1941.3300780,42.1697730,28.3614109,0.0000000,-186.7892259, 1); //
    CreateDynamicObject(1655,-2395.7465820,1735.8648680,16.7186700,0.0000000,0.0000000,-149.6014575, 1); //
    CreateDynamicObject(1655,-2392.5158690,1730.3720700,20.5361370,16.3292972,0.0000000,-149.6014575, 1); //
    CreateDynamicObject(981,-2733.8498540,1630.8466800,7.0854870,0.0000000,0.0000000,-180.0000198, 1); //
    CreateDynamicObject(981,-2713.8937990,1630.8449710,7.0604880,0.0000000,0.0000000,-180.0000198, 1); //
    CreateDynamicObject(981,-2697.7556150,1648.8819580,12.6813350,0.0000000,-13.7509871,-269.0632151, 1); //
    CreateDynamicObject(13641,-2453.2597660,1717.5281980,17.2878000,0.0000000,0.0000000,67.4999860, 1); //
    CreateDynamicObject(13641,-2444.8552250,1741.3801270,17.1179730,0.0000000,0.0000000,247.4999485, 1); //
    print("[Gamemode::Objects]: San Fierro objects has been loaded.");

	CreateDynamicObject(10830,-2093.3205570,-2854.5910640,8.2098600,0.0000000,0.0000000,42.4217000, 1); //
    CreateDynamicObject(17068,-2071.8500980,-2849.7136230,0.8655210,0.0000000,0.0000000,358.2811000, 1); //
    CreateDynamicObject(17068,-2072.4943850,-2871.6127930,0.8547140,0.0000000,0.0000000,358.2811000, 1); //
    CreateDynamicObject(17068,-2093.8383790,-2849.3156740,1.2195450,0.0000000,0.0000000,358.2811000, 1); //
    CreateDynamicObject(17068,-2094.5102540,-2871.0214840,1.2087390,0.0000000,0.0000000,358.2811000, 1); //
    CreateDynamicObject(17068,-2112.9414060,-2845.2800290,0.5625750,0.0000000,0.0000000,358.2811000, 1); //
    CreateDynamicObject(17068,-2113.6137700,-2867.1445310,0.5605760,0.0000000,0.0000000,358.2811000, 1); //
    CreateDynamicObject(3187,-2128.3757320,-2794.5483400,11.0051190,0.0000000,0.0000000,56.2500000, 1); //
    CreateDynamicObject(710,-2119.7360840,-2829.1052250,15.7237950,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(710,-2064.4785160,-2831.8020020,16.8866690,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(8644,-2092.3288570,-2830.4606930,16.2748150,0.0000000,0.0000000,292.5000000, 1); //
    CreateDynamicObject(1655,-2137.5046390,-2931.0214840,0.6151280,0.0000000,0.0000000,86.5623000, 1); //
    CreateDynamicObject(1655,-2048.9296880,-2926.8901370,0.5533390,0.0000000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(1655,-2044.1796880,-2926.9013670,3.4481250,15.4699000,0.0000000,270.0000000, 1); //
    CreateDynamicObject(1681,-2032.2066650,-2925.8359380,6.1660830,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1655,-2012.7047120,-2927.9135740,1.1526460,0.0000000,0.0000000,90.0000000, 1); //
    CreateDynamicObject(1655,-2017.0889890,-2927.8945310,4.0270360,19.7670000,0.0000000,90.0000000, 1); //
    CreateDynamicObject(8881,-2183.3884280,-2925.4675290,3.2204970,0.0000000,2.5783000,22.5000000, 1); //
    CreateDynamicObject(8493,-2022.3299560,-3012.5820310,11.8180310,358.2811000,322.1848000,123.6726000, 1); //
    CreateDynamicObject(1655,-2028.3249510,-2982.5729980,0.8014600,0.0000000,0.0000000,219.8434000, 1); //
    CreateDynamicObject(1655,-2001.0000000,-3017.4709470,1.0192330,0.0000000,0.0000000,39.8433000, 1); //
    CreateDynamicObject(13641,-2108.1826170,-2972.6862790,1.3658730,0.0000000,0.0000000,213.7500000, 1); //
    CreateDynamicObject(13641,-2105.5366210,-3012.9802250,1.3036070,0.0000000,0.0000000,63.0480000, 1); //
    CreateDynamicObject(13641,-2067.0239260,-2997.7336430,0.8869960,0.0000000,0.0000000,288.0480000, 1); //
    CreateDynamicObject(13641,-2095.0100100,-2989.9694820,1.3429030,0.0000000,0.0000000,243.0480000, 1); //
    CreateDynamicObject(1655,-1978.1765140,-2953.1215820,0.9016940,0.0000000,0.0000000,264.8434000, 1); //
    CreateDynamicObject(1655,-1971.4146730,-2953.7375490,4.7338790,13.7510000,0.0000000,264.8434000, 1); //
    CreateDynamicObject(1655,-1965.6804200,-2954.2504880,10.3687920,29.2208000,0.0000000,264.8434000, 1); //
    CreateDynamicObject(13592,-1974.3322750,-2886.4760740,9.5458060,0.0000000,0.0000000,45.0000000, 1); //
    CreateDynamicObject(13592,-2157.3059080,-2873.0869140,9.6983630,0.0000000,0.0000000,157.5000000, 1); //
    CreateDynamicObject(13592,-2153.4611820,-2990.4909670,8.9867270,0.0000000,0.0000000,236.2500000, 1); //
    CreateDynamicObject(5400,-2081.5053710,-2996.9772950,-5.8084620,0.0000000,352.2651000,270.0000000, 1); //
    CreateDynamicObject(5400,-2081.4929200,-3006.5124510,-4.5399040,0.0000000,352.2651000,270.0000000, 1); //
    CreateDynamicObject(5400,-2081.5014650,-3016.0485840,-3.2613360,0.0000000,352.2651000,270.0000000, 1); //
    CreateDynamicObject(5400,-2085.0974120,-3107.0490720,-3.2426990,0.0000000,352.2651000,90.0000000, 1); //
    CreateDynamicObject(5400,-2085.0578610,-3116.1398930,-4.4989430,0.0000000,352.2651000,90.0000000, 1); //
    CreateDynamicObject(5400,-2085.0239260,-3124.6113280,-5.6799020,0.0000000,352.2651000,90.0000000, 1); //
    CreateDynamicObject(1655,-2144.6960450,-2930.5783690,4.6882670,13.7510000,0.0000000,86.5623000, 1); //
    CreateDynamicObject(1655,-2150.6774900,-2930.2158200,10.4298060,28.3614000,0.0000000,86.5623000, 1); //
    CreateDynamicObject(16675,-1907.5267330,-3009.4907230,-1.7303700,0.0000000,353.9839000,270.0000000, 1); //
    CreateDynamicObject(16675,-1986.9970700,-3107.8242190,-5.2563710,0.0000000,353.9839000,270.0000000, 1); //
    CreateDynamicObject(16142,-1901.8551030,-2921.1242680,-3.6842860,0.0000000,0.0000000,293.5141000, 1); //
    CreateDynamicObject(16675,-2190.1076660,-3118.3486330,-0.6910780,0.0000000,353.9839000,22.5001000, 1); //
    CreateDynamicObject(16675,-2220.0375980,-3010.3762210,-1.3838420,0.0000000,353.9839000,22.5001000, 1); //
    CreateDynamicObject(16142,-2019.6710210,-2905.7062990,-13.9460540,0.0000000,0.0000000,340.7831000, 1); //
    print("[Gamemode::Objects]: Water park objects has been loaded.");

	CreateDynamicObject(16384,251.1490940,2974.5380860,6.7762430,0.0000000,0.0000000,-82.1877017, 1); //
    CreateDynamicObject(16384,229.4844970,3132.4414060,6.7617380,0.0000000,0.0000000,-82.1877017, 1); //
    CreateDynamicObject(16384,207.7924960,3290.4519040,6.7722340,0.0000000,0.0000000,-82.1877017, 1); //
    CreateDynamicObject(16384,186.1094210,3448.4333500,6.7577300,0.0000000,0.0000000,-82.1877017, 1); //
    CreateDynamicObject(8417,172.1755830,3550.1220700,7.5024870,0.0000000,0.0000000,8.6716589, 1); //
    CreateDynamicObject(8417,212.9287410,3556.3273930,7.4738020,0.0000000,0.0000000,8.6716589, 1); //
    CreateDynamicObject(8417,131.7102660,3543.9084470,7.4988060,0.0000000,0.0000000,8.6716589, 1); //
    CreateDynamicObject(8417,206.9907680,3595.6752930,7.4701210,0.0000000,0.0000000,8.6716589, 1); //
    CreateDynamicObject(8417,166.5641780,3589.4895020,7.4477640,0.0000000,0.0000000,8.6716589, 1); //
    CreateDynamicObject(8417,125.7739260,3583.2082520,7.4450500,0.0000000,0.0000000,8.6716589, 1); //
    CreateDynamicObject(8417,203.1643220,3534.6911620,7.2201210,-90.2408527,0.0000000,8.6716589, 1); //
    CreateDynamicObject(8417,233.2039490,3560.0920410,7.4451210,-89.3814160,0.0000000,98.6716402, 1); //
    CreateDynamicObject(8417,227.3798980,3598.5566410,7.4664400,-89.3814160,0.0000000,98.6716402, 1); //
    CreateDynamicObject(8417,204.5835720,3615.5043950,7.4664400,-89.3814160,0.0000000,188.6716788, 1); //
    CreateDynamicObject(8417,165.0945430,3609.4606930,7.4440830,-89.3814160,0.0000000,188.6716788, 1); //
    CreateDynamicObject(8417,125.1332780,3603.3679200,7.4413700,-89.3814160,0.0000000,188.6716788, 1); //
    CreateDynamicObject(8417,108.0904460,3580.1042480,7.4413700,-89.3814160,0.0000000,278.6717174, 1); //
    CreateDynamicObject(8417,113.8439180,3542.3137210,7.4951260,-89.3814160,0.0000000,278.6717174, 1); //
    CreateDynamicObject(8417,146.3323360,3526.3879390,7.4951280,-89.3814160,0.0000000,8.6718308, 1); //
    CreateDynamicObject(13831,172.3340000,3533.9096680,25.5047800,0.0000000,0.0000000,8.5943669, 1); //
    CreateDynamicObject(7666,174.9693760,3530.2141110,23.2148720,0.0000000,0.0000000,-51.9528335, 1); //
    CreateDynamicObject(3472,178.4047390,3531.2900390,27.0691180,0.0000000,-182.2006934,0.0000000, 1); //
    CreateDynamicObject(3472,171.6921540,3530.0830080,26.8083720,0.0000000,-182.2006934,-67.4999860, 1); //
    CreateDynamicObject(654,183.2341310,3516.0056150,7.4740900,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3472,183.6040340,3516.0737300,25.8341670,0.0000000,-182.2006934,-67.4999860, 1); //
    CreateDynamicObject(3472,183.0983280,3517.1911620,26.8992540,0.0000000,-194.2328644,-101.2500076, 1); //
    CreateDynamicObject(3472,183.8505860,3516.1950680,26.3441600,0.0000000,-194.2328644,-213.7499842, 1); //
    CreateDynamicObject(3472,181.6146090,3515.9064940,13.8612650,0.0000000,-351.5094354,-13.7509871, 1); //
    CreateDynamicObject(3472,183.4135130,3515.7502440,9.9369090,0.0000000,-351.5094354,-13.7509871, 1); //
    CreateDynamicObject(664,168.7723690,3574.9265140,4.7300060,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(656,213.4186550,3596.8161620,6.1068950,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(656,122.5784450,3583.8188480,6.0818240,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(656,223.6992800,3548.2348630,6.5855750,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(656,127.4507450,3538.7590330,6.3855810,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(654,170.1731260,3514.0881350,7.3490900,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3472,170.2385100,3513.7751460,7.8325840,0.0000000,-358.3848717,-36.2509824, 1); //
    CreateDynamicObject(3472,170.1103360,3514.4511720,11.8143920,0.0000000,-358.3848717,-13.7509871, 1); //
    CreateDynamicObject(3472,170.0233310,3514.8078610,23.6112650,0.0000000,-540.5856224,-36.2509824, 1); //
    CreateDynamicObject(3472,168.8528140,3515.0439450,15.8075850,0.0000000,-351.5094354,-13.7509871, 1); //
    CreateDynamicObject(3472,169.1181790,3573.9724120,2.2778610,0.0000000,-361.8226184,-148.7509590, 1); //
    CreateDynamicObject(3472,168.8274840,3575.3955080,20.5427910,0.0000000,-293.9273489,-13.7509871, 1); //
    CreateDynamicObject(3472,169.5127870,3575.2719730,17.3398990,0.0000000,-293.9273489,121.2489848, 1); //
    CreateDynamicObject(3472,171.8854980,3575.4270020,18.7427810,0.0000000,-293.9273489,188.7489708, 1); //
    CreateDynamicObject(3472,167.8854980,3575.3901370,25.1598870,0.0000000,-328.3044728,188.7489708, 1); //
    CreateDynamicObject(3472,168.6241150,3574.7968750,24.4676420,0.0000000,-328.3044728,-13.7509871, 1); //
    CreateDynamicObject(3472,168.6790470,3574.9970700,32.9721180,0.0000000,-359.2440792,-13.7509871, 1); //
    CreateDynamicObject(3472,169.1300660,3574.9721680,23.1830390,0.0000000,-415.9665571,76.2489942, 1); //
    CreateDynamicObject(3472,169.1017760,3574.7221680,18.3645690,-150.4014785,-473.5489874,97.9757830, 1); //
    CreateDynamicObject(3472,169.2051540,3574.6196290,26.3847310,0.0000000,-328.3044728,58.1145362, 1); //
    CreateDynamicObject(3472,169.9673310,3574.4970700,1.9566910,0.0000000,-361.8226184,32.1857895, 1); //
    CreateDynamicObject(3534,187.6092380,3566.9365230,22.3619610,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,169.2929990,3574.2919920,20.9573860,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,168.9288330,3574.9970700,34.1238980,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,184.8163760,3579.0285640,23.3166140,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,170.9524540,3575.9526370,41.4339450,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,170.9524540,3575.8149410,43.2222710,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,170.9524540,3576.1586910,34.1546940,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,177.3023070,3586.2333980,24.3046990,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,175.6524660,3570.6337890,38.9296950,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,165.6885830,3591.5698240,22.6584450,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,156.7604060,3581.2917480,24.9946670,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,153.6354980,3571.6364750,23.9815960,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,172.9432980,3563.2470700,24.3262600,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,159.8529660,3561.5554200,23.4145010,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,162.6298070,3565.4970700,1.3010810,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,163.2555080,3575.1042480,40.0850410,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,168.8647610,3574.9970700,46.4284250,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,168.8647610,3574.9970700,48.6784250,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,168.8647610,3574.9970700,50.5034140,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,168.8647610,3574.9970700,51.2534140,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,168.8647610,3574.9970700,47.8534200,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,168.8647610,3574.9970700,49.5284160,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3472,223.3627470,3547.8020020,18.3904380,0.0000000,-361.8226184,-148.7509590, 1); //
    CreateDynamicObject(3472,224.0876920,3548.1047360,13.8654380,0.0000000,-361.8226184,-227.5009713, 1); //
    CreateDynamicObject(3472,223.7875820,3547.8039550,9.6154380,0.0000000,-361.8226184,-148.7509590, 1); //
    CreateDynamicObject(3472,223.4091030,3547.9262700,24.5539000,0.0000000,-182.2006934,0.0000000, 1); //
    CreateDynamicObject(3472,213.2320250,3596.4196780,23.8546240,0.0000000,-182.2006934,0.0000000, 1); //
    CreateDynamicObject(3472,213.5004730,3596.6735840,15.5966850,0.0000000,-361.8226184,-205.0009759, 1); //
    CreateDynamicObject(3472,213.7254180,3596.6218260,11.1216850,0.0000000,-361.8226184,-148.7509590, 1); //
    CreateDynamicObject(3472,216.5775150,3594.9729000,19.8900760,0.0000000,-332.6017709,-205.0009759, 1); //
    CreateDynamicObject(3472,122.3519970,3583.8300780,19.6015700,0.0000000,-364.4009285,121.2489848, 1); //
    CreateDynamicObject(3472,122.9607930,3583.7241210,14.2052690,0.0000000,-364.4009285,64.9990252, 1); //
    CreateDynamicObject(3472,122.9297710,3583.6782230,5.2592810,0.0000000,-364.4009285,64.9990252, 1); //
    CreateDynamicObject(3472,127.7176280,3537.9157710,17.2701490,0.0000000,-364.4009285,64.9990252, 1); //
    CreateDynamicObject(3472,127.7142790,3538.6418460,10.6011600,0.0000000,-364.4009285,64.9990252, 1); //
    CreateDynamicObject(3472,127.3611980,3538.3420410,14.8171270,0.0000000,-371.2762502,-140.4064017, 1); //
    CreateDynamicObject(3472,123.0878910,3583.4223630,11.0363160,0.0000000,-364.4009285,-36.2509824, 1); //
    CreateDynamicObject(3472,127.7243800,3538.3752440,11.0087070,0.0000000,-342.0555172,5.8614155, 1); //
    CreateDynamicObject(3472,130.4276890,3538.6618650,23.9498650,0.0000000,-164.1524083,5.8614155, 1); //
    CreateDynamicObject(980,121.2341690,3522.3979490,10.2331350,0.0000000,0.8594367,8.6716589, 1); //
    CreateDynamicObject(980,229.0745090,3538.5275880,10.1081320,0.0000000,0.8594367,8.6716589, 1); //
    CreateDynamicObject(980,235.7187810,3539.5095210,10.0081260,0.0000000,0.8594367,8.6716589, 1); //
    CreateDynamicObject(3511,194.3037720,3604.2690430,7.4248350,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3511,144.6995540,3599.2634280,7.4024780,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3511,118.3969190,3562.8869630,7.4535200,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3511,147.2742310,3539.4274900,7.4535200,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3511,197.9091490,3542.5214840,7.4285140,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3511,214.9925840,3574.5385740,7.4285160,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(881,229.6275020,3561.0712890,7.4860780,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(881,123.8464510,3597.1806640,7.4573250,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(881,209.6255490,3547.3469240,7.4860780,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(881,115.0116270,3582.9633790,7.4573250,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(881,215.5017700,3607.6943360,7.4823970,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(881,132.7358400,3530.6394040,7.5110820,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(881,165.0479890,3603.1506350,7.4600400,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3472,240.1544800,3573.7358400,21.7790680,0.0000000,-273.3008683,-165.9398074, 1); //
    CreateDynamicObject(3472,205.3127290,3624.8361820,24.4233320,0.0000000,-273.3008683,-87.7310111, 1); //
    CreateDynamicObject(3472,178.5148320,3619.3493650,25.0261460,0.0000000,-273.3008683,-87.7310111, 1); //
    CreateDynamicObject(3472,148.4424900,3616.1726070,24.7309760,0.0000000,-273.3008683,-87.7310111, 1); //
    CreateDynamicObject(3472,119.2240830,3610.1992190,25.4909480,0.0000000,-273.3008683,-87.7310111, 1); //
    CreateDynamicObject(3472,99.2444080,3581.2668460,25.4707600,0.0000000,-273.3008683,9.2218130, 1); //
    CreateDynamicObject(3472,102.0797730,3559.5268550,25.4916080,0.0000000,-273.3008683,6.6435029, 1); //
    CreateDynamicObject(3472,108.1107180,3523.6970210,26.0403630,0.0000000,-273.3008683,9.2218130, 1); //
    CreateDynamicObject(3534,159.3515320,3529.8786620,18.7565590,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,158.5968480,3529.6840820,11.9862690,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,154.9463810,3529.1147460,13.1462260,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,151.9519810,3528.6240230,19.9499030,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,155.1088100,3529.2373050,25.0571800,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,144.5013890,3527.6342770,22.6610580,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,135.4656220,3526.2661130,21.1311590,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,133.5327760,3525.8630370,11.8329800,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,144.2109380,3527.4902340,11.9577490,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,140.0259400,3526.9553220,18.5855010,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,147.7669370,3527.9870610,16.1390060,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,128.1584930,3524.8674320,27.9462010,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,214.7665860,3537.9567870,16.9205400,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,217.9960480,3538.4807130,24.2537480,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,209.9358060,3537.5236820,23.8575740,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,207.2435300,3536.8154300,18.3184530,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,219.8741300,3538.7155760,12.1483630,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,209.7234800,3537.1667480,11.9911800,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,202.5527340,3536.0742190,12.2274390,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,202.1753690,3536.0412600,18.0128440,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,205.0236820,3536.7812500,24.3509730,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,201.1836090,3536.2009280,24.1448650,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,195.4803160,3535.0207520,18.1789700,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,192.8895570,3534.6000980,12.1842800,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,188.0094910,3532.7075200,23.0981410,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3534,187.5568080,3533.8081050,17.1852230,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3461,172.1818080,3573.6354980,5.8087120,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3461,170.6277310,3571.8605960,5.8087110,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3461,167.6518400,3571.6850590,5.7837100,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3461,165.7636110,3575.6201170,5.7837100,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3461,169.0495150,3578.6884770,5.8087100,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3461,171.5593260,3577.1826170,5.7837120,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3524,181.3420100,3531.4511720,10.4555720,0.0000000,0.0000000,11.1726770, 1); //
    CreateDynamicObject(3524,167.9725340,3529.7468260,10.4805810,0.0000000,0.0000000,11.1726770, 1); //
    CreateDynamicObject(3877,185.9818730,3537.5046390,9.1291660,0.0000000,0.0000000,11.2500263, 1); //
    CreateDynamicObject(3877,213.0924840,3553.7189940,9.1004810,0.0000000,0.0000000,11.2500263, 1); //
    CreateDynamicObject(3877,220.7822270,3572.1926270,9.1004810,0.0000000,0.0000000,11.2500263, 1); //
    CreateDynamicObject(3877,216.2810520,3597.1699220,9.0968000,0.0000000,0.0000000,11.2500263, 1); //
    CreateDynamicObject(3877,198.7366330,3600.7419430,9.0968000,0.0000000,0.0000000,11.2500263, 1); //
    CreateDynamicObject(3877,182.2408140,3596.4091800,9.0744420,0.0000000,0.0000000,11.2500263, 1); //
    CreateDynamicObject(3877,156.7208250,3582.6267090,9.0744420,0.0000000,0.0000000,11.2500263, 1); //
    CreateDynamicObject(3877,130.6577910,3599.1652830,9.0717280,0.0000000,0.0000000,11.2500263, 1); //
    CreateDynamicObject(3877,117.6487880,3578.6611330,9.0717280,0.0000000,0.0000000,11.2500263, 1); //
    CreateDynamicObject(3877,131.1925660,3554.2761230,9.1254840,0.0000000,0.0000000,11.2500263, 1); //
    CreateDynamicObject(3877,123.2762300,3542.4440920,9.1254840,0.0000000,0.0000000,11.2500263, 1); //
    CreateDynamicObject(3877,153.8867800,3535.2976070,9.1291660,0.0000000,0.0000000,11.2500263, 1); //
    CreateDynamicObject(1304,174.7039340,3574.3894040,8.3363330,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1304,171.7824100,3571.6552730,8.3910560,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1304,162.3076170,3576.8747560,8.3363330,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1304,173.3811800,3583.4653320,8.3363330,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1304,163.1776730,3570.1892090,8.3910560,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1304,120.5122910,3591.6044920,8.3336190,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1304,128.8776250,3577.6823730,8.3336190,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1304,129.5614620,3563.3337400,8.3873750,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1304,142.6556400,3546.4050290,8.3873750,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1304,132.8678590,3540.6059570,8.3873750,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1304,195.7225040,3550.1359860,8.3623710,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1304,221.0942380,3548.1198730,8.3623710,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1304,220.0951080,3564.6684570,8.3623710,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1304,215.6885990,3590.7387700,8.3586900,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1304,208.4283140,3601.3041990,8.3586900,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1304,175.2591400,3603.3396000,8.3363330,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1304,154.2266540,3603.8305660,8.3363330,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(978,169.1176610,3530.0231930,8.2823250,0.0000000,0.0000000,-172.1877403, 1); //
    CreateDynamicObject(978,174.6433720,3531.7895510,8.3036450,0.0000000,0.0000000,-172.1877403, 1); //
    CreateDynamicObject(979,180.3729400,3531.5021970,8.3036450,0.0000000,0.0000000,-172.1877403, 1); //
    CreateDynamicObject(3472,179.1228940,3450.4052730,8.0643880,0.0000000,-361.8226184,-148.7509590, 1); //
    CreateDynamicObject(3472,201.6235050,3384.9824220,8.0643900,0.0000000,-361.8226184,-148.7509590, 1); //
    CreateDynamicObject(3472,198.1789550,3309.5305180,8.0788940,0.0000000,-361.8226184,-148.7509590, 1); //
    CreateDynamicObject(3472,222.5780030,3235.5175780,8.0788940,0.0000000,-361.8226184,-148.7509590, 1); //
    CreateDynamicObject(3472,218.4082950,3162.4206540,8.0683980,0.0000000,-361.8226184,-148.7509590, 1); //
    CreateDynamicObject(3472,245.2320710,3067.1337890,8.0683980,0.0000000,-361.8226184,-148.7509590, 1); //
    CreateDynamicObject(3472,254.2338100,2902.2585450,8.0829030,0.0000000,-361.8226184,-148.7509590, 1); //
    CreateDynamicObject(3472,267.7271420,2903.9655760,8.0829030,0.0000000,-361.8226184,-148.7509590, 1); //
    CreateDynamicObject(1318,260.7323610,2903.6120610,7.5090940,0.0000000,92.8191628,-83.1244877, 1); //
    CreateDynamicObject(1276,191.6691890,3555.3442380,8.0169830,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1276,199.6175690,3569.8649900,7.9882940,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1276,197.5399930,3589.3735350,7.9846120,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1276,133.3600920,3569.6157230,7.9595410,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1276,140.0418850,3531.6865230,8.0132940,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1276,127.6948930,3590.8869630,7.9595410,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1276,166.0047000,3601.1901860,7.9622550,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(14562,172.1430510,3545.8000490,8.7325210,0.0000000,0.0000000,-83.9065751, 1); //
    CreateDynamicObject(7666,123.2544560,3583.4372560,31.2223430,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(7666,127.7242890,3538.7138670,31.4385910,0.0000000,0.0000000,56.2500169, 1); //
    CreateDynamicObject(7666,168.9436650,3574.7241210,53.7524870,0.0000000,0.0000000,119.3755274, 1); //
    CreateDynamicObject(7666,212.8809970,3596.1782230,32.1974220,0.0000000,0.0000000,104.7650464, 1); //
    CreateDynamicObject(7666,223.7876430,3547.9797360,32.0725780,0.0000000,0.0000000,172.2650896, 1); //
    CreateDynamicObject(3798,165.6641390,3573.4201660,7.4052450,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3798,174.0291750,3575.3249510,7.4052450,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3798,168.8030400,3583.6130370,7.4052450,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(3798,172.5126190,3575.6843260,9.0052510,0.0000000,-32.6585943,0.0000000, 1); //
    CreateDynamicObject(3799,170.8141330,3566.8598630,7.3452290,0.0000000,0.0000000,0.0000000, 1); //
    CreateDynamicObject(1461,251.5765380,2874.8928220,17.6909430,0.0000000,0.0000000,0.0000000, 1); //
    print("[Gamemode::Objects]: x-Mas objects has been loaded.");

    CreateObject(6522,2816.0996100,2732.0000000,18.4000000,0.0000000,0.0000000,270.0000000); //object(country_law2) (1)
    CreateObject(987,2749.5000000,2665.6001000,9.8000000,0.0000000,0.0000000,0.0000000); //object(elecfence_bar) (1)
    CreateObject(987,2831.5000000,2665.1999500,9.8000000,0.0000000,0.0000000,0.0000000); //object(elecfence_bar) (2)
    CreateObject(987,2820.8999000,2694.8999000,9.8000000,0.0000000,0.0000000,90.0000000); //object(elecfence_bar) (3)
    CreateObject(987,2773.1001000,2665.8999000,9.8000000,0.0000000,0.0000000,0.0000000); //object(elecfence_bar) (4)
    CreateObject(987,2784.8000500,2665.8000500,9.8000000,0.0000000,0.0000000,0.0000000); //object(elecfence_bar) (5)
    CreateObject(987,2761.1999500,2665.8999000,9.8000000,0.0000000,0.0000000,0.0000000); //object(elecfence_bar) (6)
    CreateObject(987,2854.3999000,2712.8000500,10.6000000,0.0000000,0.0000000,0.0000000); //object(elecfence_bar) (7)
    CreateObject(987,2843.3999000,2665.1999500,9.8000000,0.0000000,0.0000000,0.0000000); //object(elecfence_bar) (8)
    CreateObject(987,2855.1999500,2665.3000500,9.8000000,0.0000000,0.0000000,0.0000000); //object(elecfence_bar) (9)
    CreateObject(987,2867.6001000,2665.6999500,9.8000000,0.0000000,0.0000000,90.0000000); //object(elecfence_bar) (10)
    CreateObject(987,2867.3000500,2677.5000000,9.8000000,0.0000000,0.0000000,90.0000000); //object(elecfence_bar) (11)
    CreateObject(987,2866.6999500,2701.5000000,9.8000000,0.0000000,0.0000000,90.0000000); //object(elecfence_bar) (12)
    CreateObject(987,2867.0000000,2689.5000000,9.8000000,0.0000000,0.0000000,90.0000000); //object(elecfence_bar) (13)
    CreateObject(987,2865.8000500,2712.8000500,9.8000000,0.0000000,0.0000000,90.0000000); //object(elecfence_bar) (14)
    CreateObject(987,2866.1999500,2725.1001000,9.8000000,0.0000000,0.0000000,90.0000000); //object(elecfence_bar) (15)
    CreateObject(987,2866.3999000,2737.1999500,9.8000000,0.0000000,0.0000000,90.0000000); //object(elecfence_bar) (16)
    CreateObject(987,2866.5000000,2749.3000500,9.8000000,0.0000000,0.0000000,90.0000000); //object(elecfence_bar) (17)
    CreateObject(987,2866.3000500,2761.0000000,9.8000000,0.0000000,0.0000000,90.0000000); //object(elecfence_bar) (18)
    CreateObject(987,2865.8999000,2772.3000500,9.8000000,0.0000000,0.0000000,90.0000000); //object(elecfence_bar) (19)
    CreateObject(987,2866.0000000,2784.1999500,9.8000000,0.0000000,0.0000000,90.0000000); //object(elecfence_bar) (20)
    CreateObject(987,2853.8999000,2796.0000000,9.8000000,0.0000000,0.0000000,0.0000000); //object(elecfence_bar) (21)
    CreateObject(987,2842.1999500,2796.1001000,9.8000000,0.0000000,0.0000000,0.0000000); //object(elecfence_bar) (22)
    CreateObject(987,2830.3999000,2795.8000500,9.8000000,0.0000000,0.0000000,0.0000000); //object(elecfence_bar) (23)
    CreateObject(987,2818.3999000,2795.8000500,9.8000000,0.0000000,0.0000000,0.0000000); //object(elecfence_bar) (24)
    CreateObject(987,2806.5000000,2796.3000500,9.8000000,0.0000000,0.0000000,0.0000000); //object(elecfence_bar) (25)
    CreateObject(988,2795.6999500,2791.5000000,-68.3000000,0.0000000,0.0000000,0.0000000); //object(ws_apgate) (1)
    CreateObject(987,2824.0000000,2665.1001000,9.8000000,0.0000000,0.0000000,0.0000000); //object(elecfence_bar) (26)
    CreateObject(987,2796.8000500,2665.6001000,9.8000000,0.0000000,0.0000000,0.0000000); //object(elecfence_bar) (27)
    CreateObject(987,2797.6999500,2795.6999500,9.8000000,0.0000000,0.0000000,0.0000000); //object(elecfence_bar) (28)
    CreateObject(987,2785.6999500,2795.3999000,9.8000000,0.0000000,0.0000000,0.0000000); //object(elecfence_bar) (29)
    CreateObject(987,2774.1999500,2795.8000500,9.8000000,0.0000000,0.0000000,0.0000000); //object(elecfence_bar) (30)
    CreateObject(987,2762.0000000,2795.6999500,9.8000000,0.0000000,0.0000000,0.0000000); //object(elecfence_bar) (31)
    CreateObject(987,2750.1001000,2795.8999000,9.8000000,0.0000000,0.0000000,0.0000000); //object(elecfence_bar) (32)
    CreateObject(3749,2779.6001000,2719.6999500,15.7000000,0.0000000,0.0000000,0.0000000); //object(clubgate01_lax) (1)
    CreateObject(3749,2847.8999000,2713.6001000,15.7000000,0.0000000,0.0000000,0.0000000); //object(clubgate01_lax) (2)
    CreateObject(987,2764.3000500,2784.3000500,9.8000000,0.0000000,0.0000000,90.0000000); //object(elecfence_bar) (33)
    CreateObject(987,2752.3000500,2665.8999000,9.8000000,0.0000000,0.0000000,0.0000000); //object(elecfence_bar) (34)
    CreateObject(987,2749.6001000,2719.3000500,9.9000000,0.0000000,0.0000000,0.0000000); //object(elecfence_bar) (35)
    CreateObject(987,2758.5000000,2719.6001000,9.8000000,0.0000000,0.0000000,0.0000000); //object(elecfence_bar) (36)
    CreateObject(987,2854.1001000,2712.8999000,9.8000000,0.0000000,0.0000000,0.0000000); //object(elecfence_bar) (37)
    CreateObject(987,2780.3999000,2784.5000000,9.8000000,0.0000000,0.0000000,90.0000000); //object(elecfence_bar) (38)
    CreateObject(987,2796.1001000,2783.6001000,9.8000000,0.0000000,0.0000000,90.0000000); //object(elecfence_bar) (39)
    CreateObject(987,2809.8999000,2784.6999500,9.8000000,0.0000000,0.0000000,90.0000000); //object(elecfence_bar) (40)
    CreateObject(987,2824.5000000,2785.1999500,9.8000000,0.0000000,0.0000000,90.0000000); //object(elecfence_bar) (41)
    CreateObject(987,2839.8999000,2783.0000000,9.8000000,0.0000000,0.0000000,90.0000000); //object(elecfence_bar) (42)
    CreateObject(987,2853.6999500,2784.1999500,9.8000000,0.0000000,0.0000000,90.0000000); //object(elecfence_bar) (43)
    CreateObject(987,2810.8000500,2695.1999500,9.8000000,0.0000000,0.0000000,90.0000000); //object(elecfence_bar) (44)
    CreateObject(3749,2813.8999000,2665.1001000,15.7000000,0.0000000,0.0000000,0.0000000); //object(clubgate01_lax) (3)
    CreateObject(4726,2846.1999500,2713.1001000,23.1000000,0.0000000,0.0000000,0.0000000); //object(libtwrhelipd_lan2) (1)
    CreateObject(4726,2784.6999500,2718.6001000,22.6000000,0.0000000,0.0000000,0.0000000); //object(libtwrhelipd_lan2) (2)

    AdminGate[0] = CreateObject(980,2813.8994100,2664.5000000,12.6000000,0.0000000,0.0000000,0.0000000);
    AdminGate[1] = CreateObject(980, 2779.6999500, 2719.6999500, 12.6000000,0.0000000, 0.0000000, 0.0000000); //object(airportgate) (3)
    AdminGate[2] = CreateObject(980,2847.8999000,2712.8000500,12.6000000,0.0000000,0.0000000,0.0000000); //object(airportgate) (5)
    print("[Gamemode::Objects]: Admin House has been loaded.");

    CreateDynamicObject(19001,1537.5784900,1377.4652100,19.3000000,0.0000000,0.0000000,86.3400000); //
    CreateDynamicObject(18985,1528.0878900,1486.5416300,14.8800000,0.0000000,0.0000000,0.0000000); //
    CreateDynamicObject(19005,1434.4259000,1346.1906700,10.0000000,0.0000000,0.0000000,0.0000000); //
    CreateDynamicObject(19002,1433.9875500,1372.1129200,18.7000000,0.0000000,0.0000000,0.0000000); //
    CreateDynamicObject(18845,1444.9429900,1226.7923600,55.0000000,0.0000000,0.0000000,0.0000000); //
    CreateDynamicObject(19005,1454.6392800,1226.8156700,10.0679000,0.0000000,0.0000000,88.1784000); //
    CreateDynamicObject(18780,1404.3237300,1646.9382300,20.5000000,0.0000000,0.0000000,-89.3999900); //
    CreateDynamicObject(18777,1432.2753900,1539.8300800,12.3000000,0.0000000,0.0000000,0.0000000); //
    CreateDynamicObject(18777,1432.2895500,1538.5752000,64.3734000,0.0200000,0.0000000,2.0037000); //
    CreateDynamicObject(18777,1432.1811500,1539.6784700,38.3000000,0.0000000,0.0000000,0.0000000); //
    CreateDynamicObject(18835,1454.2486600,1612.0760500,60.0000000,0.0000000,0.0000000,0.0000000); //
    CreateDynamicObject(18801,1331.7450000,1421.5797100,32.6000000,0.0000000,0.0000000,271.4699700); //
    CreateDynamicObject(18801,1351.4508100,1424.3793900,32.6000000,0.0000000,0.0000000,271.4699700); //
    CreateDynamicObject(18828,1451.2045900,1576.6163300,100.0000000,0.0000000,0.0000000,0.0000000); //
    CreateDynamicObject(18786,1477.1910400,1455.0567600,12.1000000,0.0000000,0.0000000,269.7978800); //
    CreateDynamicObject(18836,1367.4517800,1660.2756300,14.7300000,0.0000000,0.0000000,0.3010000); //
    CreateDynamicObject(18836,1367.7512200,1610.3380100,14.7300000,0.0000000,0.0000000,0.3010000); //
    CreateDynamicObject(18779,1423.8560800,1773.0793500,19.7000000,0.0000000,0.0000000,-89.1600000); //
    CreateDynamicObject(18779,1435.8761000,1773.1878700,19.7000000,0.0000000,0.0000000,-89.1600000); //
    CreateDynamicObject(18778,1521.2117900,1279.0164800,11.2800000,0.0000000,0.0000000,41.1600000); //
    CreateDynamicObject(18771,1592.7794200,1329.2019000,9.8000000,0.0000000,0.0000000,0.0000000); //
    CreateDynamicObject(18771,1592.8020000,1329.1932400,59.6800000,0.0000000,0.0000000,-13.0800000); //
    CreateDynamicObject(18809,1489.8171400,1621.4753400,14.0000000,0.0000000,90.0000000,89.7600000); //
    CreateDynamicObject(18826,1573.3210400,1560.2047100,61.5000000,0.0000000,-1.0000000,-180.0000000); //
    CreateDynamicObject(18809,1489.6319600,1663.4735100,46.0000000,0.0000000,90.0000000,89.7600000); //
    CreateDynamicObject(18809,1489.8171400,1664.1095000,14.0000000,0.0000000,90.0000000,89.7600000); //
    CreateDynamicObject(18809,1489.6319600,1616.5267300,46.0000000,0.0000000,90.0000000,89.7600000); //
    CreateDynamicObject(18824,1500.2163100,1573.4925500,46.0000000,270.0000000,50.0000000,91.1400000); //
    CreateDynamicObject(18809,1541.7545200,1560.3055400,46.0000000,0.0000000,90.0000000,180.0000000); //
    CreateDynamicObject(18826,1490.2340100,1698.7740500,30.0000000,0.0000000,0.0000000,-93.1800000); //
    CreateDynamicObject(18824,1542.1336700,1550.0822800,77.5000000,270.0000000,50.0000000,360.0000000); //
    CreateDynamicObject(18809,1525.5362500,1507.7464600,77.5000000,0.0000000,90.0000000,83.0000000); //
    CreateDynamicObject(19005,1467.5419900,1603.6499000,10.0000000,0.0000000,0.0000000,0.0000000); //
    CreateDynamicObject(18859,1379.2258300,1834.6440400,21.2000000,0.0000000,0.0000000,0.0000000); //
    CreateDynamicObject(18780,1508.3547400,1187.6784700,20.5000000,0.0000000,0.0000000,270.0000000); //
    CreateDynamicObject(3851,1388.7229000,1413.5686000,11.8000000,0.0000000,0.0000000,90.0000000); //
    CreateDynamicObject(3851,1388.8253200,1393.4295700,11.8000000,0.0000000,0.0000000,90.0000000); //
    CreateDynamicObject(3851,1388.5783700,1397.5787400,11.8000000,0.0000000,0.0000000,90.0000000); //
    CreateDynamicObject(3851,1388.6165800,1401.6046100,11.8000000,0.0000000,0.0000000,90.0000000); //
    CreateDynamicObject(3851,1388.6505100,1405.1673600,11.8000000,0.0000000,0.0000000,90.0000000); //
    CreateDynamicObject(3851,1388.6927500,1409.6181600,11.8000000,0.0000000,0.0000000,90.0000000); //
    CreateDynamicObject(18786,1345.2523200,1341.3706100,12.1000000,0.0000000,0.0000000,229.0000000); //
    CreateDynamicObject(19005,1388.1350100,1503.2142300,10.0000000,0.0000000,0.0000000,0.0000000); //
    CreateDynamicObject(19072,1478.4179700,1768.4147900,9.9000000,0.0000000,0.0000000,0.0000000); //
    CreateDynamicObject(18779,1332.9815700,1580.9425000,19.7000000,0.0000000,0.0000000,-42.1200200); //
    CreateDynamicObject(19001,1537.5784900,1377.4652100,19.3000000,0.0000000,0.0000000,86.3400000); //
    CreateDynamicObject(18985,1528.0878900,1486.5416300,14.8800000,0.0000000,0.0000000,0.0000000); //
    CreateDynamicObject(19002,1433.9875500,1372.1129200,18.7000000,0.0000000,0.0000000,0.0000000); //
    CreateDynamicObject(18845,1444.9429900,1226.7923600,55.0000000,0.0000000,0.0000000,0.0000000); //
    CreateDynamicObject(19005,1454.6392800,1226.8156700,10.0679000,0.0000000,0.0000000,88.1784000); //
    CreateDynamicObject(18777,1432.2753900,1539.8300800,12.3000000,0.0000000,0.0000000,0.0000000); //
    CreateDynamicObject(18777,1432.2895500,1538.5752000,64.3734000,0.0200000,0.0000000,2.0037000); //
    CreateDynamicObject(18777,1432.1811500,1539.6784700,38.3000000,0.0000000,0.0000000,0.0000000); //
    CreateDynamicObject(18835,1454.2486600,1612.0760500,60.0000000,0.0000000,0.0000000,0.0000000); //
    CreateDynamicObject(18801,1331.7450000,1421.5797100,32.6000000,0.0000000,0.0000000,271.4699700); //
    CreateDynamicObject(18801,1351.4508100,1424.3793900,32.6000000,0.0000000,0.0000000,271.4699700); //
    CreateDynamicObject(18828,1451.2045900,1576.6163300,100.0000000,0.0000000,0.0000000,0.0000000); //
    CreateDynamicObject(19005,1597.4929200,1601.6848100,9.7754300,0.0000000,0.0000000,-182.0399900); //
    CreateDynamicObject(18786,1477.3541300,1508.0969200,12.1000000,0.0000000,0.0000000,89.6178400); //
    CreateDynamicObject(18836,1367.4517800,1660.2756300,14.7300000,0.0000000,0.0000000,0.3010000); //
    CreateDynamicObject(18836,1367.7512200,1610.3380100,14.7300000,0.0000000,0.0000000,0.3010000); //
    CreateDynamicObject(18779,1423.8560800,1773.0793500,19.7000000,0.0000000,0.0000000,-89.1600000); //
    CreateDynamicObject(18779,1435.8761000,1773.1878700,19.7000000,0.0000000,0.0000000,-89.1600000); //
    CreateDynamicObject(18778,1515.7191200,1285.2345000,11.2800000,0.0000000,0.0000000,-139.2600400); //
    CreateDynamicObject(18771,1592.8020000,1329.1932400,59.6800000,0.0000000,0.0000000,-13.0800000); //
    CreateDynamicObject(18809,1489.8234900,1621.4942600,14.0000000,0.0000000,90.0000000,89.7600000); //
    CreateDynamicObject(18826,1573.3210400,1560.2047100,61.5000000,0.0000000,-1.0000000,-180.0000000); //
    CreateDynamicObject(18809,1489.6319600,1663.4735100,46.0000000,0.0000000,90.0000000,89.7600000); //
    CreateDynamicObject(18809,1489.8424100,1664.1220700,14.0000000,0.0000000,90.0000000,89.7600000); //
    CreateDynamicObject(18809,1489.6319600,1616.5267300,46.0000000,0.0000000,90.0000000,89.7600000); //
    CreateDynamicObject(18824,1500.1894500,1573.4760700,46.0000000,270.0000000,50.0000000,91.1400000); //
    CreateDynamicObject(18809,1541.7545200,1560.3055400,46.0000000,0.0000000,90.0000000,180.0000000); //
    CreateDynamicObject(18826,1490.2277800,1698.7550000,30.0000000,0.0000000,0.0000000,-93.1800000); //
    CreateDynamicObject(18824,1542.1336700,1550.0822800,77.5000000,270.0000000,50.0000000,360.0000000); //
    CreateDynamicObject(18809,1525.5362500,1507.7464600,77.5000000,0.0000000,90.0000000,83.0000000); //
    CreateDynamicObject(18859,1379.2258300,1834.6440400,21.2000000,0.0000000,0.0000000,0.0000000); //
    CreateDynamicObject(3851,1388.7229000,1413.5686000,11.8000000,0.0000000,0.0000000,90.0000000); //
    CreateDynamicObject(3851,1388.8253200,1393.4295700,11.8000000,0.0000000,0.0000000,90.0000000); //
    CreateDynamicObject(3851,1388.5783700,1397.5787400,11.8000000,0.0000000,0.0000000,90.0000000); //
    CreateDynamicObject(3851,1388.6165800,1401.6046100,11.8000000,0.0000000,0.0000000,90.0000000); //
    CreateDynamicObject(3851,1388.6505100,1405.1673600,11.8000000,0.0000000,0.0000000,90.0000000); //
    CreateDynamicObject(3851,1388.6927500,1409.6181600,11.8000000,0.0000000,0.0000000,90.0000000); //
    CreateDynamicObject(18786,1345.2523200,1341.3706100,12.1000000,0.0000000,0.0000000,229.0000000); //
    CreateDynamicObject(19005,1387.8721900,1522.5378400,10.0000000,0.0000000,0.0000000,-179.3400300); //
    CreateDynamicObject(19072,1478.4179700,1768.4147900,9.9000000,0.0000000,0.0000000,0.0000000); //
    CreateDynamicObject(18779,1332.9815700,1580.9425000,19.7000000,0.0000000,0.0000000,-42.1200200); //
    CreateDynamicObject(3851,1527.9958500,1557.1630900,1.0000000,0.0000000,0.0000000,90.0000000); //
    CreateDynamicObject(3851,1526.6345200,1578.2265600,11.8000000,0.0000000,0.0000000,90.0000000); //
    CreateDynamicObject(3851,1527.5256300,1557.9055200,11.8000000,0.0000000,0.0000000,90.0000000); //
    CreateDynamicObject(3851,1527.2584200,1562.9426300,11.8000000,0.0000000,0.0000000,90.0000000); //
    CreateDynamicObject(3851,1527.1273200,1568.5224600,11.8000000,0.0000000,0.0000000,90.0000000); //
    CreateDynamicObject(3851,1526.8903800,1573.7742900,11.8000000,0.0000000,0.0000000,90.0000000); //
    CreateDynamicObject(19005,1467.4902300,1622.9694800,10.0000000,0.0000000,0.0000000,-180.6599900); //
    CreateDynamicObject(18809,1379.7603800,1875.6341600,37.0000000,90.0000000,-2.0000000,1.0200000); //
    CreateDynamicObject(18809,1380.7054400,1925.2855200,37.0000000,90.0000000,-2.0000000,1.0200000); //
    CreateDynamicObject(18809,1381.5557900,1974.7388900,37.0000000,90.0000000,-2.0000000,1.0200000); //
    CreateDynamicObject(18826,1382.4660600,2009.5816700,53.0000000,0.0000000,0.0000000,-92.8200000); //
    CreateDynamicObject(18809,1380.9331100,1974.4423800,68.8000000,0.0000000,90.0000000,87.7600300); //
    CreateDynamicObject(18809,1378.9910900,1924.8691400,68.8000000,0.0000000,90.0000000,87.7600300); //
    CreateDynamicObject(18809,1377.0688500,1875.1986100,68.8000000,0.0000000,90.0000000,87.7600300); //
    CreateDynamicObject(18809,1375.1253700,1825.3872100,68.8000000,0.0000000,90.0000000,87.7600300); //
    CreateDynamicObject(18824,1384.9318800,1780.4891400,68.8000000,90.0000000,295.0000000,106.3399900); //
    CreateDynamicObject(18824,1419.2382800,1751.0113500,68.8000000,90.0000000,295.0000000,-83.5000200); //
    CreateDynamicObject(18824,1410.9856000,1712.1246300,68.8000000,90.0000000,295.0000000,-170.4399700); //
    CreateDynamicObject(18824,1367.5708000,1696.6666300,68.8000000,90.0000000,295.0000000,-353.3201900); //
    CreateDynamicObject(18826,1349.1926300,1670.7727100,84.7000000,180.0000000,0.0000000,77.4399900); //
    CreateDynamicObject(18809,1356.6589400,1704.6389200,100.5604000,90.0000000,25.0000000,-37.3200000); //
    CreateDynamicObject(18809,1367.3073700,1753.2966300,100.5604000,90.0000000,25.0000000,-37.3200000); //
    CreateDynamicObject(18809,1377.9370100,1801.9785200,100.5604000,90.0000000,25.0000000,-37.3200000); //
    CreateDynamicObject(18824,1399.7299800,1842.5081800,100.5604000,90.0000000,0.0000000,-59.0000000); //
    CreateDynamicObject(18809,1446.3000500,1844.9937700,100.5604000,90.0000000,25.0000000,-125.2201600); //
    CreateDynamicObject(18824,1488.1607700,1825.2032500,100.5604000,90.0000000,0.0000000,-145.0999900); //
    CreateDynamicObject(18809,1492.3377700,1778.9780300,100.5604000,90.0000000,25.0000000,-214.7400800); //
    CreateDynamicObject(18809,1483.9156500,1729.9384800,100.5604000,90.0000000,25.0000000,-214.7400800); //
    CreateDynamicObject(18809,1519.4585000,1458.2769800,77.5000000,0.0000000,90.0000000,83.0000000); //
    CreateDynamicObject(18824,1501.3923300,1416.2066700,77.5000000,270.0000000,50.0000000,535.9199800); //
    CreateDynamicObject(18809,1455.2066700,1410.4449500,77.5000000,0.0000000,90.0000000,173.0599500); //
    CreateDynamicObject(18824,1409.1971400,1404.6906700,77.5000000,270.0000000,50.0000000,355.7400500); //
    CreateDynamicObject(18824,1402.6280500,1365.7375500,77.5000000,270.0000000,50.0000000,445.0801400); //
    CreateDynamicObject(18809,1444.4622800,1345.8288600,77.5000000,0.0000000,90.0000000,169.0398700); //
    CreateDynamicObject(18786,1360.1002200,1328.5251500,12.1000000,0.0000000,0.0000000,229.0000000); //
    CreateDynamicObject(18809,1474.5169700,1339.9854700,77.5000000,0.0000000,90.0000000,169.0399000); //
    CreateDynamicObject(19005,1513.0172100,1332.4003900,75.7800000,0.0000000,0.0000000,-100.4400000); //
    CreateDynamicObject(18750,1586.1922600,1218.1650400,56.0000000,90.0000000,0.0000000,-180.0999300); //
    CreateDynamicObject(18779,1514.0651900,1818.2500000,19.7000000,0.0000000,0.0000000,-89.1600000); //
    CreateDynamicObject(18779,1525.4783900,1818.4942600,19.7000000,0.0000000,0.0000000,-89.1600000); //
    CreateDynamicObject(18779,1302.4169900,1472.4108900,19.7000000,0.0000000,0.0000000,-19.6800200); //
    CreateDynamicObject(18780,1518.3248300,1187.6859100,20.5000000,0.0000000,0.0000000,270.0000000); //
    CreateDynamicObject(18780,1528.1999500,1187.7181400,20.5000000,0.0000000,0.0000000,270.0000000); //
    CreateDynamicObject(19005,1627.5319800,1272.5481000,10.0000000,0.0000000,0.0000000,-90.2400100); //
    CreateDynamicObject(3458,1644.0097700,1669.6951900,18.0000000,0.0000000,0.0000000,0.0000000); //
    CreateDynamicObject(3458,1686.8219000,1569.6344000,20.3595000,0.0000000,18.0000000,-85.3600100); //
    CreateDynamicObject(3458,1683.9069800,1608.3475300,26.5000000,0.0000000,0.0000000,-85.9800100); //
    CreateDynamicObject(3458,1681.2211900,1646.9510500,22.6800000,0.0000000,-11.0000000,-86.0000000); //
    CreateDynamicObject(19005,1598.3535200,1669.0679900,20.7475600,0.0000000,0.0000000,90.0600400); //
    CreateDynamicObject(19005,1570.5366200,1347.1521000,10.0000000,0.0000000,0.0000000,-41.1599800); //
    CreateDynamicObject(19005,1381.1406300,1257.0330800,10.0000000,0.0000000,0.0000000,145.0000000); //
    CreateDynamicObject(13667,1583.1739500,1156.9057600,25.0000000,0.0000000,0.0000000,100.0000000); //
    CreateDynamicObject(7073,1552.7833300,1189.5607900,17.0000000,0.0000000,0.0000000,0.0000000); //
    CreateDynamicObject(8644,1619.9249300,1180.4603300,21.9377000,0.0000000,0.0000000,27.0000000); //
    AddStaticVehicleEx(522,1610.6178000,1188.2228000,10.3200000,0.0000000,-1,-1,15); //NRG-500
    AddStaticVehicleEx(522,1609.2190000,1188.2228000,10.3200000,0.0000000,-1,-1,15); //NRG-500
    AddStaticVehicleEx(522,1607.8009000,1188.2228000,10.3200000,0.0000000,-1,-1,15); //NRG-500
    AddStaticVehicleEx(522,1606.4166000,1188.2228000,10.3200000,0.0000000,-1,-1,15); //NRG-500
    AddStaticVehicleEx(411,1616.9375000,1214.6444000,10.5200000,90.0000000,-1,-1,15); //Infernus
    AddStaticVehicleEx(541,1617.0928000,1211.3799000,10.4400000,90.0000000,-1,-1,15); //Bullet
    AddStaticVehicleEx(519,1283.2231000,1324.6036000,11.8800000,-90.0000000,-1,-1,15); //Shamal
    AddStaticVehicleEx(519,1283.1674000,1361.5773000,11.8800000,-90.0000000,-1,-1,15); //Shamal
    AddStaticVehicleEx(411,1328.7456000,1279.0938000,10.5200000,0.0000000,-1,-1,15); //Infernus
    AddStaticVehicleEx(541,1322.3148000,1279.4095000,10.4400000,0.0000000,-1,-1,15); //Bullet
    AddStaticVehicleEx(556,1334.6750000,1279.9583000,11.0400000,0.0000000,-1,-1,15); //Monster A
    AddStaticVehicleEx(522,1305.4514000,1279.9585000,10.3200000,0.0000000,-1,-1,15); //NRG-500
    AddStaticVehicleEx(411,1312.7032000,1279.0193000,10.5200000,0.0000000,-1,-1,15); //Infernus
    AddStaticVehicleEx(556,1339.6405000,1279.9583000,11.0400000,0.0000000,-1,-1,15); //Monster A
    AddStaticVehicleEx(522,1307.2705000,1279.9575000,10.3200000,0.0000000,-1,-1,15); //NRG-500
    AddStaticVehicleEx(522,1310.3104000,1279.8900000,10.3200000,0.0000000,-1,-1,15); //NRG-500
    AddStaticVehicleEx(522,1308.6514000,1279.9043000,10.3200000,0.0000000,-1,-1,15); //NRG-500
    AddStaticVehicleEx(411,1282.1232000,1303.7489000,10.5200000,-90.0000000,-1,-1,15); //Infernus
    AddStaticVehicleEx(541,1282.7258000,1290.9510000,10.4400000,-90.0000000,-1,-1,15); //Bullet
    AddStaticVehicleEx(556,1283.4608000,1283.2673000,11.0400000,-90.0000000,-1,-1,15); //Monster A
    AddStaticVehicleEx(522,1283.1223000,1288.5280000,10.3200000,-90.0000000,-1,-1,15); //NRG-500
    AddStaticVehicleEx(522,1283.2065000,1287.0098000,10.3200000,-90.0000000,-1,-1,15); //NRG-500
    AddStaticVehicleEx(560,1282.4287000,1297.4229000,10.3800000,-90.0000000,-1,-1,15); //Sultan
    AddStaticVehicleEx(560,1315.9139000,1279.0894000,10.3800000,0.0000000,-1,-1,15); //Sultan
    AddStaticVehicleEx(487,1288.0433000,1384.5037000,10.9800000,-90.0000000,-1,-1,15); //Maverick
    AddStaticVehicleEx(487,1287.6787000,1401.3170000,10.9800000,-90.0000000,-1,-1,15); //Maverick
    print("[Gamemode::Objects]: Las Venturas Airpot objects has been loaded.");

    print("[Gamemode::VehicleManager]: Loading..");
    print("[Gamemode::VehicleManager]: Creating NPC cars...");
    for(new i = 0; i < 10; i++) NPCCars[i] = CreateVehicle(431,0.0,0.0,i+4,0.0,-1,-1,-1);
    print("[Gamemode::VehicleManager]: 9 NPC cars has been created.");
    print("[Gamemode::VehicleManager]: Creating Player cars...");

    vehicles += LoadStaticVehiclesFromFile("vehicles/trains.txt");
    vehicles += LoadStaticVehiclesFromFile("vehicles/pilots.txt");

    vehicles += LoadStaticVehiclesFromFile("vehicles/lv_law.txt");
    vehicles += LoadStaticVehiclesFromFile("vehicles/lv_airport.txt");
    vehicles += LoadStaticVehiclesFromFile("vehicles/lv_gen.txt");

    vehicles += LoadStaticVehiclesFromFile("vehicles/sf_law.txt");
    vehicles += LoadStaticVehiclesFromFile("vehicles/sf_airport.txt");
    vehicles += LoadStaticVehiclesFromFile("vehicles/sf_gen.txt");

    vehicles += LoadStaticVehiclesFromFile("vehicles/ls_law.txt");
    vehicles += LoadStaticVehiclesFromFile("vehicles/ls_airport.txt");
    vehicles += LoadStaticVehiclesFromFile("vehicles/ls_gen_inner.txt");
    vehicles += LoadStaticVehiclesFromFile("vehicles/ls_gen_outer.txt");

    vehicles += LoadStaticVehiclesFromFile("vehicles/whetstone.txt");
    vehicles += LoadStaticVehiclesFromFile("vehicles/bone.txt");
    vehicles += LoadStaticVehiclesFromFile("vehicles/flint.txt");
    vehicles += LoadStaticVehiclesFromFile("vehicles/tierra.txt");
    vehicles += LoadStaticVehiclesFromFile("vehicles/red_county.txt");

    printf("[Gamemode::VehicleManager]: %d Player cars has been created.", vehicles);
    print("[Gamemode::Non-PlayableChar]: Connecting bots..");

    NPCTimer = SetTimer("ConnectBots", 60*1000, true);
    ConnectNPC("EliteX", "Gunther");

    print("[Gamemode::Non-PlayableChar]: 10 NPC's has been connected.");
    LoadTextDraws();
    print("[Gamemode::TextDraws]: Textdraws has been loaded and created.");
	return 1;
}

public OnGameModeExit()
{
	#if USE_SAVING_SYSTEM == 1

		#if USE_SQLITE
            db_close(Database);
        #elseif USE_MYSQL
            mysql_close(Database);
        #endif

    #endif

	#if USE_EXTERN_CHAT == 1

		#if USE_IRC == 1 
            for(new i = 0; i < 4; i++) IRC_Quit(IRCBots[i], "Server shutdown");
            IRC_DestroyGroup(GroupId);
		#elseif USE_TS3 == 1
            TSC_Disconnect();
        #endif

    #endif

    KillTimer(m_Timer);
    if(!m_Found) DestroyPickup(m_Pickup);
	for(new i = 0; i < GetPlayerPoolSize(); i++) Kick(i);
	return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
    for(new i = 0; i < 7; i++) TextDrawHideForPlayer(playerid, Connect[i]);
    for(new i = 0; i < 2; i++) TextDrawShowForPlayer(playerid, RequestClass[i]);

    SetPlayerPos(playerid, -1634.218872, 1318.792114, 11.679484);
    SetPlayerFacingAngle(playerid, 312.969665);

    InterpolateCameraPos(playerid, -1588.194946, 1348.114135, 35.142406, -1634.218872 + (5 * floatsin(-312.969665, degrees)), 1318.792114 + (5 * floatcos(-312.969665, degrees)), 11.679484, 3000);
    InterpolateCameraLookAt(playerid, -1588.194946, 1348.114135, 35.142406, -1634.218872, 1318.792114, 11.679484, 2000);

    SetPlayerAttachedObject(playerid, 1, 19270, 5, 0.118957, 0.048861, -0.017178, 67.190078, 288.352386, 0.000000, 0.000000, 0.000000, 1.000000);
    SetPlayerAttachedObject(playerid, 2, 19270, 6, 0.118957, 0.037811, 0.022248, 93.706535, 288.517608, 0.000000, 0.000000, 0.000000, 1.000000);
    SetPlayerAttachedObject(playerid, 3, 19270, 9, 0.118957, 0.037811, 0.022248, 93.706535, 288.517608, 0.000000, 0.000000, 0.000000, 1.000000);
    SetPlayerAttachedObject(playerid, 4, 19270, 10, 0.118957, 0.037811, 0.022248, 93.706535, 288.517608, 0.000000, 0.000000, 0.000000, 1.000000);
    SetPlayerSpecialAction(playerid, 5);
    return 1;
}

public OnPlayerConnect(playerid)
{   
    if(IsSnowy) CreateSnow(playerid);
    House_PlayerInit(playerid);
    PlayAudioStreamForPlayer(playerid, "https://ia601504.us.archive.org/33/items/login_201706/login.mp3");
    for(new i = 0; i < 16; i++) SendClientMessage(playerid, -1, "");
    for(new i = 0; i < 7; i++) TextDrawShowForPlayer(playerid, Connect[i]);

    SetPlayerColor(playerid, PlayerColors[random(sizeof(PlayerColors))]);
    GetPlayerName(playerid, PlayerInfo[playerid][Name], 24);

    PlayerInfo[playerid][Color] = GetPlayerColor(playerid);
	PlayerInfo[playerid][Deaths] = 0;
	PlayerInfo[playerid][Kills] = 0;
	PlayerInfo[playerid][Money] = 0;
    if(!strcmp(PlayerInfo[playerid][Name], "EliteX")) PlayerInfo[playerid][Admin] = 1;
	else PlayerInfo[playerid][Admin] = 0;
    PlayerInfo[playerid][Teleport] = 0;
	PlayerInfo[playerid][Spawned] = false;
	PlayerInfo[playerid][VIP] = false;
	PlayerInfo[playerid][Skin] = 0;
	PlayerInfo[playerid][Time] = 0;
    PlayerInfo[playerid][InDM] = false;
    PlayerInfo[playerid][DmZone] = 0;
    PlayerInfo[playerid][Muted] = false;
    PlayerInfo[playerid][Jailed] = false;
    KillTimer(PlayerInfo[playerid][JailTimer]);
    KillTimer(PlayerInfo[playerid][MuteTimer]);
    PlayerInfo[playerid][LoginAttemps] = 0;
    PlayerInfo[playerid][Pers] = 1655;

    if(IsPlayerNPC(playerid)) return SpawnPlayer(playerid);

    SetTimerEx("OnPlayerTextDrawUpdate", 2500, true, "i", playerid);
	GetPlayerClientId(playerid, PlayerInfo[playerid][ClientId], 41);
	GetPlayerIp(playerid, PlayerInfo[playerid][IP], 16);
    LoadPlayerTextDraw(playerid);

	new str[100];
	if(BanCheck(playerid))
	{
		new xadmin[24], reason[50], date[19];
		//GetBanInformations(playerid, xadmin, reason, date);
		SendClientMessage(playerid, -1, "{C3C3C3}You are still banned from {6EF83C}Stunt {F81414}Freeroam {0049FF}Server");
		format(str, sizeof(str), "{C3C3C3}You were banned by {F81414}%s{C3C3C3} for {F81414}%s{C3C3C3} in {F81414}%s", xadmin, reason, date);
		SendClientMessage(playerid, -1, str);
		Ban(playerid);
		return 1;
	}

	format(str, sizeof(str), "{C3C3C3}*%s (Id: %d) has joined {6EF83C}Stunt {F81414}Freeroam {0049FF}Server.", PlayerInfo[playerid][Name], playerid);
	if(!IsPlayerNPC(playerid)) SendClientMessageToAll(-1, str);

    #if USE_EXTERN_CHAT == 1
        #if USE_DISCORD == 1 
            DCC_SendChannelMessage(DDC_Echo_Channel, str);
        #endif

        #if USE_IRC == 1
            format(str, sizeof(str), "02[%d] 03*** %s has joined the server.", playerid, PlayerInfo[playerid][Name]);
            IRC_GroupSay(GroupId, IRC_ECHO, str);
        #endif
    #endif

    #if USE_SAVING_SYSTEM == 1

        #if USE_SQLITE == 1

            new DBResult:Results, rows;
            format(str, sizeof(str), "SELECT * FROM `Accounts` WHERE `Name` = '%q'", PlayerInfo[playerid][Name]);
            Results = db_query(Database, str);
            rows = db_num_rows(Results);
            if(rows > 0)
            {
                ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "{DC143C}|SFS|:{FFFFFF} Login", "Weclome back!\nThank you for being loyal!\nPlease input your password below to get your stats back\nThank you.", "Login", "Cancel");
                db_get_field_assoc(Results, "Password", PlayerInfo[playerid][Password], 129);
            }
            else ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "{DC143C}|SFS|:{FFFFFF} Register", "Weclome to our server!\nThank you for joining!\nPlease input an password below to make sure that your stats are safe\nThank you.", "Register", "Cancel");
            db_free_result(Results);

        #elseif USE_MYSQL == 1

            new Cache:Results, rows;
            mysql_format(Database, str, sizeof(str), "SELECT * FROM `Accounts` WHERE `Name` = '%e'", PlayerInfo[playerid][Name]);
            Results = mysql_query(Database, str);
            cache_get_row_count(rows);
            if(rows > 0)
            {
                ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "{DC143C}|SFS|:{FFFFFF} Login", "Weclome back!\nThank you for being loyal!\nPlease input your password below to get your stats back\nThank you.", "Login", "Cancel");
                cache_get_value_name(0, "Password", PlayerInfo[playerid][Password], 129);
            }
            else ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "{DC143C}|SFS|:{FFFFFF} Register", "Weclome to our server!\nThank you for joining!\nPlease input an password below to make sure that your stats are safe\nThank you.", "Register", "Cancel");
            cache_delete(Results);

        #endif 

    #endif
    RemoveBuildingForPlayer(playerid, 3369, 349.8750, 2438.2500, 15.4766, 0.25);
    RemoveBuildingForPlayer(playerid, 3369, 242.3984, 2438.2500, 15.4766, 0.25);
    RemoveBuildingForPlayer(playerid, 3367, 296.1406, 2438.2500, 15.4766, 0.25);
    RemoveBuildingForPlayer(playerid, 16598, 231.2813, 2545.7969, 20.0234, 0.25);
    RemoveBuildingForPlayer(playerid, 16602, 307.9531, 2543.4531, 20.3984, 0.25);
    RemoveBuildingForPlayer(playerid, 3269, 242.3984, 2438.2500, 15.4766, 0.25);
    RemoveBuildingForPlayer(playerid, 16599, 231.2813, 2545.7969, 20.0234, 0.25);
    RemoveBuildingForPlayer(playerid, 16098, 307.9531, 2543.4531, 20.3984, 0.25);
    RemoveBuildingForPlayer(playerid, 3271, 296.1406, 2438.2500, 15.4766, 0.25);
    RemoveBuildingForPlayer(playerid, 3269, 349.8750, 2438.2500, 15.4766, 0.25);
    RemoveBuildingForPlayer(playerid, 10109, -1660.6875, 1358.9766, 12.2031, 0.25);
    RemoveBuildingForPlayer(playerid, 10141, -1421.6250, 1490.8594, 6.9688, 0.25);
    RemoveBuildingForPlayer(playerid, 728, -1498.1172, 1380.9688, 1.4922, 0.25);
    RemoveBuildingForPlayer(playerid, 728, -1499.1719, 1376.1328, 1.4922, 0.25);
    RemoveBuildingForPlayer(playerid, 728, -1501.1484, 1370.2734, 1.4922, 0.25);
    RemoveBuildingForPlayer(playerid, 728, -1508.8672, 1370.6641, 1.4922, 0.25);
    RemoveBuildingForPlayer(playerid, 728, -1513.2422, 1371.4453, 1.4922, 0.25);
    RemoveBuildingForPlayer(playerid, 728, -1514.3281, 1376.4453, 1.4922, 0.25);
    RemoveBuildingForPlayer(playerid, 728, -1511.1719, 1375.4844, 1.4922, 0.25);
    RemoveBuildingForPlayer(playerid, 10229, -1421.8750, 1489.4453, 5.8203, 0.25);
    RemoveBuildingForPlayer(playerid, 10230, -1421.6250, 1490.8594, 6.9688, 0.25);
    RemoveBuildingForPlayer(playerid, 10231, -1422.5391, 1489.3516, 8.4531, 0.25);
    RemoveBuildingForPlayer(playerid, 10286, -1602.0000, 1323.5859, -6.2500, 0.25);
    RemoveBuildingForPlayer(playerid, 1216, -1696.6875, 1334.4766, 6.8828, 0.25);
    RemoveBuildingForPlayer(playerid, 1496, -1673.1016, 1336.3125, 6.1797, 0.25);
    RemoveBuildingForPlayer(playerid, 9904, -1660.6875, 1358.9766, 12.2031, 0.25);
    RemoveBuildingForPlayer(playerid, 1232, -1649.9609, 1318.2422, 8.8047, 0.25);
    RemoveBuildingForPlayer(playerid, 1232, -1629.5781, 1297.1406, 8.8047, 0.25);
    RemoveBuildingForPlayer(playerid, 10183, -1643.0469, 1302.6094, 6.1016, 0.25);
    RemoveBuildingForPlayer(playerid, 10166, -1602.0000, 1323.5859, -6.2500, 0.25);
    RemoveBuildingForPlayer(playerid, 10140, -1406.9063, 1489.8047, 7.1250, 0.25);
    RemoveBuildingForPlayer(playerid, 10227, -1376.7500, 1490.6328, 12.0234, 0.25);
    RemoveBuildingForPlayer(playerid, 10226, -1377.2344, 1491.6250, 6.2109, 0.25);
    RemoveBuildingForPlayer(playerid, 4257, -1499.9609, 1452.5156, -49.7188, 0.25);
    RemoveBuildingForPlayer(playerid, 4391, -1499.9609, 1452.5156, -49.7188, 0.25);

	return 1;
}

public OnPlayerObjectMoved(playerid, objectid)
{
    if(snowActive[playerid] == 0)
        return 1;

    for(new i = 0; i < 20; i++)
    {
        if(objectid == snowObject[playerid][i])
        {
            RecreateSnow(playerid, objectid);
            return 1;
        }
    }
    return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    switch(dialogid)
    {
        case DIALOG_REGISTER:
        {
            if(!response) return Kick(playerid);
			if(strlen(inputtext) > 30 || strlen(inputtext) < 4)
			{
				SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: Invalid password length.");
				SendClientMessage(playerid, -1, "{FF9900}*Info{FFFFFF}: Password length must be highter than 4 and less than 30");
                ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "{DC143C}|SFS|:{FFFFFF} Register", "Weclome to our server!\nThank you for joining!\nPlease input an password below to make sure that your stats are safe\nThank you.", "Register", "Cancel");
				return 1;
			}
			PlayerInfo[playerid][AccountId] = GetLastUserId() + 1;
            WP_Hash(PlayerInfo[playerid][Password], 129, inputtext);
			PlayerInfo[playerid][Time] = 0;
			PlayerInfo[playerid][Kills] = 0;
			PlayerInfo[playerid][Deaths] = 0;
			PlayerInfo[playerid][Admin] = 0;
			PlayerInfo[playerid][VIP] = false;
			PlayerInfo[playerid][Skin] = 0;
			PlayerInfo[playerid][Money] = 30000;
			SetPlayerScore(playerid, PlayerInfo[playerid][Money]);
            GivePlayerMoney(playerid, PlayerInfo[playerid][Money]);

			new query[523];

			#if USE_SAVING_SYSTEM == 1

				#if USE_SQLITE == 1

					format(query, sizeof(query), "INSERT INTO `Accounts` (`UserId`, `Name`, `IP`, `Password`, `ClientId`, `Admin`, `VIP`, `Money`, `Deaths`, `Kills`, `Skin`, `Time`, `Color`) VALUES (%d, '%q', '%s', '%s', 0, 0, 0, 0, 0, 0, 0, 0, 0)",
						PlayerInfo[playerid][AccountId], PlayerInfo[playerid][Name], PlayerInfo[playerid][IP], PlayerInfo[playerid][Password], PlayerInfo[playerid][ClientId]);
					db_query(Database, query);

				#elseif USE_MYSQL == 1

					mysql_format(Database, query, sizeof(query), "INSERT INTO `Accounts` (`UserId`, `Name`, `IP`, `Password`, `ClientId`, `Admin`, `VIP`, `Money`, `Deaths`, `Kills`, `Skin`, `Time`, `Color`) VALUES (%d, '%e', '%s', '%s', 0, 0, 0, 0, 0, 0, 0, 0, 0)",
						PlayerInfo[playerid][AccountId], PlayerInfo[playerid][Name], PlayerInfo[playerid][IP], PlayerInfo[playerid][Password], PlayerInfo[playerid][ClientId]);
					mysql_query(Database, query);
				#endif

			#endif
			return 1;
        }
        case DIALOG_LOGIN:
        {
            if(!response) return Kick(playerid);
            if(PlayerInfo[playerid][LoginAttemps] > 3) Kick(playerid);

            new pwd[129];

            WP_Hash(pwd, sizeof(pwd), inputtext);

            if(strcmp(PlayerInfo[playerid][Password], pwd))
            {
                PlayerInfo[playerid][LoginAttemps]++;
                ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "{DC143C}|SFS|:{FFFFFF} Login", "Weclome back!\nThank you for being loyal!\nPlease input your password below to get your stats back\nThank you.", "Login", "Cancel");
                return 1;
            }

			GetPlayerStats(PlayerInfo[playerid][Name], PlayerInfo[playerid][AccountId], PlayerInfo[playerid][Time], PlayerInfo[playerid][Kills], PlayerInfo[playerid][Deaths], PlayerInfo[playerid][Admin], PlayerInfo[playerid][VIP], PlayerInfo[playerid][Skin], PlayerInfo[playerid][Money], PlayerInfo[playerid][Color]);

            SetPlayerColor(playerid, PlayerInfo[playerid][Color]);
            GivePlayerMoney(playerid, PlayerInfo[playerid][Money]);
            SetPlayerSkin(playerid, PlayerInfo[playerid][Skin]);

            format(pwd, sizeof(pwd), "{C3C3C3}*%s (Id: %d) has logged into {6EF83C}Stunt {F81414}Freeroam {0049FF}Server.", PlayerInfo[playerid][Name], playerid);
			SendClientMessageToAll(-1, pwd);
			return 1;
		}
        case DIALOG_DM:
        {
            if(response)
		    {
			 	switch(listitem)
				{
					case 0:return cmd_de(playerid);
					case 1:return cmd_rw(playerid);
					case 2:return cmd_sos(playerid);
					case 3:return cmd_snipedm(playerid);
					case 4:return cmd_sos2(playerid);
					case 5:return cmd_snipedm2(playerid);
					case 6:return cmd_shotdm(playerid);
					case 7:return cmd_mini(playerid);
					case 8:return cmd_wz(playerid);
					case 9:return cmd_shipdm(playerid);
				}
			}
		}
        case DIALOG_TELEPORTS:
        {
            switch(listitem)
            {
                case 0: 
                {
                    SetPlayerPos(playerid, 418.8394, 2550.6501, 16.2770); 
                    PlayerInfo[playerid][Stunt] = true;
                }
                case 1:
                {
                    SetPlayerPos(playerid, 1981.0939, -2571.9971,13.5469);
                    PlayerInfo[playerid][Stunt] = true;
                }
                case 2:
                {
                    SetPlayerPos(playerid, 1369.4260, 1645.8193, 10.8125);
                    PlayerInfo[playerid][Stunt] = true;
                }
                case 3:
                {
                    SetPlayerPos(playerid, -2329.6567, -1621.5319, 483.7103);
                    PlayerInfo[playerid][Stunt] = true;
                }
                case 4:
                {
                    SetPlayerPos(playerid, -1480.1720, 314.9091, 70.5794);
                    PlayerInfo[playerid][Stunt] = true;
                }
                case 5:
                {
                    SetPlayerPos(playerid, 833.9306, -2064.2236, 30.5217);
                    PlayerInfo[playerid][Stunt] = true;
                }
                case 6:
                {
                    SetPlayerPos(playerid, 1334.1573, -1203.1504, 224.5517);
                    PlayerInfo[playerid][Stunt] = true;
                }
                case 7:
                {
                    SetPlayerPos(playerid, -2496.5032, 1493.9352, 21.6894);
                    PlayerInfo[playerid][Stunt] = true;
                }
                case 8:
                {
                    SetPlayerPos(playerid, -2077.3125, -2829.6646, 3.0000);
                    PlayerInfo[playerid][Stunt] = true;
                }
                case 9:
                {
                    SetPlayerPos(playerid, 251.1491, 2974.5381, 16.9843);
                    PlayerInfo[playerid][Stunt] = true;
                }
                case 10: 
                {
                    if(!PlayerInfo[playerid][Stunt]) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You are not at stunt area.");
                    PlayerInfo[playerid][Stunt] = false;
                    SetPlayerVirtualWorld(playerid, 0);
                    SetPlayerHealth(playerid, 100.0);
                    SpawnPlayer(playerid);
                }
            }
            if(PlayerInfo[playerid][Stunt]) SetPlayerVirtualWorld(playerid, 1); SetPlayerHealth(playerid, 999999);
        }
        case DIALOG_BUY_HOUSE:
        {
            if(!response) return 1;
            new id = GetPVarInt(playerid, "PickupHouseID");
            if(!IsPlayerInRangeOfPoint(playerid, 2.0, HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ])) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not near any house.");
            #if LIMIT_PER_PLAYER > 0
            if(OwnedHouses(playerid) + 1 > LIMIT_PER_PLAYER) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You can't buy any more houses.");
            #endif
            if(HouseData[id][Price] > GetPlayerMoney(playerid)) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You can't afford this house.");
            if(strcmp(HouseData[id][Owner], "-")) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: Someone already owns this house.");
            GivePlayerMoney(playerid, -HouseData[id][Price]);
            GetPlayerName(playerid, HouseData[id][Owner], MAX_PLAYER_NAME);
            HouseData[id][LastEntered] = gettime();
            HouseData[id][Save] = true;

            UpdateHouseLabel(id);
            Streamer_SetIntData(STREAMER_TYPE_PICKUP, HouseData[id][HousePickup], E_STREAMER_MODEL_ID, 19522);
            Streamer_SetIntData(STREAMER_TYPE_MAP_ICON, HouseData[id][HouseIcon], E_STREAMER_TYPE, 32);
            SendToHouse(playerid, id);
            return 1;
        }

        case DIALOG_HOUSE_PASSWORD:
        {
            if(!response) return 1;
            new id = GetPVarInt(playerid, "PickupHouseID");
            if(!IsPlayerInRangeOfPoint(playerid, 2.0, HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ])) return SendClientMessage(playerid, -1, "You're not near any house.");
            if(!(1 <= strlen(inputtext) <= MAX_HOUSE_PASSWORD)) return ShowPlayerDialog(playerid, DIALOG_HOUSE_PASSWORD, DIALOG_STYLE_INPUT, "{DC143C}|SFS|:{FFFFFF} House Password", "This house is password protected.\n\nEnter house password:\n\n{E74C3C}The password you entered is either too short or too long.", "Try Again", "Close");
            if(strcmp(HouseData[id][Password], inputtext)) return ShowPlayerDialog(playerid, DIALOG_HOUSE_PASSWORD, DIALOG_STYLE_INPUT, "{DC143C}|SFS|:{FFFFFF} House Password", "This house is password protected.\n\nEnter house password:\n\n{E74C3C}Wrong password.", "Try Again", "Close");
            SendToHouse(playerid, id);
            return 1;
        }

        case DIALOG_HOUSE_MENU:
        {
            if(!response) return 1;
            new id = InHouse[playerid];
            if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not in a house.");
            if(strcmp(HouseData[id][Owner], PlayerInfo[playerid][Name])) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not the owner of this house.");

            if(listitem == 0) ShowPlayerDialog(playerid, DIALOG_HOUSE_NAME, DIALOG_STYLE_INPUT, "{DC143C}|SFS|:{FFFFFF} House Name", "Write a new name for this house:", "Change", "Back");
            if(listitem == 1) ShowPlayerDialog(playerid, DIALOG_HOUSE_NEW_PASSWORD, DIALOG_STYLE_INPUT, "{DC143C}|SFS|:{FFFFFF} House Password", "Write a new password for this house:", "Change", "Back");
            if(listitem == 2) ShowPlayerDialog(playerid, DIALOG_HOUSE_LOCK, DIALOG_STYLE_LIST, "{DC143C}|SFS|:{FFFFFF} House Lock", "Not Locked\nPassword Lock\nKeys\nOwner Only", "Change", "Back");
            if(listitem == 3)
            {
                if(HouseData[id][SalePrice] > 0)
                {
                    SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You can't use this feature while the house is for sale.");
                    return ShowHouseMenu(playerid);
                }

                new string[144];
                format(string, sizeof(string), "{DC143C}|SFS|:{FFFFFF} Take Money From Safe {2ECC71}($%s)\nPut Money To Safe {2ECC71}($%s)\nView Safe History\nClear Safe History", convertNumber(HouseData[id][SafeMoney]), convertNumber(GetPlayerMoney(playerid)));
                ShowPlayerDialog(playerid, DIALOG_SAFE_MENU, DIALOG_STYLE_LIST, "House Safe", string, "Choose", "Back");
            }

            if(listitem == 4)
            {
                if(HouseData[id][SalePrice] > 0)
                {
                    SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You can't use this feature while the house is for sale.");
                    return ShowHouseMenu(playerid);
                }

                ShowPlayerDialog(playerid, DIALOG_FURNITURE_MENU, DIALOG_STYLE_LIST, "{DC143C}|SFS|:{FFFFFF} Furnitures", "Buy Furniture\nEdit Furniture\nSell Furniture\nSell All Furnitures", "Choose", "Back");
            }

            if(listitem == 5) ShowPlayerDialog(playerid, DIALOG_GUNS_MENU, DIALOG_STYLE_LIST, "{DC143C}|SFS|:{FFFFFF} Guns", "Put Gun\nTake Gun", "Choose", "Back");
            if(listitem == 6)
            {
                ListPage[playerid] = 0;
                ShowPlayerDialog(playerid, DIALOG_VISITORS_MENU, DIALOG_STYLE_LIST, "{DC143C}|SFS|:{FFFFFF} Visitors", "Look Visitor History\nClear Visitor History", "Choose", "Back");
            }

            if(listitem == 7)
            {
                ListPage[playerid] = 0;
                ShowPlayerDialog(playerid, DIALOG_KEYS_MENU, DIALOG_STYLE_LIST, "{DC143C}|SFS|:{FFFFFF} Keys", "View Key Owners\nChange Locks", "Choose", "Back");
            }

            if(listitem == 8)
            {
                new string[128];
                format(string, sizeof(string), "{B7FF00}*Success{FFFFFF}: House owner %s kicked everybody from the house.", HouseData[id][Owner]);

                foreach(new i : Player)
                {
                    if(i == playerid) continue;
                    if(InHouse[i] == id)
                    {
                        SetPVarInt(i, "HousePickupCooldown", gettime() + HOUSE_COOLDOWN);
                        SetPlayerVirtualWorld(i, 0);
                        SetPlayerInterior(i, 0);
                        SetPlayerPos(i, HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ]);
                        InHouse[i] = INVALID_HOUSE_ID;
                        SendClientMessage(i, -1, string);
                    }
                }

                SendClientMessage(playerid, -1, "{B7FF00}*Success{FFFFFF}: You kicked everybody from your house.");
            }

            if(listitem == 9)
            {
                new string[128];
                format(string, sizeof(string), "Sell Instantly\t{2ECC71}$%s\n%s", convertNumber(floatround(HouseData[id][Price]*0.85)), (HouseData[id][SalePrice] > 0) ? ("Remove From Sale") : ("Put For Sale"));
                ShowPlayerDialog(playerid, DIALOG_SELL_HOUSE, DIALOG_STYLE_TABLIST, "{DC143C}|SFS|:{FFFFFF} Sell House", string, "Choose", "Back");
            }

            return 1;
        }

        case DIALOG_HOUSE_NAME:
        {
            if(!response) return ShowHouseMenu(playerid);
            new id = InHouse[playerid];
            if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not in a house.");
            if(strcmp(HouseData[id][Owner], PlayerInfo[playerid][Name])) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not the owner of this house.");
            if(!(1 <= strlen(inputtext) <= MAX_HOUSE_NAME)) return ShowPlayerDialog(playerid, DIALOG_HOUSE_NAME, DIALOG_STYLE_INPUT, "{DC143C}|SFS|:{FFFFFF} House Name", "Write a new name for this house:\n\n{E74C3C}The name you entered is either too short or too long.", "Change", "Back");
            format(HouseData[id][Name], MAX_HOUSE_NAME, "%s", inputtext);
            HouseData[id][Save] = true;

            UpdateHouseLabel(id);
            ShowHouseMenu(playerid);
            return 1;
        }

        case DIALOG_HOUSE_NEW_PASSWORD:
        {
            if(!response) return ShowHouseMenu(playerid);
            new id = InHouse[playerid];
            if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not in a house.");
            if(strcmp(HouseData[id][Owner], PlayerInfo[playerid][Name])) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not the owner of this house.");
            if(!(1 <= strlen(inputtext) <= MAX_HOUSE_PASSWORD)) return ShowPlayerDialog(playerid, DIALOG_HOUSE_NEW_PASSWORD, DIALOG_STYLE_INPUT, "{DC143C}|SFS|:{FFFFFF} House Password", "Write a new password for this house:\n\n{E74C3C}The pasword you entered is either too short or too long.", "Change", "Back");
            format(HouseData[id][Password], MAX_HOUSE_PASSWORD, "%s", inputtext);
            HouseData[id][Save] = true;
            ShowHouseMenu(playerid);
            return 1;
        }

        case DIALOG_HOUSE_LOCK:
        {
            if(!response) return ShowHouseMenu(playerid);
            new id = InHouse[playerid];
            if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not in a house.");
            if(strcmp(HouseData[id][Owner], PlayerInfo[playerid][Name])) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not the owner of this house.");
            HouseData[id][LockMode] = listitem;
            HouseData[id][Save] = true;

            UpdateHouseLabel(id);
            ShowHouseMenu(playerid);
            return 1;
        }

        case DIALOG_SAFE_MENU:
        {
            if(!response) return ShowHouseMenu(playerid);
            new id = InHouse[playerid];
            if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not in a house.");
            if(strcmp(HouseData[id][Owner], PlayerInfo[playerid][Name])) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not the owner of this house.");
            if(HouseData[id][SalePrice] > 0) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You can't use this feature while the house is for sale.");
            if(listitem == 0) ShowPlayerDialog(playerid, DIALOG_SAFE_TAKE, DIALOG_STYLE_INPUT, "{DC143C}|SFS|:{FFFFFF} Safe: Take Money", "Write the amount you want to take from safe:", "Take", "Back");
            if(listitem == 1) ShowPlayerDialog(playerid, DIALOG_SAFE_PUT, DIALOG_STYLE_INPUT, "{DC143C}|SFS|:{FFFFFF} Safe: Put Money", "Write the amount you want to put to safe:", "Put", "Back");
            if(listitem == 2)
            {
                ListPage[playerid] = 0;

                new query[200], Cache: safelog;
                mysql_format(Database, query, sizeof(query), "SELECT Type, Amount, FROM_UNIXTIME(Date, '%%d/%%m/%%Y %%H:%%i') as TransactionDate FROM housesafelogs WHERE HouseID=%d ORDER BY Date DESC LIMIT 0, 15", id);
                safelog = mysql_query(Database, query);
                new rows = cache_num_rows();
                if(rows) {
                    new list[1024], type, amount, date[20];
                    format(list, sizeof(list), "Action\tDate\n");
                    for(new i; i < rows; ++i)
                    {
                        cache_get_value_name_int(i, "Type", type);
                        cache_get_value_name_int(i, "Amount", amount);
                        cache_get_value_name(i, "TransactionDate", date);

                        format(list, sizeof(list), "%s%s $%s\t{FFFFFF}%s\n", list, TransactionNames[type], convertNumber(amount), date);
                    }

                    ShowPlayerDialog(playerid, DIALOG_SAFE_HISTORY, DIALOG_STYLE_TABLIST_HEADERS, "{DC143C}|SFS|:{FFFFFF} Safe History (Page 1)", list, "Next", "Previous");
                }else{
                    SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: Can't find any safe history.");
                }

                cache_delete(safelog);
            }

            if(listitem == 3)
            {
                new query[64];
                mysql_format(Database, query, sizeof(query), "DELETE FROM housesafelogs WHERE HouseID=%d", id);
                mysql_tquery(Database, query, "", "");
                ShowHouseMenu(playerid);
            }

            return 1;
        }

        case DIALOG_SAFE_TAKE:
        {
            if(!response) return ShowHouseMenu(playerid);
            new id = InHouse[playerid];
            if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not in a house.");
            if(strcmp(HouseData[id][Owner], PlayerInfo[playerid][Name])) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not the owner of this house.");
            if(HouseData[id][SalePrice] > 0) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You can't use this feature while the house is for sale.");
            new amount = strval(inputtext);
            if(!(1 <= amount <= 10000000)) return ShowPlayerDialog(playerid, DIALOG_SAFE_TAKE, DIALOG_STYLE_INPUT, "{DC143C}|SFS|:{FFFFFF} Safe Take Money", "Write the amount you want to take from safe:\n\n{E74C3C}Invalid amount. You can take between $1 - $10,000,000 at a time.", "Take", "Back");
            if(amount > HouseData[id][SafeMoney]) return ShowPlayerDialog(playerid, DIALOG_SAFE_TAKE, DIALOG_STYLE_INPUT, "{DC143C}|SFS|:{FFFFFF} Safe Take Money", "Write the amount you want to take from safe:\n\n{E74C3C}You don't have that much money in your safe.", "Take", "Back");
            new query[128];
            mysql_format(Database, query, sizeof(query), "INSERT INTO housesafelogs SET HouseID=%d, Type=0, Amount=%d, Date=UNIX_TIMESTAMP()", id, amount);
            mysql_tquery(Database, query, "", "");

            GivePlayerMoney(playerid, amount);
            HouseData[id][SafeMoney] -= amount;
            HouseData[id][Save] = true;
            ShowHouseMenu(playerid);
            return 1;
        }

        case DIALOG_SAFE_PUT:
        {
            if(!response) return ShowHouseMenu(playerid);
            new id = InHouse[playerid];
            if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not in a house.");
            if(strcmp(HouseData[id][Owner], PlayerInfo[playerid][Name])) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not the owner of this house.");
            new amount = strval(inputtext);
            if(!(1 <= amount <= 10000000)) return ShowPlayerDialog(playerid, DIALOG_SAFE_PUT, DIALOG_STYLE_INPUT, "{DC143C}|SFS|:{FFFFFF} Safe Put Money", "Write the amount you want to put to safe:\n\n{E74C3C}Invalid amount. You can put between $1 - $10,000,000 at a time.", "Put", "Back");
            if(amount > GetPlayerMoney(playerid)) return ShowPlayerDialog(playerid, DIALOG_SAFE_PUT, DIALOG_STYLE_INPUT, "{DC143C}|SFS|:{FFFFFF} Safe Put Money", "Write the amount you want to put to safe:\n\n{E74C3C}You don't have that much money on you.", "Put", "Back");
            new query[128];
            mysql_format(Database, query, sizeof(query), "INSERT INTO housesafelogs SET HouseID=%d, Type=1, Amount=%d, Date=UNIX_TIMESTAMP()", id, amount);
            mysql_tquery(Database, query, "", "");

            GivePlayerMoney(playerid, -amount);
            HouseData[id][SafeMoney] += amount;
            HouseData[id][Save] = true;
            ShowHouseMenu(playerid);
            return 1;
        }

        case DIALOG_GUNS_MENU:
        {
            if(!response) return ShowHouseMenu(playerid);
            new id = InHouse[playerid];
            if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not in a house.");
            if(strcmp(HouseData[id][Owner], PlayerInfo[playerid][Name])) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not the owner of this house.");
            if(listitem == 0)
            {
                if(GetPlayerWeapon(playerid) == 0) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You can't put your fists in your house.");
                new query[128], weapon = GetPlayerWeapon(playerid), ammo = GetPlayerAmmo(playerid);
                RemovePlayerWeapon(playerid, weapon);
                mysql_format(Database, query, sizeof(query), "INSERT INTO houseguns VALUES (%d, %d, %d) ON DUPLICATE KEY UPDATE Ammo=Ammo+%d", id, weapon, ammo, ammo);
                mysql_tquery(Database, query, "", "");
                ShowHouseMenu(playerid);
            }

            if(listitem == 1)
            {
                new query[80], Cache: weapons;
                mysql_format(Database, query, sizeof(query), "SELECT WeaponID, Ammo FROM houseguns WHERE HouseID=%d ORDER BY WeaponID ASC", id);
                weapons = mysql_query(Database, query);
                new rows = cache_num_rows();
                if(rows) {
                    new list[512], weapname[32], weapon_id, weapon_ammo;
                    format(list, sizeof(list), "#\tWeapon Name\tAmmo\n");
                    for(new i; i < rows; ++i)
                    {
                        cache_get_value_name_int(i, "WeaponID", weapon_id);
                        cache_get_value_name_int(i, "Ammo", weapon_ammo);

                        GetWeaponName(weapon_id, weapname, sizeof(weapname));
                        format(list, sizeof(list), "%s%d\t%s\t%s\n", list, i+1, weapname, convertNumber(weapon_ammo));
                    }

                    ShowPlayerDialog(playerid, DIALOG_GUNS_TAKE, DIALOG_STYLE_TABLIST_HEADERS, "{DC143C}|SFS|:{FFFFFF} House Guns", list, "Take", "Back");
                }else{
                    SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You don't have any guns in your house.");
                }

                cache_delete(weapons);
            }

            return 1;
        }

        case DIALOG_GUNS_TAKE:
        {
            if(!response) return ShowHouseMenu(playerid);
            new id = InHouse[playerid];
            if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not in a house.");
            if(strcmp(HouseData[id][Owner], PlayerInfo[playerid][Name])) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not the owner of this house.");
            new query[96], Cache: weapon;
            mysql_format(Database, query, sizeof(query), "SELECT WeaponID, Ammo FROM houseguns WHERE HouseID=%d ORDER BY WeaponID ASC LIMIT %d, 1", id, listitem);
            weapon = mysql_query(Database, query);
            new rows = cache_num_rows();
            if(rows) {
                new string[64], weapname[32], weaponid, ammo;
                cache_get_value_name_int(0, "WeaponID", weaponid);
                cache_get_value_name_int(0, "Ammo", ammo);

                GetWeaponName(weaponid, weapname, sizeof(weapname));
                GivePlayerWeapon(playerid, weaponid, ammo);
                format(string, sizeof(string), "You've taken a %s from your house.", weapname);
                SendClientMessage(playerid, 0xFFFFFFFF, string);
                mysql_format(Database, query, sizeof(query), "DELETE FROM houseguns WHERE HouseID=%d AND WeaponID=%d", id, weaponid);
                mysql_tquery(Database, query, "", "");
            }else{
                SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: Can't find that weapon.");
            }

            cache_delete(weapon);
            return 1;
        }

        case DIALOG_FURNITURE_MENU:
        {
            if(!response) return ShowHouseMenu(playerid);
            new id = InHouse[playerid];
            if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not in a house.");
            if(strcmp(HouseData[id][Owner], PlayerInfo[playerid][Name])) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not the owner of this house.");
            if(HouseData[id][SalePrice] > 0) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You can't use this feature while the house is for sale.");

            if(listitem == 0)
            {
                new list[512];
                format(list, sizeof(list), "#\tFurniture Name\tPrice\n");
                for(new i; i < sizeof(HouseFurnitures); ++i)
                {
                    format(list, sizeof(list), "%s%d\t%s\t$%s\n", list, i+1, HouseFurnitures[i][Name], convertNumber(HouseFurnitures[i][Price]));
                }

                ShowPlayerDialog(playerid, DIALOG_FURNITURE_BUY, DIALOG_STYLE_TABLIST_HEADERS, "{DC143C}|SFS|:{FFFFFF} Buy Furniture", list, "Buy", "Back");
            }

            if(listitem == 1)
            {
                SelectMode[playerid] = SELECT_MODE_EDIT;
                SelectObject(playerid);
                SendClientMessage(playerid, 0xFFFFFFFF, "*Click on the furniture you want to edit.");
            }

            if(listitem == 2)
            {
                SelectMode[playerid] = SELECT_MODE_SELL;
                SelectObject(playerid);
                SendClientMessage(playerid, 0xFFFFFFFF, "*Click on the furniture you want to sell.");
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
                format(string, sizeof(string), "{B7FF00}*Success{FFFFFF}: Sold %d furnitures for $%s.", sold, convertNumber(money));
                SendClientMessage(playerid, -1, string);
                GivePlayerMoney(playerid, money);

                mysql_format(Database, query, sizeof(query), "DELETE FROM housefurnitures WHERE HouseID=%d", id);
                mysql_tquery(Database, query, "", "");
            }

            return 1;
        }

        case DIALOG_FURNITURE_BUY:
        {
            if(!response) return ShowHouseMenu(playerid);
            new id = InHouse[playerid];
            if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not in a house.");
            if(strcmp(HouseData[id][Owner], PlayerInfo[playerid][Name])) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not the owner of this house.");
            if(HouseData[id][SalePrice] > 0) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You can't use this feature while the house is for sale.");
            if(HouseFurnitures[listitem][Price] > GetPlayerMoney(playerid)) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You can't afford this furniture.");
            GivePlayerMoney(playerid, -HouseFurnitures[listitem][Price]);
            new Float: x, Float: y, Float: z;
            GetPlayerPos(playerid, x, y, z);
            GetXYInFrontOfPlayer(playerid, x, y, 3.0);
            new objectid = CreateDynamicObject(HouseFurnitures[listitem][ModelID], x, y, z, 0.0, 0.0, 0.0, GetPlayerVirtualWorld(playerid), GetPlayerInterior(playerid)), query[256];
            mysql_format(Database, query, sizeof(query), "INSERT INTO housefurnitures SET HouseID=%d, FurnitureID=%d, FurnitureX=%f, FurnitureY=%f, FurnitureZ=%f, FurnitureVW=%d, FurnitureInt=%d", id, listitem, x, y, z, GetPlayerVirtualWorld(playerid), GetPlayerInterior(playerid));
            new Cache: add = mysql_query(Database, query), data[e_furniture];
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

        case DIALOG_FURNITURE_SELL:
        {
            if(!response) return 1;
            new id = InHouse[playerid];
            if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not in a house.");
            if(strcmp(HouseData[id][Owner], PlayerInfo[playerid][Name])) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not the owner of this house.");
            if(HouseData[id][SalePrice] > 0) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You can't use this feature while the house is for sale.");
            new objectid = GetPVarInt(playerid, "SelectedFurniture"), query[64], data[e_furniture];
            Streamer_GetArrayData(STREAMER_TYPE_OBJECT, objectid, E_STREAMER_EXTRA_ID, data);
            GivePlayerMoney(playerid, HouseFurnitures[ data[ArrayID] ][Price]);
            mysql_format(Database, query, sizeof(query), "DELETE FROM housefurnitures WHERE ID=%d", data[SQLID]);
            mysql_tquery(Database, query, "", "");
            DestroyDynamicObject(objectid);
            DeletePVar(playerid, "SelectedFurniture");
            return 1;
        }

        case DIALOG_VISITORS_MENU:
        {
            if(!response) return ShowHouseMenu(playerid);
            new id = InHouse[playerid];
            if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not in a house.");
            if(strcmp(HouseData[id][Owner], PlayerInfo[playerid][Name])) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not the owner of this house.");
            if(listitem == 0)
            {
                new query[200], Cache: visitors;
                mysql_format(Database, query, sizeof(query), "SELECT Visitor, FROM_UNIXTIME(Date, '%%d/%%m/%%Y %%H:%%i') as VisitDate FROM housevisitors WHERE HouseID=%d ORDER BY Date DESC LIMIT 0, 15", id);
                visitors = mysql_query(Database, query);
                new rows = cache_num_rows();
                if(rows) {
                    new list[1024], visitor_name[MAX_PLAYER_NAME], visit_date[20];
                    format(list, sizeof(list), "Visitor Name\tDate\n");
                    for(new i; i < rows; ++i)
                    {
                        cache_get_value_name(i, "Visitor", visitor_name);
                        cache_get_value_name(i, "VisitDate", visit_date);
                        format(list, sizeof(list), "%s%s\t%s\n", list, visitor_name, visit_date);
                    }

                    ShowPlayerDialog(playerid, DIALOG_VISITORS, DIALOG_STYLE_TABLIST_HEADERS, "{DC143C}|SFS|:{FFFFFF} House Visitors (Page 1)", list, "Next", "Previous");
                }else{
                    SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You didn't had any visitors.");
                }

                cache_delete(visitors);
            }

            if(listitem == 1)
            {
                new query[64];
                mysql_format(Database, query, sizeof(query), "DELETE FROM housevisitors WHERE HouseID=%d", id);
                mysql_tquery(Database, query, "", "");
                ShowHouseMenu(playerid);
            }

            return 1;
        }

        case DIALOG_VISITORS:
        {
            if(!response) {
                ListPage[playerid]--;
                if(ListPage[playerid] < 0)
                {
                    ListPage[playerid] = 0;
                    ShowHouseMenu(playerid);
                    return 1;
                }
            }else{
                ListPage[playerid]++;
            }

            new id = InHouse[playerid];
            if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not in a house.");
            if(strcmp(HouseData[id][Owner], PlayerInfo[playerid][Name])) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not the owner of this house.");
            new query[200], Cache: visitors;
            mysql_format(Database, query, sizeof(query), "SELECT Visitor, FROM_UNIXTIME(Date, '%%d/%%m/%%Y %%H:%%i') as VisitDate FROM housevisitors WHERE HouseID=%d ORDER BY Date DESC LIMIT %d, 15", id, ListPage[playerid]*15);
            visitors = mysql_query(Database, query);
            new rows = cache_num_rows();
            if(rows) {
                new list[1024], visitor_name[MAX_PLAYER_NAME], visit_date[20];
                format(list, sizeof(list), "Visitor Name\tDate\n");
                for(new i; i < rows; ++i)
                {
                    cache_get_value_name(i, "Visitor", visitor_name);
                    cache_get_value_name(i, "VisitDate", visit_date);
                    format(list, sizeof(list), "%s%s\t%s\n", list, visitor_name, visit_date);
                }

                new title[32];
                format(title, sizeof(title), "{DC143C}|SFS|:{FFFFFF} House Visitors (Page %d)", ListPage[playerid]+1);
                ShowPlayerDialog(playerid, DIALOG_VISITORS, DIALOG_STYLE_TABLIST_HEADERS, title, list, "Next", "Previous");
            }else{
                SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: Can't find any more visitors.");
                ListPage[playerid] = 0;
                ShowHouseMenu(playerid);
            }

            cache_delete(visitors);
            return 1;
        }

        case DIALOG_KEYS_MENU:
        {
            if(!response) return ShowHouseMenu(playerid);
            new id = InHouse[playerid];
            if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not in a house.");
            if(strcmp(HouseData[id][Owner], PlayerInfo[playerid][Name])) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not the owner of this house.");
            if(listitem == 0)
            {
                new query[200], Cache: keyowners;
                mysql_format(Database, query, sizeof(query), "SELECT Player, FROM_UNIXTIME(Date, '%%d/%%m/%%Y %%H:%%i') as KeyDate FROM housekeys WHERE HouseID=%d ORDER BY Date DESC LIMIT %d, 15", id, ListPage[playerid]*15);
                keyowners = mysql_query(Database, query);
                new rows = cache_num_rows();
                if(rows) {
                    new list[1024], key_name[MAX_PLAYER_NAME], key_date[20];
                    format(list, sizeof(list), "Key Owner\tKey Given On\n");
                    for(new i; i < rows; ++i)
                    {
                        cache_get_value_name(i, "Player", key_name);
                        cache_get_value_name(i, "KeyDate", key_date);
                        format(list, sizeof(list), "%s%s\t%s\n", list, key_name, key_date);
                    }

                    ShowPlayerDialog(playerid, DIALOG_KEYS, DIALOG_STYLE_TABLIST_HEADERS, "{DC143C}|SFS|:{FFFFFF} Key Owners (Page 1)", list, "Next", "Previous");
                }else{
                    SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: Can't find any key owners.");
                }

                cache_delete(keyowners);
            }

            if(listitem == 1)
            {
                foreach(new i : Player)
                {
                    if(Iter_Contains(HouseKeys[i], id)) Iter_Remove(HouseKeys[i], id);
                }

                new query[64];
                mysql_format(Database, query, sizeof(query), "DELETE FROM housekeys WHERE HouseID=%d", id);
                mysql_tquery(Database, query, "", "");
                ShowHouseMenu(playerid);
            }

            return 1;
        }

        case DIALOG_KEYS:
        {
            if(!response) {
                ListPage[playerid]--;
                if(ListPage[playerid] < 0)
                {
                    ListPage[playerid] = 0;
                    ShowHouseMenu(playerid);
                    return 1;
                }
            }else{
                ListPage[playerid]++;
            }

            new id = InHouse[playerid];
            if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not in a house.");
            if(strcmp(HouseData[id][Owner], PlayerInfo[playerid][Name])) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not the owner of this house.");
            new query[200], Cache: keyowners;
            mysql_format(Database, query, sizeof(query), "SELECT Player, FROM_UNIXTIME(Date, '%%d/%%m/%%Y %%H:%%i') as KeyDate FROM housekeys WHERE HouseID=%d ORDER BY Date DESC LIMIT %d, 15", id, ListPage[playerid]*15);
            keyowners = mysql_query(Database, query);
            new rows = cache_num_rows();
            if(rows) {
                new list[1024], key_name[MAX_PLAYER_NAME], key_date[20];
                format(list, sizeof(list), "Key Owner\tKey Given On\n");
                for(new i; i < rows; ++i)
                {
                    cache_get_value_name(i, "Player", key_name);
                    cache_get_value_name(i, "KeyDate", key_date);
                    format(list, sizeof(list), "%s%s\t%s\n", list, key_name, key_date);
                }

                new title[32];
                format(title, sizeof(title), "{DC143C}|SFS|:{FFFFFF} Key Owners (Page %d)", ListPage[playerid]+1);
                ShowPlayerDialog(playerid, DIALOG_KEYS, DIALOG_STYLE_TABLIST_HEADERS, title, list, "Next", "Previous");
            }else{
                ListPage[playerid] = 0;
                ShowHouseMenu(playerid);
                SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: Can't find any more key owners.");
            }

            cache_delete(keyowners);
            return 1;
        }

        case DIALOG_SAFE_HISTORY:
        {
            if(!response) {
                ListPage[playerid]--;
                if(ListPage[playerid] < 0)
                {
                    ListPage[playerid] = 0;
                    ShowHouseMenu(playerid);
                    return 1;
                }
            }else{
                ListPage[playerid]++;
            }

            new id = InHouse[playerid];
            if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, -1, "You're not in a house.");
            if(strcmp(HouseData[id][Owner], PlayerInfo[playerid][Name])) return SendClientMessage(playerid, -1, "You're not the owner of this house.");
            new query[200], Cache: safelog;
            mysql_format(Database, query, sizeof(query), "SELECT Type, Amount, FROM_UNIXTIME(Date, '%%d/%%m/%%Y %%H:%%i') as TransactionDate FROM housesafelogs WHERE HouseID=%d ORDER BY Date DESC LIMIT %d, 15", id, ListPage[playerid]*15);
            safelog = mysql_query(Database, query);
            new rows = cache_num_rows();
            if(rows) {
                new list[1024], type, amount, date[20];
                format(list, sizeof(list), "Action\tDate\n");
                for(new i; i < rows; ++i)
                {
                    cache_get_value_name_int(i, "Type", type);
                    cache_get_value_name_int(i, "Amount", amount);
                    cache_get_value_name(i, "TransactionDate", date);

                    format(list, sizeof(list), "%s%s $%s\t{FFFFFF}%s\n", list, TransactionNames[type], convertNumber(amount), date);
                }

                new title[32];
                format(title, sizeof(title), "{DC143C}|SFS|:{FFFFFF} Safe History (Page %d)", ListPage[playerid]+1);
                ShowPlayerDialog(playerid, DIALOG_SAFE_HISTORY, DIALOG_STYLE_TABLIST_HEADERS, title, list, "Next", "Previous");
            }else{
                SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: Can't find any more safe history.");
            }

            cache_delete(safelog);
            return 1;
        }

        case DIALOG_MY_KEYS:
        {
            if(!response) {
                ListPage[playerid]--;
                if(ListPage[playerid] < 0)
                {
                    ListPage[playerid] = 0;
                    return 1;
                }
            }else{
                ListPage[playerid]++;
            }

            new query[200], Cache: mykeys;
            mysql_format(Database, query, sizeof(query), "SELECT HouseID, FROM_UNIXTIME(Date, '%%d/%%m/%%Y %%H:%%i') as KeyDate FROM housekeys WHERE Player='%e' ORDER BY Date DESC LIMIT %d, 15", PlayerInfo[playerid][Name], ListPage[playerid]*15);
            mykeys = mysql_query(Database, query);

            new rows = cache_num_rows();
            if(rows) {
                new list[1024], id, key_date[20];
                format(list, sizeof(list), "House Info\tKey Given On\n");
                for(new i; i < rows; ++i)
                {
                    cache_get_value_name_int(i, "HouseID", id);
                    cache_get_value_name(i, "KeyDate", key_date);
                    format(list, sizeof(list), "%s%s's %s\t%s\n", list, HouseData[id][Owner], HouseData[id][Name], key_date);
                }

                new title[32];
                format(title, sizeof(title), "{DC143C}|SFS|:{FFFFFF} My Keys (Page %d)", ListPage[playerid]+1);
                ShowPlayerDialog(playerid, DIALOG_MY_KEYS, DIALOG_STYLE_TABLIST_HEADERS, title, list, "Next", "Previous");
            }else{
                ListPage[playerid] = 0;
                SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: Can't find any more keys.");
            }

            cache_delete(mykeys);
            return 1;
        }

        case DIALOG_BUY_HOUSE_FROM_OWNER:
        {
            if(!response) return 1;
            new id = GetPVarInt(playerid, "PickupHouseID");
            if(!IsPlayerInRangeOfPoint(playerid, 2.0, HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ])) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not near any house.");
            #if LIMIT_PER_PLAYER > 0
            if(OwnedHouses(playerid) + 1 > LIMIT_PER_PLAYER) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You can't buy any more houses.");
            #endif
            if(HouseData[id][SalePrice] > GetPlayerMoney(playerid)) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You can't afford this house.");
            if(HouseData[id][SalePrice] < 1) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}:Someone already owns this house.");
            new old_owner[MAX_PLAYER_NAME], price = HouseData[id][SalePrice], owner_id = INVALID_PLAYER_ID;
            format(old_owner, MAX_PLAYER_NAME, "%s", HouseData[id][Owner]);

            foreach(new i : Player)
            {
                if(!strcmp(HouseData[id][Owner], PlayerInfo[i][Name]))
                {
                    owner_id = i;
                    break;
                }
            }

            GivePlayerMoney(playerid, -HouseData[id][SalePrice]);
            GetPlayerName(playerid, HouseData[id][Owner], MAX_PLAYER_NAME);
            HouseData[id][LastEntered] = gettime();
            HouseData[id][SalePrice] = 0;
            HouseData[id][Save] = true;

            UpdateHouseLabel(id);
            Streamer_SetIntData(STREAMER_TYPE_PICKUP, HouseData[id][HousePickup], E_STREAMER_MODEL_ID, 19522);
            Streamer_SetIntData(STREAMER_TYPE_MAP_ICON, HouseData[id][HouseIcon], E_STREAMER_TYPE, 32);
            SendToHouse(playerid, id);

            foreach(new i : Player)
            {
                if(i == playerid) continue;
                if(InHouse[i] == id)
                {
                    SetPVarInt(i, "HousePickupCooldown", gettime() + HOUSE_COOLDOWN);
                    SetPlayerVirtualWorld(i, 0);
                    SetPlayerInterior(i, 0);
                    SetPlayerPos(i, HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ]);
                    InHouse[i] = INVALID_HOUSE_ID;
                }

                if(Iter_Contains(HouseKeys[i], id)) Iter_Remove(HouseKeys[i], id);
            }

            new query[128];
            if(IsPlayerConnected(owner_id)) {
                GivePlayerMoney(owner_id, price);

                new string[128];
                format(string, sizeof(string), "{B7FF00}*Success{FFFFFF}: %s(%d) has bought your house for $%s.", HouseData[id][Owner], playerid, convertNumber(price));
                SendClientMessage(owner_id, -1, string);
            }else{
                mysql_format(Database, query, sizeof(query), "INSERT INTO housesales SET OldOwner='%e', NewOwner='%e', Price=%d", old_owner, HouseData[id][Owner], price);
                mysql_tquery(Database, query, "", "");
            }

            mysql_format(Database, query, sizeof(query), "DELETE FROM housevisitors WHERE HouseID=%d", id);
            mysql_tquery(Database, query, "", "");

            mysql_format(Database, query, sizeof(query), "DELETE FROM housekeys WHERE HouseID=%d", id);
            mysql_tquery(Database, query, "", "");

            mysql_format(Database, query, sizeof(query), "DELETE FROM housesafelogs WHERE HouseID=%d", id);
            mysql_tquery(Database, query, "", "");
            return 1;
        }

        case DIALOG_SELL_HOUSE:
        {
            if(!response) return ShowHouseMenu(playerid);
            new id = InHouse[playerid];
            if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not in a house.");
            if(strcmp(HouseData[id][Owner], PlayerInfo[playerid][Name])) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not the owner of this house.");
            if(listitem == 0)
            {
                new money = floatround(HouseData[id][Price] * 0.85) + HouseData[id][SafeMoney];
                GivePlayerMoney(playerid, money);
                ResetHouse(id);
            }

            if(listitem == 1)
            {
                if(HouseData[id][SalePrice] > 0) {
                    HouseData[id][SalePrice] = 0;
                    HouseData[id][Save] = true;

                    UpdateHouseLabel(id);
                    Streamer_SetIntData(STREAMER_TYPE_PICKUP, HouseData[id][HousePickup], E_STREAMER_MODEL_ID, 19522);
                    Streamer_SetIntData(STREAMER_TYPE_MAP_ICON, HouseData[id][HouseIcon], E_STREAMER_TYPE, 32);
                    SendClientMessage(playerid, -1, "{B7FF00}*Success{FFFFFF}: Your house is no longer for sale.");
                }else{
                    if(HouseData[id][SafeMoney] > 0) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}:You can't put your house for sale if there's money in the safe.");
                    ShowPlayerDialog(playerid, DIALOG_SELLING_PRICE, DIALOG_STYLE_INPUT, "{DC143C}|SFS|:{FFFFFF} Sell House", "How much do you want for your house?", "Put For Sale", "Cancel");
                }
            }

            return 1;
        }

        case DIALOG_SELLING_PRICE:
        {
            if(!response) return ShowHouseMenu(playerid);
            new id = InHouse[playerid];
            if(id == INVALID_HOUSE_ID) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not in a house.");
            if(strcmp(HouseData[id][Owner], PlayerInfo[playerid][Name])) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not the owner of this house.");
            new amount = strval(inputtext);
            if(!(1 <= amount <= 10000000)) return ShowPlayerDialog(playerid, DIALOG_SELLING_PRICE, DIALOG_STYLE_INPUT, "{DC143C}|SFS|:{FFFFFF} Sell House", "{E74C3C}You can't put your house for sale for less than $1 or more than $100,000,000.\n\n{FFFFFF}How much do you want for your house?", "Put For Sale", "Cancel");
            HouseData[id][SalePrice] = amount;
            HouseData[id][Save] = true;

            UpdateHouseLabel(id);
            Streamer_SetIntData(STREAMER_TYPE_PICKUP, HouseData[id][HousePickup], E_STREAMER_MODEL_ID, 1273);
            Streamer_SetIntData(STREAMER_TYPE_MAP_ICON, HouseData[id][HouseIcon], E_STREAMER_TYPE, 31);

            new string[128];
            format(string, sizeof(string), "{B7FF00}*Success{FFFFFF}: You put your house for sale for $%s.", convertNumber(amount));
            SendClientMessage(playerid, -1, string);
            return 1;
        }
    }
    return 1;
}

forward OnAntiCheatUpdate();
public OnAntiCheatUpdate()
{
    for(new playerid; playerid < GetPlayerPoolSize(); playerid++)
    {
        if(IsPlayerNPC(playerid)) return 1;
        PlayerInfo[playerid][Money] = GetPlayerMoney(playerid);
        SetPlayerScore(playerid, PlayerInfo[playerid][Money]);
        if(!PlayerInfo[playerid][Given] && !PlayerInfo[playerid][Admin])
        {
            new string[22];
            new weaponid = GetPlayerWeapon(playerid);
            if(weaponid <= 35 || weaponid >= 39 )
            {
                valstr(string, playerid);
                strcat(string, " Multi Weapons Hacks");
                cmd_ban(GetPlayerId("EliteX"), string);
            }
            else if(GetPlayerSpecialAction(playerid) == SPECIAL_ACTION_USEJETPACK)
            {
                valstr(string, playerid);
                strcat(string, " Jetpack Hacks");
                cmd_ban(GetPlayerId("EliteX"), string);
            }
            else if(GetPlayerSpeed(playerid, true) > 450)
            {
                if(GetPlayerState(playerid) != PLAYER_STATE_PASSENGER && !IsPlane(GetPlayerVehicleID(playerid)) && !IsTrain(GetPlayerVehicleID(playerid)))
                {
                    valstr(string, playerid);
                    strcat(string, " Speed Hacks");
                    cmd_ban(GetPlayerId("EliteX"), string);
                }
            }
        }
    }
    return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
    TextDrawShowForPlayer(playerid, Death[0]);
    TextDrawShowForPlayer(playerid, Death[1]);
    TextDrawShowForPlayer(playerid, Death[2]);
    SetTimerEx("PlayDeathSong", 1000, 0, "i", playerid);
    SetTimerEx("HideMessage", 7000, 0, "i", playerid);

    new reasonMsg[32], msg[180];
    if (killerid != INVALID_PLAYER_ID)
	{
        if(PlayerInfo[playerid][InDM]) respawnindm(playerid);

		switch (reason)
		{
			case 0: reasonMsg = "Unarmed";
			case 1: reasonMsg = "Brass Knuckles";
			case 2: reasonMsg = "Golf Club";
			case 3: reasonMsg = "Night Stick";
			case 4: reasonMsg = "Knife";
			case 5: reasonMsg = "Baseball Bat";
			case 6: reasonMsg = "Shovel";
			case 7: reasonMsg = "Pool Cue";
			case 8: reasonMsg = "Katana";
			case 9: reasonMsg = "Chainsaw";
			case 10: reasonMsg = "Dildo";
			case 11: reasonMsg = "Dildo";
			case 12: reasonMsg = "Vibrator";
			case 13: reasonMsg = "Vibrator";
			case 14: reasonMsg = "Flowers";
			case 15: reasonMsg = "Cane";
			case 22: reasonMsg = "Pistol";
			case 23: reasonMsg = "Silenced Pistol";
			case 24: reasonMsg = "Desert Eagle";
			case 25: reasonMsg = "Shotgun";
			case 26: reasonMsg = "Sawn-off Shotgun";
			case 27: reasonMsg = "Combat Shotgun";
			case 28: reasonMsg = "MAC-10";
			case 29: reasonMsg = "MP5";
			case 30: reasonMsg = "AK-47";
			case 31: reasonMsg = "M4";
			case 32: reasonMsg = "TEC-9";
			case 33: reasonMsg = "Country Rifle";
			case 34: reasonMsg = "Sniper Rifle";
			case 37: reasonMsg = "Fire";
			case 38: reasonMsg = "Minigun";
			case 41: reasonMsg = "Spray Can";
			case 42: reasonMsg = "Fire Extinguisher";
			case 49: reasonMsg = "Vehicle Collision";
			case 50: reasonMsg = "Vehicle Collision";
			case 51: reasonMsg = "Explosion";
			default: reasonMsg = "Unknown";
		}
		format(msg, sizeof(msg), "04* %s has been killed by %s using %s", PlayerInfo[killerid][Name], PlayerInfo[playerid][Name], reasonMsg);
        PlayerInfo[killerid][Kills]++;
        printf("[Gamemode::Death]: Player %s, KillerId: %d, Weapon: %s", PlayerInfo[playerid][Name], PlayerInfo[killerid][Name], reason);
	}
	else
	{
		switch (reason)
		{
			case 53: format(msg, sizeof(msg), "04* %s died. (Drowned)", PlayerInfo[playerid][Name]);
			case 54: format(msg, sizeof(msg), "04* %s died. (Collision)", PlayerInfo[playerid][Name]);
			default: format(msg, sizeof(msg), "04* %s died.", PlayerInfo[playerid][Name]);
		}
        printf("[Gamemode::Death]: Player %s, Weapon: %s", PlayerInfo[playerid][Name], PlayerInfo[killerid][Name], reason);
	}
    #if USE_EXTERN_CHAT == 1
        #if USE_DISCORD == 1
            IRC_GroupSay(GroupId, IRC_ECHO, msg);
            format(msg, sizeof(msg), "* %s has been killed by %s using %s", PlayerInfo[playerid][Name], PlayerInfo[killerid][Name], reasonMsg);
        #endif
        #if USE_DISCORD == 1
            DCC_SendChannelMessage(DDC_Echo_Channel, msg);
        #endif
    #endif

	PlayerInfo[playerid][Deaths]++;
	PlayerInfo[playerid][Spawned] = false;
	SendDeathMessage(killerid, playerid, reason);

	return 1;
}

public OnPlayerSelectDynamicObject(playerid, objectid, modelid, Float: x, Float: y, Float: z)
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
			format(string, sizeof(string), "Do you want to sell your %s?\nYou'll get {2ECC71}$%s.", HouseFurnitures[ data[ArrayID] ][Name], convertNumber(HouseFurnitures[ data[ArrayID] ][Price]));
			ShowPlayerDialog(playerid, DIALOG_FURNITURE_SELL, DIALOG_STYLE_MSGBOX, "{DC143C}|SFS|:{FFFFFF} Confirm Sale", string, "Sell", "Close");
		}
	}

    SelectMode[playerid] = SELECT_MODE_NONE;
	return 1;
}

public OnPlayerTakeDamage(playerid, issuerid, Float: amount, weaponid, bodypart)
{
	if(IsPlayerConnected(issuerid))
	{
		if(weaponid == 24 || weaponid == 34)
		{
			if(bodypart == 9)
			{
				SetPlayerHealth(playerid, 0);
				GameTextForPlayer(issuerid,"~r~Headshot",2000,3);
				GameTextForPlayer(playerid,"Ouch, ~r~Headshot",2000,3);
				PlayAudioStreamForPlayer(playerid, "https://crew.sa-mp.nl/jay/radio/headshot.mp3");
				PlayAudioStreamForPlayer(issuerid, "https://crew.sa-mp.nl/jay/radio/headshot.mp3");
				PlayerPlaySound(issuerid, 17802, 0.0, 0.0, 0.0);
				PlayerPlaySound(playerid, 17802, 0.0, 0.0, 0.0);
			}
		}
	}
    return 1;
}

public OnPlayerEditDynamicObject(playerid, objectid, response, Float: x, Float: y, Float: z, Float: rx, Float: ry, Float: rz)
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

		        mysql_format(Database, query, sizeof(query), "UPDATE housefurnitures SET FurnitureX=%f, FurnitureY=%f, FurnitureZ=%f, FurnitureRX=%f, FurnitureRY=%f, FurnitureRZ=%f WHERE ID=%d", data[furnitureX], data[furnitureY], data[furnitureZ], data[furnitureRX], data[furnitureRY], data[furnitureRZ], data[SQLID]);
		        mysql_tquery(Database, query, "", "");

		        EditingFurniture[playerid] = false;
			}
		}
	}

	return 1;
}

public OnPlayerText(playerid, text[])
{
    if(PlayerInfo[playerid][Muted])
    {
        SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You are muted, no-one can hear you!");
        return 0;
    }

    new str[80 + MAX_CHAT_SIZE];
    if(text[0] == '@')
    {
        switch(PlayerInfo[playerid][Admin])
        {
            case 0:
            {
                format(str, sizeof(str), "Player %s (Id: %d) asked a question: %s", PlayerInfo[playerid][Name], playerid, text[1]);
                SendClientMessage(playerid, 0x33AA33AA, "*You're message has been sended to our admins.");
                AdminNotice(str);
                return 0;
            }
            case 1: format(str, sizeof(str), "{FFFF00}*Admin({FFFFFF}%s{FFFF00}){FFFFFF}: %s", PlayerInfo[playerid][Name], text[1]);
            case 2: format(str, sizeof(str), "{FFFF00}*Manager({FFFFFF}%s{FFFF00}){FFFFFF}: %s", PlayerInfo[playerid][Name], text[1]);
            case 3: format(str, sizeof(str), "{FFFF00}*Server Co-Owner({FFFFFF}%s{FFFF00}){FFFFFF}: %s", PlayerInfo[playerid][Name], text[1]);
            case 4: format(str, sizeof(str), "{FFFF00}*Server Owner({FFFFFF}%s{FFFF00}){FFFFFF}: %s", PlayerInfo[playerid][Name], text[1]);
        }
        for(new i = 0; i < GetPlayerPoolSize(); i++)
        {
            if(PlayerInfo[i][Admin] > 0)
            {
                SendClientMessage(i, -1, str);
            }
        }
        switch(PlayerInfo[playerid][Admin])
        {
            case 1: format(str, sizeof(str), "07*Admin(%s07): %s", PlayerInfo[playerid][Name], text[1]);
            case 2: format(str, sizeof(str), "07*Manager(%s07): %s", PlayerInfo[playerid][Name], text[1]);
            case 3: format(str, sizeof(str), "07*Server Co-Owner(%s07): %s", PlayerInfo[playerid][Name], text[1]);
            case 4: format(str, sizeof(str), "07*Server Owner(%s07): %s", PlayerInfo[playerid][Name], text[1]);
        }
        IRC_Say(IRCBots[0], "%"IRC_ECHO"", str); 
        return 0;
    }

    if(GetPlayerVirtualWorld(playerid) != 0)
    {
        format(str, sizeof(str), "[Virtual World %d] [%d] %s: {FFFFFF}%s", GetPlayerVirtualWorld(playerid), playerid, PlayerInfo[playerid][Name], text);
        for(new i = 0; i < MAX_PLAYERS; i++)
        {
            if(GetPlayerVirtualWorld(i) == GetPlayerVirtualWorld(playerid) || PlayerInfo[playerid][Admin] > 0) SendClientMessage(i, GetPlayerColor(playerid), str);
        }
        format(str, sizeof(str),"07[Virtual World %d] 02[%d] 07%s: %s", GetPlayerVirtualWorld(playerid), playerid, PlayerInfo[playerid][Name],text);
        IRC_GroupSay(IRCBots[0], "+"IRC_ECHO"", str);
        return 0;
    }

	format(str, sizeof(str), "[%d] %s: {FFFFFF}%s", playerid, PlayerInfo[playerid][Name], text);
	SendClientMessageToAll(GetPlayerColor(playerid), str);

    switch(g_TestBusy)
    {
        case true:
        {
            if(!strcmp(g_Chars, text, false))
            {
                new string[128];

                format(string, sizeof(string), "{00FF40}*Announces: {FFFFFF}%s has won the reaction test. and he did earn %d.", PlayerInfo[playerid][Name], g_Cash);
                SendClientMessageToAll(-1, string);
                GivePlayerMoney(playerid, g_Cash);
                SetTimer("OnReactionTestStart", 2*60*1000, false);
                g_TestBusy = false;
            }
        }
    }

    #if USE_EXTERN_CHAT == 1
        #if USE_IRC == 1
            format(str, sizeof(str), "02[%d] 07%s: %s", playerid, PlayerInfo[playerid][Name], text);
            IRC_GroupSay(GroupId, IRC_ECHO, str);
        #endif
        #if USE_DISCORD == 1
            format(str, sizeof(str), "[%d] %s: %s", playerid, PlayerInfo[playerid][Name], text);
            DCC_SendChannelMessage(DDC_Echo_Channel, str);
        #endif
    #endif
	printf("[Gamemode::Chat]: Player %s, Chat: %s", PlayerInfo[playerid][Name], text);
	return 0;
}

public OnPlayerPickUpPickup(playerid, pickupid)
{
    if(pickupid == m_Pickup)
    {
        new 
        	string[170],
        	pname[24], 
         	money = random(MAX_MONEYBAG_MONEY - MIN_MONEYBAG_MONEY) + MIN_MONEYBAG_MONEY 
        ;

        GetPlayerName(playerid, pname, 24);

        DestroyPickup(m_Pickup);

        GivePlayerMoney(playerid, money);

        #if defined WEAPONS_BOUNS

        new 
        	weapon = random(sizeof(WeaponsBouns)),
        	ammo   = random(MAX_WEAPONS_AMMO - MIN_WEAPONS_AMMO) + MIN_WEAPONS_AMMO
        ;

        GivePlayerWeapon(playerid, WeaponsBouns[weapon], ammo);

        #endif

        format(string, sizeof(string), "{00FF40}*Announces: {FFFFFF}%s has found the money bag that had $%d inside, located in %s", pname, money, m_Location);
        SendClientMessageToAll(-1, string);

        m_Found = true;
    }
    return 1;
}

public OnPlayerCommandPerformed(playerid, cmdtext[], success)
{
	if(!success) SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: this command not exists, please take a look on /cmds.");
	else
	{
        if(PlayerInfo[playerid][Admin] > 0) return 1;
		if(!IsPlayerSpawned(playerid)) 
        {
            SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: you can't use any commands while you wasted.");
            return 0;
        }
        if(PlayerInfo[playerid][InDM])
        {
            if(!strfind(cmdtext, "/leave")) return 1;
            SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: you can't use any commands while you are at deathmatch area.");
            return 0;
        }     
        if(PlayerInfo[playerid][Fighting])
        {
            SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: you can't use any commands while you shoot or being shooted.");
            return 0;
        }
        if(GetPlayerInterior(playerid) == 1)
        {
            SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: you can't use any commands while you are at interior.");
            return 0;
        }
		printf("[Gamemode::Command]: Player %s, Command: %s", PlayerInfo[playerid][Name], cmdtext);
	}
	return 1;
}

public OnPlayerClickPlayer(playerid, clickedplayerid, source)
{
	new str[2];
	format(str, sizeof(str), "%d", clickedplayerid);
	cmd_stats(playerid, str);
	return 1;
}

new npcid = 0;
public OnPlayerSpawn(playerid)
{
    if(IsPlayerNPC(playerid))
    {
        SetPlayerSkin(playerid, 217);
        GivePlayerWeapon(playerid, 24, 1000);
		if(!strcmp(PlayerInfo[playerid][Name], "StrikerX", false, 8))
		{
			PutPlayerInVehicle(playerid, NPCCars[npcid], 0);
            npcid++;
            return 1;
		}
        return 1;
    }
    InHouse[playerid] = INVALID_HOUSE_ID;

	new query[128];
	mysql_format(Database, query, sizeof(query), "SELECT * FROM housesales WHERE OldOwner='%e'", PlayerInfo[playerid][Name]);
	mysql_tquery(Database, query, "HouseSaleMoney", "i", playerid);

    new XRandom = random(sizeof(RandomSpawns));
	SetPlayerPos(playerid, RandomSpawns[XRandom][0], RandomSpawns[XRandom][1], RandomSpawns[XRandom][2]);
    SetPlayerFacingAngle(playerid, RandomSpawns[XRandom][3]);

    PlayerTextDrawShow(playerid, StatusBar);
	PlayerInfo[playerid][Spawned] = true;
    for(new i = 0; i < sizeof(SPAWN_WEAPONS); i++) GivePlayerWeapon(playerid, SPAWN_WEAPONS[i][0], SPAWN_WEAPONS[i][1]);
	printf("[Gamemode::Spawn]: Player %s has been spawned.", PlayerInfo[playerid][Name]);
    StopAudioStreamForPlayer(playerid);
    return 1;
}


public OnPlayerPickUpDynamicPickup(playerid, pickupid)
{
	if(GetPVarInt(playerid, "HousePickupCooldown") < gettime())
	{
	    if(InHouse[playerid] == INVALID_HOUSE_ID) {
			foreach(new i : Houses)
			{
			    if(pickupid == HouseData[i][HousePickup])
			    {
			        SetPVarInt(playerid, "HousePickupCooldown", gettime() + HOUSE_COOLDOWN);
			        SetPVarInt(playerid, "PickupHouseID", i);

					if(!strcmp(HouseData[i][Owner], "-")) {
						new string[64];
						format(string, sizeof(string), "This house is for sale!\n\nPrice: {2ECC71}$%s", convertNumber(HouseData[i][Price]));
						ShowPlayerDialog(playerid, DIALOG_BUY_HOUSE, DIALOG_STYLE_MSGBOX, "{DC143C}|SFS|:{FFFFFF} House For Sale", string, "Buy", "Close");
					}else{
					    if(HouseData[i][SalePrice] > 0 && strcmp(HouseData[i][Owner], PlayerInfo[playerid][Name]))
					    {
                            new string[64];
							format(string, sizeof(string), "This house is for sale!\n\nPrice: {2ECC71}$%s", convertNumber(HouseData[i][SalePrice]));
							ShowPlayerDialog(playerid, DIALOG_BUY_HOUSE_FROM_OWNER, DIALOG_STYLE_MSGBOX, "{DC143C}|SFS|:{FFFFFF} House For Sale", string, "Buy", "Close");
							return 1;
					    }

					    switch(HouseData[i][LockMode])
					    {
					        case LOCK_MODE_NOLOCK: SendToHouse(playerid, i);
					        case LOCK_MODE_PASSWORD: ShowPlayerDialog(playerid, DIALOG_HOUSE_PASSWORD, DIALOG_STYLE_INPUT, "{DC143C}|SFS|:{FFFFFF} House Password", "This house is password protected.\n\nEnter house password:", "Done", "Close");
							case LOCK_MODE_KEYS:
							{
							    new gotkeys = Iter_Contains(HouseKeys[playerid], i);
							    if(!gotkeys) if(!strcmp(HouseData[i][Owner], PlayerInfo[playerid][Name])) gotkeys = 1;

								if(gotkeys) {
									SendToHouse(playerid, i);
								}else{
								    SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You don't have keys for this house, you can't enter.");
								}
							}

					        case LOCK_MODE_OWNER:
					        {
								if(!strcmp(HouseData[i][Owner], PlayerInfo[playerid][Name])) {
								    SetPVarInt(playerid, "HousePickupCooldown", gettime() + HOUSE_COOLDOWN);
						            SendToHouse(playerid, i);
								}else{
								    SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: only the owner can enter this house.");
								}
					        }
					    }
					}

			        return 1;
			    }
			}
		}else{
			for(new i; i < sizeof(HouseInteriors); ++i)
			{
			    if(pickupid == HouseInteriors[i][intPickup])
			    {
			        SetPVarInt(playerid, "HousePickupCooldown", gettime() + HOUSE_COOLDOWN);
			        SetPlayerVirtualWorld(playerid, 0);
			        SetPlayerInterior(playerid, 0);
			        SetPlayerPos(playerid, HouseData[ InHouse[playerid] ][houseX], HouseData[ InHouse[playerid] ][houseY], HouseData[ InHouse[playerid] ][houseZ]);
			        InHouse[playerid] = INVALID_HOUSE_ID;
			        return 1;
			    }
			}
		}
	}

	return 1;
}

#if USE_EXTERN_CHAT == 1
    #if USE_IRC == 1
        public IRC_OnConnect(botid, ip[], port)
        {
            printf("[Gamemode::IRC]: BotId %d has been connected to "IRC_SERVER" Using IP %s:%d.",botid, ip, port);
            IRC_JoinChannel(IRCBots[3], "#sfs.crew");
            if(strcmp(IRC_PASS, "")) IRC_SendRaw(botid, "privmsg nickserv id "IRC_PASS"");
            IRC_JoinChannel(botid, IRC_ECHO);
            printf("[Gamemode::IRC]: BotId %d has joined "IRC_ECHO".", botid); 
            IRC_AddToGroup(GroupId, botid);
            printf("[Gamemode::IRC]: BotId %d has joined GroupId %d.", botid, GroupId); 
            return 1;
        }
        public IRC_OnDisconnect(botid, ip[], port, reason[])
        {
            IRC_RemoveFromGroup(GroupId, botid);
            printf("[Gamemode::IRC]: BotId %d has left GroupId %d.", botid, GroupId);
            printf("[Gamemode::IRC]: BotId %d has left "IRC_ECHO".", botid); 
            printf("[Gamemode::IRC]: BotId %d has left %s:%d.", botid, ip, port); 
            return 1;
        }
        public IRC_OnKickedFromChannel(botid, channel[], oppeduser[], oppedhost[], message[])
        {
            IRC_JoinChannel(botid, channel);
            return 1;
        }
    #endif
#endif
public OnPlayerDisconnect(playerid, reason)
{
    if(IsPlayerNPC(playerid)) return 1;
	SaveStats(playerid);
    new reasonMsg[8];
    switch(reason)
	{
		case 0: reasonMsg = "Timeout";
		case 1: reasonMsg = "Leaving";
		case 2: reasonMsg = "Kicked";
	}

	new str[80];
    if(reconnect_[playerid]) format(str, sizeof(str), "{C3C3C3}*%s (Id: %d) has joined {6EF83C}Stunt {F81414}Freeroam {0049FF}Server. (Reconnecting)", PlayerInfo[playerid][Name], playerid, reasonMsg);
	else format(str, sizeof(str), "{C3C3C3}*%s (Id: %d) has joined {6EF83C}Stunt {F81414}Freeroam {0049FF}Server. (%s)", PlayerInfo[playerid][Name], playerid, reasonMsg);
	SendClientMessageToAll(-1, str);
    #if USE_EXTERN_CHAT == 1
        #if USE_DISCORD == 1
            DCC_SendChannelMessage(DDC_Echo_Channel, str);
        #endif
        #if USE_IRC == 1
            if(reconnect_[playerid]) format(str, sizeof(str), "02[%d] 03*** %s has left the server. (Reconnecting)", playerid, PlayerInfo[playerid][Name], reasonMsg);
            else format(str, sizeof(str), "02[%d] 03*** %s has left the server. (%s)", playerid, PlayerInfo[playerid][Name], reasonMsg);
            IRC_GroupSay(GroupId, IRC_ECHO, str);
        #endif
    #endif
    reconnect_[playerid] = false;
    if(PlayerInfo[playerid][CreatedRamp] == true) DestroyObject(PlayerInfo[playerid][Ramp]), PlayerInfo[playerid][CreatedRamp] = false;
    PlayerInfo[playerid][CreatedRamp] = false;
    PlayerInfo[playerid][Pers]=0;
	return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
    if (IsPlayerInAnyVehicle(playerid))
    {
        if((newkeys & KEY_ACTION) && !(oldkeys & KEY_ANALOG_UP))
        {
            switch(GetVehicleModel( GetPlayerVehicleID(playerid) )) 
            {
                case 592,577,511,512,593,520,553,476,519,460,513,487,488,548,425,417,497,563,447,469:
                return 1;
            }
            if(PlayerInfo[playerid][CreatedRamp] == true) DestroyObject(PlayerInfo[playerid][Ramp]), PlayerInfo[playerid][CreatedRamp] = false;
            new Float:pX,Float:pY,Float:pZ,Float:vA, Arabam = GetPlayerVehicleID(playerid);
            GetVehiclePos(Arabam, pX, pY, pZ);
            GetVehicleZAngle(Arabam, vA);
            PlayerInfo[playerid][Ramp] = CreateObject(PlayerInfo[playerid][Pers], pX + (20.0 * floatsin(-vA, degrees)), pY + (20.0 * floatcos(-vA, degrees)), pZ, 0, 0, vA);
            PlayerInfo[playerid][CreatedRamp] = true;
            SetTimerEx("destroy", 4000,0,"d",playerid);
        }
    }
    return 1;
}

public OnPlayerPause(playerid) 
{
    if(GetPlayerState(playerid) == PLAYER_STATE_SPAWNED)
    {
        new nick[50];
        SetPVarString(playerid, "FirstNick", PlayerInfo[playerid][Name]);
        format(nick, sizeof(nick), "[AFK]%s", PlayerInfo[playerid][Name]);
        SetPlayerName(playerid, nick);
        return 1;
    }
    return 1;
}

public OnPlayerUnpause(playerid) 
{
    if(GetPlayerState(playerid) == PLAYER_STATE_SPAWNED)
    {
        new str[20];
        GetPVarString(playerid, "FirstNick", str, sizeof(str));
        SetPlayerName(playerid, str);
        return 1;
    }
    return 1;
}

public OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ)
{
    if(PlayerInfo[playerid][Fighting] == 1) return 1;
    PlayerInfo[playerid][Fighting] = 1;
    SetTimerEx("OnPlayerFinishFight", 15*1000, false, "i", playerid);
    return 1;
}

#if USE_EXTERN_CHAT == 1

#if USE_DISCORD == 1

// Discord Commands
DCCMD:cmds(channel[], user[], params[])
{
    DCC_SendChannelMessage(DDC_Echo_Channel, "Commands: !say !players !stats !pm !getid !uptime");
    return 1;
}

DCCMD:say(channel[], user[], params[])
{
	new msg[128];
    format(msg, sizeof(msg), "[-] %s: %s", user, params);
    DCC_SendChannelMessage(DDC_Echo_Channel, msg);

    format(msg, sizeof(msg), "[Discord][-] %s: %s", user, params);
    SendClientMessageToAll(-1, msg);

	#pragma unused channel
	return 1;
}

DCCMD:players(channel[], user[], params[])
{
    new count, PlayerNames[512], string[256];
    for(new i = 0; i <= MAX_PLAYERS; i++)
    {
        if(IsPlayerConnected(i))
        {
            if(count == 0)
            {
				format(PlayerNames, sizeof(PlayerNames),"%s", PlayerInfo[i][Name]);
				count++;
			}
			else format(PlayerNames, sizeof(PlayerNames),"%s, %s", PlayerNames, PlayerInfo[i][Name]); count++;
        }
    }
    if(count == 0) PlayerNames = "there no players in server at moment.";

    new counter = 0;
    for(new i=0; i<=MAX_PLAYERS; i++) if(IsPlayerConnected(i)) counter++;

    format(string, 256, "Connected Players[%d]: %s", counter, PlayerNames);
    DCC_SendChannelMessage(DDC_Echo_Channel, string);
	return 1;
}


DCCMD:pm(channel[], user[], params[])
{
    new str[120], msg[120], id;
    if(sscanf(params, "us[100]", id, msg))  IRC_Say(GroupId, channel, "Usage: !pm [playerid] [message]");
    if(!IsPlayerConnected(id)) return IRC_Say(GroupId, channel, "Error: Invalid Player ID.");
    format(str, sizeof(str), "*PM From [Discord]%s : %s", user, msg);
    SendClientMessage(id, -1, str);
	format(str, sizeof(str), "Private Message from [Discord]%s to %s (Id: %d): %s", user, PlayerInfo[id][Name], id, msg);
    AdminNotice(str);
    return 1;
}

DCCMD:stats(channel[], user[], params[])
{
	new str[160], name[MAX_PLAYER_NAME], time, kills, deaths, admin, vip, userid, skin, money, h, m, s;
	if(sscanf(params, "s[24]", name)) return DCC_SendChannelMessage(DDC_Echo_Channel, "Usage: !stats [name]");
    secs2hms(time, h, m, s);
    new color;
	new int = GetPlayerStats(name, userid, time, kills, deaths, admin, vip, skin, money, color);
	if(!int) return DCC_SendChannelMessage(DDC_Echo_Channel, "Error: this account not exists.");
	format(str, sizeof(str), "*%s is an %s, he was online for %s hours, %d minutes and %d seconds.", name, GetLevel(admin), h, m, s);
	DCC_SendChannelMessage(DDC_Echo_Channel, str);
	format(str, sizeof(str), "*he have %s $ as amount of money hand, he wasted %d players, and got wasted %d too far. ", money, kills, deaths);
	if(vip > 0) strcat(str, "and he is an Very Important Player.");
	DCC_SendChannelMessage(DDC_Echo_Channel, str);
	return 1;
}	

DCCMD:getid(channel[], user[], params[])
{
	new name[24], msg[128];
	if (sscanf(params, "s[24]", name)) return DCC_SendChannelMessage(DDC_Echo_Channel, "Usage: !getid [name or part of name]");
	if (strlen(params) > 20) return DCC_SendChannelMessage(DDC_Echo_Channel, "No matches");
	format(msg, sizeof(msg), "Matches:");
	for(new i = 0; i < GetPlayerPoolSize(); i++)
	{
		if (strfind(PlayerInfo[i][Name], name, true) == -1) continue;
		if (strlen(msg) + 30 > 128) break;
		format(msg, sizeof(msg), "%s %s(%d),", msg, PlayerInfo[i][Name], i);
	}
	if (strlen(msg) < 12) return DCC_SendChannelMessage(DDC_Echo_Channel, "No matches");
	strdel(msg, strlen(msg)-1, strlen(msg));
	DCC_SendChannelMessage(DDC_Echo_Channel, msg);
	return 1;
}

DCCMD:uptime(channel[], user[], params[])
{
	new msg[128], h, m, s, uptime = gettime()-starttime;
	secs2hms(uptime, h, m, s);
	format(msg, sizeof(msg), "Server uptime: %d hour(s) %d minute(s) %d second(s).", h, m, s);
	DCC_SendChannelMessage(DDC_Echo_Channel, msg);
	return 1;
}
#endif

#if USE_IRC == 1
// IRC Commands
IRCCMD:stats(botid, channel[], user[], host[], params[])
{
	new str[160], name[MAX_PLAYER_NAME], time, kills, deaths, admin, vip, userid, skin, money, h, m, s, color;
	if(sscanf(params, "s[24]", name)) return IRC_Reply(USAGE, channel, "!stats [name]");
	new int = GetPlayerStats(name, userid, time, kills, deaths, admin, vip, skin, money, color);
    secs2hms(time, h, m, s);
	if(!int) return IRC_Reply(ERROR, channel, "this account not exists");
    switch(admin)
    {
        case 0: str = "Regular Player";
        case 1: str = "Administrator";
        case 2: str = "Management";
        case 3: str = "Server Co-Owner";
        case 4: str = "Server Owner";
    }
	format(str, sizeof(str), "*%s is an %s, he was online for %d hours, %d minutes and %d seconds.", name, str, h, m, s);
	IRC_Say(GroupId, channel, str);
	format(str, sizeof(str), "*he wasted %d players, and got wasted %d too far. ", kills, deaths);
	if(vip > 0) strcat(str, "and he is an Very Important Player.");
	IRC_Say(GroupId, channel, str);
	return 1;
}

IRCCMD:uptime(botid, channel[], user[], host[], params[])
{
	new msg[128], h, m, s, uptime = gettime() - starttime;
	secs2hms(uptime, h, m, s);
	format(msg, sizeof(msg), "Server uptime: %d hour(s) %d minute(s) %d second(s).", h, m, s);
	IRC_Reply(SUCCESS, channel, msg);
	return 1;
}

IRCCMD:getid(botid, channel[], user[], host[], params[])
{
	new name[24], msg[128];
	if (sscanf(params, "s[24]", name)) return IRC_Reply(USAGE, channel, "!getid [name or part of name]");
	if (strlen(params) > 20) return IRC_Reply(ERROR, channel, "No matches");
	for(new i = 0; i < GetPlayerPoolSize(); i++)
	{
		if (strfind(PlayerInfo[i][Name], name, true) == -1) continue;
		if (strlen(msg) + 30 > 128) break;
		format(msg, sizeof(msg), "%s(%d),", PlayerInfo[i][Name], i);
	}
	if (strlen(msg) < 12) return IRC_Reply(ERROR, channel, "No matches");
	strdel(msg, strlen(msg)-1, strlen(msg));
	IRC_Reply(SUCCESS, channel, msg);
	return 1;
}

IRCCMD:say(botid, channel[], user[], host[], params[])
{
	if(isnull(params)) return IRC_Reply(USAGE, channel, "!say [message]");
	new msg[128];
    if (IRC_IsOwner(botid, channel, user))
    {
        format(msg, sizeof(msg), "02Owner(%s) on IRC: %s", user, params);
        IRC_GroupSay(GroupId, channel, msg);
        format(msg, sizeof(msg), "*Owner(%s): %s", user, params);
        SendClientMessageToAll(-1, msg);
        return 1;
    }
    if (IRC_IsAdmin(botid, channel, user))
    {
        format(msg, sizeof(msg), "02Co-Owner(%s) on IRC: %s", user, params);
        IRC_GroupSay(GroupId, channel, msg);
        format(msg, sizeof(msg), "*Co-Owner(%s): %s", user, params);
        SendClientMessageToAll(-1, msg);
        return 1;
    }
    if (IRC_IsOp(botid, channel, user))
    {
        format(msg, sizeof(msg), "02Manager(%s) on IRC: %s", user, params);
        IRC_GroupSay(GroupId, channel, msg);
        format(msg, sizeof(msg), "*Manager(%s): %s", user, params);
        SendClientMessageToAll(-1, msg);
        return 1;
    }
    if (IRC_IsHalfop(botid, channel, user))
    {
        format(msg, sizeof(msg), "02Admin(%s) on IRC: %s", user, params);
        IRC_GroupSay(GroupId, channel, msg);
        format(msg, sizeof(msg), "*Admin(%s): %s", user, params);
        SendClientMessageToAll(-1, msg);
        return 1;
    }
    if (IRC_IsVoice(botid, channel, user))
    {
        format(msg, sizeof(msg), "02*VIP(%s) on IRC: %s", user, params);
        IRC_GroupSay(GroupId, channel, msg);
        format(msg, sizeof(msg), "*VIP(%s): %s", user, params);
        SendClientMessageToAll(-1, msg);
        return 1;
    }
    else
    {
        format(msg, sizeof(msg), "02[-] 07%s: %s", user, params);
        IRC_GroupSay(GroupId, channel, msg);
        format(msg, sizeof(msg), "[IRC][-] %s: %s", user, params);
        SendClientMessageToAll(-1, msg);
		return 1;
    }
}

IRCCMD:freeze(botid, channel[], user[], host[], params[])
{
    if (!IRC_IsHalfop(botid, channel, user)) return IRC_Reply(ERROR, channel, "this command require more privilages than you got.");
    new playerid, reason[64];
    if (sscanf(params, "dS(No reason)[64]", playerid, reason)) return IRC_Reply(USAGE, channel, "!freeze [playerid] [reason]");
    if (!IsPlayerConnected(playerid)) return IRC_Reply(ERROR, channel, "this player is not connected.");
    new msg[128];
    format(msg, sizeof(msg), "%s has been freezed by %s on IRC. (%s)", PlayerInfo[playerid][Name], user, reason);
    AdminNotice(msg);
    TogglePlayerControllable(playerid, 0);
    return 1;
}

IRCCMD:unfreeze(botid, channel[], user[], host[], params[])
{
    if (!IRC_IsHalfop(botid, channel, user)) return IRC_Reply(ERROR, channel, "this command require more privilages than you got.");
    new playerid, reason[64];
    if (sscanf(params, "dS(No reason)[64]", playerid, reason)) return IRC_Reply(USAGE, channel, "!unfreeze [playerid] [reason]");
    if (!IsPlayerConnected(playerid)) return IRC_Reply(ERROR, channel, "this player is not connected.");
    new msg[128];
    format(msg, sizeof(msg), "%s (Id: %d) has been unfreezed by %s on IRC. (%s)", PlayerInfo[playerid][Name], playerid, user, reason);
    AdminNotice(msg);
    TogglePlayerControllable(playerid, 1);
    return 1;
}

IRCCMD:akill(botid, channel[], user[], host[], params[])
{
    if (!IRC_IsOp(botid, channel, user)) return IRC_Reply(ERROR, channel, "this command require more privilages than you got.");
    new playerid, reason[64];
    if (sscanf(params, "dS(No reason)[64]", playerid, reason)) return IRC_Reply(USAGE, channel, "!akill [playerid] [reason]");
    if (!IsPlayerConnected(playerid)) return IRC_Reply(ERROR, channel, "this player is not connected.");
    new msg[128];
    format(msg, sizeof(msg), "%s (Id: %d) has been killed by %s on IRC. (%s)", PlayerInfo[playerid][Name], playerid, user, reason);
    AdminNotice(msg);
    SetPlayerHealth(playerid, 0);
    return 1;
}

IRCCMD:kick(botid, channel[], user[], host[], params[])
{
    if (!IRC_IsHalfop(botid, channel, user)) return IRC_Reply(ERROR, channel, "this command require more privilages than you got.");

    new id, reason[20], string[80];
    if(sscanf(params,"us[178]", id, reason)) return IRC_Reply(USAGE, channel, "!kick [playerid] [reason]");
    if (!IsPlayerConnected(id)) return IRC_Reply(ERROR, channel, "this player is not connected.");
    format(string,sizeof(string),"%s (Id: %d) has been kicked by %s for: %s", PlayerInfo[id][Name], id, user, reason);
    AdminNotice(string);

    for(new i = 0; i < 50; i++) SendClientMessage(id, -1,"");
    TogglePlayerControllable(id, 0);

    SendClientMessage(id, -1, "{C3C3C3}You were banned from {6EF83C}Stunt {F81414}Freeroam {0049FF}Server");
    format(string, sizeof(string), "{C3C3C3}You were banned by {F81414}%s{C3C3C3} for {F81414}%s", user, reason);
    SendClientMessage(id, -1, string);

    SetTimerEx("DelayKick", 1000, false, "i", id);
    return 1;
}

IRCCMD:ban(botid, channel[], user[], host[], params[])
{
    if (IRC_IsHalfop(botid, channel, user))
    {
		new id, reason[20], string[250];
		if(sscanf(params,"us[178]", id, reason)) return IRC_Reply(USAGE, channel, "!ban [playerid] [reason]");
        if (!IsPlayerConnected(id)) return IRC_Reply(ERROR, channel, "this player is not connected.");
		format(string,sizeof(string),"%s (Id: %d) has been banned by %s for: %s", PlayerInfo[id][Name], id, user, reason);
		AdminNotice(string);

		for(new i = 0; i < 50; i++) SendClientMessage(id, -1,"");
		TogglePlayerControllable(id, 0);

		SendClientMessage(id, -1, "{C3C3C3}You were banned from {6EF83C}Stunt {F81414}Freeroam {0049FF}Server");
		format(string, sizeof(string), "{C3C3C3}You were banned by {F81414}%s{C3C3C3} for {F81414}%s", user, reason);
		SendClientMessage(id, -1, string);

		new y, mo, d, h, m, s;
		getdate(y, mo, d);
		gettime(h, m, s);
		format(string, sizeof(string), "[%d/%d/%d] %d:%d:%d", y, mo, d, h, m, s);
		format(string, sizeof(string), "INSERT INTO `BanList` (`BanId`, `Name`, `IP`, `ClientId`, `Admin`, `Reason`, `Date`) VALUES \
										(%d, '%q', '%s', '%s', '%s', '%s', '%s')", GetLastBanId()+1, PlayerInfo[id][Name], PlayerInfo[id][IP],
                                        PlayerInfo[id][ClientId], PlayerInfo[id][Name], reason, string);
        #if USE_SAVING_SYSTEM == 1
            #if USE_SQLITE == 1
                db_query(Database, string);
            #elseif USE_MYSQL == 1
                mysql_query(Database, string);
            #endif
        #endif

		SetTimerEx("DelayKick", 1000, false, "i", id);
    }
    return 1;
}

IRCCMD:unban(botid, channel[], user[], host[], params[])
{
    if(!IRC_IsHalfop(botid, channel, user)) return IRC_Reply(USAGE, channel, "!unban [name]");
    if(isnull(params)) return IRC_Reply(USAGE, channel, "!unban [name]");
    #if USE_SAVING_SYSTEM == 1
        #if USE_SQLITE == 1
            new string[80], DBResult:result;
            format(string, sizeof(string), "SELECT * FROM `BanList` WHERE `Name` = '%q'", params);
            result = db_query(Database, string);
            if(db_num_rows(result) > 0)
            {
                format(string, sizeof(string), "DELETE FROM `BanList` WHERE `Name` = '%q'", params);
                db_query(Database, string);
                format(string, sizeof(string), "%s has been unbanned by %s from irc", params, user);
                AdminNotice(string);
            }
            else IRC_Reply(ERROR, channel, "this account doesn't exists");
            db_free_result(result);
        #elseif USE_MYSQL == 1
            new string[80], Cache:result, rows;
            mysql_format(Database, string, sizeof(string), "SELECT * FROM `BanList` WHERE `Name` = '%e'", params);
            result = mysql_query(Database, string);
            cache_get_row_count(rows);
            if(rows > 0)
            {
                mysql_format(Database, string, sizeof(string), "DELETE FROM `BanList` WHERE `Name` = '%e'", params);
                mysql_query(Database, string);
                format(string, sizeof(string), "%s has been unbanned by %s from irc", params, user);
                AdminNotice(string);
            }
            else IRC_Reply(ERROR, channel, "this account doesn't exists");
            cache_delete(result);
        #endif
    #endif
    return 1;
}

IRCCMD:rcon(botid, channel[], user[], host[], params[])
{
    if (!IRC_IsOwner(botid, channel, user)) return IRC_Reply(ERROR, channel, "this command require more privilages than you got.");
    if (isnull(params)) return IRC_Reply(USAGE, channel, "!rcon [command] (params)");
    if (!strcmp(params, "exit", true)) return IRC_Reply(ERROR, channel, "You can't shutdown server from irc.");
	if (!strcmp(params, "gmx", true, 3)) return IRC_Reply(ERROR, channel, "You can use !restart instand.");

    new msg[40];
    format(msg, sizeof(msg), "RCON command %s has been executed.", params);
    IRC_Reply(SUCCESS, channel, msg);
    SendRconCommand(params);
    return 1;
}

IRCCMD:pm(botid, channel[], user[], host[], params[])
{
    new str[190], msg[120], id;
    if(sscanf(params, "us[100]", id, msg)) return IRC_Reply(USAGE, channel, "!pm [playerid] [message]");
    if(!IsPlayerConnected(id)) return IRC_Say(GroupId, channel, "Invalid Player ID.");
    format(str, sizeof(str), "*PM From [IRC]%s : %s", user, msg);
    SendClientMessage(id, -1, str);
	format(str, sizeof(str), "Private Message from [IRC]%s to %s (Id: %d): %s", user, PlayerInfo[id][Name], id, msg);
    AdminNotice(str);
    return 1;
}

IRCCMD:slap(botid, channel[], user[], host[], params[])
{
    new id, str[120], Float:slapx, Float:slapy, Float:slapz;

    if(!IRC_IsHalfop(botid, channel, user)) return IRC_Reply(ERROR, channel, "this command require more privilages than you got.");
    if(sscanf(params, "us[128]", id, str)) IRC_Reply(USAGE, channel, "!slap [playerid] [reason]");
    if(!IsPlayerConnected(id)) return IRC_Reply(ERROR, channel, "this player is not connected.");

    format(str, sizeof(str), "%s (Id: %d) has been slapped by %s from IRC", PlayerInfo[id][Name], id, user);
	AdminNotice(str);

    GetPlayerPos(id, slapx, slapy, slapz);
    SetPlayerPos(id, slapx, slapy, slapz + 10);
    return 1;
}

IRCCMD:givecash(botid, channel[], user[], host[], params[])
{
    new id, amount, str[120];
    if(!IRC_IsOp(botid, channel, user)) return IRC_Reply(ERROR, channel, "this command require more privilages than you got.");
    if(sscanf(params,"ui", id, amount)) return IRC_Reply(USAGE, channel, "!givecash [playerid] [Amount]");
    if(!IsPlayerConnected(id)) return IRC_Reply(ERROR, channel, "this player is not connected.");
    GivePlayerMoney(id, amount);

	format(str, sizeof(str), "%s has given %d $ to %s (Id: %d) from IRC", user, amount, PlayerInfo[id][Name], id);
	AdminNotice(str);
    return 1;
}

IRCCMD:cmds(botid, channel[], user[], host[], params[])
{
    IRC_GroupSay(GroupId, channel, "Players: !pm !players !say !stats !uptime");
    if(IRC_IsHalfop(botid, channel, user)) IRC_GroupSay(GroupId, channel, "Administrators: !slap !kick !ban !baninfo !clearchat !unban !getip");
    if(IRC_IsOp(botid, channel, user)) IRC_GroupSay(GroupId, channel, "Managements: !givecash !freeze !unfreeze !akill ");
	if(IRC_IsAdmin(botid, channel, user)) IRC_GroupSay(GroupId, channel, "Server Co-Owners: !setvip !restart");
    if(IRC_IsOwner(botid, channel, user)) IRC_GroupSay(GroupId, channel, "Server Owner: !rcon !setlevel");
    return 1;
}

IRCCMD:restart(botid, channel[], user[], host[], params[])
{
    if(!IRC_IsAdmin(botid, channel, user)) return IRC_Reply(ERROR, channel, "this command require more privilages than you got.");
    SendRconCommand("gmx");
    return 1;
}

IRCCMD:getip(botid, channel[], user[], host[], params[])
{
    if(!IRC_IsHalfop(botid, channel, user)) return IRC_Reply(ERROR, channel, "this command require more privilages than you got.");
    new id, ip[16], str[128];

    if(sscanf(params, "i", id)) return IRC_Reply(USAGE, channel, "!getip [playerid]");
    GetPlayerIp(id, ip, sizeof(ip));
    if(!IsPlayerConnected(id)) return IRC_Reply(ERROR, channel, "this player is not connected.");

    format(str, 128, "this player ip is: %s", PlayerInfo[id][IP]);
    IRC_Reply(SUCCESS, user, str);

    return true;
}

IRCCMD:players(botid, channel[], user[], host[], params[])
{
    new count, PlayerNames[512], string[256];
    for(new i = 0; i <= MAX_PLAYERS; i++)
    {
        if(IsPlayerConnected(i) && !IsPlayerNPC(i))
        {
            if(count == 0)
            {
				format(PlayerNames, sizeof(PlayerNames),"2%s1", PlayerInfo[i][Name]);
				count++;
			}
			else format(PlayerNames, sizeof(PlayerNames),"%s, 2%s1", PlayerNames, PlayerInfo[i][Name]); count++;
        }
    }
    if(count == 0) format(PlayerNames, sizeof(PlayerNames), "1there no players in server at moment.");

    new counter = 0;
    for(new i = 0; i <= MAX_PLAYERS; i++) if(IsPlayerConnected(i)) counter++;

    format(string, 256, "5Connected Players[%d]:1 %s", counter, PlayerNames);
    IRC_GroupSay(GroupId, channel, string);

    return true;
}

IRCCMD:cc(botid, channel[], user[], host[], params[]) return irccmd_clearchat(botid, channel, user, host, params);
IRCCMD:clearchat(botid, channel[], user[], host[], params[])
{
    if(IRC_IsHalfop(botid, channel, user) == 0) return IRC_Reply(ERROR, channel, "this command require more privilages than you got.");
    for(new i = 0; i <= 32; i ++) SendClientMessageToAll(-1, "");
    IRC_Reply(SUCCESS, channel, "Chat has been cleared.");

    return 1;
}

IRCCMD:setlevel(botid, channel[], user[], host[], params[])
{
    if(!IRC_IsOwner(botid, channel, user)) return IRC_Reply(ERROR, channel, "this command require more privilages than you got.");
    new id, level, str[100];

    if(sscanf(params,"ii", id, level)) return IRC_Reply(USAGE, channel, "!setlevel [playerid] [Level]");
    if(PlayerInfo[id][Admin] == level) return IRC_Reply(ERROR, channel, "This player already have this level.");
    if(!IsPlayerConnected(id)) return IRC_Reply(ERROR, channel, "this player is not connected.");
    if(level > 4 || level < 0) return IRC_Reply(ERROR, channel, "Invalid level entred (Levels are 0 - 4).");

    switch(level)
    {
        case 0: str = "Regular Player";
        case 1: str = "Administrator";
        case 2: str = "Management";
        case 3: str = "Server Co-Owner";
        case 4: str = "Server Owner";
    }

	if(PlayerInfo[id][Admin] < level) format(str, sizeof(str), "%s (Id: %d) has been promoted by %s on IRC to an Server %s", PlayerInfo[id][Name], id, user, str);
	else format(str, sizeof(str), "%s (Id: %d) has been demonted by %s on IRC to an Server %s", PlayerInfo[id][Name], id, user, str);

	AdminNotice(str);
	PlayerInfo[id][Admin] = level;
    return 1;
}


IRCCMD:admin(botid, channel[], user[], host[], params[])
{
    new str[100];
	if(!IRC_IsHalfop(botid, channel, user)) return IRC_Reply(ERROR, channel, "this command require more privilages than you got.");
	if(isnull(params)) return IRC_Reply(USAGE, channel, "!admin [message]");

    if(IRC_IsHalfop(botid, channel, user)) format(str, sizeof(str), "{FFFF00}*Admin({FFFFFF}%s{FFFF00})on IRC: {FFFFFF}%s", user, params);
	if(IRC_IsOp(botid, channel, user)) format(str, sizeof(str), "{FFFF00}*Manager({FFFFFF}%s{FFFF00})on IRC: {FFFFFF}%s", user, params);
	if(IRC_IsAdmin(botid, channel, user)) format(str, sizeof(str), "{FFFF00}*Server Co-Owner({FFFFFF}%s{FFFF00})on IRC: {FFFFFF}%s", user, params);
	if(IRC_IsOwner(botid, channel, user)) format(str, sizeof(str), "{FFFF00}*Server Owner({FFFFFF}%s{FFFF00})on IRC: {FFFFFF}%s", user, params);

	for(new i = 0; i < GetPlayerPoolSize(); i++)
	{
		if(PlayerInfo[i][Admin] > 0)
		{
			SendClientMessage(i, -1, str);
		}
	}
	return 1;
}
#endif
#endif

// InGame Commands (Player)
CMD:stats(playerid, params[])
{
	new id;
	if(sscanf(params, "i", id)) id = playerid;
	if(!IsPlayerConnected(id)) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: this player is not connected.");
	new string[1000], str[60], strx[25], h, m, s;
    strx = "Normal Member";
    if(PlayerInfo[id][VIP]) strx = "Very Important Player";
	secs2hms(PlayerInfo[id][Time], h, m, s);
	format(str, sizeof(str), "Player stats of %s(Id: %d).", PlayerInfo[id][Name], id);
	format(string, sizeof(string), "%s			Name: %s (Id: %d)\n", string, PlayerInfo[id][Name], id);
	format(string, sizeof(string), "%s			Online Time: %d hours, %d minutes and %d seconds\n", string, h, m, s);
	format(string, sizeof(string), "%s			Level: %s\n", string, GetLevel(PlayerInfo[id][Admin]));
	format(string, sizeof(string), "%s			Social: %s\n", string, strx);
	format(string, sizeof(string), "%s			Skin: %d\n", string, PlayerInfo[id][Skin]);
	format(string, sizeof(string), "%s			Kills: %d\n", string, PlayerInfo[id][Kills]);
	format(string, sizeof(string), "%s			Deaths: %d\n", string, PlayerInfo[id][Deaths]);
	format(string, sizeof(string), "%s			Money: %d\n", string, PlayerInfo[id][Money]);
	if(PlayerInfo[playerid][Admin] > 0) format(string, sizeof(string), "%s			IP: %s\n", string, PlayerInfo[id][IP]);
	if(PlayerInfo[playerid][Admin] > 2) format(string, sizeof(string), "%s			ClientId: %s\n", string, PlayerInfo[id][ClientId]);
	if(PlayerInfo[playerid][Admin] > 0) format(string, sizeof(string), "%s			Interior: %d\n", string, GetPlayerInterior(id));
	if(PlayerInfo[playerid][Admin] > 0) format(string, sizeof(string), "%s			VirtualWorld: %s\n", string, GetPlayerVirtualWorld(id));
	if(PlayerInfo[playerid][Admin] > 0) format(string, sizeof(string), "%s			Ping: %d\n", string, GetPlayerPing(id));
    strx = "false";
    if(IsPlayerSpawned(playerid)) strx = "true";
	if(PlayerInfo[playerid][Admin] > 0) format(string, sizeof(string), "%s			Spawned: %s\n", string, strx);
	ShowPlayerDialog(playerid, DIALOG_STATS, DIALOG_STYLE_MSGBOX, str, string, "OK", "");
	return 1;
}

CMD:admins(playerid, params[])
{
	SendClientMessage(playerid, 0x33AA33AA, " ");
	SendClientMessage(playerid, 0x33AA33AA, "*Online Administrators:");
	new count = 0;
	for(new i = 0; i < MAX_PLAYERS; i++)
	{
		if(!IsPlayerConnected(i)) continue;
		if(PlayerInfo[i][Admin] == 0) continue;
		new string[90];
        format(string, sizeof(string), "%s (Id: %d) - %s", PlayerInfo[i][Name], i, GetLevel(PlayerInfo[i][Admin]));
		SendClientMessage(playerid, -1, string);
		count++;
	}
	if(!count) SendClientMessage(playerid, -1, "There no administrators connected.");
	return 1;
}

/*
CMD:changename(playerid, params[])
{

}

CMD:changepassword(playerid, params[])
{

}
*/

CMD:mb(playerid) return cmd_moneybag(playerid);
CMD:moneybag(playerid)
{
	static string[81];
    if(!m_Found) format(string, sizeof(string), "{00FF40}*Announces: {FFFFFF}Money Bag has been hidden in %s!", m_Location);
    if(m_Found) format(string, sizeof(string), "{00FF40}*Announces: {FFFFFF}There no money bag running at moment");
    SendClientMessage(playerid, -1, string);
    return 1;
}

CMD:report(playerid, params[])
{
	new id, msg[120];
    if(sscanf(params, "us[120]", id, msg)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /report [playerid] [reason]");
	if(!IsPlayerConnected(id)) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: this player is not connected.");
	format(msg, sizeof(msg), "Suscpect Player: %s (Id: %d) | Suscpect Reason: %s", PlayerInfo[id][Name], id, msg);
	AdminNotice(msg);
	SendClientMessage(playerid, 0x33AA33AA, "*You report has been sended to our admins! we are working on!");
	return 1;
}

CMD:pm(playerid, params[])
{
    new id, msg[120];
    if(sscanf(params, "us[120]", id, msg)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /pm [playerid] [message]");
    if(!IsPlayerConnected(id)) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: this player is not connected.");
	new str[190];
	format(str, sizeof(str), "*PM from %s (Id: %d): %s", PlayerInfo[playerid][Name], playerid, msg);
    SendClientMessage(id, -1, str);
	SendClientMessage(id, -1, "*{FF9900}Tip{FFFFFF}: You can use /r [msg] for fast reply.");
    format(str, sizeof(str), "*PM to %s (Id: %d): %s", PlayerInfo[id][Name], id, msg);
    SendClientMessage(playerid, -1, str);
	format(str, sizeof(str), "Private Message from %s (Id: %d) to %s (Id: %d): %s", PlayerInfo[playerid][Name], playerid, PlayerInfo[id][Name], id, msg);
    AdminNotice(str);
	SetPVarInt(playerid, "LastPm", id);
	SetPVarInt(id, "LastPm", playerid);
    return 1;
}

CMD:r(playerid, params[])
{
	if(isnull(params)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /r [message]");
	new id = GetPVarInt(playerid, "LastPm");
	if(!IsPlayerConnected(id) || id == INVALID_PLAYER_ID) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: this player is not connected anymore.");
	new str[190];
	format(str, sizeof(str), "*PM from %s (Id: %d): %s", PlayerInfo[playerid][Name], playerid, params);
    SendClientMessage(id, -1, str);
	SendClientMessage(id, -1, "*{FF9900}Tip{FFFFFF}: You can use /r [msg] for fast reply.");
    format(str, sizeof(str), "*PM to %s (Id: %d): %s", PlayerInfo[id][Name], id, params);
    SendClientMessage(playerid, -1, str);
	format(str, sizeof(str), "Private Message from %s (Id: %d) to %s (Id: %d): %s", PlayerInfo[playerid][Name], playerid, PlayerInfo[id][Name], id, params);
    AdminNotice(str);
	SetPVarInt(playerid, "LastPm", id);
	SetPVarInt(id, "LastPm", playerid);
	return 1;
}

CMD:me(playerid, params[])
{
	if(isnull(params)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /me [action]");
	new str[80];
	format(str, sizeof(str), "*%s %s", PlayerInfo[playerid][Name], params);
	SendClientMessageToAll(GetPlayerColor(playerid), str);
    #if USE_EXTERN_CHAT == 1
        #if USE_DISCORD == 1
            DCC_SendChannelMessage(DDC_Echo_Channel, str);
        #endif
        #if USE_IRC == 1
            strins(str, "07", 0);
            IRC_Say(IRCBots[0], IRC_ECHO, str);
        #endif
    #endif
	return 1;
}
/*
CMD:parkour(playerid, params[])
{
}

CMD:derby(playerid, params[])
{
}

CMD:skydive(playerid, params[])
{
}
*/
CMD:teles(playerid, params[])
{
    ShowPlayerDialog(playerid, DIALOG_TELEPORTS, DIALOG_STYLE_LIST, "{DC143C}|SFS|:{FFFFFF} Teleports", "- Abandoned Airport\n- Los Santos Airport\n- Las Venturas Airport\n- Chilliad Mount\n- BikeSkills [1]\n- BikeSkills [2]\
                                                                    \n- NRG basket ball\n- San Fierro\n- Water Park\n- X-Mas\n- Leave", "OK", "Cancel");
    return 1;
}

CMD:de(playerid)
{
    new str[100];
    format(str,sizeof(str), "{00FF40}*Announces: {FFFFFF}%s (Id: %d) Has joined Deagle dm at /de", PlayerInfo[playerid][Name], playerid);
    SendClientMessageToAll(-1, str);
	new xRandom = random(sizeof(RandomSpawnsDE));
	createdm(playerid,RandomSpawnsDE[xRandom][0], RandomSpawnsDE[xRandom][1], RandomSpawnsDE[xRandom][2], RandomSpawnsDE[xRandom][3],3,1,1,24,25,100,"~r~DEAGLE DM");
	return 1;
}

CMD:rw(playerid)
{
    new str[100];
    format(str,sizeof(str), "{00FF40}*Announces: {FFFFFF}%s (Id: %d) Has joined Running Weapons dm at /rw", PlayerInfo[playerid][Name], playerid);
    SendClientMessageToAll(-1, str);
	new xRandom = random(sizeof(RandomSpawnsRW));
	createdm(playerid,RandomSpawnsRW[xRandom][0], RandomSpawnsRW[xRandom][1], RandomSpawnsRW[xRandom][2], RandomSpawnsRW[xRandom][3],1,2,2,26,28,100,"~r~Running Weapons DM!");
	return 1;
}

CMD:sos(playerid)
{
    new str[100];
    format(str,sizeof(str), "{00FF40}*Announces: {FFFFFF}%s (Id: %d) Has joined Sawn-Off dm at /sos", PlayerInfo[playerid][Name], playerid);
    SendClientMessageToAll(-1, str);
	new xRandom = random(sizeof(RandomSpawnsSOS));
	createdm(playerid,RandomSpawnsSOS[xRandom][0], RandomSpawnsSOS[xRandom][1], RandomSpawnsSOS[xRandom][2], RandomSpawnsSOS[xRandom][3],10,3,3,26,32,100,"~r~Sawn-Off DM!");
	return 1;
}

CMD:snipedm(playerid)
{
    new str[100];
    format(str,sizeof(str), "{00FF40}*Announces: {FFFFFF}%s (Id: %d) Has joined Sniper dm at /snipe", PlayerInfo[playerid][Name], playerid);
    SendClientMessageToAll(-1, str);
	new xRandom = random(sizeof(RandomSpawnsSNIPE));
	createdm(playerid,RandomSpawnsSNIPE[xRandom][0], RandomSpawnsSNIPE[xRandom][1], RandomSpawnsSNIPE[xRandom][2], RandomSpawnsSNIPE[xRandom][3],3,4,4,25,34,100,"~r~Sniper DM!");
	return 1;
}

CMD:sos2(playerid)
{
    new str[100];
    format(str,sizeof(str), "{00FF40}*Announces: {FFFFFF}%s (Id: %d) Has joined Sawn-off 2 dm at /sos2", PlayerInfo[playerid][Name], playerid);
    SendClientMessageToAll(-1, str);
	new xRandom = random(sizeof(RandomSpawnsSOS2));
	createdm(playerid,RandomSpawnsSOS2[xRandom][0], RandomSpawnsSOS2[xRandom][1], RandomSpawnsSOS2[xRandom][2], RandomSpawnsSOS2[xRandom][3],0,5,5,26,0,100, "~r~Sawn Off DM 2");
	return 1;
}

CMD:shotdm(playerid)
{
    new str[100];
    format(str,sizeof(str), "{00FF40}*Announces: {FFFFFF}%s (Id: %d) Has joined ShotGUN dm at /shotdm", PlayerInfo[playerid][Name], playerid);
    SendClientMessageToAll(-1, str);
	new xRandom = random(sizeof(RandomSpawnsSHOT));
	createdm(playerid,RandomSpawnsSHOT[xRandom][0], RandomSpawnsSHOT[xRandom][1], RandomSpawnsSHOT[xRandom][2], RandomSpawnsSHOT[xRandom][3],1,6,6,27,0,100, "~r~Shot GUN DM");
	return 1;
}

CMD:snipedm2(playerid)
{
    new str[100];
    format(str,sizeof(str), "{00FF40}*Announces: {FFFFFF}%s (Id: %d) Has joined Sniper 2 dm at /snipedm2", PlayerInfo[playerid][Name], playerid);
    SendClientMessageToAll(-1, str);
	new xRandom = random(sizeof(RandomSpawnsSNIPE2));
	createdm(playerid,RandomSpawnsSNIPE2[xRandom][0], RandomSpawnsSNIPE2[xRandom][1], RandomSpawnsSNIPE2[xRandom][2], RandomSpawnsSNIPE2[xRandom][3],0,7,7,34,0,100,"~r~Sniper Off DM 2");
	return 1;
}

CMD:mini(playerid)
{
    new str[100];
    format(str,sizeof(str), "{00FF40}*Announces: {FFFFFF}%s (Id: %d) Has joined Minigun dm at /mini", PlayerInfo[playerid][Name], playerid);
    SendClientMessageToAll(-1, str);
	new xRandom = random(sizeof(RandomSpawnsMINI));
	createdm(playerid,RandomSpawnsMINI[xRandom][0], RandomSpawnsMINI[xRandom][1], RandomSpawnsMINI[xRandom][2], RandomSpawnsMINI[xRandom][3],0,8,8,38,0,100,"~r~MINIGUN DM");
	return 1;
}

CMD:wz(playerid)
{
    new str[100];
    format(str,sizeof(str), "{00FF40}*Announces: {FFFFFF}%s (Id: %d) Has joined War Zone dm at /wz", PlayerInfo[playerid][Name], playerid);
    SendClientMessageToAll(-1, str);
	new xRandom = random(sizeof(RandomSpawnsWZ));
	createdm(playerid,RandomSpawnsWZ[xRandom][0], RandomSpawnsWZ[xRandom][1], RandomSpawnsWZ[xRandom][2], RandomSpawnsWZ[xRandom][3],0,9,9,31,16,100,"~r~War Zone");
	return 1;
}

CMD:shipdm(playerid)
{
    new str[100];
    format(str,sizeof(str), "{00FF40}*Announces: {FFFFFF}%s (Id: %d) Has joined Ship dm at /shipdm", PlayerInfo[playerid][Name], playerid);
    SendClientMessageToAll(-1, str);
	new xRandom = random(sizeof(RandomSpawnsSHIP));
	createdm(playerid,RandomSpawnsSHIP[xRandom][0], RandomSpawnsSHIP[xRandom][1], RandomSpawnsSHIP[xRandom][2], RandomSpawnsSHIP[xRandom][3],0,10,10,23,29,100,"~r~Ship DM");
	return 1;
}

CMD:leave(playerid)
{
	if (!PlayerInfo[playerid][InDM]) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You are not in a deathmatch area!" );
    PlayerInfo[playerid][InDM] = false;
    PlayerInfo[playerid][DmZone] = 0;
    SetPlayerVirtualWorld(playerid, 0);
    SpawnPlayer(playerid);
    SetPlayerInterior(playerid,0);
    SendClientMessage(playerid, -1, "{B7FF00}*Success{FFFFFF}: You have left the deathmatch arena!" );
    StopAudioStreamForPlayer(playerid);
    SetCameraBehindPlayer(playerid);
	return 1;
}

CMD:dm(playerid)
{
	new string[900],pde,prw,psos,psnipe,psos2,psnipe2,pshot,pmini,pwz,pship;

	for(new i=0;i<MAX_PLAYERS;i++)
	{
		if(IsPlayerConnected(i))
		{
			switch(PlayerInfo[i][DmZone])
			{

				case 1:pde++;
				case 2:prw++;
				case 3:psos++;
				case 4:psnipe++;
				case 5:psos2++;
				case 6:pshot++;
				case 7:psnipe2++;
				case 8:pmini++;
				case 9:pwz++;
				case 10:pship++;
			}
		}
	}

	format(string,sizeof(string),
	"{DC143C}Map\t{DC143C}Players\n\
	{FFFFFF}Deagle (/de)\t%d\n\
	Running Weapons (/rw)\t%d\n\
	Sawn-Off Shotgun (/sos)\t%d\n\
	Sniper (/sniperdm)\t%d\n\
	Sawn-Off Shotgun 2(/sos2)\t%d\n\
	Sniper DM 2 (/snipedm2)\t%d\n\
	ShotGun DM (/shotdm)\t%d\n\
	MiniGun DM (/mini)\t%d\n\
	War Zone (/wz)\t%d\n\
	Ship DM (/shipdm)\t%d\n",pde,prw,psos,psnipe,psos2,psnipe2,pshot,pmini,pwz,pship);

	ShowPlayerDialog(playerid, DIALOG_DM,  DIALOG_STYLE_TABLIST_HEADERS, "{DC143C}|SFS|:{FFFFFF} Deathmatches",string, "Select","Cancel");
	return 1;
}

CMD:house(playerid, params[])
{
	if(InHouse[playerid] == INVALID_HOUSE_ID) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not in a house.");
	ShowHouseMenu(playerid);
	return 1;
}

CMD:myhousekeys(playerid, params[])
{
    new query[200], Cache: mykeys;
    mysql_format(Database, query, sizeof(query), "SELECT HouseID, FROM_UNIXTIME(Date, '%%d/%%m/%%Y %%H:%%i') as KeyDate FROM housekeys WHERE Player='%e' ORDER BY Date DESC LIMIT 0, 15", PlayerInfo[playerid][Name]);
	mykeys = mysql_query(Database, query);
	ListPage[playerid] = 0;

	new rows = cache_num_rows();
	if(rows) {
 		new list[1024], id, key_date[20];
   		format(list, sizeof(list), "House Info\tKey Given On\n");
	    for(new i; i < rows; ++i)
	    {
	        cache_get_value_name_int(i, "HouseID", id);
       		cache_get_value_name(i, "KeyDate", key_date);
	        format(list, sizeof(list), "%s%s's %s\t%s\n", list, HouseData[id][Owner], HouseData[id][Name], key_date);
	    }

		ShowPlayerDialog(playerid, DIALOG_MY_KEYS, DIALOG_STYLE_TABLIST_HEADERS, "{DC143C}|SFS|:{FFFFFF} My Keys (Page 1)", list, "Next", "Close");
	}else{
		SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You don't have any keys for any houses.");
	}

	cache_delete(mykeys);
	return 1;
}

CMD:givehousekeys(playerid, params[])
{
    if(InHouse[playerid] == INVALID_HOUSE_ID) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not in a house.");
    new id, houseid = InHouse[playerid];
	if(strcmp(HouseData[houseid][Owner], PlayerInfo[playerid][Name])) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not the owner of this house.");
	if(sscanf(params, "u", id)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /givehousekeys [player id]");
	if(id == INVALID_PLAYER_ID) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: Invalid player ID.");
	if(id == playerid) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're the owner, you don't need keys.");
	if(Iter_Contains(HouseKeys[id], houseid)) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: That player has keys for this house.");
	Iter_Add(HouseKeys[id], houseid);

	new query[128];
	mysql_format(Database, query, sizeof(query), "INSERT INTO housekeys SET HouseID=%d, Player='%e', Date=UNIX_TIMESTAMP()", houseid, PlayerInfo[id][Name]);
	mysql_tquery(Database, query, "", "");

	format(query, sizeof(query), "You've given keys to %s for this house.", PlayerInfo[id][Name]);
	SendClientMessage(playerid, -1, query);
	format(query, sizeof(query), "Now you have keys for %s's house, %s.", HouseData[houseid][Owner], HouseData[houseid][Name]);
	SendClientMessage(id, -1, query);
	return 1;
}

CMD:takehousekeys(playerid, params[])
{
    if(InHouse[playerid] == INVALID_HOUSE_ID) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not in a house.");
    new id, houseid = InHouse[playerid];
	if(strcmp(HouseData[houseid][Owner], PlayerInfo[playerid][Name])) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not the owner of this house.");
	if(sscanf(params, "u", id)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /takehousekeys [player id]");
	if(id == INVALID_PLAYER_ID) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: Invalid player ID.");
	if(id == playerid) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're the owner, you can't take your keys.");
	if(!Iter_Contains(HouseKeys[id], houseid)) return SendClientMessage(playerid, -1, "That player doesn't have keys for this house.");
	Iter_Remove(HouseKeys[id], houseid);

	new query[128];
	mysql_format(Database, query, sizeof(query), "DELETE FROM housekeys WHERE HouseID=%d AND Player='%e'", houseid, PlayerInfo[id][Name]);
	mysql_tquery(Database, query, "", "");

	format(query, sizeof(query), "You've taken keys from %s for this house.", PlayerInfo[id][Name]);
	SendClientMessage(playerid, -1, query);
	format(query, sizeof(query), "House owner %s has taken your keys for their house %s.", HouseData[houseid][Owner], HouseData[houseid][Name]);
	SendClientMessage(id, -1, query);
	return 1;
}

CMD:kickfromhouse(playerid, params[])
{
    if(InHouse[playerid] == INVALID_HOUSE_ID) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not in a house.");
    new id, houseid = InHouse[playerid];
	if(strcmp(HouseData[houseid][Owner], PlayerInfo[playerid][Name])) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You're not the owner of this house.");
	if(sscanf(params, "u", id)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /kickfromhouse [player id]");
	if(id == INVALID_PLAYER_ID) return SendClientMessage(playerid, -1, "I{DC143C}*Error{FFFFFF}: nvalid player ID.");
	if(id == playerid) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You can't kick yourself from your house.");
	if(InHouse[id] != houseid) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: That player isn't in your house.");
    SendClientMessage(playerid, -1, "Player kicked.");
	SendClientMessage(id, -1, "You got kicked by the house owner.");
	SetPVarInt(id, "HousePickupCooldown", gettime() + HOUSE_COOLDOWN);
	SetPlayerVirtualWorld(id, 0);
 	SetPlayerInterior(id, 0);
 	SetPlayerPos(id, HouseData[houseid][houseX], HouseData[houseid][houseY], HouseData[houseid][houseZ]);
 	InHouse[id] = INVALID_HOUSE_ID;
	return 1;
}

CMD:tp(playerid, params[])
{
    new Id, str[128]; 
    if(sscanf(params, "u", Id)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /tp [playerid]"); 
    if(!IsPlayerConnected(Id)) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: this player is not connected.");
    if(!PlayerInfo[Id][Teleport]) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: this player disabled his teleportation feature.");
    if(PlayerInfo[Id][Admin] > 0) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You can't teleport to this player");

    new Float:x, Float:y, Float:z; 
    GetPlayerPos(Id, x, y, z); 
    SetPlayerPos(playerid, x+1, y+1, z); 
    format(str, sizeof(str), "*You have been teleported to %s (Id: %d)!", PlayerInfo[Id][Name], Id); 
    SendClientMessage(playerid, 0x00FF00AA, str); 

    format(str, sizeof(str), "*%s (Id: %d) has been teleported to you!", PlayerInfo[playerid][Name], playerid); 
    SendClientMessage(Id, 0x00FF00AA, str); 

    format(str, sizeof(str), "%s (Id: %d) has been teleported to %s (Id: %d)", PlayerInfo[playerid][Name], playerid, PlayerInfo[Id][Name], Id);
    AdminNotice(str);
    return 1;
}

CMD:myramp(playerid, params[])
{
    if(isnull(params)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /myramp [rampid] (0-4)"); 
    new id = strval(params);
    switch(id)
    {
        case 0: PlayerInfo[playerid][Pers] = 1655;   
        case 1: PlayerInfo[playerid][Pers] = 1632;
        case 2: PlayerInfo[playerid][Pers] = 1631;
        case 3: PlayerInfo[playerid][Pers] = 8302;
        case 4: PlayerInfo[playerid][Pers] = 1503;
    }
    SendClientMessage(playerid, -1, "{B7FF00}*Success{FFFFFF}: You have changed your ramp type!");
    return 1;
}

// InGame Commands (Very Important Player)
CMD:v(playerid, params[])
{
	if(!PlayerInfo[playerid][VIP] && !PlayerInfo[playerid][Stunt]) return 0;
	new vehicleid, vehiclename[39];
    if(sscanf(params,"s[39]",vehiclename)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /v [carname]");
    {
        if(IsValidVehicle(PlayerInfo[playerid][Vehicle])) DestroyVehicle(PlayerInfo[playerid][Vehicle]);
        new Float:X, Float:Y, Float:Z, Float:Angle;
        vehicleid = GetVehicleModelIDFromName(vehiclename);
        GetPlayerPos(playerid, X, Y, Z);
        GetPlayerFacingAngle(playerid, Angle);
        PlayerInfo[playerid][Vehicle] = CreateVehicle(vehicleid, X, Y, Z, Angle, random(10), random(10), -1);
        SetVehicleVirtualWorld(PlayerInfo[playerid][Vehicle], GetPlayerVirtualWorld(playerid));
        PutPlayerInVehicle(playerid, PlayerInfo[playerid][Vehicle], 0);
    }
    return 1;
}

CMD:my(playerid, params[]) 
{
    new param[20];
    if (sscanf(params, "s[20]", param))
    {
        if (PlayerInfo[playerid][VIP]) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /my[stats/skin/housekeys/ramp/color/weather/time/teleport]");
        else return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /my[stats/skin/housekeys/ramp]");
    }
    return 1;
}
CMD:myteleport(playerid, params[])
{
    if(!PlayerInfo[playerid][VIP]) return 0;
	if(isnull(params)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /myteleport [on/off]");
    if(!strcmp(params, "on", true, 2))
    {
        PlayerInfo[playerid][Teleport] = false;
        SendClientMessage(playerid, -1, "{B7FF00}*Success{FFFFFF}: You have enabled your teleport");
    }
    if(!strcmp(params, "off", true, 3))
    {
        PlayerInfo[playerid][Teleport] = true;
        SendClientMessage(playerid, -1, "{B7FF00}*Success{FFFFFF}: You have disabled your teleport");
    }
    return 1;
}

CMD:mycolor(playerid, params[])
{
	if(!PlayerInfo[playerid][VIP]) return 0;
	if(isnull(params)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /mycolor [color] ex: 0xFFFFFFFF");
	SetPlayerColor(playerid, strval(params));
    PlayerInfo[playerid][Color] = strval(params);
	return 1;
}

CMD:myweather(playerid, params[])
{
	if(!PlayerInfo[playerid][VIP]) return 0;
	if(isnull(params)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /myweather [weatherid]");
	if(strval(params) > 100) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You entred an Invalid weather Id.");
	SetPlayerWeather(playerid, strval(params));
	return 1;
}

CMD:mytime(playerid, params[])
{
	if(!PlayerInfo[playerid][VIP]) return 0;
	if(isnull(params)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /mytime [timeid]");
	if(strval(params) > 23) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You entred an Invalid time id .");
	SetPlayerTime(playerid, strval(params), 00);
	return 1;
}

CMD:myskin(playerid, params[])
{
	if(!PlayerInfo[playerid][VIP]) return 0;
	if(isnull(params)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /myskin [skin id]");
	if(strval(params) > 23) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You entred an Invalid time id .");
	SetPlayerSkin(playerid, strval(params));
    PlayerInfo[playerid][Skin] = strval(params);
    SetSpawnInfo(playerid, 0, PlayerInfo[playerid][Skin], 1958.33, 1343.12, 15.36, 269.15, 0, 0, 0, 0, 0, 0);
	return 1;
}

CMD:jetpack(playerid)
{
    if(!PlayerInfo[playerid][VIP]) return 0;
    SetPlayerSpecialAction(playerid,SPECIAL_ACTION_USEJETPACK);
    return 1;
}


// InGame Commands (Administrator)
CMD:acmds(playerid)
{
    if(PlayerInfo[playerid][Admin] == 0) return 0;
    SendClientMessage(playerid, -1, "Administrative Commands:");
    if(PlayerInfo[playerid][Admin] >= 1) SendClientMessage(playerid, -1, "{F3FF02}Administrators{FFFFFF}: /fetch /world /kick /ban /unban /reconnect /jail /mute /unmute /unjail /freeze /unfreeze");
    if(PlayerInfo[playerid][Admin] >= 2) SendClientMessage(playerid, -1, "{33AA33}Management{FFFFFF}: /sethealth /setarmour /setweather /settime /slap /givecash /giveweapon");
    if(PlayerInfo[playerid][Admin] >= 3) SendClientMessage(playerid, -1, "{DC143C}Server Co-Owner{FFFFFF}: /restart /setvip /setgravity /togglemb");
    if(PlayerInfo[playerid][Admin] == 4) SendClientMessage(playerid, -1, "{DC143C}Server Owner{FFFFFF}: /shutdown /setlevel /crcon /savemb /delmb /fakemsg /cmd");
    return 1;
}

CMD:mute(playerid, params[])
{
    if(PlayerInfo[playerid][Admin] == 0) return 0;
    new reason[64], id, am;
    if (sscanf(params, "ddS(No reason)[64]", id, am, reason)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /jail [playerid] [minutes] [reason]");
    if (!IsPlayerConnected(id)) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: this player is not connected.");
    new msg[128];
    format(msg, sizeof(msg), "%s (Id: %d) has been muted by %s (Id: %d) for %d minutes. (%s)", PlayerInfo[id][Name], id, PlayerInfo[playerid][Name], playerid, am, reason);
    AdminNotice(msg);
    PlayerInfo[id][Muted] = true;
    PlayerInfo[id][MuteTimer] = SetTimerEx("UnMute", am*60*1000, false, "i", id);
    return 1;
}

CMD:unmute(playerid, params[])
{
    if(PlayerInfo[playerid][Admin] == 0) return 0;
    new reason[64], id;
    if (sscanf(params, "dS(No reason)[64]", id, reason)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /unjail [playerid] [reason]");
    if (!IsPlayerConnected(id)) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: this player is not connected.");
    new msg[128];
    format(msg, sizeof(msg), "%s (Id: %d) has been unmuted by %s (Id: %d). (%s)", PlayerInfo[id][Name], id, PlayerInfo[playerid][Name], playerid, reason);
    AdminNotice(msg);
    PlayerInfo[id][Muted] = false;
    KillTimer(PlayerInfo[id][MuteTimer]);
    return 1;
}

CMD:fetch(playerid, params[])
{
    if(PlayerInfo[playerid][Admin] == 0) return 0;
    new reason[64], id;
    if (sscanf(params, "dS(No reason)[64]", id, reason)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /fetch [playerid] [reason]");
    if (!IsPlayerConnected(id)) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: this player is not connected.");
    new msg[128];
    format(msg, sizeof(msg), "%s (Id: %d) has been teleported to %s (Id: %d). (%s)", PlayerInfo[id][Name], id, PlayerInfo[playerid][Name], playerid, reason);
    AdminNotice(msg);

    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);
    SetPlayerPos(id, x, y+1.0, z);
    return 1;
}

CMD:world(playerid, params[])
{
    if(PlayerInfo[playerid][Admin] == 0) return 0;
    new reason[64], amount, id;
    if (sscanf(params, "ddS(No reason)[64]", id, amount, reason)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /setworld [playerid] [worldid] [reason]");
    new msg[128];
    format(msg, sizeof(msg), "%s (Id: %d) virtual world has been changed by %s (Id: %d). to %d (%s)", PlayerInfo[id][Name], id, PlayerInfo[playerid][Name], playerid, amount, reason);
    AdminNotice(msg);
    SetPlayerVirtualWorld(playerid, amount);
    return 1;
}

CMD:kick(playerid, params[])
{
    if(PlayerInfo[playerid][Admin] == 0) return 0;
    new id, reason[20], string[80];
    if(sscanf(params,"us[178]", id, reason)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /kick [playerid] [reason]");
    if (!IsPlayerConnected(id)) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: this player is not connected.");
    format(string,sizeof(string),"%s (Id: %d) has been kicked by %s (Id: %d) for: %s", PlayerInfo[id][Name], id, PlayerInfo[playerid][Name], playerid, reason);
    AdminNotice(string);

    for(new i = 0; i < 16; i++) SendClientMessage(id, -1,"");
    TogglePlayerControllable(id, 0);

    SendClientMessage(playerid, -1, "{C3C3C3}You were kicked from {6EF83C}Stunt {F81414}Freeroam {0049FF}Server");
    format(string, sizeof(string), "{C3C3C3}You were kicked by {F81414}%s{C3C3C3} for {F81414}%s{C3C3C3} in {F81414}%s", PlayerInfo[playerid][Name], reason);
    SendClientMessage(playerid, -1, string);

    SetTimerEx("DelayKick", 1000, false, "i", id);
    return 1;
}

CMD:ban(playerid, params[])
{
    if(PlayerInfo[playerid][Admin] == 0) return 0;
    new id, reason[20], string[250];
    if(sscanf(params,"us[178]", id, reason)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /ban [playerid] [reason]");
    if (!IsPlayerConnected(id)) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: this player is not connected.");
    format(string,sizeof(string),"%s (Id: %d) has been banned by %s (Id: %d) for: %s", PlayerInfo[id][Name], id, PlayerInfo[playerid][Name], playerid, reason);
    AdminNotice(string);

    for(new i = 0; i < 16; i++) SendClientMessage(id, -1,"");
    TogglePlayerControllable(id, 0);

    SendClientMessage(id, -1, "{C3C3C3}You were banned from {6EF83C}Stunt {F81414}Freeroam {0049FF}Server");
    format(string, sizeof(string), "{C3C3C3}You were banned by {F81414}%s{C3C3C3} for {F81414}%s{C3C3C3} in {F81414}%s", PlayerInfo[playerid][Name], reason);
    SendClientMessage(id, -1, string);

    new y, mo, d, h, m, s;
    getdate(y, mo, d);
    gettime(h, m, s);
    format(string, sizeof(string), "[%d/%d/%d] %d:%d:%d", y, mo, d, h, m, s);
    format(string, sizeof(string), "INSERT INTO `BanList` (`BanId`, `Name`, `IP`, `ClientId`, `Admin`, `Reason`, `Date`) VALUES \
                                    (%d, '%q', '%s', '%s', '%s', '%s', '%s')", GetLastBanId()+1, PlayerInfo[id][Name], PlayerInfo[id][IP],
                                    PlayerInfo[id][ClientId], PlayerInfo[id][Name], reason, string);
    #if USE_SAVING_SYSTEM == 1
        #if USE_SQLITE == 1
            db_query(Database, string);
        #elseif USE_MYSQL == 1
            mysql_query(Database, string);
        #endif
    #endif
    SetTimerEx("DelayKick", 1000, false, "i", id);
    return 1;
}

CMD:unban(playerid, params[])
{
    if(PlayerInfo[playerid][Admin] == 0) return 0;
    if(isnull(params)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /unban [name]");
    #if USE_SAVING_SYSTEM == 1
        #if USE_SQLITE == 1
            new string[80], DBResult:result;
            format(string, sizeof(string), "SELECT * FROM `BanList` WHERE `Name` = '%q'", params);
            result = db_query(Database, string);
            if(db_num_rows(result) > 0)
            {
                format(string, sizeof(string), "DELETE * FROM `BanList` WHERE `Name` = '%q'", params);
                db_query(Database, string);
                format(string, sizeof(string), "%s has been unbanned by %s (Id: %d)", params, PlayerInfo[playerid][Name], playerid);
                AdminNotice(string);
            }
            else SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: this account doesn't exists");
            db_free_result(result);
        #elseif USE_MYSQL == 1
            new string[80], Cache:result, rows;
            mysql_format(Database, string, sizeof(string), "SELECT * FROM `BanList` WHERE `Name` = '%e'", params);
            result = mysql_query(Database, string);
            cache_get_row_count(rows);
            if(rows > 0)
            {
                mysql_format(Database, string, sizeof(string), "DELETE * FROM `BanList` WHERE `Name` = '%e'", params);
                mysql_query(Database, string);
                format(string, sizeof(string), "%s has been unbanned by %s (Id: %d)", params, PlayerInfo[playerid][Name], playerid);
                AdminNotice(string);
            }
            else SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: this account doesn't exists");
            cache_delete(result);
        #endif
    #endif
    return 1;
}

CMD:reconnect(playerid, params[])
{
    if(PlayerInfo[playerid][Admin] == 0) return 0;
    new id, string[80];
    if(sscanf(params,"u", id)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /reconnect [playerid]");
    if (!IsPlayerConnected(id)) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: this player is not connected.");
    format(string,sizeof(string),"%s (Id: %d) has been kicked by %s (Id: %d) for: reconnecting", PlayerInfo[id][Name], id, PlayerInfo[playerid][Name], playerid);
    AdminNotice(string);
    TogglePlayerControllable(id, 0);
    SendClientMessage(id, 0xa9c4e4,"[SA-MP 0.3.7 Debug]: Ops..You seems bugged. Please rejoin.");

    SetTimerEx("DelayKick", 1000, false, "i", id);
    return 1;
}

CMD:jail(playerid, params[])
{
    if(PlayerInfo[playerid][Admin] == 0) return 0;
    new reason[64], id, am;
    if (sscanf(params, "ddS(No reason)[64]", id, am, reason)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /jail [playerid] [minutes] [reason]");
    if (!IsPlayerConnected(id)) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: this player is not connected.");
    new msg[128];
    format(msg, sizeof(msg), "%s (Id: %d) has been jailed by %s (Id: %d) for %d minutes. (%s)", PlayerInfo[id][Name], id, PlayerInfo[playerid][Name], playerid, am, reason);
    AdminNotice(msg);
    SetPlayerPos(id, 264.8763,81.9862,1001.0390);
    SetPlayerInterior(id, 6);
    PlayerInfo[id][JailTimer] = SetTimerEx("UnJailTimer", am, false, "i", id);
    return 1;
}

CMD:unjail(playerid, params[])
{
    if(PlayerInfo[playerid][Admin] == 0) return 0;
    new reason[64], id;
    if (sscanf(params, "dS(No reason)[64]", id, reason)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /unjail [playerid] [reason]");
    if (!IsPlayerConnected(id)) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: this player is not connected.");
    new msg[128];
    format(msg, sizeof(msg), "%s (Id: %d) has been unjailed by %s (Id: %d). (%s)", PlayerInfo[id][Name], id, PlayerInfo[playerid][Name], playerid, reason);
    AdminNotice(msg);
    SetPlayerInterior(id, 0);
    SpawnPlayer(id);
    KillTimer(PlayerInfo[id][JailTimer]);
    return 1;
}

CMD:freeze(playerid, params[])
{
    if(PlayerInfo[playerid][Admin] == 0) return 0;
    new id, reason[64];
    if (sscanf(params, "dS(No reason)[64]", id, reason)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /freeze [playerid] [reason]");
    if (!IsPlayerConnected(id)) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: this player is not connected.");
    new msg[128];
    format(msg, sizeof(msg), "%s (Id: %d) has been freezed by %s (Id: %d). (%s)", PlayerInfo[id][Name], id, PlayerInfo[playerid][Name], playerid, reason);
    AdminNotice(msg);
    TogglePlayerControllable(playerid, 0);
    return 1;
}

CMD:unfreeze(playerid, params[])
{
    if(PlayerInfo[playerid][Admin] == 0) return 0;
    new id, reason[64];
    if (sscanf(params, "dS(No reason)[64]", id, reason)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /unfreeze [playerid] [reason]");
    if (!IsPlayerConnected(id)) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: this player is not connected.");
    new msg[128];
    format(msg, sizeof(msg), "%s (Id: %d) has been unfreezed by %s (Id: %d). (%s)", PlayerInfo[id][Name], id, PlayerInfo[playerid][Name], playerid, reason);
    AdminNotice(msg);
    TogglePlayerControllable(playerid, 1);
    return 1;
}

// InGame Commands (Management)
CMD:sethealth(playerid, params[])
{
    if(PlayerInfo[playerid][Admin] <= 1) return 0;
    new id, reason[64], amount;
    if (sscanf(params, "ddS(No reason)[64]", id, amount, reason)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /sethealth [playerid] [amount] [reason]");
    if (!IsPlayerConnected(id)) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: this player is not connected.");
    new msg[128];
    format(msg, sizeof(msg), "%s (Id: %d) health has been changed by %s (Id: %d). to %d (%s)", PlayerInfo[id][Name], id, PlayerInfo[playerid][Name], playerid, amount, reason);
    AdminNotice(msg);
    SetPlayerHealth(id, amount);
    return 1;
}

CMD:setarmour(playerid, params[])
{
    if(PlayerInfo[playerid][Admin] <= 1) return 0;
    new id, reason[64], amount;
    if (sscanf(params, "dS(No reason)[64]", id, amount, reason)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /setarmour [playerid] [amount] [reason]");
    if (!IsPlayerConnected(id)) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: this player is not connected.");
    new msg[128];
    format(msg, sizeof(msg), "%s (Id: %d) armour has been changed by %s (Id: %d). to %d (%s)", PlayerInfo[id][Name], id, PlayerInfo[playerid][Name], playerid, amount, reason);
    AdminNotice(msg);
    SetPlayerArmour(id, amount);
    return 1;
}

CMD:setweather(playerid, params[])
{
    if(PlayerInfo[playerid][Admin] <= 1) return 0;
    new reason[64], amount;
    if (sscanf(params, "dS(No reason)[64]", amount, reason)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /setweather [weatherid] [reason]");
    new msg[128];
    format(msg, sizeof(msg), "global weather has been changed by %s (Id: %d). to %d (%s)", PlayerInfo[playerid][Name], playerid, amount, reason);
    AdminNotice(msg);
    SetWeather(amount);
    return 1;
}

CMD:settime(playerid, params[])
{
    if(PlayerInfo[playerid][Admin] <= 1) return 0;
    new reason[64], amount;
    if (sscanf(params, "dS(No reason)[64]", amount, reason)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /settime [weatherid] [reason]");
    new msg[128];
    format(msg, sizeof(msg), "global time has been changed by %s (Id: %d). to %d (%s)", PlayerInfo[playerid][Name], playerid, amount, reason);
    AdminNotice(msg);
    SetWorldTime(amount);
    return 1;
}

CMD:slap(playerid, params[])
{
    if(PlayerInfo[playerid][Admin] <= 1) return 0;
    new reason[64], id;
    if (sscanf(params, "dS(No reason)[64]", id, reason)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /slap [playerid] [reason]");
    if (!IsPlayerConnected(id)) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: this player is not connected.");
    new msg[128];
    format(msg, sizeof(msg), "%s (Id: %d) has been slapped by %s (Id: %d). (%s)", PlayerInfo[id][Name], id, PlayerInfo[playerid][Name], playerid, reason);
    AdminNotice(msg);

    new Float:x, Float:y, Float:z;
    GetPlayerPos(id, x, y, z);
    SetPlayerPos(id, x, y, z+3.0);
    return 1;
}

CMD:givecash(playerid, params[])
{
    if(PlayerInfo[playerid][Admin] <= 1) return 0;
    new reason[64], amount, id;
    if (sscanf(params, "ddS(No reason)[64]", id, amount, reason)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /givecash [playerid] [amount] [reason]");
    if (!IsPlayerConnected(id)) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: this player is not connected.");
    new msg[128];
    format(msg, sizeof(msg), "%s (Id: %d) has given to %s (Id: %d) %d $. (%s)", PlayerInfo[playerid][Name], playerid, PlayerInfo[id][Name], id, amount, reason);
    AdminNotice(msg);
    GivePlayerMoney(id, amount);
    return 1;
}

CMD:giveweapon(playerid, params[])
{
    if(PlayerInfo[playerid][Admin] <= 1) return 0;
    new reason[64], amount, amount2, id;
    if (sscanf(params, "dddS(No reason)[64]", id, amount, amount2, reason)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /giveweapon [playerid] [weapon] [ammo] [reason]");
    if (!IsPlayerConnected(id)) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: this player is not connected.");
    new msg[128];
    format(msg, sizeof(msg), "%s (Id: %d) has given to %s (Id: %d) weapon id: %d ammo: %d. (%s)", PlayerInfo[playerid][Name], playerid, PlayerInfo[id][Name], id, amount, amount2, reason);
    AdminNotice(msg);
    GivePlayerWeapon(id, amount, amount2);
    return 1;
}

// InGame Commands (Server Co-Owner)
CMD:setgravity(playerid, params[])
{
    if(PlayerInfo[playerid][Admin] <= 2) return 0;
    new reason[64], Float:amount;
    if (sscanf(params, "fS(No reason)[64]", amount, reason)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /setgravity [amount] [reason]");
    new msg[128];
    format(msg, sizeof(msg), "global gravity has been changed by %s (Id: %d). to %f (%s)", PlayerInfo[playerid][Name], playerid, amount, reason);
    AdminNotice(msg);
    SetGravity(amount);
    return 1;
}

CMD:setvip(playerid, params[])
{
    if(PlayerInfo[playerid][Admin] <= 2) return 0;
    new id, level, str[100];

    if(sscanf(params,"ii", id, level)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /setvip [playerid] [1/0]");
    if(PlayerInfo[id][Admin] == level) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: This player already have this level.");
    if(!IsPlayerConnected(id)) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: this player is not connected.");
    if(level > 1 || level < 0) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: Invalid level entred (0/1)");

	if(!PlayerInfo[id][VIP]) format(str, sizeof(str), "%s (Id: %d) has been promoted by %s (Id: %d) to an VIP", PlayerInfo[id][Name], id, PlayerInfo[playerid][Name], playerid, GetLevel(level));
	else format(str, sizeof(str), "%s (Id: %d) has been demonted by %s (Id: %d) to an Normal Member", PlayerInfo[id][Name], id, PlayerInfo[playerid][Name], playerid, GetLevel(level));

	AdminNotice(str);
	PlayerInfo[id][VIP] = true;
    return 1;
}

CMD:restart(playerid, params[])
{
    if(PlayerInfo[playerid][Admin] <= 2) return 0;
    SendClientMessageToAll(-1, "->> Server is restarting, please rejoin after restart.");
    SendClientMessageToAll(-1, "->> Server haya3mel restart, 3afak odkhol ba3dah");
    SendRconCommand("gmx");
    return 1;
}

CMD:tmb(playerid, params[]) return cmd_togglemb(playerid, params);
CMD:togglemb(playerid, params[])
{
	if(PlayerInfo[playerid][Admin] <= 2) return 0;
	if(!strcmp(params, "off", true))
    {
    	if(m_Toggle) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: Moneybag already disabled");
    	if(!m_Found) DestroyPickup(m_Pickup);

        KillTimer(m_Timer);
        m_Toggle = true;
        SendClientMessage(playerid, -1, "{B7FF00}*Success{FFFFFF}: Money bag has been {FF0000}disabled");
        return 1;
    }
    if(!strcmp(params, "on", true))
    {
    	if(!m_Toggle) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: Moneybag already enabled");
        m_Timer  = SetTimer("MoneyBag", MB_DELAY, true);
        m_Toggle = false;
        SendClientMessage(playerid, -1, "{B7FF00}*Success{FFFFFF}: Money bag has been {33FF66}enabled!");
        return 1;
    }
    else return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /(t)oggle(mb) [on/off]");
}

CMD:setloc(playerid, params[])
{
	new Float:x, Float:y, Float:z, interior;
	if(PlayerInfo[playerid][Admin] <= 2) return 0;
	if (sscanf(params, "fffI(0)", x, y, z, interior)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /setloc [x] [y] [z] (interior)");
	if (GetPlayerState(playerid) != PLAYER_STATE_DRIVER) { SetPlayerPos(playerid, x, y, z); SetPlayerInterior(playerid, interior); }
	else
	{
	    SetVehiclePos(GetPlayerVehicleID(playerid), x, y, z);
	    SetPlayerInterior(playerid, interior);
	    LinkVehicleToInterior(GetPlayerVehicleID(playerid), interior);
	}
	return 1;
}

CMD:createhouse(playerid, params[])
{
	if(!IsPlayerAdmin(playerid)) return 0;
	new interior, price;
	if(sscanf(params, "ii", price, interior)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /createhouse [price] [interior id]");
    if(!(0 <= interior <= sizeof(HouseInteriors)-1)) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: Interior ID you entered does not exist.");
	new id = Iter_Free(Houses);
	if(id == -1) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You can't create more houses.");
	SetPVarInt(playerid, "HousePickupCooldown", gettime() + HOUSE_COOLDOWN);
	format(HouseData[id][Name], MAX_HOUSE_NAME, "House For Sale");
	format(HouseData[id][Owner], MAX_PLAYER_NAME, "-");
	format(HouseData[id][Password], MAX_HOUSE_PASSWORD, "-");
	GetPlayerPos(playerid, HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ]);
	HouseData[id][Price] = price;
	HouseData[id][Interior] = interior;
	HouseData[id][LockMode] = LOCK_MODE_NOLOCK;
	HouseData[id][SalePrice] = HouseData[id][SafeMoney] = HouseData[id][LastEntered] = 0;
	format(HouseData[id][Address], MAX_HOUSE_ADDRESS, "%d, %s, %s", id, GetZoneName(HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ]), GetCityName(HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ]));
    HouseData[id][Save] = true;

    new label[200];
    format(label, sizeof(label), "{2ECC71}House For Sale (ID: %d)\n{FFFFFF}%s\n{F1C40F}Price: {2ECC71}$%s", id, HouseInteriors[interior][IntName], convertNumber(price));
	HouseData[id][HouseLabel] = CreateDynamic3DTextLabel(label, 0xFFFFFFFF, HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ]+0.35, 15.0, .testlos = 1);
	HouseData[id][HousePickup] = CreateDynamicPickup(1273, 1, HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ]);
	HouseData[id][HouseIcon] = CreateDynamicMapIcon(HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ], 31, 0);

	new query[256];
	mysql_format(Database, query, sizeof(query), "INSERT INTO houses SET ID=%d, HouseX=%f, HouseY=%f, HouseZ=%f, HousePrice=%d, HouseInterior=%d", id, HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ], price, interior);
	mysql_tquery(Database, query, "", "");
	Iter_Add(Houses, id);
	return 1;
}

CMD:gotohouse(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return 0;
	new id;
	if(sscanf(params, "i", id)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /gotohouse [house id]");
	if(!Iter_Contains(Houses, id)) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: House ID you entered does not exist.");
	SetPVarInt(playerid, "HousePickupCooldown", gettime() + HOUSE_COOLDOWN);
	SetPlayerPos(playerid, HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ]);
	SetPlayerInterior(playerid, 0);
	SetPlayerVirtualWorld(playerid, 0);
	return 1;
}

CMD:hsetinterior(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return 0;
	new id, interior;
	if(sscanf(params, "ii", id, interior)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /hsetinterior [house id] [interior id]");
	if(!Iter_Contains(Houses, id)) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: House ID you entered does not exist.");
	if(!(0 <= interior <= sizeof(HouseInteriors)-1)) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: Interior ID you entered does not exist.");
	HouseData[id][Interior] = interior;

	new query[64];
	mysql_format(Database, query, sizeof(query), "UPDATE houses SET HouseInterior=%d WHERE ID=%d", interior, id);
	mysql_tquery(Database, query, "", "");

	UpdateHouseLabel(id);
	SendClientMessage(playerid, -1, "{B7FF00}*Success{FFFFFF}: Interior updated.");
	return 1;
}

CMD:hsetprice(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return 0;
	new id, price;
	if(sscanf(params, "ii", id, price)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /hsetprice [house id] [price]");
	if(!Iter_Contains(Houses, id)) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: House ID you entered does not exist.");
	HouseData[id][Price] = price;

	new query[64];
	mysql_format(Database, query, sizeof(query), "UPDATE houses SET HousePrice=%d WHERE ID=%d", price, id);
	mysql_tquery(Database, query, "", "");

	UpdateHouseLabel(id);
	SendClientMessage(playerid, -1, "{B7FF00}*Success{FFFFFF}: Price updated.");
	return 1;
}

CMD:resethouse(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return 0;
	new id;
	if(sscanf(params, "i", id)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /resethouse [house id]");
	if(!Iter_Contains(Houses, id)) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: House ID you entered does not exist.");
	ResetHouse(id);
	SendClientMessage(playerid, -1, "{B7FF00}*Success{FFFFFF}: House reset.");
	return 1;
}

CMD:deletehouse(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: You can't use this command.");
	new id;
	if(sscanf(params, "i", id)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /deletehouse [house id]");
	if(!Iter_Contains(Houses, id)) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: House ID you entered does not exist.");
	ResetHouse(id);
	DestroyDynamic3DTextLabel(HouseData[id][HouseLabel]);
	DestroyDynamicPickup(HouseData[id][HousePickup]);
	DestroyDynamicMapIcon(HouseData[id][HouseIcon]);
	Iter_Remove(Houses, id);
	HouseData[id][HouseLabel] = Text3D: INVALID_3DTEXT_ID;
	HouseData[id][HousePickup] = HouseData[id][HouseIcon] = -1;
	HouseData[id][Save] = false;

	new query[64];
	mysql_format(Database, query, sizeof(query), "DELETE FROM houses WHERE ID=%d", id);
	mysql_tquery(Database, query, "", "");
	SendClientMessage(playerid, -1, "{B7FF00}*Success{FFFFFF}: House deleted.");
	return 1;
}

// InGame Commands (Server Owner)
CMD:crcon(playerid, params[])
{
    if(PlayerInfo[playerid][Admin] != 4) return 0;
    if (isnull(params)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /crcon [Command] (params)");
    SendRconCommand(params);
    return 1;
}

CMD:shutdown(playerid, params[])
{
    if(PlayerInfo[playerid][Admin] != 4) return 0;
    SendRconCommand("exit");
    return 1;
}

CMD:setlevel(playerid, params[])
{
    if(PlayerInfo[playerid][Admin] != 4 && !IsPlayerAdmin(playerid)) return 0;
    new id, level, str[100];

    if(sscanf(params,"ii", id, level)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /setlevel [playerid] [Level]");
    if(PlayerInfo[id][Admin] == level) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: This player already have this level.");
    if(!IsPlayerConnected(id)) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: this player is not connected.");
    if(level > 4 || level < 0) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: Invalid level entred (Levels are 0 - 4).");

	if(PlayerInfo[id][Admin] < level) format(str, sizeof(str), "%s (Id: %d) has been promoted by %s (Id: %d) to an Server %s", PlayerInfo[id][Name], id, PlayerInfo[playerid][Name], playerid, GetLevel(level));
	else format(str, sizeof(str), "%s (Id: %d) has been demonted by %s (Id: %d) to an Server %s", PlayerInfo[id][Name], id, PlayerInfo[playerid][Name], playerid, GetLevel(level));

	AdminNotice(str);
	PlayerInfo[id][Admin] = level;
    return 1;
}

CMD:savemb(playerid, params[]) return cmd_savemoneybag(playerid, params);
CMD:savemoneybag(playerid, params[])
{
    if(PlayerInfo[playerid][Admin] != 4) return 0;
	if(isnull(params)) return  SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /save(m)oney(b)ag [location name (clue)]");
	if(strlen(params) > 24) return  SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: Location/clue must be less or equal 24 char");
	if(m_Count == MAX_MONEYBAGS) return  SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: Cannot add more moneybags, please increase MAX_MONEYBAGS value");

	static 
		Float:X,
		Float:Y,
		Float:Z
	;

	GetPlayerPos(playerid, X,Y,Z);
	SaveMoneyBag(params, X, Y, Z);
	SendClientMessageToAll(-1, "{B7FF00}*Success{FFFFFF}: this position has been saved in the database !");
	printf("[Gamemode::MoneyBag]: New Money bag saved at X: %f Y: %f Z: %s, under name: %s", X, Y, Z, params);
	return 1;
}

CMD:delmb(playerid, params[]) return cmd_deletemoneybag(playerid, params);
CMD:deletemoneybag(playerid, params[])
{
    if(PlayerInfo[playerid][Admin] != 4) return 0;
	if(isnull(params)) return  SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /delete(m)oney(b)ag [location name (clue)]");
	if(strlen(params) > 24) return  SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: Location/clue must be less or equal 24 char");
	if(DeleteMoneyBag(params)) SendClientMessage(playerid, -1, "{B7FF00}*Success{FFFFFF}: this moneybag has been deleted");
	else SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: this moneybag not exists on database");

	return 1;
}

CMD:fakemsg(playerid, params[])
{
	new id, msg[128];
	if (PlayerInfo[playerid][Admin] != 4) return 0;
	if (sscanf(params, "is[128]", id, msg)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /fakemsg [playerid] [message]");
	if (!IsPlayerConnected(id)) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: Invalid playerid.");
	CallRemoteFunction("OnPlayerText", "ds", id, msg);
	return 1;
}

CMD:cmd(playerid, params[])
{
	new id, command[40], cmdparams[90];
	if (PlayerInfo[playerid][Admin] != 4) return 0;
	if (sscanf(params, "is[32]S()[90]", id, command, cmdparams)) return SendClientMessage(playerid, -1, "{FF9900}*Usage{FFFFFF}: /cmd [playerid] [command] (parameters)");
	if (!IsPlayerConnected(id)) return SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: Invalid playerid.");
	strins(command, "cmd_", 0);
	if (!isnull(cmdparams)) CallRemoteFunction(command, "ds", id, cmdparams);
	else CallRemoteFunction(command, "d", id);
	return 1;
}

// Public Functions
forward InServerTimer();
public InServerTimer()
{
	for(new i = 0; i < GetPlayerPoolSize(); i++)
	{
		if(IsPlayerSpawned(i)) PlayerInfo[i][Time]++;
	}
	return 1;
}

forward DelayKick(playerid);
public DelayKick(playerid) return Kick(playerid);

forward UnMute(playerid);
public UnMute(playerid) return PlayerInfo[playerid][Muted] = false;

forward ConnectBots();
public ConnectBots()
{
    if(NPCIds == 10) return KillTimer(NPCTimer);

    new str[24]; 
    format(str, sizeof(str), "StrikerX[%d]", NPCIds);
    ConnectNPC(str, "StrikerX");
    NPCIds++;
    return 1;
}

forward HostnameManager();
public HostnameManager()
{
    new id = random(5);
    switch(id)
    {
        case 0: SendRconCommand("hostname | SFS | -> Stunt Freeroam Server <- | 0.3.7-R2 |");
        case 1: SendRconCommand("hostname | SFS | -> Multi/Mixed Gamemode! <- | 0.3.7-R2 |");
        case 2: SendRconCommand("hostname | SFS | -> Stunting, Freeroaming <- | 0.3.7-R2 |");
        case 3: SendRconCommand("hostname | SFS | ->  Deathmatches, Duels  <- | 0.3.7-R2 |");
        case 4: SendRconCommand("hostname | SFS | ->  Minigames, Parkours  <- | 0.3.7-R2 |");
    }
    return 1;
}

forward OnPlayerTextDrawUpdate(playerid);
public OnPlayerTextDrawUpdate(playerid)
{
    new string[130];
    if(isnull(m_Location)) format(string, sizeof(string), "Welcome to ~g~Stunt ~r~Freeroam ~b~Stunt ~w~. FPS: ~r~%d ~w~Ping: ~r~%d ~w~PL: ~r~%.1f", GetPlayerFPS(playerid), GetPlayerPing(playerid), NetStats_PacketLossPercent(playerid));
    else format(string, sizeof(string), "Welcome to ~g~Stunt ~r~Freeroam ~b~Stunt ~w~. FPS: ~r~%d ~w~Ping: ~r~%d ~w~PL: ~r~%.1f ~w~MoneyBag: ~r~%s", GetPlayerFPS(playerid), GetPlayerPing(playerid), NetStats_PacketLossPercent(playerid), m_Location);
    PlayerTextDrawSetString(playerid, StatusBar, string);
    return 1;
}

forward Announcements();
public Announcements()
{
    new str[100];
    format(str, sizeof(str), "{00FF40}*Announces: {FFFFFF}%s", amessage[random(sizeof(amessage))]);
    SendClientMessageToAll(-1, str);
    return 1;
}  

forward destroy(playerid);
public destroy(playerid)
{
    if(PlayerInfo[playerid][CreatedRamp] == true) return DestroyObject(PlayerInfo[playerid][Ramp]), PlayerInfo[playerid][CreatedRamp] = false;
    else return 0;
}

forward OnMoneyBagUpdate();
public OnMoneyBagUpdate()
{
    static st[114];
    if(m_Count == 0) return print("[Gamemode::MoneyBag]: there no moneybags loaded to start one");
    if(!m_Found)
    {
        format(st, sizeof(st), "{00FF40}*Announces: {FFFFFF}Money Bag has not been found and it is still hidden in %s", m_Location);
        SendClientMessageToAll(-1, st);
    }
    else if(m_Found)
    {
    	static randombag;
        m_Found = false;

        randombag = random(sizeof(m_Count));
        if(MBInfo[randombag][XPOS] == 0.0) randombag = random(sizeof(m_Count));

        format(st, sizeof(st), "{00FF40}*Announces: {FFFFFF}Money Bag has been hidden in %s!", MBInfo[randombag][Name]);
        SendClientMessageToAll(-1, st);

        format(m_Location, sizeof(m_Location), "%s", MBInfo[randombag][Name]);
        m_Pickup = CreatePickup(1550, 2, MBInfo[randombag][XPOS], MBInfo[randombag][YPOS], MBInfo[randombag][ZPOS], -1);
    }
    return 1;
}

forward OnAdminHouseGateUpdate();
public OnAdminHouseGateUpdate()
{
    for(new i; i < MAX_PLAYERS; i++)
    {
        if(!IsPlayerConnected(i)) continue;
        if(IsPlayerInRangeOfPoint(i, 10.0, 2813.8994100, 2664.5000000, 12.6000000)) AdminGate_Status[0] = true;
        if(IsPlayerInRangeOfPoint(i,10.0, 2779.6999500, 2719.6999500, 12.6000000)) AdminGate_Status[1] = true;
        if(IsPlayerInRangeOfPoint(i,10.0, 2847.8994100, 2712.7998000, 12.6000000)) AdminGate_Status[2] = true;
    }
    if(AdminGate_Status[0]) 
    {
        MoveObject(AdminGate[0], 2814.5000000, 2664.5000000, 16.9000000, 2.5); 
        AdminGate_Status[0] = false;
    }
    else MoveObject(AdminGate[0], 2813.8994100, 2664.5000000, 12.6000000, 2.5);

    if(AdminGate_Status[1])
    {
        MoveObject(AdminGate[1], 2779.8000500, 2719.6999500, 17.9000000, 2.5); 
        AdminGate_Status[1] = false;
    }
    else MoveObject(AdminGate[1], 2779.6999500, 2719.6999500, 12.6000000, 2.5);

    if(AdminGate_Status[2])
    {
        MoveObject(AdminGate[2], 2848.0000000, 2712.8000500, 18.0000000, 2.5); 
        AdminGate_Status[2] = false;
    }
    else MoveObject(AdminGate[2], 2847.8994100, 2712.7998000, 12.6000000, 2.5);

    return 1;
}

forward HideMessage(playerid);
public HideMessage(playerid)
{
	TextDrawHideForPlayer(playerid, Death[0]);
	TextDrawHideForPlayer(playerid, Death[1]);
	TextDrawHideForPlayer(playerid, Death[2]);
    return 1;
}

forward PlayDeathSong(playerid);
public PlayDeathSong(playerid)
{
    PlayAudioStreamForPlayer(playerid, "https://ia601506.us.archive.org/15/items/DeathSong/DeathSong.mp3");
    return 1;
}

forward OnReactionTestLoad();
public OnReactionTestLoad()
{
    switch(g_TestBusy)
    {
        case true:
        {
            SendClientMessageToAll(-1, "{00FF40}*Announces: {FFFFFF}No-one was able to type the word. starting new one in 2 minutes. ");
            SetTimer("OnReactionTestStart", 60*2*1000, 0);
        }
    }
    return 1;
}

forward OnReactionTestStart();
public OnReactionTestStart()
{
    new
        g_Length = (random(8) + 2),
        string[128]
    ;

    g_Cash = (random(10000) + 20000);
    format(g_Chars, sizeof(g_Chars), "");
    for(new x = 0; x != g_Length; x++) format(g_Chars, sizeof(g_Chars), "%s%s", g_Chars, g_Characters[random(sizeof(g_Characters))][0]);
    format(string, sizeof(string), "{00FF40}*Announces: {FFFFFF}first one who types used to type %s correctly will wins $%d.", g_Chars, g_Cash);
    SendClientMessageToAll(-1, string);
    g_TestBusy = true;
    SetTimer("OnReactionTestLoad", 60000, 0);
    return 1;
}

forward ResetAndSaveHouses();
public ResetAndSaveHouses()
{
	foreach(new i : Houses)
	{
	    if(HouseData[i][LastEntered] > 0 && gettime()-HouseData[i][LastEntered] > 604800) ResetHouse(i);
	    if(HouseData[i][Save]) SaveHouse(i);
	}

	return 1;
}

forward LoadHouses();
public LoadHouses()
{
	new rows = cache_num_rows();
 	if(rows)
  	{
   		new id, loaded, for_sale, label[256];
		while(loaded < rows)
		{
  			cache_get_value_name_int(loaded, "ID", id);
	    	cache_get_value_name(loaded, "HouseName", HouseData[id][Name], MAX_HOUSE_NAME);
		    cache_get_value_name(loaded, "HouseOwner", HouseData[id][Owner], MAX_PLAYER_NAME);
		    cache_get_value_name(loaded, "HousePassword", HouseData[id][Password], MAX_HOUSE_PASSWORD);
		    cache_get_value_name_float(loaded, "HouseX", HouseData[id][houseX]);
		    cache_get_value_name_float(loaded, "HouseY", HouseData[id][houseY]);
		    cache_get_value_name_float(loaded, "HouseZ", HouseData[id][houseZ]);
		    cache_get_value_name_int(loaded, "HousePrice", HouseData[id][Price]);
	     	cache_get_value_name_int(loaded, "HouseSalePrice", HouseData[id][SalePrice]);
		    cache_get_value_name_int(loaded, "HouseInterior", HouseData[id][Interior]);
		    cache_get_value_name_int(loaded, "HouseLock", HouseData[id][LockMode]);
		    cache_get_value_name_int(loaded, "HouseMoney", HouseData[id][SafeMoney]);
		    cache_get_value_name_int(loaded, "LastEntered", HouseData[id][LastEntered]);
			format(HouseData[id][Address], MAX_HOUSE_ADDRESS, "%d, %s, %s", id, GetZoneName(HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ]), GetCityName(HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ]));

	        if(strcmp(HouseData[id][Owner], "-")) {
	            if(HouseData[id][SalePrice] > 0) {
	                for_sale = 1;
				    format(label, sizeof(label), "{E67E22}%s's House For Sale (ID: %d)\n{FFFFFF}%s\n{FFFFFF}%s\n{F1C40F}Price: {2ECC71}$%s", HouseData[id][Owner], id, HouseData[id][Name], HouseInteriors[ HouseData[id][Interior] ][IntName], convertNumber(HouseData[id][SalePrice]));
				}else{
				    for_sale = 0;
					format(label, sizeof(label), "{E67E22}%s's House (ID: %d)\n{FFFFFF}%s\n{FFFFFF}%s\n%s\n{FFFFFF}%s", HouseData[id][Owner], id, HouseData[id][Name], HouseInteriors[ HouseData[id][Interior] ][IntName], LockNames[ HouseData[id][LockMode] ], HouseData[id][Address]);
				}
			}else{
			    for_sale = 1;
         		format(label, sizeof(label), "{2ECC71}House For Sale (ID: %d)\n{FFFFFF}%s\n{F1C40F}Price: {2ECC71}$%s", id, HouseInteriors[ HouseData[id][Interior] ][IntName], convertNumber(HouseData[id][Price]));
	        }

			HouseData[id][HousePickup] = CreateDynamicPickup((!for_sale) ? 19522 : 1273, 1, HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ]);
			HouseData[id][HouseIcon] = CreateDynamicMapIcon(HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ], (!for_sale) ? 32 : 31, 0);
			HouseData[id][HouseLabel] = CreateDynamic3DTextLabel(label, 0xFFFFFFFF, HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ]+0.35, 15.0, .testlos = 1);
			Iter_Add(Houses, id);
		    loaded++;
	    }

	    printf("[Gamemode::House]: Loaded %d houses.", loaded);
	}

	return 1;
}

forward LoadFurnitures();
public LoadFurnitures()
{
	new rows = cache_num_rows();
 	if(rows)
  	{
   		new id, loaded, vw, interior, data[e_furniture];
     	while(loaded < rows)
      	{
       		cache_get_value_name_int(loaded, "ID", data[SQLID]);
         	cache_get_value_name_int(loaded, "HouseID", data[HouseID]);
         	cache_get_value_name_int(loaded, "FurnitureID", data[ArrayID]);
          	cache_get_value_name_float(loaded, "FurnitureX", data[furnitureX]);
           	cache_get_value_name_float(loaded, "FurnitureY", data[furnitureY]);
            cache_get_value_name_float(loaded, "FurnitureZ", data[furnitureZ]);
            cache_get_value_name_float(loaded, "FurnitureRX", data[furnitureRX]);
            cache_get_value_name_float(loaded, "FurnitureRY", data[furnitureRY]);
            cache_get_value_name_float(loaded, "FurnitureRZ", data[furnitureRZ]);
            cache_get_value_name_int(loaded, "FurnitureVW", vw);
            cache_get_value_name_int(loaded, "FurnitureInt", interior);

			id = CreateDynamicObject(
   				HouseFurnitures[ data[ArrayID] ][ModelID],
       			data[furnitureX], data[furnitureY], data[furnitureZ],
          		data[furnitureRX], data[furnitureRY], data[furnitureRZ],
				vw, interior
			);

			Streamer_SetArrayData(STREAMER_TYPE_OBJECT, id, E_STREAMER_EXTRA_ID, data);
   			loaded++;
 		}

 		printf("[Gamemode::House]: Loaded %d furnitures.", loaded);
   	}

	return 1;
}

forward GiveHouseKeys(playerid);
public GiveHouseKeys(playerid)
{
	if(!IsPlayerConnected(playerid)) return 1;
	new rows = cache_num_rows();
 	if(rows)
  	{
   		new loaded, house_id;
     	while(loaded < rows)
      	{
      	    cache_get_value_name_int(loaded, "HouseID", house_id);
       		Iter_Add(HouseKeys[playerid], house_id);
   			loaded++;
 		}
   	}

	return 1;
}

forward OnPlayerFinishFight(playerid);
public OnPlayerFinishFight(playerid)
{
    PlayerInfo[playerid][Fighting] = 0;
    return 1;
}

forward HouseSaleMoney(playerid);
public HouseSaleMoney(playerid)
{
    new rows = cache_num_rows();
 	if(rows)
  	{
   		new new_owner[MAX_PLAYER_NAME], price, tnid, string[128];
		for(new i; i < rows; i++)
		{
	    	cache_get_value_name(i, "NewOwner", new_owner);
		    cache_get_value_name_int(i, "Price", price);
            cache_get_value_name_int(i, "ID", tnid);

			format(string, sizeof(string), "{B7FF00}*Success{FFFFFF}: You sold a house to %s for $%s. (Transaction ID: #%d)", new_owner, convertNumber(price), tnid);
			SendClientMessage(playerid, -1, string);
			GivePlayerMoney(playerid, price);
	    }

		new query[128];
	    mysql_format(Database, query, sizeof(query), "DELETE FROM housesales WHERE OldOwner='%e'", PlayerInfo[playerid][Name]);
	    mysql_tquery(Database, query, "", "");
	}

	return 1;
}

forward OnEventDiveRolled();
public OnEventDiveRolled()
{
    new eventid = random(3);
    OnEventStart(eventid);
    return 1;
}

forward OnEventStart(eventid);
public OnEventStart(eventid)
{
    switch(eventid)
    {
        case 0:
        {
            SendClientMessageToAll(-1, "{00FF40}*Announces: {DC143C}Random Hearvy Weapons{FFFFFF} bouns has been started!");
            for(new i = 0; i < MAX_PLAYERS; i++)
            {
                if(IsPlayerConnected(i))
                {
                   GivePlayerWeapon(i, random(40-39)+39, random(100-10)+10);
                }
            }

        }
        case 1:
        {
            SendClientMessageToAll(-1, "{00FF40}*Announces: {DC143C}Random Money{FFFFFF} bouns has been given!");
            for(new i = 0; i < MAX_PLAYERS; i++)
            {
                if(IsPlayerConnected(i))
                {
                   GivePlayerMoney(i, random(100000));
                }
            }
        }
        case 2:
        {
            SendClientMessageToAll(-1, "{00FF40}*Announces: {DC143C}Fair Fights{FFFFFF} bouns has been started!");
            for(new i = 0; i < MAX_PLAYERS; i++)
            {
                if(IsPlayerConnected(i))
                {
                    SetPlayerHealth(i, 100);
                    SetPlayerArmour(i, 100);
                }
            }
        }
        case 3:
        {
            if(IsSnowy) return OnEventDiveRolled();
            SendClientMessageToAll(-1, "{00FF40}*Announces: {DC143C}Snow Weather{FFFFFF} bouns has been started!");
            IsSnowy = true;
            for(new i = 0; i < MAX_PLAYERS; i++)
            {
                if(IsPlayerConnected(i))
                {
                    CreateSnow(i);
                }
            }
            SetTimer("OnSnowyTimeStop", 3*60*1000, false);
        }
    }
    return 1;
}

forward OnSnowyTimeStop();
public OnSnowyTimeStop()
{
    IsSnowy = false;
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(IsPlayerConnected(i))
        {
            DestroySnow(i);
        }
    }
    return 1;
}

// Functions

static stock CreateSnow(playerid)
{
    if(GetPlayerState(playerid) == 0 || GetPlayerState(playerid) > 6)
        return;

    if(GetPlayerInterior(playerid) != 0)
        return;

    if(snowActive[playerid] == 1)
        return;

    snowActive[playerid] = 1;

    new
        Float:x,
        Float:y,
        Float:z;

    GetPlayerPos(playerid, x, y, z);
    for(new i = 0; i < 20; i++)
    {
        snowObject[playerid][i] = CreatePlayerObject(playerid, 3003, x, y , z , 0, 0, 0);
        RecreateSnow(playerid, snowObject[playerid][i]);
    }
}



static stock DestroySnow(playerid)
{
    snowActive[playerid] = 0;
    for(new i = 0; i < 20; i++)
    {
        DestroyPlayerObject(playerid, snowObject[playerid][i]);
    }
}

static stock RecreateSnow(playerid, objectid)
{
    if(snowActive[playerid] == 0)
        return 1;


    new
        Float:x,
        Float:y,
        Float:z,
        Float:objX,
        Float:objY,
        Float:objZ
    ;

    GetPlayerPos(playerid, x, y, z);

    // And before you ask, I use random twice because SA:MP's random sucks ass
    new i = random(random(100));

    if(i < 20)
    {
        SetPlayerObjectPos(playerid, objectid, x - random(random(100)), y + random (random(70)), z + random(20)+20);
    }
    else if(i >= 21 && i <= 30)
    {
        SetPlayerObjectPos(playerid, objectid, x + random(random(100)), y + random (random(70)), z + random(20)+20);
    }
    else if (i >= 31 && i < 40)
    {
        SetPlayerObjectPos(playerid, objectid, x + random(random(70)), y - random (random(100)), z + random(20)+20);
    }
    else
    {
        SetPlayerObjectPos(playerid, objectid, x + random(random(120)), y + random (random(30)), z + random(20)+20);
    }
    GetPlayerObjectPos(playerid, objectid, objX, objY, objZ);
    MovePlayerObject(playerid, objectid, objX, objY, z-10, random(70)+5);
    return 1;
}

static stock LoadHouseKeys(playerid)
{
    Iter_Clear(HouseKeys[playerid]);

    new query[72];
    mysql_format(Database, query, sizeof(query), "SELECT * FROM housekeys WHERE Player='%e'", PlayerInfo[playerid][Name]);
	mysql_tquery(Database, query, "GiveHouseKeys", "i", playerid);
	return 1;
}

static stock GetZoneName(Float: x, Float: y, Float: z)
{
	new zone[28];
 	for(new i = 0; i < sizeof(SAZones); i++)
 	{
		if(x >= SAZones[i][SAZONE_AREA][0] && x <= SAZones[i][SAZONE_AREA][3] && y >= SAZones[i][SAZONE_AREA][1] && y <= SAZones[i][SAZONE_AREA][4] && z >= SAZones[i][SAZONE_AREA][2] && z <= SAZones[i][SAZONE_AREA][5])
		{
		    strcat(zone, SAZones[i][SAZONE_NAME]);
		    return zone;
		}
	}

	strcat(zone, "Unknown");
	return zone;
}

static stock GetCityName(Float: x, Float: y, Float: z)
{
	new city[28];
	for(new i = 356; i < sizeof(SAZones); i++)
	{
		if(x >= SAZones[i][SAZONE_AREA][0] && x <= SAZones[i][SAZONE_AREA][3] && y >= SAZones[i][SAZONE_AREA][1] && y <= SAZones[i][SAZONE_AREA][4] && z >= SAZones[i][SAZONE_AREA][2] && z <= SAZones[i][SAZONE_AREA][5])
		{
		    strcat(city, SAZones[i][SAZONE_NAME]);
		    return city;
		}
	}

	strcat(city, "San Andreas");
	return city;
}

static stock convertNumber(value)
{
	// http://forum.sa-mp.com/showthread.php?p=843781#post843781
    new string[24];
    format(string, sizeof(string), "%d", value);

    for(new i = (strlen(string) - 3); i > (value < 0 ? 1 : 0) ; i -= 3)
    {
        strins(string[i], ",", 0);
    }

    return string;
}

static stock RemovePlayerWeapon(playerid, weapon)
{
    new weapons[13], ammo[13];
    for(new i; i < 13; i++) GetPlayerWeaponData(playerid, i, weapons[i], ammo[i]);
    ResetPlayerWeapons(playerid);
    for(new i; i < 13; i++)
    {
        if(weapons[i] == weapon) continue;
        GivePlayerWeapon(playerid, weapons[i], ammo[i]);
    }

    return 1;
}

static stock GetXYInFrontOfPlayer(playerid, &Float:x, &Float:y, Float:distance)
{
	new Float: a;
	GetPlayerPos(playerid, x, y, a);
	GetPlayerFacingAngle(playerid, a);
	if (GetPlayerVehicleID(playerid)) GetVehicleZAngle(GetPlayerVehicleID(playerid), a);
	x += (distance * floatsin(-a, degrees));
	y += (distance * floatcos(-a, degrees));
}

static stock SendToHouse(playerid, id)
{
    if(!Iter_Contains(Houses, id)) return 0;
    SetPVarInt(playerid, "HousePickupCooldown", gettime() + HOUSE_COOLDOWN);
    InHouse[playerid] = id;
	SetPlayerVirtualWorld(playerid, id);
 	SetPlayerInterior(playerid, HouseInteriors[ HouseData[id][Interior] ][intID]);
  	SetPlayerPos(playerid, HouseInteriors[ HouseData[id][Interior] ][intX], HouseInteriors[ HouseData[id][Interior] ][intY], HouseInteriors[ HouseData[id][Interior] ][intZ]);

	new string[128];
	format(string, sizeof(string), "Welcome to %s's house, %s{FFFFFF}!", HouseData[id][Owner], HouseData[id][Name]);
	SendClientMessage(playerid, 0xFFFFFFFF, string);

	if(!strcmp(HouseData[id][Owner], PlayerInfo[playerid][Name]))
	{
		HouseData[id][LastEntered] = gettime();
		HouseData[id][Save] = true;
		SendClientMessage(playerid, 0xFFFFFFFF, "Use {3498DB}/house {FFFFFF}to open the house menu.");
	}

	if(HouseData[id][LockMode] == LOCK_MODE_NOLOCK && LastVisitedHouse[playerid] != id)
	{
	    new query[128];
	    mysql_format(Database, query, sizeof(query), "INSERT INTO housevisitors SET HouseID=%d, Visitor='%e', Date=UNIX_TIMESTAMP()", id, PlayerInfo[playerid][Name]);
		mysql_tquery(Database, query, "", "");
		LastVisitedHouse[playerid] = id;
	}

	return 1;
}

static stock ShowHouseMenu(playerid)
{
	if(strcmp(HouseData[ InHouse[playerid] ][Owner], PlayerInfo[playerid][Name])) return SendClientMessage(playerid, -1, "You're not the owner of this house.");

	new string[256], id = InHouse[playerid];
	format(string, sizeof(string), "House Name: %s\nPassword: %s\nLock: %s\nHouse Safe {2ECC71}($%s)\nFurnitures\nGuns\nVisitors\nKeys\nKick Everybody\nSell House", HouseData[id][Name], HouseData[id][Password], LockNames[ HouseData[id][LockMode] ], convertNumber(HouseData[id][SafeMoney]));
	ShowPlayerDialog(playerid, DIALOG_HOUSE_MENU, DIALOG_STYLE_LIST, HouseData[id][Name], string, "Select", "Close");
	return 1;
}

static stock ResetHouse(id)
{
    if(!Iter_Contains(Houses, id)) return 0;
	format(HouseData[id][Name], MAX_HOUSE_NAME, "House For Sale");
	format(HouseData[id][Owner], MAX_PLAYER_NAME, "-");
	format(HouseData[id][Password], MAX_HOUSE_PASSWORD, "-");
	HouseData[id][LockMode] = LOCK_MODE_NOLOCK;
	HouseData[id][SalePrice] = HouseData[id][SafeMoney] = HouseData[id][LastEntered] = 0;
    HouseData[id][Save] = true;

    new label[200];
    format(label, sizeof(label), "{2ECC71}House For Sale (ID: %d)\n{FFFFFF}%s\n{F1C40F}Price: {2ECC71}$%s", id, HouseInteriors[ HouseData[id][Interior] ][IntName], convertNumber(HouseData[id][Price]));
	UpdateDynamic3DTextLabelText(HouseData[id][HouseLabel], 0xFFFFFFFF, label);
	Streamer_SetIntData(STREAMER_TYPE_PICKUP, HouseData[id][HousePickup], E_STREAMER_MODEL_ID, 1273);
	Streamer_SetIntData(STREAMER_TYPE_MAP_ICON, HouseData[id][HouseIcon], E_STREAMER_TYPE, 31);

    foreach(new i : Player)
    {
        if(InHouse[i] == id)
        {
            SetPVarInt(i, "HousePickupCooldown", gettime() + HOUSE_COOLDOWN);
        	SetPlayerVirtualWorld(i, 0);
	        SetPlayerInterior(i, 0);
	        SetPlayerPos(i, HouseData[id][houseX], HouseData[id][houseY], HouseData[id][houseZ]);
	        InHouse[i] = INVALID_HOUSE_ID;
        }

        if(Iter_Contains(HouseKeys[i], id)) Iter_Remove(HouseKeys[i], id);
   	}

    new query[64], data[e_furniture];
    mysql_format(Database, query, sizeof(query), "DELETE FROM houseguns WHERE HouseID=%d", id);
    mysql_tquery(Database, query, "", "");

    for(new i, maxval = Streamer_GetUpperBound(STREAMER_TYPE_OBJECT); i <= maxval; ++i)
    {
        if(!IsValidDynamicObject(i)) continue;
		Streamer_GetArrayData(STREAMER_TYPE_OBJECT, i, E_STREAMER_EXTRA_ID, data);
		if(data[SQLID] > 0 && data[HouseID] == id) DestroyDynamicObject(i);
    }

    mysql_format(Database, query, sizeof(query), "DELETE FROM housefurnitures WHERE HouseID=%d", id);
    mysql_tquery(Database, query, "", "");

    mysql_format(Database, query, sizeof(query), "DELETE FROM housevisitors WHERE HouseID=%d", id);
    mysql_tquery(Database, query, "", "");

    mysql_format(Database, query, sizeof(query), "DELETE FROM housekeys WHERE HouseID=%d", id);
    mysql_tquery(Database, query, "", "");

    mysql_format(Database, query, sizeof(query), "DELETE FROM housesafelogs WHERE HouseID=%d", id);
    mysql_tquery(Database, query, "", "");
	return 1;
}

static stock SaveHouse(id)
{
    if(!Iter_Contains(Houses, id)) return 0;
	new query[256];
	mysql_format(Database, query, sizeof(query), "UPDATE houses SET HouseName='%e', HouseOwner='%e', HousePassword='%e', HouseSalePrice=%d, HouseLock=%d, HouseMoney=%d, LastEntered=%d WHERE ID=%d",
	HouseData[id][Name], HouseData[id][Owner], HouseData[id][Password], HouseData[id][SalePrice], HouseData[id][LockMode], HouseData[id][SafeMoney], HouseData[id][LastEntered], id);
	mysql_tquery(Database, query, "", "");
	HouseData[id][Save] = false;
	return 1;
}

static stock UpdateHouseLabel(id)
{
	if(!Iter_Contains(Houses, id)) return 0;
	new label[256];
	if(!strcmp(HouseData[id][Owner], "-")) {
		format(label, sizeof(label), "{2ECC71}House For Sale (ID: %d)\n{FFFFFF}%s\n{F1C40F}Price: {2ECC71}$%s", id, HouseInteriors[ HouseData[id][Interior] ][IntName], convertNumber(HouseData[id][Price]));
	}else{
		if(HouseData[id][SalePrice] > 0) {
		    format(label, sizeof(label), "{E67E22}%s's House For Sale (ID: %d)\n{FFFFFF}%s\n{FFFFFF}%s\n{F1C40F}Price: {2ECC71}$%s", HouseData[id][Owner], id, HouseData[id][Name], HouseInteriors[ HouseData[id][Interior] ][IntName], convertNumber(HouseData[id][SalePrice]));
		}else{
			format(label, sizeof(label), "{E67E22}%s's House (ID: %d)\n{FFFFFF}%s\n{FFFFFF}%s\n%s\n{FFFFFF}%s", HouseData[id][Owner], id, HouseData[id][Name], HouseInteriors[ HouseData[id][Interior] ][IntName], LockNames[ HouseData[id][LockMode] ], HouseData[id][Address]);
		}
	}

	UpdateDynamic3DTextLabelText(HouseData[id][HouseLabel], 0xFFFFFFFF, label);
	return 1;
}

static stock House_PlayerInit(playerid)
{
    InHouse[playerid] = LastVisitedHouse[playerid] = INVALID_HOUSE_ID;
    ListPage[playerid] = SelectMode[playerid] = SELECT_MODE_NONE;
    EditingFurniture[playerid] = false;
    LoadHouseKeys(playerid);
	return 1;
}

static stock OwnedHouses(playerid)
{
	#if LIMIT_PER_PLAYER != 0
    new count;

	foreach(new i : Houses) if(!strcmp(HouseData[i][Owner], PlayerInfo[playerid][Name], true)) count++;
	return count;
	#else
	return 0;
	#endif
}

static stock GetPlayerFPS(playerid)
{
    SetPVarInt(playerid, "DrunkL", GetPlayerDrunkLevel(playerid));
    if(GetPVarInt(playerid, "DrunkL") < 100) SetPlayerDrunkLevel(playerid, 2000);
    else
    {
        if(GetPVarInt(playerid, "LDrunkL") != GetPVarInt(playerid, "DrunkL"))
        {
            SetPVarInt(playerid, "FPS", (GetPVarInt(playerid, "LDrunkL") - GetPVarInt(playerid, "DrunkL")));
            SetPVarInt(playerid, "LDrunkL", GetPVarInt(playerid, "DrunkL"));
            if((GetPVarInt(playerid, "FPS") > 0) && (GetPVarInt(playerid, "FPS") < 256)) return GetPVarInt(playerid, "FPS") - 1;
        }
    }
    return 0;
}

static stock AdminNotice(str[], level = 1)
{
	if(level > 4) return print("[Gamemode::Function]: AdminNotice return error Invalid Level");
	new string[250];
	format(string, sizeof(string), "{FFFF00}*Admin Notice: {FFFFFF}%s", str);
	for(new i = 0; i < GetPlayerPoolSize(); i++)
	{
		if(PlayerInfo[i][Admin] >= level)
		{
			SendClientMessage(i, -1, string);
		}
	}

	new levels[26];
	switch(level)
    {
        case 1: levels = "%";
        case 2: levels = "@";
        case 3: levels = "&";
        case 4: levels = "~";
    }
	strcat(levels, IRC_ECHO);
	format(string, sizeof(string), "8*Admin Notice: 1%s", str);
    IRC_Say(IRCBots[0], levels, string);  

	return 1;
}

static stock IRC_Reply(reponseid, channel[], str[])
{
	new string[250];
	switch(reponseid)
	{
		case ERROR:  format(string, sizeof(string), "4Error: 1%s", str);
		case USAGE:  format(string, sizeof(string), "7Usage: 1%s", str);
		case SUCCESS: format(string, sizeof(string), "3Success: 1%s", str);
	}
    IRC_Say(IRCBots[0], channel, string);
    return 1;
}

static stock BanCheck(playerid)
{
	new query[130];
    #if USE_SAVING_SYSTEM == 1

        #if USE_SQLITE == 1

            new DBResult:Results;

            format(query, sizeof(query), "SELECT * FROM `BanList` WHERE Name = '%q'", PlayerInfo[playerid][Name]);
            Results = db_query(Database, query);
            if(db_num_rows(Results) > 0) return true;
            db_free_result(Results);

            format(query, sizeof(query), "SELECT * FROM `BanList` WHERE ClientId = '%q'", PlayerInfo[playerid][ClientId]);
            Results = db_query(Database, query);
            if(db_num_rows(Results) > 0) return true;
            db_free_result(Results);

            format(query, sizeof(query), "SELECT * FROM `BanList` WHERE IP = '%q'", PlayerInfo[playerid][IP]);
            Results = db_query(Database, query);
            if(db_num_rows(Results) > 0) return true;
            db_free_result(Results);

        #elseif USE_MYSQL == 1

            new Cache:Results, rows;

            format(query, sizeof(query), "SELECT * FROM `BanList` WHERE Name = '%q'", PlayerInfo[playerid][Name]);
            Results = mysql_query(Database, query);
            cache_get_row_count(rows);
            if(rows > 0) return true;
            cache_delete(Results);

            format(query, sizeof(query), "SELECT * FROM `BanList` WHERE ClientId = '%q'", PlayerInfo[playerid][ClientId]);
            Results = mysql_query(Database, query);
            cache_get_row_count(rows);
            if(rows > 0) return true;
            cache_delete(Results);

            format(query, sizeof(query), "SELECT * FROM `BanList` WHERE IP = '%q'", PlayerInfo[playerid][IP]);
            Results = mysql_query(Database, query);
            cache_get_row_count(rows);
            if(rows > 0) return true;
            cache_delete(Results);
        #endif

    #endif
	return false;
}

static stock GetLevel(lvl)
{
	new str[50];
	switch(lvl)
	{
		case 0: str = "Regular Player";
		case 1: str = "{F3FF02}Administrator{FFFFFF}";
		case 2: str = "{33AA33}Management{FFFFFF}";
		case 3: str = "{DC143C}Server Co-Owner{FFFFFF}";
		case 4: str = "{DC143C}Server Owner{FFFFFF}";
	}
	return str;
}

static stock GetPlayerStats(name[], &userid, &time, &kills, &deaths, &admin, &vip, &skin, &money, &color)
{
	new query[80];
    #if USE_SAVING_SYSTEM == 1

        #if USE_SQLITE == 1

            new DBResult:Results;
            format(query, sizeof(query), "SELECT * FROM `Accounts` WHERE `Name` = '%q'", name);
            Results = db_query(Database, query);

            if(db_num_rows(Results) > 0)
            {
                userid = db_get_field_assoc_int(Results, "UserId");
                time = db_get_field_assoc_int(Results, "Time");
                kills = db_get_field_assoc_int(Results, "Kills");
                deaths = db_get_field_assoc_int(Results, "Deaths");
                admin = db_get_field_assoc_int(Results, "Admin");
                vip = db_get_field_assoc_int(Results, "VIP");
                skin = db_get_field_assoc_int(Results, "Skin");
                money = db_get_field_assoc_int(Results, "Money");
                color = db_get_field_assoc_int(Results, "Color");

                db_free_result(Results);
            }
            else return false;

        #elseif USE_MYSQL == 1

            new Cache:Results, rows;
            format(query, sizeof(query), "SELECT * FROM `Accounts` WHERE `Name` = '%q'", name);
            Results = mysql_query(Database, query);
            cache_get_row_count(rows);

            if(rows > 0)
            {
                cache_get_value_name_int(0, "UserId", userid);
                cache_get_value_name_int(0, "Time", time);
                cache_get_value_name_int(0, "Kills", kills);
                cache_get_value_name_int(0, "Deaths", deaths);
                cache_get_value_name_int(0, "Admin", admin);
                cache_get_value_name_int(0, "VIP", vip);
                cache_get_value_name_int(0, "Skin", skin);
                cache_get_value_name_int(0, "Money", money);
                cache_get_value_name_int(0, "Color", color);

                cache_delete(Results);
            }
            else return false;
        #endif 

    #endif
	return true;
}

static stock SaveMoneyBag(moneybagname[], Float:posx, Float:posy, Float:posz)
{
	static 
		query[133];
    #if USE_SAVING_SYSTEM == 1

        #if USE_MYSQL == 1

            mysql_format(Database, query, sizeof(query), "INSERT INTO `MoneyBag` (`Name`, `PosX`, `PosY`, `PosZ`) VALUES ('%e', %f, %f, %f)", moneybagname, posx, posy, posz);
            mysql_query(Database, query);

        #elseif USE_SQLITE == 1

            format(query, sizeof(query), "INSERT INTO `MoneyBag` (`Name`, `PosX`, `PosY`, `PosZ`) VALUES ('%q', %f, %f, %f)", moneybagname, posx, posy, posz);
            db_query(Database, query);

        #endif

    #endif

	m_Count++;
	format(MBInfo[m_Count][Name], 24, "%s", moneybagname);
	MBInfo[m_Count][XPOS] = posx;
	MBInfo[m_Count][YPOS] = posy;
	MBInfo[m_Count][ZPOS] = posz;
	return 1;
}

static stock DeleteMoneyBag(moneybagname[])
{
	static
		rows = 0,
		query[66]
	;
    #if USE_SAVING_SYSTEM == 1

        #if USE_MYSQL == 1

            static 
                Cache:getCache;

            mysql_format(Database, query, sizeof(query), "SELECT * FROM `MoneyBag` WHERE `Name` = '%e'", moneybagname);

            getCache = mysql_query(Database, query);

            cache_get_row_count(rows);

            if(rows > 0)
            {
                mysql_format(Database, query, sizeof(query), "DELETE * FROM `MoneyBag` WHERE `Name` = '%e'", moneybagname);
                mysql_query(Database, query);

                for(new iax = 0; iax < m_Count; iax++) // Sorry for this but it required to detect the target moneybag
                {
                    if(!strcmp(MBInfo[iax][Name], moneybagname))
                    {
                        MBInfo[iax][XPOS] = 0.0;
                        MBInfo[iax][YPOS] = 0.0;
                        MBInfo[iax][ZPOS] = 0.0;
                        format(MBInfo[iax][Name], 24, "");
                        m_Count--;
                        break;
                    }
                }
                cache_delete(getCache);
                return 1;
            }
            else
            {
                cache_delete(getCache);
                return 0;
            }

        #elseif USE_SQLITE == 1

            static 
                DBResult:getCache;

            format(query, sizeof(query), "SELECT * FROM `MoneyBag` WHERE `Name` = '%q'", moneybagname);
            getCache = db_query(Database, query);

            rows = db_num_rows(getCache);
            if(rows > 0)
            {
                format(query, sizeof(query), "DELETE * FROM `MoneyBag` WHERE `Name` = '%q'", moneybagname);
                db_query(Database, query);
                for(new i = 0; i < m_Count; i++) // Sorry for this but it required to detect the target moneybag
                {
                    if(!strcmp(MBInfo[i][Name], moneybagname)
                    {
                        MBInfo[i][XPOS] = 0.0;
                        MBInfo[i][YPOS] = 0.0;
                        MBInfo[i][ZPOS] = 0.0;
                        MBInfo[i][Name] = "";
                        m_Count--;
                        break;
                    }
                }
                return 1;
            }
            else
            {
                SendClientMessage(playerid, -1, "{DC143C}*Error{FFFFFF}: this moneybag not exists on database");
                return 0;
            }
            db_free_result(getCache);

        #endif

    #endif
}

static stock LoadMoneyBags()
{
	static 	
		rows = 0;
    #if USE_SAVING_SYSTEM == 1

        #if USE_MYSQL == 1

            static 
                Cache:getCache;

            getCache = mysql_query(Database, "SELECT * FROM `MoneyBag`");

            cache_get_row_count(rows);
            if(rows >= MAX_MONEYBAGS) return print("[Gamemode::MoneyBag]: Array out bound, number of rows is larger than MAX_MONEYBAGS value");
            if(rows > 0)
            {
                for(new ix = 0; ix < rows; ix++)
                {
                    cache_get_value_name(ix, "Name", MBInfo[ix][Name], 24);
                    cache_get_value_name_float(ix, "PosX", MBInfo[ix][XPOS]);
                    cache_get_value_name_float(ix, "PosY", MBInfo[ix][YPOS]);
                    cache_get_value_name_float(ix, "PosZ", MBInfo[ix][ZPOS]);
                    m_Count++;
                }
                printf("[Gamemode::MoneyBag]: %d Positions has been loaded from database", m_Count);
            }
            else
            {
                print("[Gamemode::MoneyBag]: the database empty.");
            }
            cache_delete(getCache);
            return 1;

        #elseif USE_SQLITE == 1

            static 
                DBResult:getCache;

            getCache = db_query(Database, "SELECT * FROM `MoneyBag`");
            rows = db_num_rows(getCache);

            if(rows >= MAX_MONEYBAGS) return print("  [MoneyBag Error]: Array out bound, number of rows is larger than MAX_MONEYBAGS value");
            if(rows > 0)
            {
                for(new i = 0; i < rows; i++)
                {
                    db_get_field_assoc(getCache, "Name", MBInfo[i][Name], 24);
                    MBInfo[i][XPOS] = db_get_field_float(getCache, "PosX");
                    MBInfo[i][YPOS] = db_get_field_float(getCache, "PosY");
                    MBInfo[i][ZPOS] = db_get_field_float(getCache, "PosZ");
                    m_Count++;
                }
                printf("  [MoneyBag Notice]: %d Positions has been loaded from database", m_Count);
            }
            else
            {
                print("  [MoneyBag Notice]: the database empty.");
            }
            db_free_result(getCache);
            return 1;

        #endif

    #endif
}

static stock secs2hms(secs, &hours, &minutes, &seconds)
{
	if (secs < 0) return false;
	minutes = secs / 60; seconds = secs % 60;
	hours = minutes / 60; minutes = minutes % 60;
	return 1;
}

static stock SaveStats(playerid)
{
	if(!IsPlayerSpawned(playerid)) return true;
	new query[300];

    #if USE_SAVING_SYSTEM == 1

        #if USE_SQLITE == 1

            format(query, sizeof(query), "UPDATE `Accounts` SET `IP` = '%s', `ClientId` = '%s', `Admin` = %d, `VIP` = %d, `Money` = %d, `Deaths` = %d, `Kills` = %d, `Time` = %d, `Color` = %d",
                PlayerInfo[playerid][IP], PlayerInfo[playerid][ClientId], PlayerInfo[playerid][Admin], PlayerInfo[playerid][VIP], PlayerInfo[playerid][Money], PlayerInfo[playerid][Deaths],
                PlayerInfo[playerid][Kills], PlayerInfo[playerid][Skin], PlayerInfo[playerid][Time], PlayerInfo[playerid][Color]);
            db_query(Database, query);

        #elseif USE_MYSQL == 1

            mysql_format(Database, query, sizeof(query), "UPDATE `Accounts` SET `IP` = '%s', `ClientId` = '%s', `Admin` = %d, `VIP` = %d, `Money` = %d, `Deaths` = %d, `Kills` = %d, `Skin` = %d, `Time` = %d, `Color` = %d",
                PlayerInfo[playerid][IP], PlayerInfo[playerid][ClientId], PlayerInfo[playerid][Admin], PlayerInfo[playerid][VIP], PlayerInfo[playerid][Money], PlayerInfo[playerid][Deaths],
                PlayerInfo[playerid][Kills], PlayerInfo[playerid][Skin], PlayerInfo[playerid][Time], PlayerInfo[playerid][Color]);
            mysql_query(Database, query);
        #endif

    #endif
	return true;
}

static stock GetLastBanId()
{
    new rows;
    #if USE_SAVING_SYSTEM == 1

        #if USE_SQLITE == 1
            new DBResult:Cache;
            Cache = db_query(Database, "SELECT * FROM `BanList`");
            rows = db_num_rows(Cache);
            db_free_result(Cache);
        #elseif USE_MYSQL == 1
            new Cache:Cache;
            Cache = mysql_query(Database, "SELECT * FROM `BanList`");
            cache_get_row_count(rows);
            cache_delete(Cache);
        #endif

    #endif
    return rows;
}

static stock GetLastUserId()
{
    new rows;
    #if USE_SAVING_SYSTEM == 1

        #if USE_SQLITE == 1
            new DBResult:Cache;
            Cache = db_query(Database, "SELECT * FROM `Accounts`");
            rows = db_num_rows(Cache);
            db_free_result(Cache);
        #elseif USE_MYSQL == 1
            new Cache:Cache;
            Cache = mysql_query(Database, "SELECT * FROM `Accounts`");
            cache_get_row_count(rows);
            cache_delete(Cache);
        #endif

    #endif
    return rows;
}

static stock GetVehicleName(vehicleid)
{
    format(String,sizeof(String),"%s",VehicleNames[GetVehicleModel(vehicleid) - 400]);
    return String;
}

static stock GetVehicleModelIDFromName(vname[]) 
{ 
    for(new i = 0; i < 211; i++) 
    { 
        if(strfind(VehicleNames[i], vname, true) != -1) 
        return i + 400; 
    } 
    return 0; 
}

static stock randomString(strDest[], strLen = 10)
{
	while(strLen--)
		strDest[strLen] = random(2) ? (random(26) + (random(2) ? 'a' : 'A')) : (random(10) + '0');
}

static stock LoadStaticVehiclesFromFile(const filename[])
{
	new File:file_ptr;
	new line[256];
	new var_from_line[64];
	new vehicletype;
	new Float:SpawnX;
	new Float:SpawnY;
	new Float:SpawnZ;
	new Float:SpawnRot;
	new Color1, Color2;
	new index;
	new vehicles_loaded;

	file_ptr = fopen(filename,filemode:io_read);
	if(!file_ptr) return 0;

	vehicles_loaded = 0;

	while(fread(file_ptr,line,256) > 0)
	{
        index = 0;

 		index = token_by_delim(line,var_from_line,',',index);
 		if(index == (-1)) continue;
 		vehicletype = strval(var_from_line);
  		if(vehicletype < 400 || vehicletype > 611) continue;

 		index = token_by_delim(line,var_from_line,',',index+1);
 		if(index == (-1)) continue;
 		SpawnX = floatstr(var_from_line);

 		index = token_by_delim(line,var_from_line,',',index+1);
 		if(index == (-1)) continue;
 		SpawnY = floatstr(var_from_line);

 		index = token_by_delim(line,var_from_line,',',index+1);
 		if(index == (-1)) continue;
 		SpawnZ = floatstr(var_from_line);

 		index = token_by_delim(line,var_from_line,',',index+1);
 		if(index == (-1)) continue;
 		SpawnRot = floatstr(var_from_line);

 		index = token_by_delim(line,var_from_line,',',index+1);
 		if(index == (-1)) continue;
 		Color1 = strval(var_from_line);

 		index = token_by_delim(line,var_from_line,';',index+1);
 		Color2 = strval(var_from_line);

		AddStaticVehicleEx(vehicletype,SpawnX,SpawnY,SpawnZ,SpawnRot,Color1,Color2,-1);

		vehicles_loaded++;
	}

	fclose(file_ptr);
	printf("Loaded %d vehicles from: %s",vehicles_loaded,filename);
	return vehicles_loaded;
}

static stock token_by_delim(const string[], return_str[], delim, start_index)
{
	new x=0;
	while(string[start_index] != EOS && string[start_index] != delim) {
	  return_str[x] = string[start_index];
	  x++;
	  start_index++;
	}
	return_str[x] = EOS;
	if(string[start_index] == EOS) start_index = (-1);
	return start_index;
}

static stock LoadTextDraws()
{
    Connect[0] = TextDrawCreate(644.000000, 1.000000, ".");
    TextDrawBackgroundColor(Connect[0], 255);
    TextDrawFont(Connect[0], 1);
    TextDrawLetterSize(Connect[0], 0.500000, 50.599998);
    TextDrawColor(Connect[0], -1);
    TextDrawSetOutline(Connect[0], 0);
    TextDrawSetProportional(Connect[0], 1);
    TextDrawSetShadow(Connect[0], 1);
    TextDrawUseBox(Connect[0], 1);
    TextDrawBoxColor(Connect[0], 120);
    TextDrawTextSize(Connect[0], -30.000000, 58.000000);
    TextDrawSetSelectable(Connect[0], 0);

    Connect[1] = TextDrawCreate(210.000000, 93.000000, "~r~Stunt ~g~Freeroam ~b~Server");
    TextDrawBackgroundColor(Connect[1], 255);
    TextDrawFont(Connect[1], 1);
    TextDrawLetterSize(Connect[1], 0.600000, 4.000000);
    TextDrawColor(Connect[1], -1);
    TextDrawSetOutline(Connect[1], 0);
    TextDrawSetProportional(Connect[1], 1);
    TextDrawSetShadow(Connect[1], 1);
    TextDrawSetSelectable(Connect[1], 0);

    Connect[2] = TextDrawCreate(394.000000, 125.000000, "~y~v1.0");
    TextDrawBackgroundColor(Connect[2], 255);
    TextDrawFont(Connect[2], 1);
    TextDrawLetterSize(Connect[2], 0.500000, 1.000000);
    TextDrawColor(Connect[2], -1);
    TextDrawSetOutline(Connect[2], 0);
    TextDrawSetProportional(Connect[2], 1);
    TextDrawSetShadow(Connect[2], 1);
    TextDrawSetSelectable(Connect[2], 0);

    Connect[3] = TextDrawCreate(240.000000, 42.000000, "Welcome!");
    TextDrawBackgroundColor(Connect[3], 255);
    TextDrawFont(Connect[3], 1);
    TextDrawLetterSize(Connect[3], 0.760000, 2.800000);
    TextDrawColor(Connect[3], -1);
    TextDrawSetOutline(Connect[3], 0);
    TextDrawSetProportional(Connect[3], 1);
    TextDrawSetShadow(Connect[3], 1);
    TextDrawSetSelectable(Connect[3], 0);

    Connect[4] = TextDrawCreate(183.000000, 140.000000, "~r~Stunt ~w~/ ~b~Freeroam ~w~/ ~y~Parkours ~w~/ ~p~Deathmatches ~w~/ ~h~Minigames");
    TextDrawBackgroundColor(Connect[4], 255);
    TextDrawFont(Connect[4], 1);
    TextDrawLetterSize(Connect[4], 0.300000, 2.000000);
    TextDrawColor(Connect[4], -1);
    TextDrawSetOutline(Connect[4], 0);
    TextDrawSetProportional(Connect[4], 1);
    TextDrawSetShadow(Connect[4], 1);
    TextDrawSetSelectable(Connect[4], 0);

    Connect[5] = TextDrawCreate(150.000000, 333.000000, "News:");
    TextDrawAlignment(Connect[5], 2);
    TextDrawBackgroundColor(Connect[5], 255);
    TextDrawFont(Connect[5], 1);
    TextDrawLetterSize(Connect[5], 0.500000, 2.000000);
    TextDrawColor(Connect[5], -1);
    TextDrawSetOutline(Connect[5], 1);
    TextDrawSetProportional(Connect[5], 1);
    TextDrawSetSelectable(Connect[5], 0);

    Connect[6] = TextDrawCreate(150.000000, 370.000000, NEWS);
    TextDrawBackgroundColor(Connect[6], 255);
    TextDrawFont(Connect[6], 1);
    TextDrawLetterSize(Connect[6], 0.500000, 2.000000);
    TextDrawColor(Connect[6], -1);
    TextDrawSetOutline(Connect[6], 0);
    TextDrawSetProportional(Connect[6], 1);
    TextDrawSetShadow(Connect[6], 1);
    TextDrawSetSelectable(Connect[6], 0);

    RequestClass[0] = TextDrawCreate(499.000000, 10.000000, "~g~Stunt ~r~Freeroam ~b~Server");
    TextDrawBackgroundColor(RequestClass[0], 255);
    TextDrawFont(RequestClass[0], 1);
    TextDrawLetterSize(RequestClass[0], 0.310000, 1.300000);
    TextDrawColor(RequestClass[0], -1);
    TextDrawSetOutline(RequestClass[0], 0);
    TextDrawSetProportional(RequestClass[0], 1);
    TextDrawSetShadow(RequestClass[0], 1);
    TextDrawSetSelectable(RequestClass[0], 0);

    RequestClass[1] = TextDrawCreate(545.000000, 27.000000, "~p~www.sfs.ml");
    TextDrawBackgroundColor(RequestClass[1], 255);
    TextDrawFont(RequestClass[1], 1);
    TextDrawLetterSize(RequestClass[1], 0.349999, 1.100000);
    TextDrawColor(RequestClass[1], -1);
    TextDrawSetOutline(RequestClass[1], 0);
    TextDrawSetProportional(RequestClass[1], 1);
    TextDrawSetShadow(RequestClass[1], 1);
    TextDrawSetSelectable(RequestClass[1], 0);

    Death[0] = TextDrawCreate(650.000000, 0.000000, ".");
	TextDrawBackgroundColor(Death[0], 255);
	TextDrawFont(Death[0], 1);
	TextDrawLetterSize(Death[0], 0.500000, 51.000000);
	TextDrawColor(Death[0], -1);
	TextDrawSetOutline(Death[0], 0);
	TextDrawSetProportional(Death[0], 1);
	TextDrawSetShadow(Death[0], 1);
	TextDrawUseBox(Death[0], 1);
	TextDrawBoxColor(Death[0], 5111928);
	TextDrawTextSize(Death[0], -3.000000, -23.000000);
	TextDrawSetSelectable(Death[0], 0);

	Death[1] = TextDrawCreate(641.000000, 160.000000, ".");
	TextDrawBackgroundColor(Death[1], 255);
	TextDrawFont(Death[1], 1);
	TextDrawLetterSize(Death[1], 0.500000, 8.100000);
	TextDrawColor(Death[1], -1);
	TextDrawSetOutline(Death[1], 0);
	TextDrawSetProportional(Death[1], 1);
	TextDrawSetShadow(Death[1], 1);
	TextDrawUseBox(Death[1], 1);
	TextDrawBoxColor(Death[1], 100);
	TextDrawTextSize(Death[1], -20.000000, 3.000000);
	TextDrawSetSelectable(Death[1], 0);

	Death[2] = TextDrawCreate(317.000000, 172.000000, "WASTED");
	TextDrawAlignment(Death[2], 2);
	TextDrawBackgroundColor(Death[2], 131272);
	TextDrawFont(Death[2], 3);
	TextDrawLetterSize(Death[2], 1.410000, 4.099999);
	TextDrawColor(Death[2], -16776961);
	TextDrawSetOutline(Death[2], 0);
	TextDrawSetProportional(Death[2], 1);
	TextDrawSetShadow(Death[2], 0);
	TextDrawSetSelectable(Death[2], 0);
    return 1;
}

static stock LoadPlayerTextDraw(playerid)
{
    StatusBar = CreatePlayerTextDraw(playerid,6.000000, 427.000000, "Welcome to ~g~Stunt ~r~Freeroam ~b~Stunt ~w~. FPS: ~r~fpshere ~w~Ping: ~r~pinghere ~w~PL: ~r~pinghere ~w~MoneyBag: ~r~moneybag");
    PlayerTextDrawBackgroundColor(playerid,StatusBar, 255);
    PlayerTextDrawFont(playerid,StatusBar, 0);
    PlayerTextDrawLetterSize(playerid,StatusBar, 0.519999, 1.500000);
    PlayerTextDrawColor(playerid,StatusBar, -1);
    PlayerTextDrawSetOutline(playerid,StatusBar, 0);
    PlayerTextDrawSetProportional(playerid,StatusBar, 1);
    PlayerTextDrawSetShadow(playerid,StatusBar, 1);
    PlayerTextDrawSetSelectable(playerid,StatusBar, 0);
    return 1;
}


static stock SetPlayerPosition(playerid, Float:X, Float:Y, Float:Z, Float:A)
{
	SetPlayerPos(playerid, X, Y, Z);
	SetPlayerFacingAngle(playerid, A);
    return 1;
}

static stock createdm(playerid,Float:X,Float:Y,Float:Z,Float:A,interior,virtualworld,zone,weapon1,weapon2,health,text[])
{

	PlayerInfo[playerid][InDM] = true;
	PlayerInfo[playerid][DmZone] = zone;

	if (IsPlayerInAnyVehicle(playerid))
	{
		RemovePlayerFromVehicle(playerid);
	}
	SetPlayerPosition(playerid, X,Y,Z,A);
	SetPlayerInterior(playerid, interior);
	ResetPlayerWeapons(playerid);
	GameTextForPlayer(playerid, text, 2000, 3);
	SetPlayerFacingAngle(playerid, A);
	SetPlayerHealth(playerid, health);
	GivePlayerWeapon(playerid, weapon1, 100000);
	GivePlayerWeapon(playerid, weapon2, 100000);
	SetPlayerVirtualWorld(playerid, virtualworld);

	return 1;
}

static stock GetPlayerSpeed(playerid, bool:kmh)
{
    new Float:Vx, Float:Vy, Float:Vz, Float:rtn;
    if(IsPlayerInAnyVehicle(playerid)) GetVehicleVelocity(GetPlayerVehicleID(playerid), Vx, Vy, Vz); else GetPlayerVelocity(playerid, Vx, Vy, Vz);
    rtn = floatsqroot(floatabs(floatpower(Vx + Vy + Vz,2)));
    return kmh?floatround(rtn * 100 * 1.61):floatround(rtn * 100);
}

static stock IsTrain(vehicleid)
{
    switch(GetVehicleModel(vehicleid))
    {
        case 449,537,538,569,570,590: return 1;
    }
    return 0;
}

static stock IsPlane(vehicleid)
{
    switch(GetVehicleModel(vehicleid))
    {
        case 460,464,476,511,512,513,519,520,553,577,592,593: return 1;
    }
    return 0;
}

static stock GetPlayerId(playername[])
{
    for(new i = 0; i <= MAX_PLAYERS; i++)
    {
        if(IsPlayerConnected(i))
        {
            if(strcmp(PlayerInfo[i][Name], playername, true, strlen(playername)) == 0)
            {
                return i;
            }
        }
    }
    return INVALID_PLAYER_ID;
}

static stock respawnindm(playerid)
{
	switch (PlayerInfo[playerid][DmZone])
	{
		case 1:
		{
			new xRandom = random(sizeof(RandomSpawnsDE));
			createdm(playerid,RandomSpawnsDE[xRandom][0], RandomSpawnsDE[xRandom][1], RandomSpawnsDE[xRandom][2], RandomSpawnsDE[xRandom][3],3,1,1,24,25,100,"");
		}

		case 2:
		{
			new xRandom = random(sizeof(RandomSpawnsRW));
			createdm(playerid,RandomSpawnsRW[xRandom][0], RandomSpawnsRW[xRandom][1], RandomSpawnsRW[xRandom][2], RandomSpawnsRW[xRandom][3],1,2,2,26,28,100,"");
			return 1;
		}
		case 3:
		{
			new xRandom = random(sizeof(RandomSpawnsSOS));
			createdm(playerid,RandomSpawnsSOS[xRandom][0], RandomSpawnsSOS[xRandom][1], RandomSpawnsSOS[xRandom][2], RandomSpawnsSOS[xRandom][3],10,3,3,26,32,100,"");
		}
		case 4:
		{
			new xRandom = random(sizeof(RandomSpawnsSNIPE));
			createdm(playerid,RandomSpawnsSNIPE[xRandom][0], RandomSpawnsSNIPE[xRandom][1], RandomSpawnsSNIPE[xRandom][2], RandomSpawnsSNIPE[xRandom][3],3,4,4,25,34,100,"");
		}
		case 5:
		{
			new xRandom = random(sizeof(RandomSpawnsSOS2));
			createdm(playerid,RandomSpawnsSOS2[xRandom][0], RandomSpawnsSOS2[xRandom][1], RandomSpawnsSOS2[xRandom][2], RandomSpawnsSOS2[xRandom][3],0,5,5,31,16,100,"");
		}
		case 6:
		{
			new xRandom = random(sizeof(RandomSpawnsSHOT));
			createdm(playerid,RandomSpawnsSHOT[xRandom][0], RandomSpawnsSHOT[xRandom][1], RandomSpawnsSHOT[xRandom][2], RandomSpawnsSHOT[xRandom][3],1,6,6,27,0,100, "");
		}
		case 7:
		{
			new xRandom = random(sizeof(RandomSpawnsSNIPE2));
			createdm(playerid,RandomSpawnsSNIPE2[xRandom][0], RandomSpawnsSNIPE2[xRandom][1], RandomSpawnsSNIPE2[xRandom][2], RandomSpawnsSNIPE2[xRandom][3],0,7,7,34,0,100,"");
		}
		case 8:
		{
			new xRandom = random(sizeof(RandomSpawnsMINI));
			createdm(playerid,RandomSpawnsMINI[xRandom][0], RandomSpawnsMINI[xRandom][1], RandomSpawnsMINI[xRandom][2], RandomSpawnsMINI[xRandom][3],0,8,8,38,0,100,"");
		}
		case 9:
		{
			new xRandom = random(sizeof(RandomSpawnsWZ));
			createdm(playerid,RandomSpawnsWZ[xRandom][0], RandomSpawnsWZ[xRandom][1], RandomSpawnsWZ[xRandom][2], RandomSpawnsWZ[xRandom][3],0,9,9,31,16,100,"");
		}
		case 10:
		{
			new xRandom = random(sizeof(RandomSpawnsSHIP));
			createdm(playerid,RandomSpawnsSHIP[xRandom][0], RandomSpawnsSHIP[xRandom][1], RandomSpawnsSHIP[xRandom][2], RandomSpawnsSHIP[xRandom][3],0,10,10,23,29,100,"");
		}
	}
	return 1;
}