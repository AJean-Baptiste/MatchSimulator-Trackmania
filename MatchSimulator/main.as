[Setting category="Display Settings" name="Hide on hidden interface"]
bool hideWithIFace = false;

[Setting category="Display Settings" name="Hide the window"];
bool hideWindow = false;

[Setting category="Display Settings" name="Show only with OpenPlanet menu" description="To hide the window anytime except when you open the OpenPlanet overlay with F3"]
bool showOnF3 = false;

[Setting category="Display Settings" name="Hide on run" description="Hide when you're driving (more than 10kph)"]
bool hideOnDrive = false;

[Setting category="Display Settings" name="Window position"]
vec2 anchor = vec2(0, 780);

[Setting category="Display Settings" name="Lock window position"]
bool lockPosition = false;

[Setting category="Settings" name="Count DNF"]
bool doDNF = true;

[Setting category="Settings" name="Do first round warmup" description="Will ask you to complete a run to the finish before starting"]
bool doWarmup = true;

float ecart = 2.3;
int round = 10;

PlayerState::sTMData@ TMData;

bool beginRun = false;
bool reset = false;

int respawnCount = 0;
int runNumber = 0;

Record@ pbest = Record();
Record@ one = Record();
Record@ two = Record();
Record@ three = Record();
Record@ four = Record();
Record@ five = Record();
Record@ six = Record();
Record@ seven = Record();
Record@ eigh = Record();
Record@ nine = Record();
Record@ ten = Record();
Record@ eleven = Record();
Record@ twelve = Record();
Record@ thirteen = Record();
Record@ fourteen = Record();
Record@ fifteen = Record();
Record@ sixteen = Record();
Record@ seventeen = Record();
Record@ eighteen = Record();
Record@ ninteen = Record();
Record@ twenty = Record();

array<Record@> run = {one, two, three, four, five, six, seven, eigh, nine, ten, eleven, twelve, thirteen, fourteen, fifteen, sixteen, seventeen, eighteen, ninteen, twenty};

class Record
{
	bool dnf;
	int time;
	string style;
	int respawn;
	
	Record(bool dnf = false, int time = -1,  int respawn = 0, string &in style = "\\$fff")
	{
		this.dnf = dnf;
		this.time = time;
		this.style = style;
		this.respawn = respawn;
	}
}

void Main()
{
	for (int i = 0; i < round; i++)
	{
		run[i].time = 0;
		run[i].dnf = false;
		run[i].respawn = 0;
	}
	auto app = cast<CTrackMania>(GetApp());
	auto network = cast<CTrackManiaNetwork>(app.Network);
	@TMData = PlayerState::sTMData();
	TMData.Update(null);
	
	string currentMapUid = "";
	
	while(true) {
		auto map = app.RootMap;
		
		if(map !is null && map.MapInfo.MapUid != "" && app.Editor is null) {
			if(network.ClientManiaAppPlayground !is null) {
				auto userMgr = network.ClientManiaAppPlayground.UserMgr;
				MwId userId;
				if (userMgr.Users.Length > 0) {
					userId = userMgr.Users[0].Id;
				} else {
					userId.Value = uint(-1);
				}
				auto scoreMgr = network.ClientManiaAppPlayground.ScoreMgr;
				pbest.time = scoreMgr.Map_GetRecord_v2(userId, map.MapInfo.MapUid, "PersonalBest", "", "TimeAttack", "");
			}
			else {
				pbest.time = -1;
			}
		}
		else //reset the scoreboard if you're not in game
		{
			for (int i = 0; i < round; i++){
				run[i].time = 0;
				run[i].dnf = false;
				run[i].respawn = 0;
				respawnCount = 0;
				runNumber = 0;
			}
		}
		sleep(500);
	}
}

void Update(float dt)
{
	if (TMData !is null)
	{	
		PlayerState::sTMData@ previous = TMData;
			
		@TMData = PlayerState::sTMData();
		TMData.Update(previous);
		TMData.Compare(previous);
		
		if(beginRun)
		{
			if(TMData.dEventInfo.FinishRun) //is true when you crossed the finish line
			{
					NewRun(TMData.dPlayerInfo.EndTime, respawnCount);
			}
			if(TMData.dEventInfo.bRespawnChange) //is true when you crossed a CP
			{
					if(TMData.dEventInfo.bRespawned)
						respawnCount++;
			}
			if(TMData.dEventInfo.PlayerStateChange)
					if (PlayerState::EPlayerStateToString(TMData.PlayerState) == "EPlayerState_EndRace") //is true when you restart a run
						NewRun(0, respawnCount);
		}
		if (reset){
			beginRun = false;
			reset = false;
			for (int i = 0; i < round; i++){
				run[i].time = 0;
				run[i].dnf = false;
				run[i].respawn = 0;
			}
			respawnCount = 0;
			runNumber = 0;
		}
	}
}

