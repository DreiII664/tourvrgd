extends ARVROrigin
const JOY_AXIS_TRIGGER:int = 2
const JOY_AXIS_GRIP:int = 3
var materialnovo:SpatialMaterial
var FocusedHotspot:hotspot
var PressedHotspot:bool = false
onready var VRscene = get_parent()
onready var ControlLeft:ARVRController = $ControllerLeft
var PressedListLeft:Array = []
onready var ControlRight:ARVRController = $ControllerRight
var PressedListRight:Array = []
func _ready():
	materialnovo = SpatialMaterial.new()
	materialnovo.albedo_color = Color(0,1,0)
	ControlRight

var multiplier:int = 0

func _input(event):
	var t = $ControllerLeft.get_joystick_axis(2)
	$ControllerLeft/Label3D.text = str(t)
	
	var t2 = $ControllerRight.get_joystick_axis(2)
	$ControllerRight/Label3D.text = str(t2)

func UpdateLabel(label:Label3D, list:Array):
	var start = "["
	var end = "]"
	var empty = ""
	empty+= start+ " "
	for i in list:
		empty+= str(i) + " "
	empty+= end
	label.text = empty

func _on_ControllerLeft_button_pressed(button):
	if FocusedHotspot and button == 0: PressedHotspot = true
func _on_ControllerLeft_button_release(button):
	if button == 0 and PressedHotspot and FocusedHotspot:
		FocusedHotspot.press()

func _on_ControllerRight_button_pressed(button):
	if FocusedHotspot and button == 0: PressedHotspot = true
func _on_ControllerRight_button_release(button):
	if button == 0 and PressedHotspot and FocusedHotspot:
		FocusedHotspot.press()


func _on_PointArea_area_entered(area):
	if FocusedHotspot != null:
		FocusedHotspot.new_material(VRscene.MaterialUnfocus)
	FocusedHotspot = area
	FocusedHotspot.new_material(VRscene.MaterialFocus)
func _on_PointArea_area_exited(area):
	if FocusedHotspot == area:
		FocusedHotspot.new_material(VRscene.MaterialUnfocus)
		FocusedHotspot = null
