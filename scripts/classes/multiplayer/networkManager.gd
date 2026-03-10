## This will handle the lifecycle of the multiplayer peer.
extends Node

# --|| SIGNALS ||--

## Signal fired when a host is created.
signal createdHost
## Signal fired when a client is created.
signal createdClient
## Signal fired when the current peer is closed.
signal closedPeer

# --|| CONSTANTS ||--

## If true, we will use an Enet peer as opposed to a Steam peer.
## This is purely for debugging, everything hosted through ENet is local.
const USE_ENET : bool = true

# --|| VARIABLES ||--

## Our current steam peer.
var steamPeer : SteamMultiplayerPeer
## Our current Enet peer.
var enetPeer : ENetMultiplayerPeer

# --|| MAIN FUNCTIONS ||--
func _ready() -> void:
	LobbyManager.createdLobby.connect(onCreatedLobby)
	LobbyManager.joinedLobby.connect(onJoinedLobby)
	LobbyManager.leftLobby.connect(onLeftLobby)

# --|| LOBBY FUNCTIONS ||--
func onCreatedLobby(_thisLobbyId : int) -> void:
	createHost()

func onJoinedLobby(thisLobbyId : int) -> void:
	createClient(thisLobbyId)

func onLeftLobby() -> void:
	closePeer()

# --|| PEER FUNCTIONS ||--

## Closes the current peer.
func closePeer() -> void:
	match USE_ENET:
		true: closeEnetPeer()
		false: closeSteamPeer()
	closedPeer.emit()

## Closes the current Enet peer.
func closeEnetPeer() -> void:
	if not enetPeer: return
	enetPeer.close()

## Closes the current Steam peer.
func closeSteamPeer() -> void:
	if not steamPeer: return
	steamPeer.close()

# --|| HOST FUNCTIONS ||--

## Creates a host peer.
func createHost() -> void:
	match USE_ENET:
		true: createEnetHost()
		false: createSteamHost()
	createdHost.emit()

## Create a local Enet host.
func createEnetHost() -> void:
	enetPeer = ENetMultiplayerPeer.new()
	enetPeer.create_server(9999)
	multiplayer.multiplayer_peer = enetPeer

## Create a server Steam host.
func createSteamHost() -> void:
	steamPeer = SteamMultiplayerPeer.new()
	steamPeer.create_host()
	multiplayer.multiplayer_peer = steamPeer

# --|| CLIENT FUNCTIONS ||--

## Create a client peer.
func createClient(steamLobbyId : int) -> void:
	match USE_ENET:
		true: createEnetClient()
		false: createSteamClient(steamLobbyId)
	createdClient.emit()

## Create a  local Enet client.
func createEnetClient() -> void:
	enetPeer = ENetMultiplayerPeer.new()
	enetPeer.create_client("localhost",9999)
	multiplayer.multiplayer_peer = enetPeer

## Create a Steam client.
func createSteamClient(lobbyId : int) -> void:
	var ownerId : int = Steam.getLobbyOwner(lobbyId)
	
	steamPeer = SteamMultiplayerPeer.new()
	steamPeer.create_client(ownerId)
	multiplayer.multiplayer_peer = steamPeer
