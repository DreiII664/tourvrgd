extends Spatial
class_name flat_agent
var RayCastInUse:RayCast
var FocusedHotspot:hotspot
var close_button
var VRscene
var detect_inputs
onready var GlobalL = get_node("/root/GlobalLoad")
var GyroPath = "res://main/gyro_component/gyro_component.tscn"
onready var Gyroscope:GyroComponent
var neweuler = Vector3.ZERO
signal fadein_finished()
signal fadeout_finished()
var touch_screen = ["Android", "iPhone", "iPad", "iPod"]
var mobile_touch:bool = true
var InputStates:Array = ["InputStateEditing", "InputStateExploring", "LockedRaycast"]
var AgentInputState:FuncRef = funcref(self, InputStates[1])
var interpolateHotspotRot:FuncRef = null
var EditingInstance:int = -1
var vr_allowed_platform = [
	"Windows",
	"Quest", 
	"Oculus",
	"Macintosh",
	"Linux"
]
var vr_prohibited_platform = [
	"iPhone", 
	"iPad", 
	"iPod", 
	"Android"
]
var platform:String
func _ready():
	VRscene = get_parent()
	get_viewport().connect("size_changed", self, "WindowSizeChanged")
	platform = OS.get_name()
#	screenDebug(platform)
	WindowSizeChanged()
	set_process(false)
	var isMobile:bool = TestMobile()
	if !isMobile:
		$CanvasLayer/usegyro.visible = false
	else:
		$CanvasLayer/usegyro.visible = true
	var prohibited_vr = false

func screen_input(event):
	if event is InputEventScreenTouch:
		var mousePos = event.position
		MoveRaycast(mousePos)
		if FocusedHotspot:
			var t = FocusedHotspot.press(true)
			if t != null:
				$CanvasLayer/Description.visible = true
				mobile_touch = false
				$CanvasLayer/Description/ScrollContainer/Label.text = t
		if close_button != null:
			close_button.press_close()
	
	elif event is InputEventScreenDrag and mobile_touch:
		if FocusedHotspot != null: 
			FocusedHotspot.set_state(FocusedHotspot.stateMachine.STATE_UNFOCUS)
			FocusedHotspot = null
		moveCamera(event, 0.2)

var edit_focus := false
func InputStateEditing(event):
	if !edit_focus:
		if event is InputEventMouseMotion and Input.is_action_pressed("MouseLeft"):
			moveCamera(event, 0.2)
			RayCastInUse.cast_to = Vector3(0,0,0)

func InputStateExploring(event):
	if Input.is_action_just_pressed("MouseLeft") and FocusedHotspot:
		var t = FocusedHotspot.press(true)
		if t != null:
			$CanvasLayer/Description.visible = true
			$CanvasLayer/Description/ScrollContainer/Label.text = t
	
#	if Input.is_action_just_pressed("MouseRight") and FocusedHotspot:
#		FocusedHotspot._state_2()
#		$CanvasLayer/EditHotspotDialog.show()
#		SetStateEditing(true)
	
	if Input.is_action_just_pressed("MouseLeft") and close_button:
		if close_button != null:
			close_button.press_close()
	
	if event is InputEventMouseMotion and Input.is_action_pressed("MouseLeft"):
		moveCamera(event, 0.2)
		MoveRaycast(Vector2(0,0))
	elif event is InputEventMouseMotion:
		var mousePos = event.position
		MoveRaycast(mousePos)

var yaw:float = 0
func device_gyroscope(delta):
	var gyro_vector := Input.get_gravity()
	var roll = atan2(-gyro_vector.x, -gyro_vector.y)
	gyro_vector = gyro_vector.rotated(Vector3.FORWARD, -roll)
	var pitch = atan2(gyro_vector.z, -gyro_vector.y)
	
	var giroscopio = Input.get_gyroscope()
