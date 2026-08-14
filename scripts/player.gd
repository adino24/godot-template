extends Area2D
# The player. Owns input and movement only - health lives in its
# HealthComponent child, exactly like every other damageable thing.

@export var speed: float = 120.0

@onready var health_component: HealthComponent = $HealthComponent

func _ready() -> void:
	health_component.died.connect(_on_died)

func _physics_process(delta: float) -> void:
	# get_vector normalises diagonals for us - moving by hand on both
	# axes would make diagonal movement ~40% faster than straight.
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	position += direction * speed * delta

# Fires when the HealthComponent hits 0. Deliberately just a hook - what
# death means (results screen, respawn, game over) is a per-game choice.
func _on_died() -> void:
	print("Player died")
