extends Camera3D
class_name Camera

var move_speed = 5
var rotate_speed = 75

var t = 0
var dir = 1
var rotationEnabled = false
var startAngle = -20
var targetAngle = 20

@export var validPositions: Array[Vector3] = [
	Vector3(0, 2, 0),
]

var orbitPos = validPositions[0]

func _init() -> void:
	name = "Camera"

func rotate_camera_around_position(pos, distance, progress, sA, tA):
	# Define the rotation angle based on 't'
	var angle = PI * progress

	# Calculate the new position of the camera
	var new_x = pos.x + distance * cos(angle) 
	var new_y = pos.y
	var new_z = pos.z + distance * sin(angle)
	var new_position = Vector3(new_x, new_y, new_z)
	
	# Calculate the rotation of the camera
	progress = abs(progress - int(progress))
	var x_rotation = deg_to_rad(lerp(sA, tA, progress))
	var new_rotation = Vector3(x_rotation, 360-angle, 0)
	
	return [new_position, new_rotation]

func _process(delta):
	if Engine.is_editor_hint(): # No idea why this runs in the editor
		return

	if rotationEnabled:
		t = t + 0.05 * delta * dir
		var newPos = rotate_camera_around_position(orbitPos, 5, t, startAngle, targetAngle)
		position = newPos[0]
		rotation = newPos[1]
		
	if (t > 1 or t < -1) or Input.is_action_just_pressed("move_camera_skip"):
		dir = dir * -1
		t = 0
		orbitPos = validPositions[randi_range(0, len(validPositions)-1)]
		startAngle = randi_range(-35, 10)
		targetAngle = randi_range(-10, 35)
	
	# Movement
	var movement = Vector3()
	
	if Input.is_action_pressed("move_right"):
		movement.z += cos(rotation.y + PI/2)
		movement.x += sin(rotation.y + PI/2)
	if Input.is_action_pressed("move_left"):
		movement.z -= cos(rotation.y + PI/2)
		movement.x -= sin(rotation.y + PI/2)
	if Input.is_action_pressed("move_backward"):
		movement.z += cos(rotation.y)
		movement.x += sin(rotation.y)
	if Input.is_action_pressed("move_forward"):
		movement.z -= cos(rotation.y)
		movement.x -= sin(rotation.y)
	if Input.is_action_pressed("move_up"):
		movement.y += 1
	if Input.is_action_pressed("move_down"):
		movement.y -= 1
	
	movement = movement.normalized()
	
	position += movement * move_speed * delta
	
	# Rotation
	var rotation_vector = Vector3()
	
	if Input.is_action_pressed("rotate_left"):
		rotation_vector.y += 1
	if Input.is_action_pressed("rotate_right"):
		rotation_vector.y -= 1
	if Input.is_action_pressed("rotate_up"):
		rotation_vector.x += 1
	if Input.is_action_pressed("rotate_down"):
		rotation_vector.x -= 1
	
	rotation_degrees.y += rotation_vector.y * rotate_speed * delta
	rotation_degrees.x += rotation_vector.x * rotate_speed * delta
	
	rotation_degrees.x = clamp(rotation_degrees.x, -89.0, 89.0)
	
	if Input.is_action_just_pressed("move_camera"):
		rotationEnabled = !rotationEnabled
