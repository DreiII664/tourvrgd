extends Node

var loc:Dictionary = {
	"baixa qualidade" : {
		0 : [Vector3(0, 30, 0), "res://Panoramas/panorama.jpg", "panorama bonito"]
	},
	"panorama bonito":{
		0 : [Vector3(0, 0, 0), "res://Panoramas/OIP.jpg", "baixa qualidade"],
		1 : [Vector3(0, -60, 0), "res://Panoramas/casa do jao.jpeg", "jao"]
	},
	"jao" : {
		0 : [Vector3(0, 0, 0), "res://Panoramas/panorama.jpg", "panorama bonito"],
		1 : [Vector3(0, -30, 0), "res://Panoramas/aaa.jpeg", "entrada"],
		2 : [Vector3(0, -60, 0), "res://Panoramas/bbb.jpeg", "nao sei"]
	},
	"nao sei" : {
		0: [Vector3(0, 0, 0), "res://Panoramas/casa do jao.jpeg", "jao"]
	},
	"entrada" : {
		0: [Vector3(0, 90, 0), "res://Panoramas/casa do jao.jpeg", "jao"]
	}
}
