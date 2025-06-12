extends Node2D

#usa o script GlobalLoad
onready var GlobalL = get_node("/root/GlobalLoad")

func _ready():
	$Label.text = "pode vr " + GlobalL.VerifyXR()

func bool_string(boolean:bool) -> String:#converte booleano em texto
	if boolean:return "true"
	else:return "false"

func _on_xr_pressed():
	GlobalL.ActivateXR()

func _on_noxr_pressed():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GlobalL.call_deferred("ChangeToFlat")

func _on_HTTPRequest_request_completed(_result, response_code:int, _headers, body:PoolByteArray):
	if response_code == 200:
		var stringed:String = body.get_string_from_ascii()
		var dict = JSON.parse(stringed).result
		print(response_code,": ", dict["address"])
		$requesttext.text = "200" +": "+ dict["address"]
	else:
		$requesttext.text = "erro na request"

func _on_Button_pressed():
	$HTTPRequest.request("https://cep.awesomeapi.com.br/json/05424020")
