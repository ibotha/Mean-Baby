extends Enemy


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	stats.set_max_health(rand_range(7, 12))
	stats.character_type = stats.GOLEM
	MAX_SPEED = 20
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
