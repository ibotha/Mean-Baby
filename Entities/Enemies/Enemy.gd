extends KinematicBody2D

onready var animatedSprite = $AnimatedSprite
onready var detectionArea = $DetectionArea
onready var stats = $Stats

var velocity = Vector2.ZERO
var target = null

export var MAX_SPEED = 100
export var ACCELLERATION = 100
export var FRICTION = 100

func _ready():
	pass # Replace with function body.


func _physics_process(delta):
	if target != null:
		velocity = velocity.move_toward(target.global_position - global_position, ACCELLERATION * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	
	move_and_slide(velocity)


func _on_DetectionArea_entity_list_changed():
	if len(detectionArea.entities) > 0:
		target = detectionArea.entities[0]
	else:
		target = null


func _on_Hurtbox_area_entered(area):
	stats.health -= area.damage


func _on_Stats_no_health():
	queue_free()