void NewRun(int time, int respawn) //add a new time to the array when called
{
	if (time == 0 && runNumber == 0 && doWarmup)
		return;
	if (time == 0 && !doDNF)
		if (runNumber == 0){
			runNumber++;
			return;
		}else return;
	if (runNumber > 0 && runNumber <= round){
		run[runNumber-1].time = time;
		run[runNumber-1].respawn = respawn;
		run[runNumber-1].dnf = false;
		if (time == 0)
			run[runNumber-1].dnf = true;
		if (runNumber == round)
			beginRun = false;
	}
	if (runNumber > round)
		beginRun = false;
	runNumber++;
	respawnCount = 0;
}

string RenderTime(int t) //return formated time
{
	return (t > 0 ? Time::Format(t) : "-:--.---");
}

string RenderDelta(int t, int pb) //return the formated delta time between two time
{
    if (t-pb >= 0) {
		string prefix = DeltaColor(t , pb);
		return prefix + (Time::Format(t-pb));
    }else
        return "--.---";
}

int AverageRun() //return the average time for each run
{
	int total = 0;
	int totalTime = 0;
	for (int i = 0; i < round; i++){
		if (run[i].time > 0){
			totalTime = totalTime+run[i].time;
			total++;
		}
	}
	if (total > 0)
		return (totalTime/total);
	else
		return 0;
}

string DeltaColor(int t, int pb) //return the colortag to use wheter how far or close you are from pb
{
	float result = 100.0*(t-pb)/pb;
	if (result > 0){
		if (result < ecart/2)// [0 , 0.5]
			return "\\$0F0";
		if (result <= ecart)// [0.5, 1]
			return "\\$aF3";
		if (result < ecart*1.5)// [1, 1.5]
			return "\\$df0";
		if (result < ecart*1.75)// [1.5, 1.75]
			return "\\$ff0";
		if (result < ecart*2)// [1.75, 2]
			return "\\$F80";
		return "\\$f00";
	}
	return "\\$0f0";
}

