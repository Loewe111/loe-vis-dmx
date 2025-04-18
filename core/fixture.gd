@tool
@icon("res://assets/icons/fixture.svg")
extends Node3D
class_name AdvancedFixture

@export_range(1, 512) var device_address: int = 1:
	set(value):
		device_address = value
		init()
@export var fixture_profile: FixtureProfile:
	set(value):
		fixture_profile = value
		init()

@export_tool_button("Update Fixture", "Reload") var update_profile = init

var dmx_data: Array[float] = []

var artnet
var fixture
var light
var light_surface
var axes

@onready var location: Location = get_tree().get_current_scene()

var _dimmer: float = 0.0
var _strobe: Dictionary = {
	"value": 0.0,
	"frequency": 0.0,
	"state": false,
	"time": 0.0
}
var _color: ExtendedColor = ExtendedColor.new()
var _pan: float = 0.0
var _tilt: float = 0.0
var _rotation: float = 0.0
var _gobo: Texture2D = null
var _fog: float = 0.0

var capabilities = {
	"color": false,
	"rgb": false,
	"color_changer": false,
	"moving_head": false,
	"rotation": false,
	"dimmer": false,
	"gobo": false,
	"strobe": false
}

func _ready() -> void:
	init()
	if Engine.is_editor_hint():
		return
	artnet = location.artnet
	artnet.dmx_data.connect(_on_art_net_dmx_data)

func _get_configuration_warnings():
	var warnings = []

	if fixture_profile == null:
		warnings.append("Fixture profile not configured")

	return warnings

func checkCapabilities() -> void:
	if fixture_profile == null:
		return

	capabilities = {
		"color": false,
		"rgb": false,
		"color_changer": false,
		"moving_head": false,
		"rotation": false,
		"dimmer": false,
		"gobo": false,
		"strobe": false
	}
	for channel in fixture_profile.dmx_channels:
		if (channel == FixtureProfile.DMXChannelType.COLOR_RED or 
			channel == FixtureProfile.DMXChannelType.COLOR_GREEN or 
			channel == FixtureProfile.DMXChannelType.COLOR_BLUE or 
			channel == FixtureProfile.DMXChannelType.COLOR_WHITE):
			capabilities["color"] = true
			capabilities["rgb"] = true
		elif (channel == FixtureProfile.DMXChannelType.COLOR_WHEEL):
			capabilities["color"] = true
			capabilities["color_changer"] = true
		elif (channel == FixtureProfile.DMXChannelType.PAN_FINE or 
			channel == FixtureProfile.DMXChannelType.TILT_FINE):
			capabilities["moving_head"] = true
		elif (channel == FixtureProfile.DMXChannelType.PAN or 
			channel == FixtureProfile.DMXChannelType.TILT):
			capabilities["moving_head"] = true
		elif (channel == FixtureProfile.DMXChannelType.ROTATION):
			capabilities["rotation"] = true
		elif (channel == FixtureProfile.DMXChannelType.GOBO):
			capabilities["gobo"] = true
		elif (channel == FixtureProfile.DMXChannelType.STROBE):
			capabilities["strobe"] = true
		elif (channel == FixtureProfile.DMXChannelType.DIMMER):
			capabilities["dimmer"] = true

func init() -> void:
	if not is_inside_tree():
		return

	update_configuration_warnings()
	# Remove all children
	for child in get_children():
		child.queue_free()

	if fixture_profile == null:
		return

	if Engine.is_editor_hint():
		var text = Label3D.new()
		text.text = "%s\nAddress: %d" % [fixture_profile.name, device_address]
		text.billboard = true
		text.position = Vector3(0, 0.3, 0)
		text.no_depth_test = true
		add_child(text)

	checkCapabilities()

	fixture = null
	if (fixture_profile.fixture_type == FixtureProfile.FixtureType.DIMMER or 
		fixture_profile.fixture_type == FixtureProfile.FixtureType.COLOR_CHANGER):
		fixture = load("res://fixtures/types/par.tscn").instantiate()
	elif fixture_profile.fixture_type == FixtureProfile.FixtureType.MOVING_HEAD:
		fixture = load("res://fixtures/types/moving_head.tscn").instantiate()
	elif fixture_profile.fixture_type == FixtureProfile.FixtureType.FLOWER:
		fixture = load("res://fixtures/types/flower.tscn").instantiate()
	elif fixture_profile.fixture_type == FixtureProfile.FixtureType.STROBE:
		fixture = load("res://fixtures/types/strobe.tscn").instantiate()
	elif fixture_profile.fixture_type == FixtureProfile.FixtureType.BAR:
		fixture = load("res://fixtures/types/bar.tscn").instantiate()
	

	if fixture != null:
		add_child(fixture)
		light = fixture.find_child("light")
		light_surface = fixture.find_child("light_surface")

		light.spot_angle = fixture_profile.beam_angle
		if not capabilities["color"]:
			light.light_color = fixture_profile.colorFilter
		light.light_energy = fixture_profile.brightness / 10.0
		light.spot_attenuation = 2.0 - fixture_profile.beam_focus * 2.0

	if not Engine.is_editor_hint():
		_update_axes()

func _update_axes():
	axes = get_tree().get_nodes_in_group("axis")
	# filter out the axes that are not children of this node
	axes = axes.filter(func(a): return is_ancestor_of(a))

func _set_axis(id: String, value: float) -> void:
	if axes.size() == 0:
		return

	for axis in axes:
		if axis.axis_id == id:
			axis.value = value
			return
	
	push_warning("Axis %d not found" % id)

