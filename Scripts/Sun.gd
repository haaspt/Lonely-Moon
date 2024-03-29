extends Node2D

signal sun_collided_with(area)

export var body_mass := 500
export var rotation_speed := 0.5


func _process(delta: float) -> void:
	rotation_degrees = rotation_degrees + rotation_speed * delta


func _on_Area2D_area_entered(area: Area2D) -> void:
	emit_signal("sun_collided_with", area)
