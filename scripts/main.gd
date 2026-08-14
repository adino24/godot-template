extends Node2D
# Root scene of the running game. Owns the run's state and is the only
# script that touches get_tree().paused - see RULEBOOK, "Who owns the run".

@onready var player_health: HealthComponent = $Player/HealthComponent

func _ready() -> void:
	player_health.died.connect(_on_player_died)

# Fires when the player's health hits 0. Pausing freezes enemies, timers
# and physics in one line; a results screen would be shown from here.
func _on_player_died() -> void:
	get_tree().paused = true
