extends KinematicBody2D
class_name Enemy

onready var animatedSprite = $AnimatedSprite
onready var detectionArea = $DetectionArea
onready var stats = $Stats

var velocity = Vector2.ZERO
var target = null

export var MAX_SPEED = 70
export var ACCELLERATION = 300
export var FRICTION = 200

enum states {
	IDLE,
	CHASE,
	ATTACK
}

var state = states.IDLE

func _ready():
	pass # Replace with function body.


func _physics_process(delta):
	match(state):
		states.IDLE:
			_idle_state(delta)
		states.CHASE:
			_chase_state(delta)
		states.ATTACK:
			_attack_state(delta)
		
	if abs(velocity.x) > abs(velocity.y):
		animatedSprite.play("Left" if velocity.x < 0 else "Right")
	else:
		animatedSprite.play("Up" if velocity.y < 0 else "Down")
	
	velocity = move_and_slide(velocity)

func _idle_state(delta):
	velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)

func _chase_state(delta):
	velocity = velocity.move_toward((target.global_position - global_position).normalized() * MAX_SPEED, ACCELLERATION * delta)
	
func _attack_state(delta):
	pass
	
func _on_DetectionArea_entity_list_changed():
	if len(detectionArea.entities) > 0:
		target = detectionArea.entities[0]
		state = states.CHASE
	else:
		target = null
		state = states.IDLE


func _on_Hurtbox_area_entered(area):
	stats.health -= area.damage


func _on_Stats_no_health():
	queue_free()
