tool
extends Node2D

class_name AstroBody

signal influence_entered
signal influence_exited
signal radius_collided
signal radius_exited

export var body_radius: float = 10.0 setget set_body_radius
export var body_mass: float = 10000.0 setget set_body_mass
export var rotation_speed: float = 15

onready var influence_area := $InfluenceArea
onready var collision_area := $CollisionArea


func _process(delta: float) -> void:
	rotation_degrees += rotation_speed * delta


func set_body_radius(new_radius: float) -> void:
	body_radius = new_radius
	var new_shape := CircleShape2D.new()
	new_shape.radius = new_radius
	($CollisionArea/CollisionShape2D as CollisionShape2D).shape = new_shape


func set_body_mass(new_mass: float) -> void:
	body_mass = new_mass
	var max_influence := calc_max_influence(body_mass)
	assert(max_influence >= body_radius, "Influence is smaller than body radius!")
	var new_shape := CircleShape2D.new()
	new_shape.radius = max_influence
	($InfluenceArea/CollisionShape2D as CollisionShape2D).shape = new_shape


func calc_max_influence(mass: float) -> float:
	var max_influence_radius: float = sqrt(
		Globals.GRAVITATIONAL_CONSTANT * mass / Globals.INFLUENCE_CUTOFF
	)
	return max_influence_radius


func _on_CollisionArea_area_entered(area: Area2D) -> void:
	if area != influence_area:
		emit_signal("radius_collided")


func _on_InfluenceArea_area_entered(area: Area2D) -> void:
	if area != collision_area:
		emit_signal("influence_entered")


func _on_CollisionArea_area_exited(area: Area2D) -> void:
	if area != influence_area:
		emit_signal("radius_exited")


func _on_InfluenceArea_area_exited(area: Area2D) -> void:
	if area != collision_area:
		emit_signal("influence_exited")
