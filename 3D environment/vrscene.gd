extends Spatial
#usa o script GlobalLoad
onready var GlobalL = get_node("/root/GlobalLoad")
onready var Locations = get_node("/root/Locations")
var LocationInfo:Dictionary
export var current_location:String
class_name vrscene

var MaterialFocus:SpatialMaterial
var MaterialUnfocus:SpatialMaterial

var flatagent

const MB:int = 1024*1024

var AsyncImagesNames = []
var AsyncImages = []
var AsyncHotspots = []

func _ready():#inicia a cena e verifica se irá usar vr, não vr, etc
	MaterialFocus = ResourceLoader.load("res://3D environment/materials/HotspotFocus.tres")
	MaterialUnfocus = ResourceLoader.load("res://3D environment/materials/HotspotUnFocus.tres")
	ChangeLocation(current_location, true)
	AddAgent()

var targeted_location:String

func ChangeLocation(locName:String, ForceLoad:bool = false):#carrega as informações do hotspot
	if has_node("Agent"):get_node("Agent").FocusedHotspot = null
	targeted_location = locName
	if locName in AsyncImagesNames:
		var index = AsyncImagesNames.find(locName)
		var Bytes = AsyncImages[index]
		var DictionaryButtons = AsyncHotspots[index]
		LoadEnvironment(Bytes, DictionaryButtons)
	elif ForceLoad:
		$ChangeLocationRequest.request(
			$Database.COLL_ENVIRONMENTS+"/"+locName,
			$Database.HEADER,
			true,
			HTTPClient.METHOD_GET
		)
func _on_ChangeLocationRequest_request_completed(_result, response_code, _headers, body:PoolByteArray):
	if response_code == 200:
		var FSfields = FirestoreFields.new()
		FSfields.init_firestore_fields(body)
		LocationInfo = FSfields.get_full_fields()
		var BytesArray:PoolByteArray = JSON.parse(
			FSfields.get_field("buffer", FSfields.FIELD_STRING)).result
#		print(LocationInfo)
		var NewButtons = JSON.parse(
			FSfields.get_field("Hotspots", FSfields.FIELD_STRING)
		).result
		LoadEnvironment(BytesArray, NewButtons)
	else:
		print("error %d ocurred" % response_code)
		print(body.get_string_from_ascii())

func LoadEnvironment(EnvImage:PoolByteArray, NewButtons:Dictionary):
	targeted_location = ""
	for i in $Hotspots.get_child_count():
		$Hotspots.get_child(i).queue_free()
	
	var panorama_texture:ImageTexture = get_panorama_from_buffer(EnvImage)
	var pano = PanoramaSky.new()
	pano.panorama = panorama_texture
	$WorldEnvironment.environment.background_sky = pano
	
	var Doclist = []
	for i in NewButtons:
		var button_packed: PackedScene = load("res://3D environment/Hotspot.tscn")
		var button:hotspot = button_packed.instance()
		$Hotspots.add_child(button)
		var specific_info = NewButtons[i]
		var VecArray = specific_info[0]
		var hotspotName = specific_info[1]
		var angle = VectorFromArray3(VecArray)
		button.set_hotspot(
			angle,
			hotspotName,
			str2var(i),
			self
		)
		button.new_material(MaterialUnfocus)
		Doclist.append(hotspotName)
	LoadAsynchronous(Doclist)

var AsyncResponses = 0
func LoadAsynchronous(DocList:Array):#recebe uma lista de nomes de documentos
	AsyncResponses = 0
	AsyncImagesNames = []
	AsyncImages = []
	AsyncHotspots = []
	var AsyncListNode = Node.new()
	add_child(AsyncListNode)
	AsyncListNode.name = "Asyncs"
	var Collection:String = $Database.COLL_ENVIRONMENTS+"/"
	var headers = $Database.HEADER
	for i in DocList:
		var AsyncRequest = HTTPRequest.new()
		AsyncListNode.add_child(AsyncRequest)
		var ImageLink = Collection+i
		AsyncRequest.connect("request_completed", self, "_AsyncRequest_response")
		AsyncRequest.request(
			ImageLink,
			headers,
			true,
			HTTPClient.METHOD_GET
		)
func _AsyncRequest_response(_result, response_code, _headers, body:PoolByteArray):
	var Asyncs = get_node("Asyncs")
	var async_count = Asyncs.get_child_count()
	AsyncResponses+=1
	if response_code == 200:
		var fields = FirestoreFields.new()
		fields.init_firestore_fields(body)
		var AsyncBytes = JSON.parse(
			fields.get_field("buffer", fields.FIELD_STRING)
		).result
		var DocName = fields.get_field("DocName", fields.FIELD_STRING)
		var buttonhotspots:Dictionary = JSON.parse(
			fields.get_field("Hotspots", fields.FIELD_STRING)
		).result
		if not DocName in AsyncImagesNames:
			AsyncImagesNames.append(DocName)
			AsyncImages.append(AsyncBytes)
			AsyncHotspots.append(buttonhotspots)
		
		if DocName == targeted_location:
			var index = AsyncImagesNames.find(DocName)
			var Bytes = AsyncImages[index]
			var DictionaryButtons = AsyncHotspots[index]
			LoadEnvironment(Bytes, DictionaryButtons)
			print("carregamento assincrono feito para: ", DocName)
	if AsyncResponses>=async_count:
		Asyncs.call_deferred("queue_free")

func generate_ray() -> RayCast:
	var r = RayCast.new()
	r.collide_with_areas = true
	r.collide_with_bodies = true
	r.set_collision_mask_bit(0, true)
	return r

func _on_Timer_timeout():
	var agent = get_node("Agent")
	if agent is ARVROrigin:
		var coords = agent.get_node("ARVRCamera").global_position
		$Hotspots.global_position = coords

func AddAgent():
	var useVR: bool = GlobalL.GetParam(0)
	if useVR:
		var packed_vr: PackedScene = load("res://Agents/XRAgent.scn")
		var agent_vr = packed_vr.instance()
		add_child(agent_vr)
	else:
		var ray = generate_ray()
		add_child(ray)
		var packed_flat: PackedScene = load("res://Agents/flat_agent.scn")
		var agent_flat:flat_agent = packed_flat.instance()
		agent_flat.RayCastInUse = ray
		ray.enabled = true
		add_child(agent_flat)

func get_panorama_from_buffer(buffer:PoolByteArray) -> ImageTexture:
	var image = Image.new()
	var e = image.load_jpg_from_buffer(buffer)
	var tex := ImageTexture.new()
	if e != OK:
		print("image panorama not loaded")
		return tex
	tex.create_from_image(image, Texture.FLAG_REPEAT | ImageTexture.FLAG_FILTER)
	tex.set_flags(tex.get_flags() & ~Texture.FLAG_MIPMAPS)
	return tex

func VectorFromArray3(list:Array)->Vector3:
	var v:Vector3 = Vector3(list[0], list[1], list[2])
	return v
