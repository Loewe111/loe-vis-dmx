@tool
extends Node3D
class_name Axis

enum AxisType {
	X,
	Y,
	Z
}

@export var axis_type: AxisType = AxisType.X
@export var axis_id: String = "axis"
@export var value: float:
	set(v):
		if value != v:
			value = v
			update()

func update():
	match axis_type:
		AxisType.X:
			rotation_degrees.x = value
		AxisType.Y:
			rotation_degrees.y = value
		AxisType.Z:
			rotation_degrees.z = value

func _ready():
	add_to_group("axis")