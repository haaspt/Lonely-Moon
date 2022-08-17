extends Node2D

export var debug: bool = true

var camera_focus: Vector2
var player_start_pos: Vector2

onready var moon = $Moon
onready var sun = $Sun
onready var camera = $Camera2D


func connect_astrobody_signals(astro_bodies: Array) -> void:
	for item in astro_bodies:
		var astro_body := item as AstroBody
		if astro_body:
			connect_astrobody_signals(astro_body.get_children())
			astro_body.connect("influence_entered", self, "on_influence_entered", [astro_body])
			astro_body.connect("influence_exited", self, "on_influence_exited", [astro_body])


func update_camera_focus() -> void:
	var active_astro_body := moon.parent_body as AstroBody
	if active_astro_body:
		camera_focus = (
			moon.global_position
			+ (active_astro_body.global_position - moon.global_position) / 2
		)
	else:
		camera_focus = moon.global_position


func reset_player_pos() -> void:
	moon.global_position = player_start_pos
	moon.move_vec = Vector2.ZERO
	camera.global_position = player_start_pos
	camera_focus = player_start_pos


func _ready() -> void:
	connect_astrobody_signals(sun.get_children())
	player_start_pos = moon.global_position
	moon.parent_body = sun
	update_camera_focus()


func _process(_delta: float) -> void:
	update_camera_focus()
	camera.global_position = lerp(camera.global_position, camera_focus, 0.25)
	if debug:
		if Input.is_action_just_pressed("ui_reset"):
			reset_player_pos()


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
