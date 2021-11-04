extends Node2D
class_name dungeon_gen
# Procedurally generates a tile-based map with a border.
# Right click or press enter to re-generate the map.

signal started
signal finished

export var perimeter_size := Vector2(10, 10)
export var room_count = 5
export var gen_difficulty = 3

## Public variables
#onready var size := inner_size + Vector2(2, 2)# * perimeter_size
#
# Private variables
onready var _tilemap_walls : TileMap = $Walls
onready var _tilemap_floor : TileMap = $Floor
onready var _tilemap_doors : TileMap = $Doors
onready var _player = get_node("YSort/Player")
onready var _ysort = get_node("YSort")

var _rng := RandomNumberGenerator.new()

var grid_size = Vector2(30, 30)
#var _array_door_positions = []
#
##WALKER
#const DIRECTIONS = [Vector2.RIGHT, Vector2.UP, Vector2.LEFT, Vector2.DOWN]
const EXIT_SCENE = preload("res://Scenes/ExitDoor.tscn")
#var walker_position = Vector2.ZERO
#var walker_direction = Vector2.RIGHT
#var borders = Rect2()
#var step_history = []
#var steps_since_turn = 0
#var rooms = []
#var exit
#
#ENEMIES
var SMALL_ENEMY_SCENES = [
	preload("res://Entities/Enemies/Skull.tscn")
]
var MEDIUM_ENEMY_SCENES = [
	preload("res://Entities/Enemies/Goblin.tscn")
]
var LARGE_ENEMY_SCENES = [
	preload("res://Entities/Enemies/Golem.tscn")
]
var BOSS_ENEMY_SCENES = [
	preload("res://Entities/Enemies/Skull.tscn")
]

#LOAD PREMADE ROOMS
#var min_x
#var min_y
#var max_x
#var max_y
var room_instances = [
	preload("res://Scenes/Rooms/Room.tscn").instance(),
	preload("res://Scenes/Rooms/Dungeon.tscn").instance(),
	preload("res://Scenes/Rooms/CourtRoom.tscn").instance()
]

enum {
	DOOR_CONTROL_TILE = 1
}

enum {
	WALL = 0
	SHADOW = 1
}

enum enemyDifficulties {
	SMALL,
	MEDIUM,
	LARGE,
	BOSS
}

func spawn_enemy(difficulty, position: Vector2):
	var scene_list = SMALL_ENEMY_SCENES
	match difficulty:
		enemyDifficulties.SMALL:
			scene_list = SMALL_ENEMY_SCENES
		enemyDifficulties.MEDIUM:
			scene_list = MEDIUM_ENEMY_SCENES
		enemyDifficulties.LARGE:
			scene_list = LARGE_ENEMY_SCENES
	var enemy = scene_list[_rng.randi_range(0, scene_list.size() - 1)].instance()
	_ysort.add_child(enemy)
	enemy.get_node("Stats").max_health *= gen_difficulty
	enemy.global_position = position
	return enemy

func get_random_room():
	return room_instances[_rng.randi_range(0, len(room_instances) - 1)]

func create_room_chain(length):
	var chain = []
	var rooms = 0
	while rooms < length:
		chain.append(RoomNode.new())
		chain[-1].room = get_random_room()
		if rooms > 0:
			chain[rooms - 1].next_room = chain[rooms]
		rooms += 1
	return chain

func generate_room_graph():
	var rooms = 0
	var main_path_length = ceil(room_count / 2.0)
	var main_path = create_room_chain(main_path_length)
	rooms += main_path_length
	while rooms < room_count:
		var chain_length = min(_rng.randi_range(1, room_count - 1), room_count - rooms)
		var room_number = _rng.randi_range(0, main_path_length - 1)
		main_path[room_number].add_room_chain(create_room_chain(chain_length))
		rooms += chain_length
		
	main_path.push_front(RoomNode.new())
	main_path[0].room = get_random_room()
	main_path.append(RoomNode.new())
	main_path[-1].room = get_random_room()
	main_path[0].next_room = main_path[1]
	main_path[-2].next_room = main_path[-1]
	main_path[-1].is_end = true
	return main_path[0]

enum {
	UP,
	DOWN,
	LEFT,
	RIGHT
}

