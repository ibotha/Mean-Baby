extends Enemy


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	stats.set_max_health(rand_range(1, 3))
	stats.character_type = stats.GOBLIN
	MAX_SPEED = 200
	ACCELLERATION = 150
	FRICTION = 80
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
