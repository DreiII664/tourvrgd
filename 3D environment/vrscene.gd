extends Spatial
#usa o script GlobalLoad
onready var GlobalL = get_node("/root/GlobalLoad")
onready var Locations = get_node("/root/Locations")
var LocationInfo:Dictionary
export var current_location:int
export var tamanho_tour_estimado:float = 500
class_name vrscene
#var MaterialFocus:SpatialMaterial
#var MaterialUnfocus:SpatialMaterial
var raycast:RayCast
var flatagent
var targeted_location:int = -1
var targeted_angle:float = 0
var alignHotspots:FuncRef

var loaderThread := Thread.new()

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

func GenerateScenesData(envs:Directory):
	$Aviso.visible = true
	envs.make_dir(GlobalLoad.ROOT_PATH_ENVIRONMENTS)
	var copybasescn:PackedScene = ResourceLoader.load("res://custom_class/SceneCopy.scn")
	var copybase:Node = copybasescn.instance()
	add_child(copybase)
	copybase.connect("carregamento_completo", self, "alterar_texto")
	copybase.connect("tudo_carregado", self, "sair")
	copybase.fetch_from_jsonbd()
	var loadingMaterial:SpatialMaterial = ResourceLoader.load("res://3D environment/materials/LoadingSpace.tres")
	$MeshInstance.material_override = loadingMaterial
	if $AnimationPlayer.is_playing(): $AnimationPlayer.stop()
	$WorldEnvironment.environment.background_energy = 1
	$MeshInstance.rotation = Vector3(0, 0, 0)
	if $Agent.has_method("total_lock"):
		$Agent.total_lock()
	if $Agent is ARVROrigin:
		$Aviso.global_position = $Agent/ARVRCamera.global_position
	for i in $Hotspots.get_child_count():
		$Hotspots.get_child(i).queue_free()

#função semelhante ao main do C
func _ready():#inicia a cena e verifica se irá usar vr, não vr, etc
	AddAgent()
	get_viewport().connect("size_changed", self, "UpdateScreen")
	UpdateScreen()
	if OS.has_feature("Android"):
		if OS.get_granted_permissions().size() < 4:
			OS.request_permissions()
			yield(get_tree().create_timer(6), "timeout")
	
	print(OS.get_user_data_dir())
	var envs := Directory.new()
	if !envs.dir_exists(GlobalLoad.ROOT_PATH_ENVIRONMENTS):
		GenerateScenesData(envs)
	else:
		ChangeLocation(current_location, 90)

func sair():
	get_tree().quit()

var totalbaixado:float = 0
func alterar_texto(cena_atual:int, cenas:int, mb_loaded:float):
	totalbaixado+= mb_loaded
	$Aviso/Label3D.text = "cenas baixadas: "+str(cena_atual)+"/"+str(cenas)+"\n %.2f MB/ ~%.2f MB"%[totalbaixado, tamanho_tour_estimado]

func UpdateScreen() -> void:
	var window_size = get_viewport().size

func _process(delta):
	
	if alignHotspots != null: 
		alignHotspots.call_func()

#função chamada no _ready e pelos hotspots para trocar de ambiente
#essa função apenas muda a variável targeted_location, se o número do ambiente
#estiver registrado localmente, a função LoadEnvironment é chamada
func ReloadLocation(angle:float):
	ChangeLocation(current_location, angle)

func ChangeLocation(id:int, agent_angle = null) -> void:
	targeted_location = id
	if agent_angle != null: targeted_angle = agent_angle
	#get_tree().call_group("Spots", "ShadeNodes")
	get_node("Agent").lock()
	$AnimationPlayer.play("fadein")
	if !loaderThread.is_alive(): loaderThread.wait_to_finish()
	loaderThread = Thread.new()
	loaderThread.start($LocalDB, "carregar_dados", id)
	#$LocalDB.carregar_dados(id, false)
	
	if $AnimationPlayer.is_playing():
		yield($AnimationPlayer, "animation_finished")
	#$LocalDB.fetch_data("cenas", 2)
func _on_LocalDB_dados_carregados(data, identification):
	
	if !loaderThread.is_alive(): loaderThread.wait_to_finish()
	
	call_deferred(
		"LoadEnvironment",
		data["textura"],
		data["adjacentes"],
		data["infospots"],
		identification,
		data["scene_properties"]
	)
	if get_node("Agent").has_method("SetRaycastAgain"):
		get_node("Agent").SetRaycastAgain(raycast)
	else:
		get_node("Agent").unlock()
	$AnimationPlayer.play("fadeout")
