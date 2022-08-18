extends Node2D

export var debug: bool = true

var camera_focus: Vector2
var player_start_pos: Vector2
var root_influence: InfluenceBody
var current_influence: InfluenceBody setget set_current_influence

onready var moon = $Moon
onready var sun = $Sun
onready var camera = $Camera2D


class InfluenceBody:
	var parent_body: InfluenceBody
	var body: Node2D
	var child_body: InfluenceBody

	func _init(
		init_body: Node2D,
		init_parent_body: InfluenceBody = null,
		init_child_body: InfluenceBody = null
	):
		self.parent_body = init_parent_body
		self.body = init_body
		self.child_body = init_child_body


func connect_astrobody_signals(astro_bodies: Array) -> void:
	for item in astro_bodies:
		var astro_body := item as AstroBody
		if astro_body:
			connect_astrobody_signals(astro_body.get_children())  # recursive search
			astro_body.connect("influence_entered", self, "on_influence_entered", [astro_body])
			astro_body.connect("influence_exited", self, "on_influence_exited", [astro_body])
			astro_body.connect("radius_collided", self, "on_planet_collided_with", [astro_body])


func update_camera_focus() -> void:
	var active_astro_body := moon.parent_body as AstroBody
	if active_astro_body:
		# Set camera focus to midpoint between player and active influence
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


func set_current_influence(influence_body: InfluenceBody) -> void:
	current_influence = influence_body
	moon.parent_body = current_influence.body
	if debug:
		print("Current influencing body: ", influence_body.body.name)


func _ready() -> void:
	connect_astrobody_signals(sun.get_children())
	player_start_pos = moon.global_position
	moon.parent_body = sun
	update_camera_focus()
	root_influence = InfluenceBody.new(sun)
	set_current_influence(root_influence)
	$Music.play()


func _process(_delta: float) -> void:
	update_camera_focus()
	camera.global_position = lerp(camera.global_position, camera_focus, 0.25)
	if debug:
		if Input.is_action_just_pressed("ui_reset"):
			reset_player_pos()


func get_node_hierarchy() -> Array:
	var all_nodes_found := false
	var node_list := []
	var current_node := root_influence
	while not all_nodes_found:
		var node_info := {
			"body": current_node.body.name,
			"parent": current_node.parent_body.body.name if current_node.parent_body else null,
			"child": current_node.child_body.body.name if current_node.child_body else null,
		}
		node_list.append(node_info)
		if not current_node.child_body:
			all_nodes_found = true
		else:
			current_node = current_node.child_body
	return node_list


func find_influence_body(node_to_find: Node) -> InfluenceBody:
	var is_node_found := false
	var current_body: InfluenceBody = root_influence
	while not is_node_found:
		if current_body.body == node_to_find:
			is_node_found = true
		else:
			if current_body.child_body:
				current_body = current_body.child_body
				continue
			else:
				current_body = null
				break
	return current_body


func add_influence_body(body_to_add: Node) -> InfluenceBody:
	var new_influence_body := InfluenceBody.new(body_to_add)
	new_influence_body.parent_body = current_influence
	current_influence.child_body = new_influence_body
	set_current_influence(new_influence_body)
	if debug:
		print(get_node_hierarchy())
	return new_influence_body


func remove_influence_body(node_to_remove: Node) -> void:
	var body_to_remove := find_influence_body(node_to_remove)
	if body_to_remove:
		if body_to_remove.child_body:
			body_to_remove.parent_body.child_body = body_to_remove.child_body
			body_to_remove.child_body.parent_body = body_to_remove.parent_body
		else:
			body_to_remove.parent_body.child_body = null
		if current_influence == body_to_remove:
			set_current_influence(body_to_remove.parent_body)
		body_to_remove.call_deferred("free")
		if debug:
			print(get_node_hierarchy())
	else:
		if debug:
			print("Error! Could not find node in hierarchy: ", node_to_remove)


func on_influence_entered(node: AstroBody) -> void:
	add_influence_body(node)


func on_influence_exited(node: AstroBody) -> void:
	remove_influence_body(node)


func on_planet_collided_with(planet: AstroBody) -> void:
	moon.bounce_off_planet(planet)
	if debug:
		print("Collided with planet: ", planet.name)


func _on_Sun_sun_collided_with(area: Node2D) -> void:
	if debug:
		print("Game over!! ", area.name, " flew into the sun!")
