extends Node
#esse script é um script global, que é executado sempre que o programa inicia
#sem precisar de nenhum node, ou seja, esse script funciona sozinho
var xr_interface:ARVRInterface
var vr_supported:bool = false
"""
problemas do tamanho do arquivo:
	mais lento pra transferência de rede em redes mais fracas
	consome muita rede
"""

func ActivateXR()->bool:#força a ativação da realidade virtual (quest)
	if vr_supported:
		xr_interface.session_mode = 'immersive-vr'
		xr_interface.requested_reference_space_types = 'bounded-floor, local-floor, local'
		xr_interface.required_features = 'local-floor'
		xr_interface.optional_features = 'bounded-floor'
		if xr_interface.initialize():
			return true
		else:
			return false
	else: return false

func VerifyXR()->String:#verifica se é possível ativar realidade virtual
	xr_interface = ARVRServer.find_interface("WebXR")
	if xr_interface:
		xr_interface.connect("session_supported", self, "_webxr_session_supported")
		xr_interface.connect("session_started", self, "_webxr_session_started")
		xr_interface.is_session_supported("immersive-vr")
		return "Avaliable"
	else:
		return "Unavaliable"

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

var params = {
	0: false, # parametro usado para decitir se entrará em realidade virtual
	1: false # parametro usado para decidir se está no mobile ou pc
}
#funções pra mudar parametros usados na cena em 3D
func SetParams(prm:Dictionary):
	for i in prm:
		params[i] = prm[i]

func GetParam(Parameter:int)->bool:
	return params[Parameter]
