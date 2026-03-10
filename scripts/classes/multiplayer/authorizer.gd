## A node that assigns multiplayer authority when [method assignAuthority] is called.

class_name Authorizer extends Node

# --|| VARIABLES ||--

## An array of nodes to assign a given authority.
@export var peerAuthorizeArray : Array[Node] = []

## An array of nodes to assign authority of 1
@export var serverAuthorizeArray : Array[Node] = []

## The id that was assigned to this node using [method assignAuthority]
var peerId : int = 0

# --|| LOGIC FUNCTIONS ||--

## Sets multiplayer authority of the nodes in [member peerAuthorizeArray] to [param id].
## In addition, sets multiplayer authority of the nodes in [member serverAuthorizeArray] to 1.
func assignAuthority(id : int) -> void:
	peerId = id
	for node : Node in peerAuthorizeArray:
		node.set_multiplayer_authority(id)
	
	for node : Node in serverAuthorizeArray:
		node.set_multiplayer_authority(1)
		if node is RollbackSynchronizer: node.process_settings()