func _on_LocalDB_dados_carregados_nuvem(cena:SceneProperties):
	call_deferred(
		"LoadEnvironment",
		cena.Panorama,
		{},
		{},
		cena.id,
		{"pitch": cena.entrada_pitch, "yaw":cena.entrada_yaw, "roll":cena.entrada_roll}
	)
	print("deu")
	$AnimationPlayer.play("fadeout")

func VectorFromArray3(list:Array)->Vector3:
	var v:Vector3 = Vector3(list[0], list[1], list[2])
	return v

func VectorFromArray2(list:Array)->Vector2:
	var v:Vector2 = Vector2(list[0], list[1])
	return v

#função pra carregar o ambiente atual e carregar os adjacentes de forma
#assíncrona
func LoadEnvironment(
	EnvImage:ImageTexture, 
	NewButtons:Dictionary, 
	Infospots:Dictionary, 
	id:int,
	ScnProperties:Dictionary
	):
	
	for i in $Hotspots.get_child_count():
		$Hotspots.get_child(i).queue_free()
#	AddAsyncInformation(EnvImage, "", NewButtons, Infospots, id, 4)
	$MeshInstance.rotation_degrees = Vector3(180, 270, 0)
	var js_rotations = Vector3(
		0,#x
		ScnProperties["yaw"],#y
		0#z
	)
	print(js_rotations)
	$MeshInstance.rotation_degrees += js_rotations
	
	var texture:ImageTexture = EnvImage
	var Mat := SpatialMaterial.new()
#	Mat.albedo_color = Color(0,0,0)
	Mat.flags_unshaded = false
	Mat.flags_do_not_receive_shadows = true
	Mat.params_cull_mode = Material3D.CULL_DISABLED
	Mat.albedo_texture = texture
	$MeshInstance.material_override = Mat
	
#	var Panorama:PanoramaSky = PanoramaSky.new()
#	Panorama.radiance_size = Sky.RADIANCE_SIZE_64
#	Panorama.panorama = texture
#	$WorldEnvironment.environment.background_sky = Panorama
	
	var Hotspots_info = NewButtons
#	var new_adjacents:Array = []
	for i in Hotspots_info:
		var HTPscn:PackedScene = ResourceLoader.load("res://3D environment/Hotspot.tscn")
		var hot:hotspot = HTPscn.instance()
		var index = Hotspots_info[i]
		var TableId:int = str2var(i)
		$Hotspots.add_child(hot)
		hot.call_deferred("set_hotspot",
			VectorFromArray3(index[0]),
			index[1],
			TableId,
			self,
			false
		)
#		hot.adjust_angle($Agent)
	
	current_location = id
	targeted_location = -1
	if has_node("Agent"):
		if get_node("Agent").has_method("SetRaycastAgain"):
			get_node("Agent").SetRaycastAgain(raycast)
		else:
			get_node("Agent").unlock()

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
		var index = Infospots[i]#lista de infos do hotspot atual

		$Hotspots.add_child(hot)

		hot.set_hotspot(
			VectorFromArray3(index[0]),
			i,
			-1,
			self,
			true
		)
		hot.set_description(index[1])

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

func AlignHotspots():
	$Hotspots.global_position = $Agent/ARVRCamera.global_position
	$MeshInstance.global_position = $Agent/ARVRCamera.global_position

func AddAgent():
	var verify:bool = GlobalL.VerifyXR()
	var useVR: bool = false
	if verify:
		useVR = GlobalL.ActivateXR()
	if useVR:
		var packed_vr: PackedScene = load("res://Agents/XRAgent.scn")
		var agent_vr = packed_vr.instance()
		add_child(agent_vr)
		alignHotspots = funcref(self, "AlignHotspots")
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


func _on_LocalDB_error_loading_image():
	var dir = Directory.new()
	dir.remove(GlobalLoad.ROOT_PATH_ENVIRONMENTS)
	$Aviso/Label3D2.text = "houve um problema ao carregar imagens,\ntentando baixar novamente.\nNão saia do aplicativo"
	GenerateScenesData(dir)
