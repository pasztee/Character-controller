
extends KinematicBody

var crouch_speed = 4
var speed = 7
var max_speed = 14
const ACCEL_DEFAULT = 7
const ACCEL_AIR = 1
onready var accel = ACCEL_DEFAULT
var gravity = 9.8
var jump = 5
var max_stamina = 200
var stamina = max_stamina
var sprint = false
var staminaPS = 1
var crouch = false
var cam_accel = 40
var mouse_sense = 0.2
var snap
var head_lvl = 0

var direction = Vector3()
var velocity = Vector3()
var gravity_vec = Vector3()
var movement = Vector3()

onready var head = $Rotation_Helper
onready var camera = $Rotation_Helper/Camera


signal staminaHUD(stm, max_stm)


func _ready():
	#hides the cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	
	#get mouse input for camera rotation
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(deg2rad(-event.relative.x * mouse_sense))
		head.rotate_x(deg2rad(-event.relative.y * mouse_sense))
		head.rotation.x = clamp(head.rotation.x, deg2rad(-89), deg2rad(89))
	
	#cursor snap
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _process(delta):
	
	#camera physics interpolation to reduce physics jitter on high refresh-rate monitors
	if Engine.get_frames_per_second() > Engine.iterations_per_second:
		camera.set_as_toplevel(true)
		camera.global_transform.origin = camera.global_transform.origin.linear_interpolate(head.global_transform.origin, cam_accel * delta)
		camera.rotation.y = rotation.y
		camera.rotation.x = head.rotation.x
	else:
		camera.set_as_toplevel(false)
		camera.global_transform = head.global_transform
	
	

func _physics_process(delta):
	
	#get keyboard input for walking
	direction = Vector3.ZERO
	var h_rot = global_transform.basis.get_euler().y
	var f_input = Input.get_action_strength("movement_backward") - Input.get_action_strength("movement_forward")
	var h_input = Input.get_action_strength("movement_right") - Input.get_action_strength("movement_left")
	direction = Vector3(h_input, 0, f_input).rotated(Vector3.UP, h_rot).normalized()
	
	#sprint
	if Input.is_action_pressed("movement_sprint") and crouch == false and is_on_floor():
		if stamina > 0:
			sprint = true
			stamina -= staminaPS
		else:
			sprint = false
	else:
		sprint = false
		if stamina < max_stamina and is_on_floor():
			stamina += staminaPS
	
	#crouch
	if Input.is_action_pressed("movement_crouch"):
		if crouch == false:
			head.global_translate(Vector3(0, -0.5, 0))
		crouch = true
	else:
		if crouch == true:
			head.global_translate(Vector3(0, 0.5, 0))
		crouch = false
	
	#jumping and gravity
	if is_on_floor():
		snap = -get_floor_normal()
		accel = ACCEL_DEFAULT
		gravity_vec = Vector3.ZERO
	else:
		snap = Vector3.DOWN
		accel = ACCEL_AIR
		gravity_vec += Vector3.DOWN * gravity * delta
		
	if Input.is_action_just_pressed("movement_jump") and is_on_floor() and crouch == false:
		snap = Vector3.ZERO
		gravity_vec = Vector3.UP * jump
	
	#make it move
	if sprint:
		velocity = velocity.linear_interpolate(direction * max_speed, accel * delta)
	elif crouch:
		velocity = velocity.linear_interpolate(direction * crouch_speed, accel * delta)
	else:
		velocity = velocity.linear_interpolate(direction * speed, accel * delta)
	movement = velocity + gravity_vec
	
	move_and_slide_with_snap(movement, snap, Vector3.UP)
	#print(stamina)
	#print(staminaPS)
	emit_signal("staminaHUD", stamina, max_stamina)