#	var fixed = FixRotation(gyro_vector.x, gyro_vector.y, gyro_vector.z)
	yaw += giroscopio.y * delta
	var fixed = Vector3(pitch, yaw, roll)
	screenDebugMultiple([
		"x: "+str(giroscopio.x),
		"y: "+str(giroscopio.y),
		"z: "+str(giroscopio.z),
		"converted",
		str(fixed[0]),
		str(fixed[1]),
		str(fixed[2])
	])
	$Camera.rotation = fixed
#	$Camera.rotation = Vector3(fixed.z, fixed.x, fixed.y)

func _process(delta):
	device_gyroscope(delta)
#	if interpolateHotspotRot != null:
#		interpolateHotspotRot.call_func()

func InterpolateHotspotRotation():
	var valX = $CanvasLayer/EditHotspotDialog/HBoxContainer/rotx/Rotation.value
	var valY = $CanvasLayer/EditHotspotDialog/HBoxContainer/roty/Rotation.value
	
	FocusedHotspot.rotation_degrees = lerp(
		FocusedHotspot.rotation_degrees, Vector3(valX, valY, 0), 0.01
	)

#reinicia os parametros do agent usados por outros objetos
func lock():
	RayCastInUse.cast_to = Vector3(0,0,0)
	FocusedHotspot = null
	RayCastInUse = null

func SetRaycastAgain(ray:RayCast): 
	RayCastInUse = ray
	$CanvasLayer/SelectAmb/current.text = str(VRscene.current_location)

func WindowSizeChanged():#função que recebe sinal de quando a tela mudad de tamanho
	var _viewport_size:Vector2 = get_viewport().size #tamanho da tela em um vetor2
	$CanvasLayer/blackScreen.margin_right = _viewport_size.x
	$CanvasLayer/blackScreen.margin_bottom = _viewport_size.y
	var Container_separation:int = _viewport_size.y - 100
	var inside:float = _viewport_size.x
	var mnimum = 650
	if touch_screen.find(platform) != -1:
		var dynamicfont:DynamicFont = DynamicFont.new()
		var font_data:DynamicFontData = load("res://Resource/Roboto-MediumItalic.ttf")
		dynamicfont.size = 60
		dynamicfont.font_data = font_data
		
		$CanvasLayer/Description/ScrollContainer/Label.set(
			"custom_fonts/font",
			dynamicfont
		)
	else:
		if _viewport_size.x > mnimum:
			inside = mnimum
	
#	$CanvasLayer/EditHotspotDialog.rect_position = Vector2(
#		_viewport_size.x/2,
#		_viewport_size.y/2
#	)
	
	$CanvasLayer/Description.global_position.x = _viewport_size.x/2
	$CanvasLayer/Description.global_position.y = _viewport_size.y/2
	$CanvasLayer/Description/Sprite2D.texture.height = _viewport_size.y
	$CanvasLayer/Description/Sprite2D.texture.width = inside/5
	
	$CanvasLayer/Description/ScrollContainer.rect_size.x = inside*0.9
	$CanvasLayer/Description/ScrollContainer.rect_size.y = _viewport_size.y * 0.8
	$CanvasLayer/Description/ScrollContainer.rect_position.x = -(inside/2)
	$CanvasLayer/Description/ScrollContainer.rect_position.y = -(_viewport_size.y*0.45)
	
	$CanvasLayer/Description/close.rect_position.y = -(_viewport_size.y/2)
	if touch_screen.find(platform) == -1:
		if _viewport_size.x > mnimum:
			$CanvasLayer/Description/close.rect_position.x = inside/2-30
		else:
			$CanvasLayer/Description/close.rect_position.x = inside/2-60
	else:
		$CanvasLayer/Description/close.rect_position.x = inside/2-120
		$CanvasLayer/Description/close.rect_scale = Vector2(2, 2)

func _input(event):#detecta as entradas (teclado, mouse ou qualquer outra coisa)
	screen_input(event)
	AgentInputState.call_func(event)

