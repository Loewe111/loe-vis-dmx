@icon("res://assets/icons/fixture_profile.svg")
class_name FixtureProfile
extends Resource

@export_group("General")

@export var manufacturer: String
@export var name: String
@export var description: String

enum FixtureType {
	COLOR_CHANGER,
	DIMMER,
	MOVING_HEAD,
	FLOWER,
	STROBE,
	BAR,
	SPIDER,
	FOGGER,
	LASER,
	MIRROR_BALL,
}

@export var fixture_type: FixtureType = FixtureType.COLOR_CHANGER

@export_subgroup("Physical")

@export var pan_range: int
@export var pan_offset: int
@export var tilt_range: int
@export var tilt_offset: int

@export_group("DMX Channels")

enum DMXChannelType {
	NONE,
	DIMMER,
	STROBE,
	COLOR_WHEEL,
	COLOR_RED,
	COLOR_GREEN,
	COLOR_BLUE,
	COLOR_WHITE,
	PAN,
	PAN_FINE,
	TILT,
	TILT_FINE,
	GOBO,
	FOG,
	SPECIAL,
	ROTATION,
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