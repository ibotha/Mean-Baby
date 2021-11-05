extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var SPEED = 200


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	position += Vector2.RIGHT.rotated(transform.get_rotation()) * delta * SPEED
#	pass


func _on_Hitbox_area_entered(_area):
	if (_area.get_parent().stats.character_type == _area.get_parent().stats.PLAYER):
		_area.get_parent().knockback_pos_hit = global_position
	#_area.get_parent().velocity += global_position.direction_to(_area.get_parent().position) * 10
	#_area.get_parent().move(Vector2(0,-1).rotated(global_position.angle_to_point(_area.get_parent().position)) * speed * delta)
	queue_free()


func _on_Hitbox_body_entered(_body):
	queue_free()
