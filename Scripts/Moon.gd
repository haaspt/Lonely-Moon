extends Node2D

signal hitpoints_exhausted

const BOUNCE_FORCE = 1.025
const GRAVITY_SCALE_EFFECT = 7.5

export var speed := 10
export var rotation_speed := 10
export var total_hit_points: int = 4
var parent_body: Node2D
var initial_vel := Vector2.LEFT * 50
var move_vec := initial_vel
var sprite_shaking := false
var hit_points: int setget set_hit_points
onready var sprite := $Sprite
onready var sprite_default_pos: Vector2 = sprite.position


func _ready() -> void:
	set_hit_points(total_hit_points)


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
		move_vec += calc_grav_accel() * GRAVITY_SCALE_EFFECT
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
	if move_vec.length() < 100:
		# Prevent player from falling through the planet surface
		move_vec = move_vec.normalized() * 220
	shake_sprite()


func dec_hit_points() -> void:
	set_hit_points(hit_points - 1)


func inc_hit_points() -> void:
	set_hit_points(hit_points + 1)


func set_hit_points(new_points: int) -> void:
	hit_points = new_points
	if hit_points < total_hit_points:
		$HealthRegenTimer.start(4)
	var lerp_val := float(hit_points) / float(total_hit_points)
	var color := Color(1, lerp_val, lerp_val, 1)
	sprite.modulate = color
	if hit_points <= 0:
		emit_signal("hitpoints_exhausted")


func _on_ShakeTimer_timeout() -> void:
	sprite_shaking = false
	sprite.position = sprite_default_pos


func _on_HealthRegenTimer_timeout() -> void:
	if hit_points < total_hit_points:
		inc_hit_points()
	else:
		$HealthRegenTimer.stop()
