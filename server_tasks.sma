#include <amxmodx>
#include <amxmisc>

// DEFINE 1 TO ENABLE DEBUG (server_print)
//
#define DEBUG 0

new Array:g_pTimes; // = Invalid_Array;
new Array:g_pCommands; // = Invalid_Array;
new Array:g_pDarkHours; // = Invalid_Array;

new g_commandsCount = 0;

// pfnSpawn()
// OnMapStart()
// SERVER LOADS MAP
//
public plugin_precache()
{
	// CREATES ARRAYS
	//
	g_pTimes = ArrayCreate(8);
	g_pCommands = ArrayCreate(512);
	g_pDarkHours = ArrayCreate(8);

	// GETS FILE NAME READY
	//
	new File[256];
	get_configsdir(File, charsmax(File));
	add(File, charsmax(File), "/server_tasks.ini");

	// OPENS FILE
	//
	new pFile = fopen(File, "r");
	if (pFile)
	{
		// LINE DATA
		//
		new Line[512], Key[16], Value[512];

		// READS FILE IF OPENED
		//
		while (!feof(pFile))
		{
			fgets(pFile, Line, charsmax(Line));

			// REMOVES '\r', '\t', ' ' AND OTHER IMPURITIES FROM LINE
			//
			trim(Line);

			// SKIPS BAD LINES
			//
			if (Line[0] != '"')
				continue;

			// PARSES LINE
			//
			if (parse(Line, Key, charsmax(Key), Value, charsmax(Value)) >= 2)
			{
				//
				// APPENDS DATA
				//

				// DARK HOURS
				//
				if (containi(Key, "DARK HOURS") != -1)
				{
					// SPLITS DARK HOURS IN TOKENS
					//
					while (Value[0] != EOS && strtok(Value, Key, charsmax(Key), Value, charsmax(Value), ','))
					{
						// TRIMS DATA BY GETTING RID OF IMPURITIES SUCH ' ', '\t', '\n', ...
						//
						trim(Key);
						trim(Value);

						// APPENDS DARK HOURS
						//
						ArrayPushString(g_pDarkHours, Key);

						// DEBUG
						//
#if defined(DEBUG) && DEBUG == 1
						server_print("PUSHING NIGHT HOUR (%s)", Key);
#endif
					}
				}

				// NORMAL TASK
				//
				else
				{
					// APPENDS TIME AND TASK
					//
					ArrayPushString(g_pTimes, Key);
					ArrayPushString(g_pCommands, Value);

					// DEBUG
					//
#if defined (DEBUG) && DEBUG == 1
					server_print("PUSHING TASK (%s @ %s)", Key, Value);
#endif
				}
			}
		}

		// CLOSES FILE IF OPENED
		//
		fclose(pFile);
	}

	// GETS COMMANDS COUNT
	//
	g_commandsCount = ArraySize(g_pTimes);
}

// pfnServerActivate_Post()
// SERVER ACTIVATES AFTER LOADED MAP AND SPAWNED ENTITIES
//
public plugin_init()
{
	// REGISTERS PLUG-IN
	//
	register_plugin("SERVER TASKS", "2.0", "HATTRICK (HTTRCKCLDHKS)");

	// REGISTERS VERSION CONSOLE VARIABLE
	//
	new pCVar = register_cvar("server_tasks_version", "2.0", FCVAR_SERVER | FCVAR_EXTDLL | FCVAR_UNLOGGED | FCVAR_SPONLY);

	// SETS VERSION
	//
	if (pCVar)
		set_pcvar_string(pCVar, "2.0");

	// GETS TIME H
	//
	new Hour[8];
	get_time("%H", Hour, charsmax(Hour));

	// GETS CONFIGURATION FILES DIRECTORY
	//
	new File[256];
	get_configsdir(File, charsmax(File));

	// DARK
	//
	new DarkHour[8];
	new bool:Dark = false;

	for (new Iterator = 0; Iterator < ArraySize(g_pDarkHours); Iterator++)
	{
		ArrayGetString(g_pDarkHours, Iterator, DarkHour, charsmax(DarkHour));

		if (equal(DarkHour, Hour))
		{
			Dark = true;

			break;
		}
	}

	//
	// EXECUTES THE RIGHT CONFIGURATIONS FILE
	//

	if (Dark)
		server_cmd("exec %s/night_config.cfg", File);

	else
		server_cmd("exec %s/day_config.cfg", File);

	// PREPARES TASK
	//
	if (g_commandsCount)
		set_task(60.0, "ExecuteCommands", .flags = "b");
}

// TASK TO EXECUTE COMMANDS AT THE GIVEN TIME H:M
//
public ExecuteCommands()
{
	// FUNCTION EXECUTED EACH SIXTY SECONDS
	//
	static Iterator, Time[8], NeededTime[8];

	// GETS TIME NOW H:M
	//
	get_time("%H:%M", Time, charsmax(Time));

	// ITERATES BETWEEN TASKS
	//
	for (Iterator = 0; Iterator < g_commandsCount; Iterator++)
	{
		ArrayGetString(g_pTimes, Iterator, NeededTime, charsmax(NeededTime));

		if (equal(Time, NeededTime))
			server_cmd("%a", ArrayGetStringHandle(g_pCommands, Iterator));

		// DEBUG
		//
#if defined(DEBUG) && DEBUG == 1
		server_print("TIME NOW = %s, TIME REQUIRED = %s, TASK = %a, Equal(TimeNow, NeededTime) = %d", \
			Time, NeededTime, ArrayGetStringHandle(g_pCommands, Iterator), equali(Time, NeededTime));
#endif
	}
}

// pfnServerDeactivate_Post()
// SERVER DEACTIVATES AND PLUG-IN UNLOADS
//
public plugin_end()
{
	//
	// DESTROYS ARRAYS
	//

	ArrayDestroy(g_pCommands);
	ArrayDestroy(g_pTimes);
	ArrayDestroy(g_pDarkHours);
}