func get_adjacent_position(direction, room: RoomNode):
	match direction:
		UP:
			return Vector2(room.grid_pos.x, room.grid_pos.y - 1)
		DOWN:
			return Vector2(room.grid_pos.x, room.grid_pos.y + 1)
		LEFT:
			return Vector2(room.grid_pos.x - 1, room.grid_pos.y)
		RIGHT:
			return Vector2(room.grid_pos.x + 1, room.grid_pos.y)

func allocate(grid_pos: Vector2, room: RoomNode):
	var size = room.room.size
	room.allocation = Rect2((grid_pos * grid_size) + ((grid_size - size) / 2).floor(), size)
	room.grid_pos = grid_pos

var opposite_direction = {
	UP: DOWN,
	DOWN: UP,
	LEFT: RIGHT,
	RIGHT: LEFT
}

func is_position_taken(grid_position: Vector2, graph: RoomNode):
	if graph == null:
		return false
	if graph.grid_pos.distance_squared_to(grid_position) == 0:
		return true
	if is_position_taken(grid_position, graph.next_room):
		return true
	if is_position_taken(grid_position, graph.offshoot1):
		return true
	if is_position_taken(grid_position, graph.offshoot2):
		return true
	return false
	

func try_place_room(room: RoomNode, grid_position : Vector2, root: RoomNode, from):
	if room == null:
		return true
	var directions = [UP, DOWN, LEFT, RIGHT]
	# Place first room
	if from == null:
		randomize()
		directions.shuffle()
		allocate(grid_position, room)
		try_place_room(room.next_room, get_adjacent_position(directions[0], room), root, opposite_direction[directions[0]])
		
	if is_position_taken(grid_position, root):
		return false
		
	allocate(grid_position, room)
		
	directions.remove(directions.find(from))
	var placed = false
	var tries = 0
	while not placed and tries < 3:
		tries = tries + 1
		if try_place_room(room.next_room, get_adjacent_position(directions[0], room), root, opposite_direction[directions[0]]) && try_place_room(room.offshoot1, get_adjacent_position(directions[1], room), root, opposite_direction[directions[1]]) && try_place_room(room.offshoot2, get_adjacent_position(directions[2], room), root, opposite_direction[directions[2]]):
			return true
		directions.push_front(directions.pop_back())
	return false

func allocate_rooms(graph: RoomNode):
	try_place_room(graph, Vector2(0, 0), graph, null)

func place_premade_room(position, room: Room, spawn_enemies = true) -> bool:
	var rooms_floors : TileMap = room.get_node("Floor")
	var rooms_walls : TileMap = room.get_node("Walls")

	for cell in rooms_floors.get_used_cells():
		var pos = position + cell
		
		_tilemap_floor.set_cell(pos.x, pos.y, 0, false, false, false, get_subtile_with_priority(0, _tilemap_floor))

	for cell in rooms_walls.get_used_cells():
		_tilemap_walls.set_cellv(position + cell,
		rooms_walls.get_cellv(cell))

	for cell in room.control_tilemap.get_used_cells():
		if spawn_enemies:
			var difficulty_map = {
				2: enemyDifficulties.MEDIUM,
				4: enemyDifficulties.LARGE,
				5: enemyDifficulties.SMALL
			}
			if room.control_tilemap.get_cellv(cell) in [2, 4, 5]:
				spawn_enemy(difficulty_map[room.control_tilemap.get_cellv(cell)], _tilemap_floor.map_to_world(position + cell) + Vector2(0.5, 0.5) * _tilemap_floor.cell_size)
	return true

