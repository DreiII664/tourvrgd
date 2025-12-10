extends Area

class_name hotspot
var ImageFilePath:String
var Identification:int = -1
var VRscene
var HotspotName:String
onready var DEFINED_COLOR = Color(0.01, 0.8, 0)
var agent_rotation:float = 0
var IsInfospot:bool = false
enum stateMachine{
	STATE_FOCUS,
	STATE_UNFOCUS,
	EDIT_MODE
}
var state:int = stateMachine.STATE_UNFOCUS
var description = "" setget set_description

var PAGE_SIZE:int = 810
var pages = []
var current_page:int = 0
var MaterialFocus:SpatialMaterial
var MaterialUnfocus:SpatialMaterial
var MaterialEditMode:SpatialMaterial

func ShadeNodes():
	$MeshInstance.material_override.set("emission_enabled", false)
	$MeshInstance/Sprite3D/Label3D.shaded = true
	$MeshInstance/Sprite3D.shaded = true
#define a imagem que vai usar, angulo em relação ao centro e outras informações do
#hotspot
func set_hotspot(angle:Vector3, hotspot_name:String, id:int, vrsc, InfoSpot:bool, agent_angle:float = 0)->void:
	add_to_group("Spots")
	HotspotName = hotspot_name
	$MeshInstance/Sprite3D/Label3D.text = HotspotName
	if hotspot_name.length() == 0:
		$MeshInstance/Sprite3D.visible = false
	else:
		var text_size:int = HotspotName.length()
		var box_heigth_mp:int = (text_size/20)+1
		if text_size != 0 and box_heigth_mp != 0:
			$MeshInstance/Sprite3D.texture.height = box_heigth_mp*24-6*box_heigth_mp
			if box_heigth_mp == 1:
				$MeshInstance/Sprite3D.texture.width = 10*text_size
			else:
				$MeshInstance/Sprite3D.texture.width = 235
	$MeshInstance/id.text = str(id)
	rotation_degrees = angle
	Identification = id
	VRscene = vrsc
	IsInfospot = InfoSpot
	$MeshInstance.global_rotation.z = 0
	agent_rotation = agent_angle
	randomize()
	$MeshInstance/Sprite3D.modulate = Color(
		0.45*randf(), 
		0.45*randf(), 
		0.45*randf())
	
	MaterialEditMode = ResourceLoader.load("res://3D environment/materials/HotspotEditMode.tres")
	if not InfoSpot:
		$Description.queue_free()
		MaterialFocus = ResourceLoader.load("res://3D environment/materials/HotspotFocus.tres")
		MaterialUnfocus = ResourceLoader.load("res://3D environment/materials/HotspotUnFocus.tres")
	else:
		MaterialFocus = ResourceLoader.load("res://3D environment/materials/InfospotFocus.tres")
		MaterialUnfocus = ResourceLoader.load("res://3D environment/materials/InfospotUnFocus.tres")
	call_deferred("set_state", stateMachine.STATE_UNFOCUS)

func set_as_blur(angle:Vector3, strech:Vector3):
	if strech.x == 0 or strech.y == 0 or strech.z == 0:
		queue_free()
		return
	rotation_degrees = angle
	monitorable = false
	$CollisionShape.disabled = true
	var newmesh := SphereMesh.new() 
	$MeshInstance/id.visible = false
	newmesh.radius = 0.4
	newmesh.height = 0.8
	newmesh.radial_segments = 9
	newmesh.rings = 8
	$MeshInstance.mesh = newmesh
	$Description/close_description/CollisionShape.disabled = true
	$MeshInstance.scale = strech
	$MeshInstance/Sprite3D.visible = false
	var material_blur:SpatialMaterial = ResourceLoader.load(
		"res://3D environment/materials/Blur.tres"
	)
	$MeshInstance.set_surface_material(0, material_blur)
#	$MeshInstance.material_override = material_blur

func press(ReturnText:bool = false):#pressiona o hotspot
	if not IsInfospot: 
		VRscene.ChangeLocation(Identification, agent_rotation)
		return null
	else:
		if ReturnText:
			return description
		$Description.visible = true
		$Description/close_description.monitorable = true
		$Description/close_description/CollisionShape.disabled = false
		
		$Description/PageChange/Next.monitorable = true
		$Description/PageChange/Next/CollisionShape.disabled = false
		$Description/PageChange/Back.monitorable = true
		$Description/PageChange/Back/CollisionShape.disabled = false
		
		if pages.size() == 1:
			$Description/PageChange/Next/CollisionShape.disabled = true
			$Description/PageChange/Back/CollisionShape.disabled = true
			$Description/PageChange/Next/Label.visible = false
			$Description/PageChange/Back/Label.visible = false

func adjust_angle(reference:Spatial):
	look_at(reference.global_position, Vector3.UP)

func define_color(modulate:Color):
	var material:SpatialMaterial = $MeshInstance.material_override
	DEFINED_COLOR = modulate
	material.emission = modulate
	material.albedo_color = modulate

func set_state(stt:int):
	state = stt
	call("_state_"+str(state))

func _state_0():
	$MeshInstance.set("material_override", MaterialFocus)
func _state_1():
	$MeshInstance.set("material_override", MaterialUnfocus)
func _state_2():
	$MeshInstance.set("material_override", MaterialEditMode)

func set_description(val:String):
	description = val
	var description_lenght = val.length()
	var total_pages:int = description_lenght/PAGE_SIZE+1
	var remaining := val
	var re_lenght := remaining.length()
	var pointer:int = 0
	for i in range(total_pages):
		var last_from_piece:int = pointer+PAGE_SIZE
		if last_from_piece >= re_lenght:
			last_from_piece = re_lenght-1
		var piece:String = remaining.substr(pointer, last_from_piece)
		var pc_lenght:int = piece.length()
		if !piece.ends_with(" ") and i < total_pages-1:
			piece+="..."
		
		pages.append(piece)
		pointer+=PAGE_SIZE
		
	$Description/Label3D.text = pages[0]

func _on_close_description_close_pressed():
	$Description.visible = false
	$Description/close_description.monitorable = false
	$Description/close_description/CollisionShape.disabled = true
	
	$Description/PageChange/Next.monitorable = false
	$Description/PageChange/Next/CollisionShape.disabled = true
	$Description/PageChange/Back.monitorable = false
	$Description/PageChange/Back/CollisionShape.disabled = true

func ChangePage(amount:int):
	var target_page = current_page+amount
	if target_page >= 0 and target_page < pages.size():
		current_page = target_page
		$Description/Label3D.text = pages[current_page]

func _on_Back_page_button_pressed():
	ChangePage(-1)


func _on_Next_page_button_pressed():
	ChangePage(1)
