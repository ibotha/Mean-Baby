extends Node2D
class_name dungeon_gen
# Procedurally generates a tile-based map with a border.
# Right click or press enter to re-generate the map.

signal started
signal finished

enum Cell {OBSTACLE, GROUND, OUTER}

export var player_start_pos = Vector2(150, 150)
export var grid_pixel_size := 16
export var inner_size := Vector2(200, 200)
export var perimeter_size := Vector2(10, 10)
export(float, 0 , 1) var ground_probability := 0.1

# Public variables
onready var size := inner_size + Vector2(2, 2)# * perimeter_size

# Private variables
onready var _tilemap_walls : TileMap = $Walls
onready var _tilemap_floor : TileMap = $Floor
onready var _tilemap_doors : TileMap = $Doors
onready var _player = get_node("YSort/Player")
onready var _ysort = get_node("YSort")

var _rng := RandomNumberGenerator.new()
var _array_door_positions = []

#WALKER
const DIRECTIONS = [Vector2.RIGHT, Vector2.UP, Vector2.LEFT, Vector2.DOWN]
const Exit = preload("res://Scenes/ExitDoor.tscn")
const Enemy = preload("res://Entities/Enemies/Enemy.tscn")
var walker_position = Vector2.ZERO
var walker_direction = Vector2.RIGHT
var borders = Rect2()
var step_history = []
var steps_since_turn = 0
var rooms = []
var exit

#ENEMIES
var enemies = []

#LOAD PREMADE ROOMS
var min_x
var min_y
var max_x
var max_y
var room_collections = [preload("res://Scenes/Rooms/Room.tscn").instance()]


func generate() -> void:
	#init, cleaup and prep
	_tilemap_walls.clear()
	_tilemap_doors.clear()
	_tilemap_floor.clear()
	_array_door_positions = []
	
	grid_pixel_size = _tilemap_walls.cell_size.x
	_player.set_position(Vector2((player_start_pos.x + 0.5) * grid_pixel_size, (player_start_pos.y + 1) * grid_pixel_size))
	min_x = player_start_pos.x
	max_x = player_start_pos.x
	min_y = player_start_pos.y
	max_y = player_start_pos.y
	
	_rng.randomize()
	enemies.clear()
	
	#Emit the worked "started"
	emit_signal("started")
	
	#generate the world
	fill_world()
	generate_level()
	generate_doors()

	#Emit the worked "finished"
	emit_signal("finished")


