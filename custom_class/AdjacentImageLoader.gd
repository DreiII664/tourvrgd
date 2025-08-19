extends HTTPRequest

class_name AdjacentImageRequest
signal ImageLoaded(texture, new_info)
signal received_request(obj, body_req)
var identification = -1
var stored_information
var mutex:Mutex = Mutex.new()
var thread:Thread
signal finished_texture_threadload()
func _ready():
	connect("request_completed", self, "_on_request_completed")

func request_adjacent(link:String, Headers:PoolStringArray, secure:bool, Method:int, EnvInfo:Dictionary):
	
	identification = EnvInfo["id"]
	stored_information = EnvInfo
	request(
		link,
		Headers,
		secure,
		Method
	)

var adj_image:ImageTexture
func get_panorama_from_buffer(buffer:PoolByteArray) -> ImageTexture:
	mutex.lock()
	var image = Image.new()
	var e = image.load_jpg_from_buffer(buffer)
	var tex := ImageTexture.new()
	if e != OK:
		return tex
	tex.create_from_image(image, Texture.FLAG_REPEAT | ImageTexture.FLAG_FILTER)
	adj_image = tex
	stored_information["texture"] = tex
	emit_signal("ImageLoaded", tex, stored_information)
	mutex.unlock()
	return tex

func _on_request_completed(result, response_code, headers, body:PoolByteArray):
	emit_signal("received_request", self, body)
#	var tex:ImageTexture
#	if response_code:
#		thread = Thread.new()
#		thread.start(self, "get_panorama_from_buffer", body)
#		yield(self, "finished_texture_threadload")
#	tex = adj_image
#	stored_information["texture"] = tex
#	emit_signal("ImageLoaded", tex, stored_information)
#	call_deferred("queue_free")
