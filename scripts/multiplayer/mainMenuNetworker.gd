extends Node

# --|| VARIABLES ||--

@export_group("Scenes","scene_")
## The scene we load into when we connect.
@export var scene_mainGame : PackedScene

# --|| MAIN FUNCTIONS ||--

func _ready() -> void:
	NetworkManager.createdClient.connect(onCreatedClient)
	NetworkManager.createdHost.connect(onCreatedHost)
	NetworkManager.closedPeer.connect(onClosedPeer)

# --|| LOGIC FUNCTIONS ||--

func onClosedPeer() -> void:
	ErrorManager.onFailedToJoinLobby("Error:\nDisconnected peer while still in lobby.")

func onCreatedClient() -> void:
	SceneManager.goToScene(scene_mainGame)

func onCreatedHost() -> void:
	SceneManager.goToScene(scene_mainGame)