func load_custom_rooms(map):
	#Lets get the size of our current tilemap
	for location in map:
		min_x = location.x if location.x < min_x else min_x
		max_x = location.x if location.x > max_x else max_x
		min_y = location.y if location.y < min_y else min_y
		max_y = location.y if location.y > max_y else max_y
	
	
	
	#=======================================================================================
	#Lets get a random point outside of that, though it must not be too far so i use min+7 max-7
	var random_x_pos = _rng.randi_range(min_x, max_x)
	var random_y_pos = _rng.randi_range(min_y, max_y)
	
	while (random_x_pos >= min_x and random_x_pos <= max_x):
		random_x_pos = _rng.randi_range(min_x - 7, max_x + 7)
		print("I'm a random generator, lets test your luck for X.... and away we go... I selected: ", random_x_pos)
		pass
	
	while (random_y_pos >= min_y and random_y_pos <= min_y):
		random_y_pos = _rng.randi_range(min_y + 7, max_y - 7)
		print("I'm a random generator, lets test your luck for Y.... and away we go... I selected: ", random_y_pos)
		pass
	
	
	
	#=======================================================================================
	#Create the room on our current tilemaps, both the floor and the walls
	print("Room in pos: ", random_x_pos, ":", random_y_pos)
	for room in room_collections:
		print(min_x, ":", max_x, ":", min_y, ":", max_y)
		var rooms_floors = room.get_node("Floor")
		var rooms_walls = room.get_node("Walls")
		
		for x in rooms_floors.get_cell_size().x:
			for y in rooms_floors.get_cell_size().y:
				_tilemap_floor.set_cell(random_x_pos + x, random_y_pos + y, 0, false, false, false, get_subtile_with_priority(0, _tilemap_floor))
				#_tilemap_floor.set_cell(random_x_pos + x, random_y_pos + y, rooms_floors.get_cell(x, y))
				
				if (rooms_walls.get_cell(x, y) == -1):
					continue
				_tilemap_walls.set_cell(random_x_pos + x, random_y_pos + y, -1)
		_tilemap_floor.update_bitmask_region(Vector2(0, 0), Vector2(0, 0))
		
		
		for x in rooms_walls.get_cell_size().x:
			for y in rooms_walls.get_cell_size().y:
				if (rooms_walls.get_cell(x, y) == -1):
					continue
				_tilemap_walls.set_cell(random_x_pos + x, random_y_pos + y, rooms_walls.get_cell(x, y))
		_tilemap_walls.update_bitmask_region(Vector2(0, 0), Vector2(0, 0))
		
		
		
		#=======================================================================================
		#We create the path here, because all roads must lead to rome
		#Its a little wow and weird magic I dont fully understand
		#However i can promise i did test this over and over and
		#It seems to work.
		#
		#Only things is... our roads are cursed with wierd shadows
		#So we need to go through this section to fugure out why?
		var closest_vector
		var closest_distance = 100000
		for location in map:
			for x in rooms_floors.get_cell_size().x:
				for y in rooms_floors.get_cell_size().y:
					var current_distance = location.distance_to(Vector2(random_x_pos + x, random_y_pos + y))
					
					if (current_distance < closest_distance):
						closest_distance = current_distance
						closest_vector = location

		# Carve a path between two points
		var pos1 = closest_vector
		var pos2 = Vector2(random_x_pos + round(rooms_floors.get_cell_size().x / 2), random_y_pos + round(rooms_floors.get_cell_size().y / 2))
		var x_diff = sign(pos2.x - pos1.x)
		var y_diff = sign(pos2.y - pos1.y)
		if x_diff == 0: x_diff = pow(-1.0, randi() % 2)
		if y_diff == 0: y_diff = pow(-1.0, randi() % 2)
		
		# choose either x/y or y/x
		var x_y = pos1
		var y_x = pos2
		if (randi() % 2) > 0:
			x_y = pos2
			y_x = pos1
		for x in range(pos1.x, pos2.x, x_diff):
			_tilemap_walls.set_cell(x, x_y.y, -1)
			_tilemap_walls.set_cell(x, x_y.y + y_diff, -1)
			_tilemap_floor.set_cell(x, x_y.y, 0, false, false, false, get_subtile_with_priority(0, _tilemap_floor))
			_tilemap_floor.set_cell(x, x_y.y + y_diff, 0, false, false, false, get_subtile_with_priority(0, _tilemap_floor))
		for y in range(pos1.y, pos2.y, y_diff):
			_tilemap_walls.set_cell(y_x.x, y, -1)
			_tilemap_walls.set_cell(y_x.x + x_diff, y, -1)
			_tilemap_floor.set_cell(y_x.x, y, 0, false, false, false, get_subtile_with_priority(0, _tilemap_floor))
			_tilemap_floor.set_cell(y_x.x + x_diff, y, 0, false, false, false, get_subtile_with_priority(0, _tilemap_floor))
		
		#It could be these bad bois? But I'm not entirely sure what bitmasks to
		#VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
		_tilemap_walls.update_bitmask_region(Vector2(0, 0), Vector2(0, 0))
		_tilemap_floor.update_bitmask_region(Vector2(0, 0), Vector2(0, 0))
		print("==============================================")
		print(closest_distance)
		print(closest_vector)
	pass


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
		
	#Create Map from Walk
	for location in map:
		_tilemap_walls.set_cellv(location, 1)
	
	#Create custom rooms
	load_custom_rooms(map)

	#Create Enemies
	for location in map:
		if rand_range(0, 100) < 1:
			print("eneny spawned at " + str(location))
			enemies.append(Enemy.instance())
			_ysort.add_child(enemies[-1])
			enemies[-1].global_position = Vector2((location.x + 0.5) * grid_pixel_size, (location.y + 0.5) * grid_pixel_size)
	
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
#endregion


func reload_level():
	get_tree().reload_current_scene()


func _ready() -> void:
	generate()


#func _unhandled_input(event: InputEvent) -> void:
#	if event.is_action_pressed("space") or event.is_action_pressed("ui_accept"):
#		reload_level()
