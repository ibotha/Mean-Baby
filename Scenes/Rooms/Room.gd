extends Node2D
class_name Room

onready var floor_tilemap = $Floor
onready var wall_tilemap = $Walls
onready var control_tilemap = $Control
var _size = null
var size setget ,get_size

func get_size():
	"""
	Assumes the top-left of the room is at 0,0 and that the room is surrounded by walls
	"""
	if _size == null:
		_size = wall_tilemap.get_used_rect().end
		print(_size)
	return _size
	
# Called when the node enters the scene tree for the first time.
func _ready():
	print("Ready")
