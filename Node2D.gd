extends Node2D

#usa o script GlobalLoad
onready var GlobalL = get_node("/root/GlobalLoad")

func bool_string(boolean:bool) -> String:#converte booleano em texto
	if boolean:return "true"
	else:return "false"

func _on_xr_pressed():
	GlobalL.ActivateXR()

func _on_noxr_pressed():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GlobalL.call_deferred("ChangeToFlat")
