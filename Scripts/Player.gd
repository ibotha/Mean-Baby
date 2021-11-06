extends KinematicBody2D

const FIREBALL_SCENE = preload("res://Entities/Projectiles/Fireball.tscn")

onready var animation_player = $AnimationPlayer
onready var flame_animation_player = $FlameAnimationPlayer
onready var animation_tree = $AnimationTree
onready var animation_state = animation_tree.get("parameters/playback")
onready var sword_hitbox = $HitboxPivot/SwordHitbox
onready var flame = $Flame
onready var flame_pivot = $FlamePivot
onready var flame_destination = $FlamePivot/FlameDestination
onready var animation_damage = $AnimationDamage

onready var health_bar = get_node("CanvasLayer/HealthBar/ColorRect")
onready var mana_bar = get_node("CanvasLayer/ManaBar/ColorRect")

export var invulnerable = false
export var MAX_SPEED = 80
export var ACCELERATION = 500
export var FRICTION = 500
export var ROLL_SPEED = 100
export var FLAME_SPEED = 30
export var FIREBALL_SPEED = 300
export var ATTACK_DELAY = 0.333333

enum {
	MOVE,
	ROLL,
	ATTACK
}

var state = MOVE
var velocity = Vector2.ZERO
var roll_vector = Vector2.DOWN
var stats = PlayerStats
var attack_cooldown = 0
var knockback_froce = Vector2.ZERO

func _ready():
#	stats.connect("no_health", self, "queue_free")
	animation_tree.active = true
	sword_hitbox.knockback_vector = roll_vector
	stats.character_type = stats.PLAYER

func _process(delta):
	_handle_attack(delta)
	_handle_health_mana(delta)

func _handle_attack(delta):
	if attack_cooldown > 0:
		attack_cooldown -= delta
	else:
		if Input.is_action_pressed("Attack"):
			if (stats.mana - stats.mana_drain) < 0:
				return
			
			stats.mana = stats.mana - stats.mana_drain
			attack_cooldown = ATTACK_DELAY
			flame_animation_player.play("Shoot")
			var fireball = FIREBALL_SCENE.instance()
			fireball.global_position = flame.global_position
			fireball.global_rotation = flame_pivot.global_rotation
			get_tree().get_root().add_child(fireball)


func _handle_health_mana(delta):
	# Regenerates mana
	if (stats.mana < 100):
		var new_mana = min(stats.mana + stats.mana_regeneration * delta, stats.get_max_mana())
		if new_mana != stats.mana:
			stats.mana = new_mana
	mana_bar.rect_size.x = 72 * stats.mana / stats.get_max_mana()

	# Regenerates health
	if (stats.health < 100):
		var new_health = min(stats.health + stats.health_regeneration * delta, stats.get_max_health())
		if new_health != stats.health:
			stats.health = new_health
	health_bar.rect_size.x = 72 * stats.health / stats.get_max_health()
	
	if (stats.invulnerability_timer <= 0):
		animation_damage.play("Normal")
#		animation_damage.seek(0, true)
	else:
		stats.invulnerability_timer -= delta
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	flame_pivot.look_at(get_global_mouse_position())
	flame.move_and_slide((flame_destination.global_position - flame.global_position) * 2)
	if (flame.global_position - flame_destination.global_position).length_squared() > 400:
		flame.global_position = global_position
		
	match(state):
		MOVE:
			MoveState(delta)
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
	velocity = move_and_slide(velocity + knockback_froce)
	knockback_froce = lerp(knockback_froce, Vector2.ZERO, 0.1)
	
	# Update animation states
	if velocity.length_squared() > 0:
		animation_state.travel("Run")
	else:
		animation_state.travel("Idle")
		
	# State transitions
	if Input.is_action_just_pressed("Roll"):
		state = ROLL

func KnockbackPlayer(knockback_pos_hit, add_force=true):
	if (add_force == true && stats.invulnerability_timer <= 0):
		knockback_froce = (global_position-knockback_pos_hit).normalized() * 25

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
	if (stats.invulnerability_timer <= 0):
		animation_damage.play("Damage")
		animation_damage.queue("Invulnerable")
		stats.health -= area.damage
		health_bar.rect_size.x = 72 * stats.health / stats.get_max_health()
		stats.set_invulnerability_timer(stats.max_invulnerability_timer)
