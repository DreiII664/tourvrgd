extends ARVROrigin
const JOY_AXIS_TRIGGER:int = 2
const JOY_AXIS_GRIP:int = 3
var materialnovo:SpatialMaterial

var FocusedHotspot:hotspot
var ControllerSelected:int = -1# left 0 / right 1

var not_locked:bool = true
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
	var t = ControlLeft.get_joystick_axis(2)
	$ControllerLeft/Label3D.text = str(t)
	
	var t2 = ControlRight.get_joystick_axis(2)
	$ControllerRight/Label3D.text = str(t2)
	
	if t > 0.6 and ControllerSelected == 0:
		if not_locked:
			if FocusedHotspot != null:
				FocusedHotspot.press()
	
	if t2 > 0.6 and ControllerSelected == 1:
		if not_locked:
			if FocusedHotspot != null:
				FocusedHotspot.press()

func lock():
	not_locked = false
	ControllerSelected = -1
	FocusedHotspot = null
	$ControllerLeft/PointAreaLeft.monitoring = false
	$ControllerRight/PointAreaRight.monitoring = false
	$ControllerLeft/PointArea.disconnect(
		"area_entered", 
		self, 
		"_on_PointArea_area_entered_left"
	)
	$ControllerRight/PointArea.disconnect(
		"area_entered", 
		self, 
		"_on_PointArea_area_entered_right"
	)
	
	$ControllerLeft/PointArea.disconnect(
		"area_exited", 
		self, 
		"_on_PointArea_area_exited_left"
	)
	$ControllerRight/PointArea.disconnect(
		"area_exited", 
		self, 
		"_on_PointArea_area_exited_right"
	)

func unlock():
	yield(get_tree().create_timer(0.5), "timeout")
	not_locked = true
	$ControllerLeft/PointArea.connect(
		"area_entered", 
		self, 
		"_on_PointArea_area_entered_left"
	)
	$ControllerRight/PointArea.connect(
		"area_entered", 
		self, 
		"_on_PointArea_area_entered_right"
	)
	
	$ControllerLeft/PointArea.connect(
		"area_exited", 
		self, 
		"_on_PointArea_area_exited_left"
	)
	$ControllerRight/PointArea.connect(
		"area_exited", 
		self, 
		"_on_PointArea_area_exited_right"
	)
	$ControllerLeft/PointAreaLeft.monitoring = true
	$ControllerRight/PointAreaRight.monitoring = true

func UpdateLabel(label:Label3D, list:Array):
	var start = "["
	var end = "]"
	var empty = ""
	empty+= start+ " "
	for i in list:
		empty+= str(i) + " "
	empty+= end
	label.text = empty


func _on_PointArea_area_entered_left(area):
	ControllerSelected = 0
	if FocusedHotspot != null:
		FocusedHotspot.set_state(FocusedHotspot.stateMachine.STATE_UNFOCUS)
	FocusedHotspot = area
	FocusedHotspot.set_state(FocusedHotspot.stateMachine.STATE_FOCUS)

func _on_PointArea_area_exited_left(area):
	if ControllerSelected == 0: ControllerSelected = -1
	if FocusedHotspot == area:
		FocusedHotspot.set_state(FocusedHotspot.stateMachine.STATE_UNFOCUS)
		FocusedHotspot = null

func _on_PointArea_area_entered_right(area):
	ControllerSelected = 1
	if FocusedHotspot != null:
		FocusedHotspot.set_state(FocusedHotspot.stateMachine.STATE_UNFOCUS)
	FocusedHotspot = area
	FocusedHotspot.set_state(FocusedHotspot.stateMachine.STATE_FOCUS)

func _on_PointArea_area_exited_right(area):
	if ControllerSelected == 1: ControllerSelected = -1
	if FocusedHotspot == area:
		FocusedHotspot.set_state(FocusedHotspot.stateMachine.STATE_UNFOCUS)
		FocusedHotspot = null
