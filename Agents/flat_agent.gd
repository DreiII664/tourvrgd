extends Spatial
class_name flat_agent
var RayCastInUse:RayCast
var FocusedHotspot:hotspot
var VRscene
var detect_inputs
onready var GlobalL = get_node("/root/GlobalLoad")
var GyroPath = "res://main/gyro_component/gyro_component.tscn"
onready var Gyroscope:GyroComponent
var neweuler = Vector3.ZERO
func _ready():
	VRscene = get_parent()
	print(GlobalL.VerifyNativeMobile())
	get_viewport().connect("size_changed", self, "WindowSizeChanged")
	WindowSizeChanged()
	set_process(false)
	var Platform = TestMobile()
	if Platform == "unknown" or Platform == null:
		$CanvasLayer/usegyro.visible = false

func WindowSizeChanged():
	var _viewport_size:Vector2 = get_viewport().size
#	print(viewport_size)

func _input(event):#detecta as entradas (teclado, mouse ou qualquer outra coisa)
	if event is InputEventScreenTouch:
		var mousePos = event.position
		MoveRaycast(mousePos)
		if FocusedHotspot:
			FocusedHotspot.press()
			FocusedHotspot = null
	elif event is InputEventScreenDrag:
		moveCamera(event, 0.5)
	
	if Input.is_action_just_pressed("MouseLeft") and FocusedHotspot:
		FocusedHotspot.press()
	elif Input.is_action_pressed("MouseLeft"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if Input.is_action_just_released("MouseLeft"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		moveCamera(event, 0.5)
	elif event is InputEventMouseMotion:
		var mousePos = event.position
		MoveRaycast(mousePos)

func moveCamera(event, sense:float):#move a camera tanto no toque quanto no mouse
	var Movement = event.relative*sense
	rotation_degrees.y+=Movement.x
	$Camera.rotation_degrees.x+= Movement.y
	$Camera.rotation_degrees.x = clamp($Camera.rotation_degrees.x,-80 , 80)

func MoveRaycast(mousePos:Vector2):#move o raycast de acordo com toque ou mouse
	var from = $Camera.project_ray_origin(mousePos)
	var to = from + $Camera.project_ray_normal(mousePos)*9
	RayCastInUse.global_position = from
	RayCastInUse.cast_to = to
	var area = RayCastInUse.get_collider()
	if area != null:
		FocusedHotspot = area
		FocusedHotspot.new_material(VRscene.MaterialFocus)
	elif !area and FocusedHotspot != null:
		FocusedHotspot.new_material(VRscene.MaterialUnfocus)
		FocusedHotspot = null

func screenDebug(text):
	$CanvasLayer/text/Label.text = str(text)
func screenDebugMultiple(args:Array):
	var text := ""
	for i in args:
		text += str(i) + "\n"
	$CanvasLayer/text/Label.text = text

func TestMobile() -> String:
	return JavaScript.eval("""
		// https://dev.to/vaibhavkhulbe/get-os-details-from-the-webpage-in-javascript-b07
		function getOS() {
			var userAgent = window.navigator.userAgent,
			platform = window.navigator.platform,
			iosPlatforms = ['iPhone', 'iPad', 'iPod'],
			os = 'unknown';
			if (iosPlatforms.indexOf(platform) !== -1) {
				os = 'iOS';
			} else if (/Android/.test(userAgent)) {
				os = 'Android';
			}
			return os;
		}
		getOS();
	""")

var current_quat = Quat.IDENTITY
var rotation_rate = Vector3.ZERO
func _on_GyroComponent_gyroscope_triggered(coords:Array):
	
	screenDebug(coords)
	$Camera.rotation_degrees = Vector3(coords[1], coords[2], coords[0])

func _on_button_toggled(button_pressed):
	$Camera.rotation = Vector3.ZERO
	rotation = Vector3.ZERO
	if button_pressed:
		var GyroscopeScene:PackedScene = ResourceLoader.load(GyroPath)
		Gyroscope = GyroscopeScene.instance()
		add_child(Gyroscope)
		Gyroscope.name = "Gyro"
		Gyroscope.connect(
			"gyroscope_triggered", 
			self, 
			"_on_GyroComponent_gyroscope_triggered"
		)
	else:
		get_node("Gyro").queue_free()
		screenDebug("")
