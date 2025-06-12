extends Area

class_name hotspot
var ImageFilePath:String
var Identification:int = -1
var VRscene
var HotspotName:String
onready var DEFINED_COLOR = Color(0.01, 0.8, 0)
#material do modelo 3d do hotspot
func new_material(material:SpatialMaterial):
	$MeshInstance.material_override = material
#define a imagem que vai usar, angulo em relação ao centro, etc
func set_hotspot(angle:Vector3, hotspot_name:String, id:int, vrsc)->void:
	HotspotName = hotspot_name
	$MeshInstance/Label3D.text = HotspotName
	rotation_degrees = angle
	Identification = id
	VRscene = vrsc

func press():#pressiona o hotspot
	VRscene.ChangeLocation(HotspotName)

func define_color(modulate:Color):
	var material:SpatialMaterial = $MeshInstance.material_override
	DEFINED_COLOR = modulate
	material.emission = modulate
	material.albedo_color = modulate
