@tool
class_name ExtendedColor
extends Resource

var _color: Color = Color(0, 0, 0)
@export var color: Color:
	get:
		return _color
	set(value):
		_color = value

		_red = value.r
		_green = value.g
		_blue = value.b
		_white = 0.0
		_amber = 0.0
		_uv = 0.0
		changed.emit()

var _red: float = 0.0
@export_range(0.0, 1.0) var red: float = 0.0:
	get:
		return _red
	set(value):
		_red = value
		_channel_update()

var _green: float = 0.0
@export_range(0.0, 1.0) var green: float = 0.0:
	get:
		return _green
	set(value):
		_green = value
		_channel_update()

var _blue: float = 0.0
@export_range(0.0, 1.0) var blue: float = 0.0:
	get:
		return _blue
	set(value):
		_blue = value
		_channel_update()

var _white: float = 0.0
@export_range(0.0, 1.0) var white: float = 0.0:
	get:
		return _white
	set(value):
		_white = value
		_channel_update()

var _amber: float = 0.0
@export_range(0.0, 1.0) var amber: float = 0.0:
	get:
		return _amber
	set(value):
		_amber = value
		_channel_update()

var _uv: float = 0.0
@export_range(0.0, 1.0) var uv: float = 0.0:
	get:
		return _uv
	set(value):
		_uv = value
		_channel_update()

func _channel_update() -> void:
	_multichannel_to_color()
	changed.emit()

func _multichannel_to_color() -> void:
	# convert RGBWAUV to RGB
	const r = Color(1, 0, 0)
	const g = Color(0, 1, 0)
	const b = Color(0, 0, 1)
	const w = Color(1, 1, 1)
	const a = Color(1, 0.5, 0)
	const u = Color(0.5, 0, 1)

	var clr = Color(0, 0, 0)
	clr += _red * r
	clr += _green * g
	clr += _blue * b
	clr += _white * w
	clr += _amber * a
	clr += _uv * u
	clr /= max(clr.r, clr.g, clr.b, 1)
	
	_color = clr