extends Node

export(int) var max_health = 1
onready var health = max_health setget set_health
onready var health_regeneration = 0.01

export(int) var max_mana = 1
onready var mana = max_mana setget set_mana
onready var mana_regeneration = 0.05
onready var mana_drain = 0.05

onready var max_invulnerability_timer = 3
onready var invulnerability_timer = 0 setget set_invulnerability_timer

signal no_health

enum {
	NONE,
	PLAYER,
	GOBLIN,
	SKULL,
	GOLEM
}
var character_type = NONE

func set_invulnerability_timer(value):
	invulnerability_timer = value

func set_max_health(value):
	max_health = value
	health = value

func get_max_health():
	return max_health

func set_health(value):
	health = value
	if health <= 0:
		emit_signal("no_health")

func get_max_mana():
	return max_mana
	
func set_mana(value):
	mana = value