func moveCamera(event, sense:float):#move a camera tanto no toque quanto no mouse
	var Movement = event.relative*sense
	rotation_degrees.y+=Movement.x
	$Camera.rotation_degrees.x+= Movement.y
	$Camera.rotation_degrees.x = clamp($Camera.rotation_degrees.x,-80 , 80)

func SetStateEditing(value:bool):
	edit_focus = false
	if value:
		EditingInstance = VRscene.current_location
		AgentInputState = funcref(self, InputStates[0])
		if FocusedHotspot:
			$CanvasLayer/EditHotspotDialog.connect("mouse_entered", self, "_on_EditHotspotDialog_focus_entered")
			$CanvasLayer/EditHotspotDialog.connect("mouse_exited", self, "_on_EditHotspotDialog_focus_exited")
			
			$CanvasLayer/EditHotspotDialog/HBoxContainer/rotx/Rotation.value = FocusedHotspot.rotation_degrees.x
			$CanvasLayer/EditHotspotDialog/HBoxContainer/roty/Rotation.value = FocusedHotspot.rotation_degrees.y
			
			$CanvasLayer/EditHotspotDialog/IdEdit.text = str(FocusedHotspot.Identification)
			$CanvasLayer/EditHotspotDialog/descricao.text = FocusedHotspot.description
			
			interpolateHotspotRot = funcref(self, "InterpolateHotspotRotation")
			set_process(true)
	else:
		if FocusedHotspot != null:
			$CanvasLayer/EditHotspotDialog.disconnect("mouse_entered", self, "_on_EditHotspotDialog_focus_entered")
			$CanvasLayer/EditHotspotDialog.disconnect("mouse_exited", self, "_on_EditHotspotDialog_focus_exited")
			
			
			
			FocusedHotspot._state_1()
			FocusedHotspot = null
			
			interpolateHotspotRot = null
			set_process(false)
		EditingInstance = -1
		AgentInputState = funcref(self, InputStates[1])

func LockedRaycast(event):
	pass

func total_lock():
	$Camera.rotation_degrees = Vector3(0, 0, 0)
	rotation_degrees = Vector3(0, 180, 0)
	AgentInputState = funcref(self, InputStates[2])

func MoveRaycast(mousePos:Vector2):#move o raycast de acordo com toque ou mouse
	if RayCastInUse != null:
		var from = $Camera.project_ray_origin(mousePos)
		var to = from + $Camera.project_ray_normal(mousePos)*9
		RayCastInUse.global_position = from
		RayCastInUse.cast_to = to
		
		var area = RayCastInUse.get_collider()
		if area != null:
			if area is hotspot:
				FocusedHotspot = area
				FocusedHotspot.set_state(FocusedHotspot.stateMachine.STATE_FOCUS)
			
			if area.has_method("press_close"):
				close_button = area
				if FocusedHotspot != null:
					FocusedHotspot.set_state(FocusedHotspot.stateMachine.STATE_UNFOCUS)
					FocusedHotspot = null
		elif area == null:
			if FocusedHotspot != null:
				FocusedHotspot.set_state(FocusedHotspot.stateMachine.STATE_UNFOCUS)
				FocusedHotspot = null
			
			if close_button != null:
				close_button = null

func ShowError(error):
	screenDebug("erro: "+str(error))

func screenDebug(text):
	$CanvasLayer/text/Label.text = str(text)
	$CanvasLayer/text.visible = true
func screenDebugMultiple(args:Array):
	var text := ""
	for i in args:
		text += str(i) + "\n"
	$CanvasLayer/text/Label.text = text
	$CanvasLayer/text.visible = true

func TestMobile() -> bool:
	if OS.has_feature("Android"):
		return true
	else:
		return false

var current_quat = Quat.IDENTITY
var rotation_rate = Vector3.ZERO
func _on_GyroComponent_gyroscope_triggered(coords:Array):
	
	$Camera.rotation_degrees = Vector3(coords[1], coords[2], coords[0])