func connect_rooms(a: RoomNode, b: RoomNode):
	var a_door
	var b_door
	var dist = null
	for a_point in a.room.control_tilemap.get_used_cells():
		if a.room.control_tilemap.get_cellv(a_point) == DOOR_CONTROL_TILE:
			a_point = (a_point + a.allocation.position)
			for b_point in b.room.control_tilemap.get_used_cells():
				if b.room.control_tilemap.get_cellv(b_point) == DOOR_CONTROL_TILE:
					b_point = (b_point + b.allocation.position)
					var current_dist = (a_point - b_point).length_squared()
					if dist == null || current_dist < dist:
						dist = current_dist
						a_door = a_point
						b_door = b_point
	var diff = b_door - a_door;
	while diff.length_squared() > 0:
		_tilemap_walls.set_cell(a_door.x, a_door.y, SHADOW)
		_tilemap_floor.set_cell(a_door.x, a_door.y, 0, false, false, false, get_subtile_with_priority(0, _tilemap_floor))
		var dir = abs(diff.x) > abs(diff.y)
		var immune = a_door
		if dir:
			a_door.x += 1 if diff.x > 0 else -1
		else:
			a_door.y += 1 if diff.y > 0 else -1
		diff = b_door - a_door
	_tilemap_walls.set_cell(a_door.x, a_door.y, SHADOW)
	_tilemap_floor.set_cell(a_door.x, a_door.y, 0, false, false, false, get_subtile_with_priority(0, _tilemap_floor))

func place_rooms(graph: RoomNode, previous: RoomNode):
	place_premade_room(graph.allocation.position, graph.room, previous != null && !graph.is_end)
	if previous != null:
		connect_rooms(previous, graph)
	
	if graph.next_room:
		place_rooms(graph.next_room, graph)
		
	if graph.offshoot1:
		place_rooms(graph.offshoot1, graph)
	if graph.offshoot2:
		place_rooms(graph.offshoot2, graph)
		
	if graph.is_end:
		print("end")
		var exit = EXIT_SCENE.instance()
		exit.global_position = _tilemap_walls.map_to_world(graph.room.get_special_cell() + graph.allocation.position) + (_tilemap_walls.cell_size / 2)
		_ysort.add_child(exit)
		exit.connect("leaving_level", self, "generate")
		

func fill_space(graph: RoomNode):
	if not graph:
		return
	var top_left = grid_size * graph.grid_pos
	var bot_right = grid_size * (graph.grid_pos + Vector2(1, 1))
	
	var x = top_left.x
	while x < bot_right.x:
		var y = top_left.y
		while y < bot_right.y:
			_tilemap_walls.set_cell(x, y, WALL)
			y += 1
		x += 1
	fill_space(graph.next_room)
	fill_space(graph.offshoot1)
	fill_space(graph.offshoot2)

func generate() -> void:
	_tilemap_doors.clear()
	_tilemap_floor.clear()
	_tilemap_walls.clear()
	
	var room_graph : RoomNode = generate_room_graph()
	
	allocate_rooms(room_graph)
	
	fill_space(room_graph)
	
	place_rooms(room_graph, null)
	_tilemap_walls.update_dirty_quadrants()
	var rect = _tilemap_walls.get_used_rect()
	_tilemap_walls.update_bitmask_region(rect.position, rect.end)
	
	_player.global_position = _tilemap_walls.map_to_world(room_graph.allocation.position + room_graph.room.get_special_cell()) + (_tilemap_walls.cell_size / 2.0)

