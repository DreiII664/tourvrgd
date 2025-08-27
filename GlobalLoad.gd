extends Node
#esse script é um script global, que é executado sempre que o programa inicia
#sem precisar de nenhum node, ou seja, esse script funciona sozinho
var xr_interface:ARVRInterface
var vr_supported:bool = false
var params = {
	0: false, # parametro usado para decitir se entrará em realidade virtual
	1: false # parametro usado para decidir se está no mobile ou pc
}

func ActivateXR()->bool:#força a ativação da realidade virtual (quest)
	if vr_supported:
		if xr_interface.initialize():
			SetParams({0:true})
			get_viewport().arvr = true
			return true
		else:
			SetParams({0:false})
			return false
	else: return false

func VerifyXR()->bool:#verifica se é possível ativar realidade virtual
	xr_interface = ARVRServer.find_interface("OpenXR")
	if xr_interface:
		vr_supported = true
		return true
	else:
		return false

func VerifyNativeMobile()->bool:
	xr_interface = ARVRServer.find_interface("Native mobile")
	if xr_interface:
		return true
	else:
		return false

func ChangeToFlat():
	SetParams({0:false})
	var Environment3d: PackedScene = load("res://3D environment/VRscene.scn")
	get_tree().change_scene_to(Environment3d)

#função ligada a um sinal, verifica se a realidade virtual no navegador é suportada
func _webxr_session_supported(session_mode: String, supported: bool) -> void:
	if session_mode == "immersive-vr":
		vr_supported = supported

#função acionada quando a realidade virtual é ligada
func _webxr_session_started() -> void:
	SetParams({0:true, 1:false})
	var Environment3d: PackedScene = load("res://3D environment/VRscene.scn")
	get_tree().change_scene_to(Environment3d)
	get_viewport().arvr = true
#	print("sessão iniciada")

#funções pra mudar parametros usados na cena em 3D
func SetParams(prm:Dictionary):
	for i in prm:
		params[i] = prm[i]

func GetParam(Parameter:int)->bool:
	return params[Parameter]
