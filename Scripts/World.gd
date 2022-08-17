extends Node2D

onready var moon = $Moon
onready var sun = $Sun
onready var camera = $Moon/Camera2D


func connect_astrobody_signals(astro_bodies: Array) -> void:
	for item in astro_bodies:
		var astro_body := item as AstroBody
		if astro_body:
			connect_astrobody_signals(astro_body.get_children())
			astro_body.connect("influence_entered", self, "on_influence_entered", [astro_body])
			astro_body.connect("influence_exited", self, "on_influence_exited", [astro_body])


func _ready() -> void:
	connect_astrobody_signals(sun.get_children())
	moon.parent_body = sun


func reparent_camera(to_node: Node2D) -> void:
	camera.get_parent().remove_child(camera)
	to_node.add_child(camera)


func on_influence_entered(node: AstroBody) -> void:
	moon.parent_body = node
	#reparent_camera(node)


func on_influence_exited(node: AstroBody) -> void:
	if moon.parent_body == node:
		moon.parent_body = sun
		#reparent_camera(moon)


func _on_Sun_sun_collided_with(area: Node2D) -> void:
	print("Game over!! ", area.name, " flew into the sun!")
