extends Node
class_name ArtNet

## `data` contains ints from 0-255,
## `scaled_data` contains floats from 0-1
signal dmx_data(data, scaled_data)
signal dmx_info(framerate)

@export var listen_ip = "127.0.0.1"
@export var listen_port = 6454

var server := UDPServer.new()
var peers = []
var packet_count = 0
var time_elapsed = 0.0

func _init() -> void:
	name = "ArtNet"

func _ready():
	if Engine.is_editor_hint():
		return
	server.listen(listen_port, listen_ip)
	print("ArtNet: Listening on %s:%s" % [listen_ip, listen_port])

func _process(delta):
	if Engine.is_editor_hint(): # No idea why this runs in the editor
		return
	
	server.poll() # Important!
	if server.is_connection_available():
		var peer: PacketPeerUDP = server.take_connection()
		print("ArtNet: Accepted peer: %s:%s" % [peer.get_packet_ip(), peer.get_packet_port()])
		peers.append(peer)

	for i in range(0, peers.size()):
		var packet = peers[i].get_packet()
		if packet:
			handlePacket(packet)
			packet_count += 1

	# Calculate ArtNet Framerate
	time_elapsed += delta
	if time_elapsed >= 1:
		sendPacketRate()

func handlePacket(packet):
	var isArtnet = packet.slice(0,8).hex_encode() == "4172742d4e657400"
	if not isArtnet: return
	var dmx_buffer: Array[int]
	dmx_buffer.assign(Array(packet.slice(18)))
	var scaled_dmx_buffer: Array[float] = []
	for i in dmx_buffer.size():
		scaled_dmx_buffer.insert(i, dmx_buffer[i] / float(255))
	if dmx_buffer.size() < 512: return
	dmx_data.emit(dmx_buffer, scaled_dmx_buffer)
	
func sendPacketRate():
	@warning_ignore("integer_division")
	dmx_info.emit(packet_count / 1)
	time_elapsed -= 1
	packet_count = 0
