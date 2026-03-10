extends NetworkSchemaSerializer
class_name NodeSerializer

# Needs to be set from the outside
static var scene_tree: SceneTree

const nullPath : NodePath = ""

func encode(value: Variant, buffer: StreamPeerBuffer) -> void:
	var node : Node = value as Node
	buffer.put_utf8_string(node.get_path() if node else nullPath)

func decode(buffer: StreamPeerBuffer) -> Variant:
	var path : String = buffer.get_utf8_string()
	return scene_tree.root.get_node_or_null(path)
