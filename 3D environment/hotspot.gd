extends Area

class_name hotspot
var ImageFilePath:String
var Identification:int = -1
var VRscene
var HotspotName:String
onready var DEFINED_COLOR = Color(0.01, 0.8, 0)
var IsInfospot:bool = false
enum stateMachine{
	STATE_FOCUS,
	STATE_UNFOCUS
}
var state:int = stateMachine.STATE_UNFOCUS
var description = "" setget set_description

var MaterialFocus:SpatialMaterial
var MaterialUnfocus:SpatialMaterial

#material do modelo 3d do hotspot
#func new_material(material:SpatialMaterial):
#	$MeshInstance.material_override = material
#define a imagem que vai usar, angulo em relação ao centro, etc
func set_hotspot(angle:Vector3, hotspot_name:String, id:int, vrsc, InfoSpot:bool = false)->void:
	HotspotName = hotspot_name
	$MeshInstance/Label3D.text = HotspotName
	rotation_degrees = angle
	Identification = id
	VRscene = vrsc
	IsInfospot = InfoSpot
	
	if not InfoSpot:
		MaterialFocus = ResourceLoader.load("res://3D environment/materials/HotspotFocus.tres")
		MaterialUnfocus = ResourceLoader.load("res://3D environment/materials/HotspotUnFocus.tres")
	else:
		MaterialFocus = ResourceLoader.load("res://3D environment/materials/InfospotFocus.tres")
		MaterialUnfocus = ResourceLoader.load("res://3D environment/materials/InfospotUnFocus.tres")

func press():#pressiona o hotspot
	if not IsInfospot: VRscene.ChangeLocation(HotspotName)
	else: 
		$Description.visible = true
		$Description/AnimationPlayer.play("movetex")

func define_color(modulate:Color):
	var material:SpatialMaterial = $MeshInstance.material_override
	DEFINED_COLOR = modulate
	material.emission = modulate
	material.albedo_color = modulate

func set_state(stt:int):
	state = stt
	if state == stateMachine.STATE_FOCUS:
		$MeshInstance.material_override = MaterialFocus
	elif state == stateMachine.STATE_UNFOCUS:
		$Description.visible = false
		$Description/AnimationPlayer.stop()
		$MeshInstance.material_override = MaterialUnfocus

func set_description(val:String):
	description = val
	$Description/Label3D.text = val
