extends Spatial
#usa o script GlobalLoad
onready var GlobalL = get_node("/root/GlobalLoad")
onready var Locations = get_node("/root/Locations")
var LocationInfo:Dictionary
export var current_location:int
class_name vrscene

#var MaterialFocus:SpatialMaterial
#var MaterialUnfocus:SpatialMaterial
var raycast:RayCast
var flatagent
var targeted_location:int = -1
const MB:int = 1024*1024

var Step2Deletion:Array = []

var AsyncHPnames:Array = []
var AsyncImages:Array = []
var AsyncHotspots:Array = []
var AsyncInfospots:Array = []
var AsyncIds:Array = []

func AddAsyncInformation(
		ImageTex:ImageTexture, 
		HPName:String, 
		Hotspots:Dictionary, 
		Infospots:Dictionary, 
		Identification:int, 
		step:int = 2
	)->void:
	var arr_index = AsyncIds.find(Identification)
	if arr_index == -1:
		AsyncImages.append(ImageTex)
		AsyncHPnames.append(HPName)
		AsyncHotspots.append(Hotspots)
		AsyncInfospots.append(Infospots)
		AsyncIds.append(Identification)
		
		Step2Deletion.append(step)
	else:
		Step2Deletion[arr_index] = 4

func ReduceSteps() -> void:
	var offset:int = 0
	for i in range(Step2Deletion.size()):
		Step2Deletion[i-offset]-=1
		if Step2Deletion[i-offset] <= 0:
			Step2Deletion.remove(i)
			AsyncHPnames.remove(i)
			AsyncImages.remove(i)
			AsyncHotspots.remove(i)
			AsyncInfospots.remove(i)
			AsyncIds.remove(i)
			offset+=1

#função semelhante ao main do C
func _ready():#inicia a cena e verifica se irá usar vr, não vr, etc
#	MaterialFocus = ResourceLoader.load("res://3D environment/materials/HotspotFocus.tres")
#	MaterialUnfocus = ResourceLoader.load("res://3D environment/materials/HotspotUnFocus.tres")
	print(OS.get_user_data_dir())
	AddAgent()
	yield(get_tree().create_timer(3), "timeout")
	ChangeLocation(0, true)
	get_viewport().connect("size_changed", self, "UpdateScreen")
	UpdateScreen()

func UpdateScreen() -> void:
	var window_size = get_viewport().size

#função chamada no _ready e pelos hotspots para trocar de ambiente
#essa função apenas muda a variável targeted_location, se o número do ambiente
#estiver registrado localmente, a função LoadEnvironment é chamada
func ChangeLocation(id:int, forceload:bool = false) -> void:#carrega as informações do hotspot
	targeted_location = id
	$LocalDB.carregar_dados(id)
func _on_LocalDB_dados_carregados(data, identification):
	LoadEnvironment(
		data["textura"],
		data["adjacentes"],
		{},
		identification
	)
#	if forceload:
#		$Supa.RequestCurrentEnvironment(id, true)
#	elif AsyncIds.find(id) != -1:
#		var index = AsyncIds.find(id)
#		var Tex = AsyncImages[index]
#		var DictionaryButtons = AsyncHotspots[index]
#		var DictionaryInfospots = AsyncInfospots[index]
#		LoadEnvironment(Tex, DictionaryButtons, DictionaryInfospots, id)

func VectorFromArray3(list:Array)->Vector3:
	var v:Vector3 = Vector3(list[0], list[1], list[2])
	return v

func _on_Supa_current_env_loaded(information, forceload_image):
	
	LoadEnvironment(information["texture"], information["Hotspots"], information["Infospots"], information["id"])

#função pra carregar o ambiente atual e carregar os adjacentes de forma
#assíncrona
func LoadEnvironment(EnvImage:ImageTexture, NewButtons:Dictionary, Infospots:Dictionary, id:int):
#	print("carregado id: %d" % id, Infospots)
	if has_node("Agent"):
		get_node("Agent").lock()
	for i in $Hotspots.get_child_count():
		$Hotspots.get_child(i).queue_free()
	
	AddAsyncInformation(EnvImage, "", NewButtons, Infospots, id, 4)
	
	var texture:ImageTexture = EnvImage
	var Panorama:PanoramaSky = PanoramaSky.new()
	Panorama.panorama = texture
	$WorldEnvironment.environment.background_sky = Panorama
	var Hotspots_info = NewButtons
#	var new_adjacents:Array = []
	for i in Hotspots_info:
		var HTPscn:PackedScene = ResourceLoader.load("res://3D environment/Hotspot.tscn")
		var hot:hotspot = HTPscn.instance()
		var index = Hotspots_info[i]
		var TableId:int = str2var(i)
		$Hotspots.add_child(hot)
		hot.set_hotspot(
			VectorFromArray3(index[1]),
			index[0],
			TableId,
			self,
			false
		)
		
#		var id_index = AsyncIds.find(TableId)
#
#		if TableId != current_location:
#			if id_index == -1:
#				new_adjacents.append(TableId)
#			elif Step2Deletion[id_index] <= 1:
#				Step2Deletion[id_index] = 2
	
	for i in Infospots:
		var HTPscn:PackedScene = ResourceLoader.load("res://3D environment/Hotspot.tscn")
		var hot:hotspot = HTPscn.instance()
		var index = Infospots[i]
		
		$Hotspots.add_child(hot)
		
		hot.set_hotspot(
			VectorFromArray3(index[0]),
			"",
			str2var(i),
			self,
			true
		)
		hot.set_description(index[2])
	
	current_location = id
	targeted_location = -1
#	if new_adjacents.size() > 0: 
#		$Supa.GetEnvironmentRows(new_adjacents)
	if has_node("Agent"):
		if get_node("Agent").has_method("SetRaycastAgain"):
			get_node("Agent").SetRaycastAgain(raycast)
		else:
			get_node("Agent").unlock()
#	ReduceSteps()

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
	GlobalL.VerifyXR()
	var useVR: bool = GlobalL.ActivateXR()
	if useVR:
		var packed_vr: PackedScene = load("res://Agents/XRAgent.scn")
		var agent_vr = packed_vr.instance()
		add_child(agent_vr)
	else:
		raycast = generate_ray()
		add_child(raycast)
		var packed_flat: PackedScene = load("res://Agents/flat_agent.scn")
		var agent_flat:flat_agent = packed_flat.instance()
		agent_flat.RayCastInUse = raycast
		raycast.enabled = true
		add_child(agent_flat)

#adiciona localmente o ambiente adjacente que foi carregado,
#caso o targeted_location for diferente de -1, a função LoadEnvironment é chamada
func _on_Supa_async_env_loaded(information):
	if targeted_location != -1 and targeted_location == information["id"]:
		call_deferred(
			"LoadEnvironment",
			information["texture"], 
			information["Hotspots"], 
			information["Infospots"],
			information["id"]
		)
	else:
		AddAsyncInformation(
				information["texture"], 
				"", 
				information["Hotspots"],
				information["Infospots"],
				information["id"]
		)

#função de retorno de erro do supa que eu não usei ainda
func _on_Supa_error_on_loading_buffer():
	pass # Replace with function body.
