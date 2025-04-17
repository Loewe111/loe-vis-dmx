extends Control

@onready var artnetInfo: Label = get_node("Artnet")
@onready var locationInfo: Label = get_node("Location")
@onready var performanceInfo: Label = get_node("Performance")

@onready var location: Location = get_tree().get_current_scene()

func _ready():
	locationInfo.text = location.location_name
	
	location.artnet.dmx_info.connect(_on_art_net_dmx_info)

func _process(_delta):
	var fps = Engine.get_frames_per_second()
	performanceInfo.text = "%s FPS" % fps

func _on_art_net_dmx_info(framerate):
	artnetInfo.text = "ArtNet: %s FPS" % framerate