#func generate() -> void:
#	#init, cleaup and prep
#	_tilemap_walls.clear()
#	_tilemap_doors.clear()
#	_tilemap_floor.clear()
#	_array_door_positions = []
#
#	grid_pixel_size = _tilemap_walls.cell_size.x
#	_player.set_position(Vector2((player_start_pos.x + 0.5) * grid_pixel_size, (player_start_pos.y + 1) * grid_pixel_size))
#	min_x = player_start_pos.x
#	max_x = player_start_pos.x
#	min_y = player_start_pos.y
#	max_y = player_start_pos.y
#
#	_rng.randomize()
#
#	#Emit the worked "started"
#	emit_signal("started")
#
#	#generate the world
#	fill_world()
#	generate_level()
#	generate_doors()
#
#	#Emit the worked "finished"
#	emit_signal("finished")
#
#
#func load_custom_rooms(map):
#	for room in room_collections:
#		#=======================================================================================
#		#Lets get the size of our current tilemap
#		for location in map:
#			min_x = location.x if location.x < min_x else min_x
#			max_x = location.x if location.x > max_x else max_x
#			min_y = location.y if location.y < min_y else min_y
#			max_y = location.y if location.y > max_y else max_y
#
#
#		#=======================================================================================
#		#Lets make sure the room is not 20 units of the door exit. otherwise we would block it off
#		#Lets get a random point outside of that, though it must not be too far so i use min+7 max-7
#		var random_x_pos = _rng.randi_range(min_x, max_x)
#		var random_y_pos = _rng.randi_range(min_y, max_y)
#		var distance_to_door = 0
#		while (distance_to_door < 20):
#			while (random_x_pos >= min_x and random_x_pos <= max_x):
#				random_x_pos = _rng.randi_range(min_x - 14, max_x + 7)
#				print("I'm a random generator, lets test your luck for X.... and away we go... I selected: ", random_x_pos)
#				pass
#
#			while (random_y_pos >= min_y and random_y_pos <= min_y):
#				random_y_pos = _rng.randi_range(min_y + 14, max_y - 7)
#				print("I'm a random generator, lets test your luck for Y.... and away we go... I selected: ", random_y_pos)
#				pass
#
#			print(get_end_room().position)
#			print(random_x_pos)
#			print(random_y_pos)
#			distance_to_door = (get_end_room().position).distance_to(Vector2(random_x_pos, random_y_pos))
#			if (distance_to_door < 20):
#				random_x_pos = _rng.randi_range(min_x - 14, max_x + 7)
#				random_y_pos = _rng.randi_range(min_y + 14, max_y - 7)
#			#print("Distance to door: ", distance_to_door)
#		print("Room in pos: ", random_x_pos, ":", random_y_pos)
#
#
#		#=======================================================================================
#		#Create the room on our current tilemaps, both the floor and the walls	
#		print(min_x, ":", max_x, ":", min_y, ":", max_y)
#		place_premade_room(Vector2(random_x_pos, random_y_pos), room)
#		#_tilemap_walls.update_bitmask_region(Vector2(0, 0), Vector2(0, 0))
#
#
#
#		#=======================================================================================
#		#We create the path here, because all roads must lead to rome
#		#Its a little wow and weird magic I dont fully understand
#		#However i can promise i did test this over and over and
#		#It seems to work.
#		#
#		#Only things is... our roads are cursed with wierd shadows
#		#So we need to go through this section to fugure out why?
#		var closest_vector
#		var closest_distance = 100000
#		var room_vector = Vector2.ZERO
#		for location in map:
#			for cell in room.control_tilemap.get_used_cells():
#				if (room.control_tilemap.get_cellv(cell) == 1):
#					var current_distance = location.distance_to(Vector2(random_x_pos, random_y_pos) + cell)
#
#					if (current_distance < closest_distance):
#						closest_distance = current_distance
#						room_vector = cell
#						closest_vector = location
#
#		# Carve a path between two points
#		var pos1 = closest_vector
#		var pos2 = Vector2(random_x_pos, random_y_pos) + room_vector
#		var x_diff = sign(pos2.x - pos1.x)
#		var y_diff = sign(pos2.y - pos1.y)
#		if x_diff == 0: x_diff = pow(-1.0, randi() % 2)
#		if y_diff == 0: y_diff = pow(-1.0, randi() % 2)
#
#		# choose either x/y or y/x
#		var x_y = pos1
#		var y_x = pos2
#		if (randi() % 2) > 0:
#			x_y = pos2
#			y_x = pos1
#		for x in range(pos1.x, pos2.x, x_diff):
#			_tilemap_walls.set_cell(x, x_y.y, -1)
#			_tilemap_floor.set_cell(x, x_y.y, 0, false, false, false, get_subtile_with_priority(0, _tilemap_floor))
#		for y in range(pos1.y, pos2.y, y_diff):
#			_tilemap_walls.set_cell(y_x.x, y, -1)
#			_tilemap_floor.set_cell(y_x.x, y, 0, false, false, false, get_subtile_with_priority(0, _tilemap_floor))
#
#
#		_tilemap_walls.set_cellv(pos2, -1)
#		_tilemap_floor.set_cell(pos2.x, pos2.y, 0, false, false, false, get_subtile_with_priority(0, _tilemap_floor))
#
#		#It could be these bad bois? But I'm not entirely sure what bitmasks to
#		#VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
#		#_tilemap_walls.update_bitmask_region(Vector2(0, 0), Vector2(0, 0))
#		#_tilemap_walls.update_bitmask_region(borders.position, borders.end)
#		#_tilemap_floor.update_bitmask_region(Vector2(0, 0), Vector2(0, 0))
#		print("==============================================")
#		print(closest_distance)
#		print(closest_vector)
#	pass
#
#
#
#func generate_doors():
#	_tilemap_doors.set_cell(player_start_pos.x, player_start_pos.y, 0)
#	print(_player.position)
#	print(Vector2(get_end_room().position.x * 16, get_end_room().position.y * 16))
#	_tilemap_doors.set_cell(get_end_room().position.x, get_end_room().position.y, 0)
#
#	exit = Exit.instance()
#	add_child(exit)
#	exit.position = get_end_room().position * grid_pixel_size
#	exit.connect("leaving_level", self, "reload_level")
#
#
#func fill_world() -> void:
#	# Fills the world with walls
#	for x in [0, size.x - 1]:
#		for y in range(0, size.y):
#			_array_door_positions.append(Vector2(x, y))
#
#	for x in range(-perimeter_size.x, size.x + perimeter_size.x):
#		for y in range(-perimeter_size.y, size.y + perimeter_size.y):
#			_tilemap_walls.set_cell(x, y, 0)
#			_tilemap_floor.set_cell(x, y, 0, false, false, false, get_subtile_with_priority(0, _tilemap_floor))
#	_tilemap_floor.update_bitmask_region(Vector2(0, 0), Vector2(0, 0))
#
##region WALKER
#func generate_level():
#	var borders = Rect2(1, 1, size.x, size.y)
#	set_start(player_start_pos, borders)
#	var map = walk(500)
#	_player.set_position(Vector2((player_start_pos.x + 0.5) * grid_pixel_size, (player_start_pos.y + 1) * grid_pixel_size))
#
#	#Create Map from Walk
#	for location in map:
#		_tilemap_walls.set_cellv(location, 1)
#
#	#Create custom rooms
#	load_custom_rooms(map)
#
#	_tilemap_walls.update_bitmask_region(borders.position, borders.end)
#
#
#func set_start(starting_position, new_borders):
#	assert(new_borders.has_point(starting_position))
#	walker_position = starting_position
#	step_history = []
#	step_history.append(walker_position)
#	borders = new_borders
#
#
#func walk(steps):
#	place_room(walker_position)
#	for step in steps:
#		if steps_since_turn >= _rng.randi_range(4, 9):
#			change_direction()
#
#		if step():
#			step_history.append(walker_position)
#		else:
#			change_direction()
#	return step_history
#
#
#func step():
#	var target_position = walker_position + walker_direction
#	if borders.has_point(target_position):
#		steps_since_turn += 1
#		walker_position = target_position
#		return true
#	else:
#		return false
#
#
#func change_direction():
#	place_room(walker_position)
#	steps_since_turn = 0
#	var directions = DIRECTIONS.duplicate()
#	directions.erase(walker_direction)
#	directions.shuffle()
#	walker_direction = directions.pop_front()
#	while not borders.has_point(walker_position + walker_direction):
#		walker_direction = directions.pop_front()
#
#
#func create_room(position, size):
#	return { position = position, size = size }
#
#
#func place_room(position):
#	var size = Vector2(_rng.randi() % 4 + 2, _rng.randi() % 4 + 2)
#	var top_left_corner = (position - size / 2).ceil()
#	rooms.append(create_room(position, size))
#	for y in size.y:
#		for x in size.x:
#			var new_step = top_left_corner + Vector2(x, y)
#			if borders.has_point(new_step):
#				step_history.append(new_step)
#
#
#func get_end_room():
#	var end_room = rooms.pop_front()
#	var starting_position = step_history.front()
#	for room in rooms:
#		if starting_position.distance_to(room.position) > starting_position.distance_to(end_room.position):
#			end_room = room
#	return end_room
#
#
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
##endregion
#
#
#func reload_level():
#	get_tree().reload_current_scene()
#
#
func _ready() -> void:
	# Get rooms ready
	for room in room_instances:
		add_child(room)
		room.visible = false
		room.global_position = Vector2(-10000, -10000)
	generate()
#
#
##func _unhandled_input(event: InputEvent) -> void:
##	if event.is_action_pressed("space") or event.is_action_pressed("ui_accept"):
##		reload_level()
