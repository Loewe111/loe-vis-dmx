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
var light
var axes
var color

@onready var location: Location = get_tree().get_current_scene()

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

	light = null
	if (fixture_profile.fixture_type == FixtureProfile.FixtureType.DIMMER or 
		fixture_profile.fixture_type == FixtureProfile.FixtureType.COLOR_CHANGER):
		light = load("res://fixtures/types/par.tscn").instantiate()
	elif fixture_profile.fixture_type == FixtureProfile.FixtureType.MOVING_HEAD:
		light = load("res://fixtures/types/moving_head.tscn").instantiate()
	elif fixture_profile.fixture_type == FixtureProfile.FixtureType.FLOWER:
		light = load("res://fixtures/types/flower.tscn").instantiate()
	elif fixture_profile.fixture_type == FixtureProfile.FixtureType.STROBE:
		light = load("res://fixtures/types/strobe.tscn").instantiate()
	elif fixture_profile.fixture_type == FixtureProfile.FixtureType.BAR:
		light = load("res://fixtures/types/bar.tscn").instantiate()
	

	if light != null:
		add_child(light)
		light.find_child("light").spot_angle = fixture_profile.beam_angle
		if not capabilities["color"]:
			light.find_child("light").light_color = fixture_profile.colorFilter
		light.find_child("light").light_energy = fixture_profile.brightness / 10.0
		light.find_child("light").spot_attenuation = 2.0 - fixture_profile.beam_focus * 2.0

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

func _rgbw_to_rgb(r: float, g: float, b: float, w: float) -> Color:
	var clr = Color(r+w, g+w, b+w)
	clr /= max(clr.r, clr.g, clr.b, 1)
	return clr

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
	
	color = fixture_profile.colorFilter

	if capabilities["rgb"]:
		color = _rgbw_to_rgb(
			_get_channel_value(scaled_data, FixtureProfile.DMXChannelType.COLOR_RED),
			_get_channel_value(scaled_data, FixtureProfile.DMXChannelType.COLOR_GREEN),
			_get_channel_value(scaled_data, FixtureProfile.DMXChannelType.COLOR_BLUE),
			_get_channel_value(scaled_data, FixtureProfile.DMXChannelType.COLOR_WHITE)
		)

	elif capabilities["color_changer"]:
		var color_index = _get_channel_value(data, FixtureProfile.DMXChannelType.COLOR_WHEEL)
		
		var colors: Dictionary[int, Color] = fixture_profile.colorWheel.colors
		var sorted_colors = colors.keys()
		sorted_colors.sort()

		for i in range(0, sorted_colors.size()):
			var color_value = sorted_colors[i]
			if i < sorted_colors.size() - 1:
				if color_index >= color_value and color_index < sorted_colors[i + 1]:
					color = colors[color_value]
					break
			else:
				if color_index >= color_value:
					color = colors[color_value]
					break

	light.find_child("light").light_color = color

	if capabilities["dimmer"]:
		light.find_child("light").light_energy = _get_channel_value(scaled_data, FixtureProfile.DMXChannelType.DIMMER) * fixture_profile.brightness / 10.0
		color = color * _get_channel_value(scaled_data, FixtureProfile.DMXChannelType.DIMMER)

	# Set Surface Color 
	var light_surface = light.find_child("light_surface")
	if light_surface != null:
		var base_material: Material = light_surface.get_surface_override_material(0)
		if base_material:
			# Create a duplicate to ensure this instance has its unique material
			var unique_material: Material = base_material.duplicate(true)
			unique_material.albedo_color = color
			unique_material.emission = color
			light_surface.set_surface_override_material(0, unique_material)
		else:
			push_warning("No base material found for light surface")

	if capabilities["moving_head"]:
		_set_axis("pan", _get_channel_value(scaled_data, FixtureProfile.DMXChannelType.PAN) * fixture_profile.pan_range - fixture_profile.pan_offset)
		_set_axis("tilt", _get_channel_value(scaled_data, FixtureProfile.DMXChannelType.TILT) * fixture_profile.tilt_range - fixture_profile.tilt_offset)

	if capabilities["gobo"]:
		var gobo_index = _get_channel_value(data, FixtureProfile.DMXChannelType.GOBO)
	
		var gobos: Dictionary[int, Texture2D] = fixture_profile.goboWheel.gobos 
		var sorted_gobos = gobos.keys()
		sorted_gobos.sort()

		for i in range(0, sorted_gobos.size()):
			var gobo_value = sorted_gobos[i]
			if i < sorted_gobos.size() - 1:
				if gobo_index >= gobo_value and gobo_index < sorted_gobos[i + 1]:
					light.find_child("light").light_projector = gobos[gobo_value]
					break
			else:
				if gobo_index >= gobo_value:
					light.find_child("light").light_projector = gobos[gobo_value]
					break

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if capabilities["rotation"]:
		var r = _get_axis("rotation")
		r += delta * _get_channel_value(dmx_data, FixtureProfile.DMXChannelType.ROTATION) * 25
		_set_axis("rotation", r) 
