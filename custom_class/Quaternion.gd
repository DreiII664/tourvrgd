extends Node
class_name Quaternion

var w:float
var x:float
var y:float
var z:float

func new_quaternion(beta:float, alpha:float, gamma:float):
	var _x = deg2rad(beta)      # X-axis (pitch) rotation
	var _y = deg2rad(alpha)     # Y-axis (yaw) rotation
	var _z = deg2rad(-gamma)    # Z-axis (roll) rotation (note the negation)
	
	var cX = cos(_x / 2)
	var cY = cos(_y / 2)
	var cZ = cos(_z / 2)
	var sX = sin(_x / 2)
	var sY = sin(_y / 2)
	var sZ = sin(_z / 2)
	
	w = cX * cY * cZ - sX * sY * sZ
	x = sX * cY * cZ + cX * sY * sZ
	y = cX * sY * cZ + sX * cY * sZ
	z = cX * cY * sZ - sX * sY * cZ
