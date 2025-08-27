# Example class to show how to get gyroscope data from mobile devices running
# HTML5 apps. We leverage the Godot-Javascript bridge to make JavaScript calls
# and get data from the sensors.
# This is needed because the Godot API for the gyroscope only works on **native**
# mobile platforms.
# Note: apparently, when using JavaScript.create_callback, we need to do that
# at the top of the script, otherwise it will not work.
class_name GyroComponent
extends Node

signal ios_permission_requested(is_granted)
signal gyroscope_triggered(coords)
signal send_orientation_args(args)

var window = JavaScript.get_interface("window")
var console = JavaScript.get_interface("console")
var handleOrientation = JavaScript.create_callback(self, "_handle_orientation")
var iosHandleOrientation = JavaScript.create_callback(self, "_ios_handle_orientation")
# iOS only: should be set from a different script
var is_permission_asked := false setget _set_is_permission_asked
var os_string: String

func _ready() -> void:
	if OS.has_feature("JavaScript"):
		os_string = _get_os()
		# works on Android
		if os_string == "Android":
			window.addEventListener("deviceorientation", handleOrientation)
	else:
		print("Not running on HTML5 platform")


func _get_os() -> String:
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


# Event listener: handles orientation by getting the event data.
func _handle_orientation(args: Array) -> void:
	var event:JavaScriptObject = args[0]
	if event != null:
#		var coords := Vector3(event.beta, event.gamma, event.alpha)
		var command := "FixRotation(%f, %f, %f);" % [event.alpha, event.beta, event.gamma]
		var coords = FixRotation(event.alpha, event.beta, event.gamma)
		emit_signal("gyroscope_triggered", coords)
		
		emit_signal("send_orientation_args", event.get_property_list())
	else:
		print("Couldn't get event data!")


# iOS only. This gets triggered when the user interacted with a UI element
# to explicitly ask for permission to use a sensor.
# This function actually triggers the code to request permission to the user
# and subsequently invoke the JavaScript callback to get sensor data.
func _set_is_permission_asked(value: bool) -> void:
	is_permission_asked = value
	if value:
		var devicemotionevent = JavaScript.get_interface("DeviceMotionEvent")
		devicemotionevent.requestPermission().then(iosHandleOrientation).\
				catch(console.error)

# iOS only: checks if permission to use the gyroscope was granted.
# User interaction is mandatory for iPhones, plus note that it only works
# under an HTTPS website.
func _ios_handle_orientation(args: Array) -> void:
	var state = args[0]
	if state == "granted":
		window.addEventListener("deviceorientation", handleOrientation)
	else:
		print("Request to access the orientation was rejected")
	emit_signal("ios_permission_requested", state == "granted")

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
