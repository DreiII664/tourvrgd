extends Spatial
#usa o script GlobalLoad
onready var GlobalL = get_node("/root/GlobalLoad")
onready var Locations = get_node("/root/Locations")
var LocationInfo:Dictionary
export var current_location:String
class_name vrscene

#var MaterialFocus:SpatialMaterial
#var MaterialUnfocus:SpatialMaterial

var flatagent

const MB:int = 1024*1024

var processingResponses:int = 0
var AsyncImagesNames = []
var AsyncImages = []
var AsyncHotspots = []
var AsyncInfospots = []
func AddAsyncInformation(ImageBuffer:PoolByteArray, ImageName:String, Hotspots:Dictionary, Infospots:Dictionary):
	AsyncImages.append(ImageBuffer)
	AsyncImagesNames.append(ImageName)
	AsyncHotspots.append(Hotspots)
	AsyncInfospots.append(Infospots)

func _ready():#inicia a cena e verifica se irá usar vr, não vr, etc
#	MaterialFocus = ResourceLoader.load("res://3D environment/materials/HotspotFocus.tres")
#	MaterialUnfocus = ResourceLoader.load("res://3D environment/materials/HotspotUnFocus.tres")
	ChangeLocation(current_location)
	AddAgent()

var targeted_location:String

func ChangeLocation(locName:String):#carrega as informações do hotspot
	targeted_location = locName
	if AsyncImagesNames.find(locName) != -1:
		var index = AsyncImagesNames.find(locName)
		var Bytes = AsyncImages[index]
		var DictionaryButtons = AsyncHotspots[index]
		var DictionaryInfospots = AsyncInfospots[index]
		LoadEnvironment(Bytes, DictionaryButtons, DictionaryInfospots)
	else:
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
		var NewButtons = JSON.parse(
			FSfields.get_field("Hotspots", FSfields.FIELD_STRING)
		).result
		var NewInfospots = JSON.parse(
			FSfields.get_field("Infospots", FSfields.FIELD_STRING)
		).result
		LoadEnvironment(BytesArray, NewButtons, NewInfospots)
	

func LoadEnvironment(EnvImage:PoolByteArray, NewButtons:Dictionary, Infospots:Dictionary):
	if has_node("Agent"):
		get_node("Agent").FocusedHotspot = null
	
	if AsyncImagesNames.find(targeted_location) == -1:
		AddAsyncInformation(EnvImage, targeted_location, NewButtons, Infospots)
	targeted_location = ""
	
	for i in $Hotspots.get_child_count():
		$Hotspots.get_child(i).queue_free()
	
	var panorama_texture:ImageTexture = get_panorama_from_buffer(EnvImage)
	var pano = PanoramaSky.new()
	pano.panorama = panorama_texture
	$WorldEnvironment.environment.background_sky = pano
	
	var Doclist = []
	for i in NewButtons:#carrega hotspots par outras áreas
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
		button.set_state(button.stateMachine.STATE_UNFOCUS)
		Doclist.append(hotspotName)
	for i in Infospots:
		var button_packed: PackedScene = load("res://3D environment/Hotspot.tscn")
		var button:hotspot = button_packed.instance()
		$Hotspots.add_child(button)
		var specific_info = Infospots[i]
		var VecArray = specific_info[0]
		var hotspotName = specific_info[1]
		var description = specific_info[2]
		var angle = VectorFromArray3(VecArray)
		button.set_hotspot(
			angle,
			hotspotName,
			str2var(i),
			self,
			true
		)
		button.description = description
		button.set_state(button.stateMachine.STATE_UNFOCUS)
	LoadAsynchronous(Doclist)

func LoadAsynchronous(DocList:Array):#recebe uma lista de nomes de documentos
	var AsyncListNode = Node.new()
	AsyncListNode.name = "Asyncs"
	if !has_node("Asyncs"): add_child(AsyncListNode)
	var Collection:String = $Database.COLL_ENVIRONMENTS+"/"
	var headers = $Database.HEADER
	for i in DocList:
		if AsyncImagesNames.find(i) == -1:
			processingResponses+=1
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
	processingResponses-=1
	if processingResponses < 0: processingResponses = 0
	var async_count = Asyncs.get_child_count()
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
		var buttoninfospots:Dictionary = JSON.parse(
			fields.get_field("Infospots", fields.FIELD_STRING)
		).result
		if AsyncImagesNames.find(DocName) == -1:
			AddAsyncInformation(AsyncBytes, DocName, buttonhotspots, buttoninfospots)
		
		if DocName == targeted_location:
			var index = AsyncImagesNames.find(DocName)
			var Bytes = AsyncImages[index]
			var DictionaryButtons = AsyncHotspots[index]
			var DictionaryInfos = AsyncInfospots[index]
			LoadEnvironment(Bytes, DictionaryButtons, DictionaryInfos)
	if processingResponses == 0:
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
		return tex
	tex.create_from_image(image, Texture.FLAG_REPEAT | ImageTexture.FLAG_FILTER)
	tex.set_flags(tex.get_flags() & ~Texture.FLAG_MIPMAPS)
	return tex

func VectorFromArray3(list:Array)->Vector3:
	var v:Vector3 = Vector3(list[0], list[1], list[2])
	return v
