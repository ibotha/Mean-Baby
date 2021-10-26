extends KinematicBody2D

onready var animation_player = $AnimationPlayer
onready var animation_tree = $AnimationTree
onready var animation_state = animation_tree.get("parameters/playback")
onready var sword_hitbox = $HitboxPivot/SwordHitbox

export var MAX_SPEED = 80
export var ACCELERATION = 500
export var FRICTION = 500
export var ROLL_SPEED = 100

enum {
	MOVE,
	ROLL,
	ATTACK
}

var state = MOVE
var velocity = Vector2.ZERO
var roll_vector = Vector2.DOWN
var stats = PlayerStats

func _ready():
	stats.connect("no_health", self, "queue_free")
	animation_tree.active = true
	sword_hitbox.knockback_vector = roll_vector

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	match(state):
		MOVE:
			MoveState(delta)
			
		ATTACK:
			AttackState(delta)
			
		ROLL:
			RollState(delta)


func MoveState(delta):
	# Gather input
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("Movement Right") - Input.get_action_strength("Movement Left")
	input_vector.y = Input.get_action_strength("Movement Down") - Input.get_action_strength("Movement Up")
	
	# Change Velocity
	if input_vector != Vector2.ZERO:
		animation_tree.set("parameters/Idle/blend_position", input_vector)
		animation_tree.set("parameters/Run/blend_position", input_vector)
		animation_tree.set("parameters/Roll/blend_position", input_vector)
		animation_tree.set("parameters/Attack/blend_position", input_vector)
		velocity = velocity.move_toward(input_vector.normalized() * MAX_SPEED, ACCELERATION * delta)
		roll_vector = input_vector.normalized()
		sword_hitbox.knockback_vector = roll_vector
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		
	# Reset Animation values
	animation_tree.set("parameters/conditions/Attacking", false)
	animation_tree.set("parameters/conditions/Rolling", false)

	# Move Player
	velocity = move_and_slide(velocity)
	
	# Update animation states
	if velocity.length_squared() > 0:
		animation_state.travel("Run")
	else:
		animation_state.travel("Idle")
		
	# State transitions
	if Input.is_action_just_pressed("Attack"):
		state = ATTACK
	if Input.is_action_just_pressed("Roll"):
		state = ROLL

func AttackState(delta):
	animation_state.travel("Attack")
	velocity = Vector2.ZERO
	
func RollState(delta):
	animation_state.travel("Roll")
	velocity = ROLL_SPEED * roll_vector
	velocity = move_and_slide(velocity)	
	
func AttackAnimationFinished():
	state = MOVE

func RollAnimationFinished():
	state = MOVE


func _on_Hurtbox_area_entered(area):
	stats.health -= area.damage
