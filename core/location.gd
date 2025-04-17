@tool
@icon("res://assets/icons/location.svg")
extends Node3D
class_name Location

@export_group("General")
@export var location_name: String = name:
	set(value):
		location_name = value
		name = value # Change the node name in the scene tree
@export var description: String = ""

@export_group("Environment")
@export var fog_density: float = 0.05:
	set(value):
		fog_density = value
		update_fog()


@export_group("")
@export var artnet: ArtNet
@export var camera: Camera

@export_tool_button("Update all Fixtures", "Reload") var update_all_fixtures_button = update_all_fixtures
# Functions

func _ready() -> void:
	# Initialize the location
	if artnet == null:
		var children = get_children()
		# try to find a ArtNet node
		for child in children:
			if child is ArtNet:
				artnet = child
				break
		if artnet == null: # if no ArtNet node was found, create a new one
			artnet = ArtNet.new()
			add_child(artnet)
			artnet.owner = self
	
	if camera == null:
		var children = get_children()
		# try to find a camera node
		for child in children:
			if child is Camera:
				camera = child
				break
		if camera == null: # if no Camera node was found, create a new one
			camera = Camera.new()
			camera.environment = load("res://core/show_environment.tres").duplicate()
			camera.position = Vector3(0, 2, 0)
			add_child(camera)
			# camera.owner = self
	
	# Add overlay
	var overlay = load("res://core/overlay.tscn").instantiate()
	add_child(overlay)

	update_fog()


func update_fog() -> void:
	if not is_inside_tree():
		return
	
	var env = camera.environment

	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = fog_density

func update_all_fixtures() -> void:
	# Update all fixtures in the location
	var children = get_children()
	for child in children:
		if child is AdvancedFixture:
			child.init()