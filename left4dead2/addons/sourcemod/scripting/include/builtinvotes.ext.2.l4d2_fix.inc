new bool:VoteHandler_All,
	bool:VoteHandler_2,
	bool:VoteHandler_3;

BuiltinVotes_OnPluginStart()
{
	HookUserMessage(GetUserMessageId("VoteStart"),OnVoteStart);
	HookUserMessage(GetUserMessageId("VotePass"),OnVotePass);
	HookUserMessage(GetUserMessageId("VoteFail"),OnVoteFail);
}

public Action:OnVoteStart(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	new team = BfReadByte(bf);
	switch(team)
	{
		case 255: VoteHandler_All = true;
		case   2: VoteHandler_2 = true;
		case   3: VoteHandler_3 = true;
	}
}

public Action:OnVotePass(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	new team = BfReadByte(bf);
	switch(team)
	{
		case 255: VoteHandler_All = false;
		case   2: VoteHandler_2 = false;
		case   3: VoteHandler_3 = false;
	}
}

public Action:OnVoteFail(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	new team = BfReadByte(bf);
	switch(team)
	{
		case 255: VoteHandler_All = false;
		case   2: VoteHandler_2 = false;
		case   3: VoteHandler_3 = false;
	}
}

stock bool:IsVoting_ALL()
{
	if(VoteHandler_All)
	{
		return true;
	}
	return false;
}

stock bool:IsVoting_SURVIVORS()
{
	if(VoteHandler_2)
	{
		return true;
	}
	return false;
}

stock bool:IsVoting_INFECTED()
{
	if(VoteHandler_3)
	{
		return true;
	}
	return false;
}