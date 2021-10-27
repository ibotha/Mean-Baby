extends Node2D
class_name dungeon_gen
# Procedurally generates a tile-based map with a border.
# Right click or press enter to re-generate the map.

signal started
signal finished

enum Cell {OBSTACLE, GROUND, OUTER}

export var player_start_pos = Vector2(150, 150)
export var grid_pixel_size := 16
export var inner_size := Vector2(400, 400)
export var perimeter_size := Vector2(10, 10)
export(float, 0 , 1) var ground_probability := 0.1

# Public variables
onready var size := inner_size + Vector2(2, 2)# * perimeter_size

# Private variables
onready var _tilemap_walls : TileMap = $Walls
onready var _tilemap_floor : TileMap = $Floor
onready var _tilemap_doors : TileMap = $Doors
onready var _player = get_node("YSort/Player")

var _rng := RandomNumberGenerator.new()
var _array_door_positions = []

#WALKER
const DIRECTIONS = [Vector2.RIGHT, Vector2.UP, Vector2.LEFT, Vector2.DOWN]
const Exit = preload("res://Scenes/ExitDoor.tscn")
var walker_position = Vector2.ZERO
var walker_direction = Vector2.RIGHT
var borders = Rect2()
var step_history = []
var steps_since_turn = 0
var rooms = []
var exit

func generate() -> void:
	# Although there's no other nodes to use these signals, we're including them
	# to show when and how to emit them.
	# Watch our signals tutorial for more information.
	_tilemap_walls.clear()
	_tilemap_doors.clear()
	_tilemap_floor.clear()
	_array_door_positions = []
	_player.set_position(Vector2((player_start_pos.x + 0.5) * grid_pixel_size, (player_start_pos.y + 1) * grid_pixel_size))
	
	emit_signal("started")
	_rng.randomize()
	
	#generate the world
	fill_world()
	generate_level()
	generate_doors()
	#generate_inner()
	
	#generate the doors
	#generate_doors()
	
	emit_signal("finished")


func generate_doors():
	_tilemap_doors.set_cell(player_start_pos.x, player_start_pos.y, 0)
	print(_player.position)
	print(Vector2(get_end_room().position.x * 16, get_end_room().position.y * 16))
	_tilemap_doors.set_cell(get_end_room().position.x, get_end_room().position.y, 0)
	
	exit = Exit.instance()
	add_child(exit)
	exit.position = get_end_room().position * grid_pixel_size
	exit.connect("leaving_level", self, "reload_level")


func fill_world() -> void:
	# Fills the world with walls
	for x in [0, size.x - 1]:
		for y in range(0, size.y):
			_array_door_positions.append(Vector2(x, y))

	for x in range(-perimeter_size.x, size.x + perimeter_size.x):
		for y in range(-perimeter_size.y, size.y + perimeter_size.y):
			_tilemap_walls.set_cell(x, y, 0)
			_tilemap_floor.set_cell(x, y, 0, false, false, false, get_subtile_with_priority(0, _tilemap_floor))
	_tilemap_floor.update_bitmask_region(Vector2(0, 0), Vector2(0, 0))


#region WALKER
func generate_level():
	var borders = Rect2(1, 1, size.x, size.y)
	set_start(player_start_pos, borders)
	var map = walk(500)
	_player.set_position(Vector2((player_start_pos.x + 0.5) * grid_pixel_size, (player_start_pos.y + 1) * grid_pixel_size))
	
	#walker.queue_free()
	for location in map:
		_tilemap_walls.set_cellv(location, 1)
	_tilemap_walls.update_bitmask_region(borders.position, borders.end)


func set_start(starting_position, new_borders):
	assert(new_borders.has_point(starting_position))
	walker_position = starting_position
	step_history = []
	step_history.append(walker_position)
	borders = new_borders

func walk(steps):
	place_room(walker_position)
	for step in steps:
		if steps_since_turn >= _rng.randi_range(4, 9):
			change_direction()
		
		if step():
			step_history.append(walker_position)
		else:
			change_direction()
	return step_history


func step():
	var target_position = walker_position + walker_direction
	if borders.has_point(target_position):
		steps_since_turn += 1
		walker_position = target_position
		return true
	else:
		return false


func change_direction():
	place_room(walker_position)
	steps_since_turn = 0
	var directions = DIRECTIONS.duplicate()
	directions.erase(walker_direction)
	directions.shuffle()
	walker_direction = directions.pop_front()
	while not borders.has_point(walker_position + walker_direction):
		walker_direction = directions.pop_front()


func create_room(position, size):
	return { position = position, size = size }


func place_room(position):
	var size = Vector2(_rng.randi() % 4 + 2, _rng.randi() % 4 + 2)
	var top_left_corner = (position - size / 2).ceil()
	rooms.append(create_room(position, size))
	for y in size.y:
		for x in size.x:
			var new_step = top_left_corner + Vector2(x, y)
			if borders.has_point(new_step):
				step_history.append(new_step)


func get_end_room():
	var end_room = rooms.pop_front()
	var starting_position = step_history.front()
	for room in rooms:
		if starting_position.distance_to(room.position) > starting_position.distance_to(end_room.position):
			end_room = room
	return end_room
#endregion

func get_subtile_with_priority(id, tilemap: TileMap):
	var tiles = tilemap.tile_set
	var rect = tilemap.tile_set.tile_get_region(id)
	var size_x = rect.size.x / tiles.autotile_get_size(id).x
	var size_y = rect.size.y / tiles.autotile_get_size(id).y
	var tile_array = []
	for x in range(size_x):
		for y in range(size_y):
			var priority = tiles.autotile_get_subtile_priority(id, Vector2(x ,y))
			for p in priority:
				tile_array.append(Vector2(x,y))

	return tile_array[randi() % tile_array.size()]

func reload_level():
	get_tree().reload_current_scene()

func _ready() -> void:
	generate()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("space") or event.is_action_pressed("ui_accept"):
		reload_level()
