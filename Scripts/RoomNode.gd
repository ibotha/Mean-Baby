class_name RoomNode

var next_room : RoomNode = null
var offshoot1 : RoomNode = null
var offshoot2 : RoomNode = null
var room : Room = null
var allocation : Rect2 = Rect2()
var grid_pos : Vector2 = Vector2()
var is_end = false

func add_room_chain(chain):
	if offshoot1 == null:
		offshoot1 = chain[0]
	elif offshoot2 == null:
		offshoot2 = chain[0]
	else:
		return false
	return true
