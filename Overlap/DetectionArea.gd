extends Area2D

var entities = []

signal entity_list_changed

func _on_DetectionArea_body_entered(body):
	entities.append(body)
	emit_signal("entity_list_changed")


func _on_DetectionArea_body_exited(body):
	entities.erase(body)
	emit_signal("entity_list_changed")
