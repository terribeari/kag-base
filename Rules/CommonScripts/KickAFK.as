// kicks players that dont play for a given time
// by norill

#define CLIENT_ONLY

bool warned = false;
int warnTime = 0;
int lastMoveTime = 0;

const uint checkInterval = 90;
const uint totalToKickSeconds = 60 * 2 + 30;
const uint warnToKickSeconds = 60;
const uint idleToWarnSeconds = totalToKickSeconds - warnToKickSeconds;

void onTick(CRules@ this)
{
	if (getGameTime() % checkInterval != 0)
		return;

	CPlayer@ p = getLocalPlayer();
	CControls@ controls = getControls();
	if (p is null ||											//no player
		controls is null ||										//no controls
		p.getTeamNum() == getRules().getSpectatorTeamNum() ||	//or spectator
		getNet().isServer() ||									//or we're running the server
		getSecurity().checkAccess_Feature(p, "kick_immunity"))	//or we're not kickable
	{
		return;
	}

	//not updated yet or numbers from last game?
	if(controls.lastKeyPressTime == 0 || controls.lastKeyPressTime > getGameTime())
	{
		controls.lastKeyPressTime = getGameTime();
	}

	if(getGameTime() - controls.lastKeyPressTime < checkInterval + 1 &&		//pressed recently?
		controls.lastKeyPressTime > (checkInterval * 2))					//pressed at least after the first little while
	{
		DidInput();
	}

	int time = Time_Local();
	int diff = time - lastMoveTime - idleToWarnSeconds;
	if (!warned)
	{
		if (diff > 0)
		{
			if(diff > totalToKickSeconds) {
				//something has "gone wrong"; (probably just lastMoveTime = 0)
				//pretend an input happened and move on
				lastMoveTime = time;
			}
			else
			{
				//you have been warned
				client_AddToChat("Seems like you are currently away from your keyboard.", SColor(255, 255, 100, 32));
				client_AddToChat("Move around or you will be kicked in "+warnToKickSeconds+" seconds!", SColor(255, 255, 100, 32));
				warned = true;
				warnTime = time;
			}
		}
	}

	if (warned && time - warnTime > warnToKickSeconds)
	{
		//so long, sucker
		client_AddToChat("You were kicked for being AFK too long.", SColor(255, 240, 50, 0));
		warned = false;
		getNet().DisconnectClient();
	}
}

void DidInput()
{
	lastMoveTime = Time_Local();
	RemoveWarning();
}

void RemoveWarning()
{
	if(warned)
	{
		client_AddToChat("AFK Kick avoided.", SColor(255, 20, 120, 0));
		warned = false;
	}
}

bool onClientProcessChat(CRules@ this, const string &in textIn, string &out textOut, CPlayer@ player)
{
	//no processing
	textOut = textIn;
	//but register a movement
	DidInput();
	return true;
}

void onRestart(CRules@ this)
{
	//(nothing - if they were afk last round we still want to boot em )
}

void onInit(CRules@ this)
{
	warned = false;
	warnTime = Time_Local();
	lastMoveTime = Time_Local();
}
