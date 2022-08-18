extends Node2D

const BOUNCE_FORCE = 1.025

export var speed := 10
export var rotation_speed := 10
var parent_body: Node2D
var move_vec := Vector2.ZERO
var sprite_shaking := false
onready var sprite := $Sprite
onready var sprite_default_pos: Vector2 = sprite.position


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
		move_vec += calc_grav_accel()
	global_position = global_position + move_vec * speed * delta
	rotation_degrees = rotation_degrees + rotation_speed * delta
	if sprite_shaking:
		sprite.position = sprite_default_pos + Vector2(rand_range(-5, 5), rand_range(-5, 5))


func calc_grav_accel() -> Vector2:
	var parent_pos := parent_body.global_position
	var to_parent_vec := parent_pos - self.global_position
	var r := to_parent_vec.length()
	var accel_vector := to_parent_vec.normalized()
	var grav_accel: float = Globals.GRAVITATIONAL_CONSTANT * parent_body.body_mass / pow(r, 2)
	accel_vector *= grav_accel
	return accel_vector


func shake_sprite() -> void:
	sprite_shaking = true
	$ShakeTimer.start()


func bounce_off_planet(planet: Node2D) -> void:
	var normal_vec := (self.global_position - planet.global_position).normalized()
	move_vec = move_vec.bounce(normal_vec) * BOUNCE_FORCE
	shake_sprite()


func _on_ShakeTimer_timeout() -> void:
	sprite_shaking = false
	sprite.position = sprite_default_pos
