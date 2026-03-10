extends Node

# This will handle the lifecycle of a lobby.

# --|| SIGNALS ||--

## Signal fired when a lobby is successfully created.
signal createdLobby (lobbyId : int)
## Signal fired when a lobby is successfully joined.
signal joinedLobby (lobbyId : int)
## Signal fired when a lobby is successfully left.
signal leftLobby ()
## Signal fired when we fail to join a lobby.
signal failedToJoinLobby (errorString : String)
## Signal fired when a list of lobbies is returned.
signal lobbyListReturned (lobbies : Array)
## Signal fired when a list of lobby members is returned.
signal lobbyMembersReturned (members : Array)
## Signal fired when a change happens to the lobby due to a member.
signal lobbyChatChanged (message : String)
## Signal fired when a chat message is received.
signal chatMessageReceived (senderId : int, senderName : String, message : String)

# --|| CONSTANTS ||--

## The command line argument for connecting to a lobby.
const CONNECT_COMMAND : String = "+connect_lobby"
## The maximum number of players a lobby can support.
const MAX_MEMBERS : int = 4
## The string that translates to a lobby members id.
const MEMBER_ID_STR : String = "id"
## The string that translates to a lobby members name.
const MEMBER_NAME_STR : String = "name"

# --|| VARIABLES ||--

## Our current lobby id. '-1' or '0' means we aren't in a lobby.
var lobbyId : int = -1
## Our current lobby's host id.
var hostId : int = -1
## An array containing our current lobby's members.
var lobbyMembers : Array = []

## A bool to make sure we don't attempt to join or create a lobby
## while we are either creating or joining already.
var actionInProgress : bool = false

# --|| MAIN FUNCTIONS ||--

func _ready() -> void:
	Steam.join_requested.connect(joinRequested)
	Steam.lobby_chat_update.connect(lobbyChatUpdate)
	Steam.lobby_created.connect(lobbyCreated)
	Steam.lobby_data_update.connect(lobbyDataUpdate)
	Steam.lobby_invite.connect(lobbyInvite)
	Steam.lobby_joined.connect(lobbyJoined)
	Steam.lobby_match_list.connect(lobbyMatchList)
	Steam.lobby_message.connect(lobbyMessage)
	Steam.persona_state_change.connect(personaStateChange)

# --|| INVITE FUNCTIONS ||--

func lobbyInvite(_inviter : Variant, _lobby : Variant, _game : Variant) -> void:
	pass

# --|| LEAVE FUNCTIONS ||--
func leaveLobby() -> void:
	if lobbyId <= 0: return
	
	Steam.leaveLobby(lobbyId)
	lobbyId = -1
	
	lobbyMembers.clear()
	leftLobby.emit()

# --|| JOIN FUNCTIONS ||--

func joinLobby(thisLobbyId : int) -> void:
	if lobbyId > 0 or actionInProgress: return
	actionInProgress = true
	Steam.joinLobby(thisLobbyId)

func lobbyJoined(thisLobbyId: int, _permissions: int, _locked: bool, response: int) -> void:
	print(response)
	actionInProgress = false
	if response != Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		var errorString : String = "Error:\n " + getJoinFailReason(response)
		failedToJoinLobby.emit(errorString)
		return
	
	lobbyId = thisLobbyId
	hostId = Steam.getLobbyOwner(thisLobbyId)
	getLobbyMembers()
	
	if SteamProfile.id != hostId: joinedLobby.emit(thisLobbyId)

func joinRequested(thisLobbyId : int, _memberId : int) -> void:
	joinLobby(thisLobbyId)

func getJoinFailReason(id : int) -> String:
	match id:
		Steam.CHAT_ROOM_ENTER_RESPONSE_DOESNT_EXIST: return "This lobby no longer exists."
		Steam.CHAT_ROOM_ENTER_RESPONSE_NOT_ALLOWED: return "You don't have permission to join this lobby."
		Steam.CHAT_ROOM_ENTER_RESPONSE_FULL: return "The lobby is now full."
		Steam.CHAT_ROOM_ENTER_RESPONSE_ERROR: return "Uh... something unexpected happened!"
		Steam.CHAT_ROOM_ENTER_RESPONSE_BANNED: return "You are banned from this lobby."
		Steam.CHAT_ROOM_ENTER_RESPONSE_LIMITED: return "You cannot join due to having a limited account."
		Steam.CHAT_ROOM_ENTER_RESPONSE_CLAN_DISABLED: return "This lobby is locked or disabled."
		Steam.CHAT_ROOM_ENTER_RESPONSE_COMMUNITY_BAN: return "This lobby is community locked."
		Steam.CHAT_ROOM_ENTER_RESPONSE_MEMBER_BLOCKED_YOU: return "A user in the lobby has blocked you from joining."
		Steam.CHAT_ROOM_ENTER_RESPONSE_YOU_BLOCKED_MEMBER: return "A user you have blocked is in the lobby."
	return "Failed to join..?"

