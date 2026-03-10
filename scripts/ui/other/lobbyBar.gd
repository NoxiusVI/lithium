extends Control

# --|| VARIABLES ||--

@export_group("Nodes","node_")
## The node that will be responsible for displaying lobby name.
@export var node_lobbyName : Label
## The node that will be responsible for displaying lobby member counts.
@export var node_memberCount : Label

# The lobby id assigned to this specific bar.
var lobbyId : int = -1

# --|| LOGIC FUNCTIONS ||--

func initLobbyBar(thisLobbyId : int) -> void:
	lobbyId = thisLobbyId
	
	var lobbyName : String = Steam.getLobbyData(thisLobbyId,"name")
	var playerCount : int = Steam.getNumLobbyMembers(thisLobbyId)
	var playerCap : int = Steam.getLobbyMemberLimit(thisLobbyId)
	
	node_lobbyName.text =  lobbyName
	node_memberCount.text = str(playerCount) + "/" + str(playerCap)

func onJoinClicked() -> void:
	if lobbyId <= 0: return
	
	LobbyManager.joinLobby(lobbyId)