func _on_button_toggled(button_pressed):
	$Camera.rotation = Vector3.ZERO
	rotation = Vector3.ZERO
	if button_pressed:
		mobile_touch = false
		set_process(true)
#		var GyroscopeScene:PackedScene = ResourceLoader.load(GyroPath)
#		Gyroscope = GyroscopeScene.instance()
#		add_child(Gyroscope)
#		Gyroscope.name = "Gyro"
#		Gyroscope.connect(
#			"gyroscope_triggered", 
#			self, 
#			"_on_GyroComponent_gyroscope_triggered"
#		)
	else:
#		get_node("Gyro").queue_free()
		set_process(false)
		mobile_touch = true

func _on_immersive_pressed():
	GlobalL.ActivateXR()
	$Camera.current = false
	VRscene.AddAgent()
	call_deferred("queue_free")

func play_fade_in():
	$CanvasLayer/AnimationPlayer.play("fade in")
func play_fade_out():
	$CanvasLayer/AnimationPlayer.play("fade out")

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "fade in":
		emit_signal("fadein_finished")
	elif anim_name == "fade out":
		emit_signal("fadeout_finished")


func _on_reload_pressed():
	VRscene.ReloadLocation(rotation_degrees.y)


func _on_change_hotspot_pressed():
	var num:int = str2var($CanvasLayer/SelectAmb/LineEdit.text)
	VRscene.call_deferred("ChangeLocation", num)
	$CanvasLayer/SelectAmb/LineEdit.text = ""


func _on_close_pressed():
	$CanvasLayer/Description.visible = false
	mobile_touch = true

func FixRotationNative(DeviceRotation: Vector3) -> Vector3:
	var yaw = 0
	var roll = atan2(DeviceRotation.x, -DeviceRotation.y)
	var pitch = atan2(DeviceRotation.z, -DeviceRotation.y)
	var newvec = Vector3(pitch, yaw, roll)
	return newvec

func FixRotation(alpha:float, beta:float, gamma:float)->Array:
	var cX = cos(deg2rad(beta));
	var cY = cos(deg2rad(gamma));
	var cZ = cos(deg2rad(alpha));
	var sX = sin(deg2rad(beta));
	var sY = sin(deg2rad(gamma));
	var sZ = sin(deg2rad(alpha) );
	
	var m11 = cZ * cY - sZ * sX * sY;
	var m12 = - cX * sZ;
	var m13 = cY * sZ * sX + cZ * sY;
	
	var m21 = cY * sZ + cZ * sX * sY;
	var m22 = cZ * cX;
	var m23 = sZ * sY - cZ * cY * sX;
	
	var m31 = - cX * sY;
	var m32 = sX;
	var m33 = cX * cY;
	
	var matrix = [
		m13, m11, m12,
		m23, m21, m22,
		m33, m31, m32
	];
	
	var sy = sqrt(matrix[0] * matrix[0] +  matrix[3] * matrix[3] );
	
	var singular = sy < 1e-6;
	
	var x
	var y
	var z
	if !singular:
		x = atan2(matrix[7] , matrix[8]);
		y = atan2(-matrix[6], sy);
		z = atan2(matrix[3], matrix[0]);
	else:
		x = atan2(-matrix[5], matrix[4]);
		y = atan2(-matrix[6], sy);
		z = 0;
	return [rad2deg(x), rad2deg(y), rad2deg(z)];


func _on_EditHotspotDialog_focus_entered():
	edit_focus = true

func _on_EditHotspotDialog_focus_exited():
	edit_focus = false

func _on_EditHotspotDialog_hide():
	SetStateEditing(false)

func HotspotXrotChanged(v:float):
	FocusedHotspot.rotation_degrees.x = v

func HotspotYrotChanged(v:float):
	FocusedHotspot.rotation_degrees.y = v