# --|| CREATE FUNCTIONS ||--

func createLobby(type : int) -> void:
	if lobbyId > 0 or actionInProgress: return
	
	actionInProgress = true
	Steam.createLobby(type,MAX_MEMBERS)

func lobbyCreated(connectNum : int, thisLobbyId : int) -> void:
	actionInProgress = false
	if connectNum != 1: return
	
	print("lobby created: %s" % thisLobbyId)
	
	setLobbyDefaults(thisLobbyId)
	createdLobby.emit(thisLobbyId)

func setLobbyDefaults(thisLobbyId : int) -> void:
	Steam.setLobbyJoinable(thisLobbyId,true)
	Steam.setLobbyData(thisLobbyId, "e523255225", "e523255225")

# --|| LIST FUNCTIONS ||--

func getLobbyList(nameSearch : String) -> void:
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	if nameSearch != "": Steam.addRequestLobbyListStringFilter("name",nameSearch,Steam.LOBBY_COMPARISON_EQUAL)
	Steam.addRequestLobbyListStringFilter("e523255225","e523255225",Steam.LOBBY_COMPARISON_EQUAL)
	Steam.requestLobbyList()

func lobbyMatchList(theseLobbies : Array) -> void:
	lobbyListReturned.emit(theseLobbies)

# --|| CHAT FUNCTIONS ||--

func sendLobbyMessage(message : String) -> void:
	if lobbyId <= 0: return
	Steam.sendLobbyChatMsg(lobbyId,message)

func lobbyMessage(result : int, thisSenderId : int, message : String, chatType : int):
	if result == 0:
		push_error("Received lobby message, but 0 bytes were retrieved!")
	match chatType:
		Steam.CHAT_ENTRY_TYPE_CHAT_MSG:
			var senderInfo : Dictionary = getMember(thisSenderId)
			if senderInfo.is_empty():
				push_error("Received a message from a user we dont have locally!")
			var senderName : String = senderInfo.get(MEMBER_NAME_STR,"")
			chatMessageReceived.emit(thisSenderId,senderName,message)
		_:
			push_warning("Unhandled chat message type received: %s" % chatType)

# --|| MISC FUNCTIONS ||--

func checkCommandLine() -> void:
	var cmdArguments: Array = OS.get_cmdline_args()
	
	if cmdArguments.is_empty(): return
	if cmdArguments[0] != CONNECT_COMMAND: return
	if int(cmdArguments[1]) == 0: return
	
	print("Command line lobby ID: %s" % cmdArguments[1])
	joinLobby(int(cmdArguments[1]))

func getLobbyMembers() -> void:
	lobbyMembers.clear()

	var memberCount: int = Steam.getNumLobbyMembers(lobbyId)

	for memberIndex : int in range(memberCount):
		var memberId: int = Steam.getLobbyMemberByIndex(lobbyId, memberIndex)
		var memberName: String = Steam.getFriendPersonaName(memberId)
		
		lobbyMembers.append({"id":memberId, "name":memberName})
	
	lobbyMembersReturned.emit(lobbyMembers)

# --|| CHANGE FUNCTIONS ||--

func lobbyChatUpdate(_thisLobbyId: int, changeId: int, _makingChangeId: int, chatState: int) -> void:
	var changerName: String = Steam.getFriendPersonaName(changeId)
	
	var changeMessage : String = "%s did something..."
	
	match chatState:
		Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED: changeMessage = ("%s has joined the lobby.")
		Steam.CHAT_MEMBER_STATE_CHANGE_LEFT: changeMessage = ("%s has left the lobby.")
		Steam.CHAT_MEMBER_STATE_CHANGE_KICKED: changeMessage = ("%s has been kicked from the lobby.")
		Steam.CHAT_MEMBER_STATE_CHANGE_BANNED: changeMessage = ("%s has been banned from the lobby.")
	
	lobbyChatChanged.emit(changeMessage % changerName)
	
	getLobbyMembers()

func lobbyDataUpdate(success : Variant, thisLobbyId : int, _thisMemberId : int):
	if not success: return
	# check for host change
	var thisHost : int = Steam.getLobbyOwner(thisLobbyId)
	if thisHost != hostId and thisHost > 0:
		pass
		#_owner_changed(_steam_lobby_host, host)
		#_steam_lobby_host = host
	#emit_signal("lobby_data_updated", thisMemberId)

func personaStateChange(_thisSteamId: int, _flag: int) -> void:
	if lobbyId <= 0: return
	getLobbyMembers()

# --|| HELPER FUNCTIONS ||--

func getMember(thisMemberId : int) -> Dictionary:
	var thisMemberInfo : Dictionary = {}
	for memberInfo : Dictionary in lobbyMembers:
		var memberId : int = memberInfo.get(MEMBER_ID_STR,-1)
		if memberId != thisMemberId: continue
		thisMemberInfo = memberInfo
	return thisMemberInfo