func _get_axis(id: String) -> float:
	if axes.size() == 0:
		return 0

	for axis in axes:
		if axis.axis_id == id:
			return axis.value
	
	push_warning("Axis %d not found" % id)
	return 0

func _get_channel_value(data: Array, channel: FixtureProfile.DMXChannelType):
	if fixture_profile == null:
		print_debug("Fixture profile is null")
		return 0

	var channel_index = fixture_profile.dmx_channels.find(channel)
	if channel_index == -1:
		# push_warning("Attempting to access a channel that does not exist in the fixture profile: %s" % channel)
		return 0

	if data.size() <= device_address + channel_index - 1:
		return 0

	return data[device_address + channel_index - 1] # DMX data is 1-indexed, so we need to subtract 1

func _on_art_net_dmx_data(data: Array[int], scaled_data: Array[float]) -> void:
	dmx_data = scaled_data

	if fixture_profile == null:
		push_warning("Fixture profile not configured")
		artnet.dmx_data.disconnect(_on_art_net_dmx_data) # Disconnect to avoid spam
		return

	if capabilities["rgb"]:
		_color.color = Color(0, 0, 0)
		if fixture_profile.has_channel(FixtureProfile.DMXChannelType.COLOR_RED):
			_color.red = _get_channel_value(data, FixtureProfile.DMXChannelType.COLOR_RED)
		if fixture_profile.has_channel(FixtureProfile.DMXChannelType.COLOR_GREEN):
			_color.green = _get_channel_value(data, FixtureProfile.DMXChannelType.COLOR_GREEN)
		if fixture_profile.has_channel(FixtureProfile.DMXChannelType.COLOR_BLUE):
			_color.blue = _get_channel_value(data, FixtureProfile.DMXChannelType.COLOR_BLUE)
		if fixture_profile.has_channel(FixtureProfile.DMXChannelType.COLOR_WHITE):
			_color.white = _get_channel_value(data, FixtureProfile.DMXChannelType.COLOR_WHITE)

	elif capabilities["color_changer"]:
		var color_index = _get_channel_value(data, FixtureProfile.DMXChannelType.COLOR_WHEEL)
		_color.color = fixture_profile.colorWheel.getColor(color_index)

	else:
		_color.color = fixture_profile.colorFilter

	if capabilities["dimmer"]:
		_dimmer = _get_channel_value(scaled_data, FixtureProfile.DMXChannelType.DIMMER)
	else:
		_dimmer = 1.0

	if capabilities["moving_head"]:
		var pan = _get_channel_value(data, FixtureProfile.DMXChannelType.PAN)
		var pan_fine = _get_channel_value(data, FixtureProfile.DMXChannelType.PAN_FINE)
		_pan = ((pan << 8) | pan_fine) / 65535.0
		_pan = _pan * fixture_profile.pan_range - fixture_profile.pan_offset

		var tilt = _get_channel_value(data, FixtureProfile.DMXChannelType.TILT)
		var tilt_fine = _get_channel_value(data, FixtureProfile.DMXChannelType.TILT_FINE)
		_tilt = ((tilt << 8) | tilt_fine) / 65535.0
		_tilt = _tilt * fixture_profile.tilt_range - fixture_profile.tilt_offset

	if capabilities["gobo"]:
		var gobo_index = _get_channel_value(data, FixtureProfile.DMXChannelType.GOBO)
		_gobo = fixture_profile.goboWheel.getGobo(gobo_index)

	if fixture_profile.has_channel(FixtureProfile.DMXChannelType.STROBE):
		_strobe["value"] = _get_channel_value(scaled_data, FixtureProfile.DMXChannelType.STROBE)

	update()

func update() -> void:
	if fixture == null:
		return

	if fixture_profile.has_channel(FixtureProfile.DMXChannelType.STROBE):
		if _strobe["value"] == 0:
			_strobe["state"] = false
		_strobe["frequency"] = lerp(0.0, 30.0, _strobe["value"])

	var light_surface_color = Color(0, 0, 0)
	if not _strobe["state"]:
		light.light_energy = _dimmer * fixture_profile.brightness / 10.0
		light.light_color = _color.color
		light_surface_color = _color.color * _dimmer
	else:
		light.light_energy = 0.0
		light.light_color = Color(0, 0, 0)
		light_surface_color = Color(0, 0, 0)

	if light_surface != null:
		var base_material: Material = light_surface.get_surface_override_material(0)
		if base_material:
			var unique_material: Material = base_material.duplicate(true)
			unique_material.albedo_color = light_surface_color
			unique_material.emission = light_surface_color
			light_surface.set_surface_override_material(0, unique_material)
		else:
			push_warning("No base material found for fixture surface")

	if capabilities["gobo"]:
		light.light_projector = _gobo
	
	if capabilities["moving_head"]:
		_set_axis("pan", _pan)
		_set_axis("tilt", _tilt)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if capabilities["rotation"]:
		var r = _get_axis("rotation")
		r += delta * _get_channel_value(dmx_data, FixtureProfile.DMXChannelType.ROTATION) * 25
		_set_axis("rotation", r) 

	if _strobe["frequency"] > 0:
		_strobe["time"] += delta
		if _strobe["time"] >= 1.0 / _strobe["frequency"]:
			_strobe["state"] = !_strobe["state"]
			_strobe["time"] = 0.0
			update()
