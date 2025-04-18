@icon("res://assets/icons/fixture_profile.svg")
class_name FixtureProfile
extends Resource

@export_group("General")

@export var manufacturer: String
@export var name: String
@export var description: String

enum FixtureType {
	DIMMER = 0x00,
	COLOR_CHANGER = 0x01,
	STROBE = 0x02,
	BAR = 0x03,
	MOVING_HEAD_SPOT = 0x10,
	MOVING_HEAD_WASH = 0x11,
	MOVING_HEAD_BEAM = 0x12,
	SPIDER = 0x13,
	FLOWER = 0x20,
	FOGGER = 0x30,
}

@export var fixture_type: FixtureType = FixtureType.COLOR_CHANGER

@export_subgroup("Physical")

@export var pan_range: int
@export var pan_offset: int
@export var tilt_range: int
@export var tilt_offset: int

@export_group("DMX Channels")

enum DMXChannelType {
	NONE = 0x00,
	DIMMER = 0x01,
	STROBE = 0x02,
	COLOR_WHEEL = 0x10,
	COLOR_RED = 0x11,
	COLOR_GREEN = 0x12,
	COLOR_BLUE = 0x13,
	COLOR_WHITE = 0x14,
	COLOR_AMBER = 0x15,
	COLOR_UV = 0x16,
	PAN = 0x20,
	PAN_FINE = 0x21,
	TILT = 0x22,
	TILT_FINE = 0x23,
	ROTATION = 0x24,
	GOBO = 0x30,
	FOG = 0x40,
	SPECIAL = 0x41,
}

@export var dmx_channels: Array[DMXChannelType] 

@export_group("Light Properties")

@export var brightness: int = 100
@export var beam_angle: int = 10
@export_range(0, 1, 0.01) var beam_focus: float = 0.0

## If the fixture does not have a Color Changer Channel
@export var colorFilter: Color = Color(1, 1, 1)

## If the fixture has a Color Wheel Channel
@export var colorWheel: ColorWheel
## If the fixture has a Gobo Wheel Channel
@export var goboWheel: GoboWheel

func has_channel(channel: DMXChannelType) -> bool:
	return dmx_channels.has(channel)
