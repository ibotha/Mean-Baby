extends Enemy

const FIREBALL_SCENE = preload("res://Entities/Projectiles/EnemyFireball.tscn")

var skull_attack_distance = 40
var last_known_player_local_location = Vector2.ZERO
export var SKULL_FLAME_SPEED = 30
export var SKULL_FIREBALL_SPEED = 300
export var SKULL_ATTACK_DELAY = 0.5

func _ready():
	randomize()
	stats.set_max_health(rand_range(1, 4))
	stats.character_type = stats.SKULL
	MAX_SPEED = 40
	pass # Replace with function body.

func _chase_state(delta):
	if (target != null):
		last_known_player_location = target.global_position

	if (global_position.distance_to(last_known_player_location) <= skull_attack_distance):
		state = states.ATTACK
		velocity = Vector2.ZERO
		_attack_state(delta)
		return
	
	velocity = velocity.move_toward((last_known_player_location - global_position).normalized() * MAX_SPEED, ACCELLERATION * delta)
			
	
func _attack_state(delta):
	if (target != null):
		last_known_player_location = target.global_position
		last_known_player_local_location = target.position
	else:
		state = states.CHASE
		return
		
	if (global_position.distance_to(last_known_player_location) > skull_attack_distance):
		velocity = velocity.move_toward((last_known_player_location - global_position).normalized() * MAX_SPEED, ACCELLERATION * delta)
		state = states.CHASE
		
	if attack_cooldown > 0:
		attack_cooldown -= delta
		return
	
	var enemy_fireball = FIREBALL_SCENE.instance()
	enemy_fireball.global_position = global_position
	enemy_fireball.global_rotation = (last_known_player_local_location - global_position).angle()
	get_tree().get_root().add_child(enemy_fireball)
	attack_cooldown = ATTACK_DELAY

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