void Render()
{	
	auto app = GetApp();
	auto map = app.RootMap;
	
	if (hideWindow)
		return;
	
	if (hideOnDrive && TMData.dPlayerInfo.Speed > 10.0)
		return;
	
	if(hideWithIFace && !UI::IsGameUIVisible()) {
		return;
	}
	
	if(!UI::IsOverlayShown() && showOnF3){
		return;
	}
	
	if (map !is null && map.MapInfo.MapUid != "" && app.Editor is null) {
		
		if (lockPosition) {
			UI::SetNextWindowPos(int(anchor.x), int(anchor.y), UI::Cond::Always);
		} else {
			UI::SetNextWindowPos(int(anchor.x), int(anchor.y), UI::Cond::FirstUseEver);
		}
		
		int windowFlags = UI::WindowFlags::NoDocking | UI::WindowFlags::NoNavInputs;
		
		if (UI::Begin("Match Simulator", windowFlags))
		{
		
			if (!lockPosition) {
				anchor = UI::GetWindowPos();
			}
			UI::BeginGroup();
			
			UI::BeginTable("header", 2);
			UI::TableNextRow();
			UI::TableNextColumn();
			UI::Text(StripFormatCodes(map.MapInfo.Name));
			UI::TableNextColumn();
			UI::Text("PB: \\$0ff" + RenderTime(pbest.time));
			UI::TableNextRow();
			UI::TableNextColumn();
			UI::Text(StripFormatCodes(map.MapInfo.AuthorNickName));
			UI::EndTable();
			
			if (runNumber == 0 && beginRun){
				if (doWarmup){
					UI::PushStyleColor(UI::Col::Text, vec4(1,0.56,0,1));
					UI::Text("Warmup ! complete a first run to start");
					UI::PopStyleColor();
				}
			}
			
			UI::BeginTable("timesHeader", 4);
			UI::TableNextRow();
			UI::TableNextColumn();
			UI::Text("Round");
			UI::TableNextColumn();
			UI::Text("Time");
			UI::TableNextColumn();
			UI::Text("Delta PB");
			UI::TableNextColumn();
			UI::Text("Respawns");
			
			for (int i = 0; i < round; i++){
				
				UI::TableNextRow();
				UI::TableNextColumn();
				
				if (runNumber == 0 && beginRun){
					if (doWarmup)
						UI::PushStyleColor(UI::Col::Text, vec4(1,0.56,0,1));
					else
						UI::PushStyleColor(UI::Col::Text, vec4(0.625,0.625,0.625,1));
					UI::Text("N°"+(i+1));
					UI::TableNextColumn();
					UI::Text("-:--.---");
					UI::TableNextColumn();
					UI::Text("--.---");
					UI::TableNextColumn();
					UI::Text("-");
					UI::PopStyleColor();
				}
				else
				{
					if (i+1 == runNumber){
						UI::Text("\\$fff"+"N°"+(i+1));
						UI::TableNextColumn();
						UI::Text("\\$fff" + "-:--.---");
						UI::TableNextColumn();
						UI::Text("\\$fff" + "--.---");
						UI::TableNextColumn();
						UI::Text("\\$fff" + "-");
					}
					else
					{
						UI::Text("\\$aaa"+"N°"+(i+1));
						UI::TableNextColumn();
						
						if (run[i].dnf)
							UI::Text("\\$f00" + "DNF");
						
						else
							UI::Text("\\$aaa" + RenderTime(run[i].time));
						
						UI::TableNextColumn();
						UI::Text("\\$aaa" + RenderDelta(run[i].time, pbest.time));
						UI::TableNextColumn();
						UI::Text("\\$aaa" + run[i].respawn);
					}
				}
			}
			
			int average = AverageRun();
			UI::TableNextRow();
			UI::TableNextColumn();
			UI::Text("Average:");
			UI::TableNextColumn();
			UI::Text("\\$FFF" + RenderTime(average));
			UI::TableNextColumn();
			UI::Text("\\$aaa" + RenderDelta(average, pbest.time));
			UI::EndTable();
			
			if (pbest.time > 0)
				UI::Text("objective:\\$aF3 +" + RenderTime(int((ecart/100)*pbest.time)) + "\\$fff from PB"); //show your delta PB objective that you choosed with the slider
			
			UI::PushStyleColor(UI::Col::Text, vec4(0,0,0,0));
			if (ecart != UI::SliderFloat("objective", ecart, 0, 10))		//slider to chose your delta pb objective
			{
				UI::PushStyleVar(UI::StyleVar::Alpha, 0);
				ecart = (UI::SliderFloat("objective", ecart, 0, 10));
				UI::PopStyleVar();
			}
			UI::PopStyleColor();
				
			if (round != UI::SliderInt("Rounds", round, 1, 20)) //slider to chose how much round you want to do
				round = UI::SliderInt("Rounds", round, 1, 20);
				
			UI::BeginTable("Button", 3);
			UI::TableNextRow();
			UI::TableNextColumn();
			
			if (!beginRun){
				if (UI::Button("Start Run", vec2(75, 20)))
					if (runNumber == 0)
						beginRun = true;
			}
			else
			{
				if (UI::Button("Stop Run", vec2(75, 20)))
					beginRun = false;
			}
			
			UI::TableNextColumn();
			if (UI::Button("Reset", vec2(75, 20)))
				reset = true;
			
			UI::TableNextColumn();
			
			if (UI::Button("Save", vec2(75, 20))) //save your scoreboard into a txt file compatible with any calc like excel
			{
				
				string splitDir = IO::FromUserGameFolder("Splits");
				if (!IO::FolderExists(splitDir))
					IO::CreateFolder(splitDir);
					
				IO::File f(splitDir + "/" + StripFormatCodes(map.MapInfo.Name)+ "_" + average + ".txt");
				f.Open(IO::FileMode::Write);
				f.WriteLine(StripFormatCodes(map.MapInfo.Name));
				if (!doDNF)
					f.WriteLine("!DNF not counted!");
				f.WriteLine("Personnal Best:, " + pbest.time);
				f.WriteLine("Run, Time(ms), Delta (ms), Respawn");
				for (int i = 0; i < round; i++){
					if (!run[i].dnf){
						if (run[i].time > 0){
							f.WriteLine((i+1) + ", " + run[i].time + ", " + (run[i].time-pbest.time) + ", " + run[i].respawn);
						}
					}
					else
						f.WriteLine((i+1) + ", " + "DNF" + ", " + "X" + ", " + run[i].respawn);
				}
				f.WriteLine("Average, " + average + ", " + (average-pbest.time));
				f.Close();
				
			}
			UI::EndTable();
			UI::EndGroup();
		}
		UI::End();		
	}
}