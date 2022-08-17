extends Node2D

export var speed := 10
export var rotation_speed := 10
var parent_body: Node2D
var move_vec := Vector2.ZERO


func _process(delta: float) -> void:
	if Input.is_action_pressed("ui_up"):
		move_vec += Vector2.UP
	if Input.is_action_pressed("ui_down"):
		move_vec += Vector2.DOWN
	if Input.is_action_pressed("ui_left"):
		move_vec += Vector2.LEFT
	if Input.is_action_pressed("ui_right"):
		move_vec += Vector2.RIGHT
	#move_vec = move_vec.normalized()
	if parent_body:
		move_vec += calc_grav_accel(delta)
	global_position = global_position + move_vec * speed * delta
	rotation_degrees = rotation_degrees + rotation_speed * delta


func calc_grav_accel(delta: float) -> Vector2:
	var parent_pos := parent_body.global_position
	var to_parent_vec := parent_pos - self.global_position
	var r := to_parent_vec.length()
	var accel_vector := to_parent_vec.normalized()
	var grav_accel: float = Globals.GRAVITATIONAL_CONSTANT * parent_body.body_mass / pow(r, 2)
	accel_vector *= grav_accel
	return accel_vector
