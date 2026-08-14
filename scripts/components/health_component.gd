class_name HealthComponent extends Node
# Gives whatever it's attached to a pool of health. It doesn't know or
# care what its owner is - it tracks a number and announces when that
# number changes or hits zero. The owner decides what dying means.

@export var max_health: float = 100.0

# Anything that cares (a health bar, the owner, a score counter) connects
# to these instead of us needing to know who's listening.
signal health_changed(current: float, maximum: float)
signal died

# Filled in from max_health in _ready(). Doing it on this line instead
# would capture the script's default, not whatever the Inspector set -
# @export values aren't applied to the instance until after it runs.
var current_health: float = 0.0

func _ready() -> void:
	current_health = max_health

# Reduces health and reports the result. Called by bullets, hazards, etc.
func take_damage(amount: float) -> void:
	if current_health <= 0.0:
		return # Already dead - ignore later hits so `died` only fires once.

	current_health = max(current_health - amount, 0.0)
	health_changed.emit(current_health, max_health)

	if current_health <= 0.0:
		died.emit()

# Restores health, never above max.
func heal(amount: float) -> void:
	if current_health <= 0.0:
		return # Healing doesn't revive - reviving is the owner's call.

	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)
