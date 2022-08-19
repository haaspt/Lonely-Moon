extends Node2D

export var debug: bool = true
export var camera_lean_amount: float = 10.0

var camera_focus: Vector2
var player_start_pos: Vector2
var root_influence: InfluenceBody
var current_influence: InfluenceBody setget set_current_influence
var Moon := preload("res://Scenes/Moon.tscn")
var death_label_lookup := {
	"sun": "Ouch! You flew into the sun!",
	"space": "Oh no! You flew off into deep space!",
	"planet": "Ooph! You crashed into a planet too many times!"
}
var default_zoom := Vector2(1.5, 1.5)
var max_zoom := Vector2(4.5, 4.5)
onready var moon = $Moon
onready var sun = $Sun
onready var camera = $Camera2D
onready var death_label = $HUD/DeathLabel


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
	if get_node_or_null("Moon"):
		var active_astro_body := moon.parent_body as AstroBody
		if active_astro_body:
			var vector_towards_body: Vector2 = (active_astro_body.global_position - moon.global_position).normalized()
			camera_focus = moon.global_position + (vector_towards_body * camera_lean_amount)
		else:
			camera_focus = moon.global_position


func reset_player_pos() -> void:
	if not get_node_or_null("Moon"):
		moon = Moon.instance()
		self.add_child(moon)
		moon.parent_body = current_influence.body
	moon.global_position = player_start_pos
	moon.move_vec = moon.initial_vel
	camera.global_position = player_start_pos
	camera_focus = player_start_pos
	death_label.visible = false


func set_current_influence(influence_body: InfluenceBody) -> void:
	current_influence = influence_body
	moon.parent_body = current_influence.body
	if debug:
		print("Current influencing body: ", influence_body.body.name)


func _ready() -> void:
	if not debug:
		$HUD/DebugLabel.call_deferred("free")
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
	if get_node_or_null("Moon"):
		var dist_to_sun: float = (sun.global_position - moon.global_position).length()
		if dist_to_sun >= 12000:
			kill_player("space")
			if debug:
				"Game over!! Flew into deep space!"
	if Input.is_action_just_pressed("ui_reset"):
		reset_player_pos()
	if Input.is_action_just_pressed("ui_accept"):
		var tween: SceneTreeTween = get_tree().create_tween()
		tween.tween_property($Camera2D, "zoom", max_zoom, 0.5)
	if Input.is_action_just_released("ui_accept"):
		var tween: SceneTreeTween = get_tree().create_tween()
		tween.tween_property($Camera2D, "zoom", default_zoom, 0.5)
	if debug:
		if get_node_or_null("Moon"):
			var debug_string := ""
			debug_string += "Vel: " + str(round(moon.move_vec.length())) + "\n"
			debug_string += (
				"Dist. to Sun: "
				+ str(round((sun.global_position - moon.global_position).length()))
				+ "\n"
			)
			debug_string += "Act. Bod.: " + str(current_influence.body.name) + "\n"
			debug_string += "Hit Pts.: " + str(moon.hit_points)
			$HUD/DebugLabel.text = debug_string


func kill_player(cause: String) -> void:
	moon.call_deferred("free")
	var cause_str: String = death_label_lookup[cause]
	cause_str += "\n\nPress 'R' to try again!"
	death_label.text = cause_str
	death_label.visible = true


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
	moon.dec_hit_points()
	if debug:
		print("Collided with planet: ", planet.name)


func _on_Sun_sun_collided_with(area: Node2D) -> void:
	kill_player("sun")
	if debug:
		print("Game over!! ", area.name, " flew into the sun!")


func _on_Moon_hitpoints_exhausted() -> void:
	kill_player("planet")
