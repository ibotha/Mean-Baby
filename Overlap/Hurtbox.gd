extends Area2D

const HIT_EFFECT_SCENE = preload("res://Effects/HitEffect.tscn")

export(bool) var show_hit_effect = true

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _on_Hurtbox_area_entered(area):
	if show_hit_effect:
		var hit_effect = HIT_EFFECT_SCENE.instance()
		get_tree().current_scene.add_child(hit_effect)
		hit_effect.global_position = global_position
