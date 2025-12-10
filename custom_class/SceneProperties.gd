extends Node
class_name SceneProperties

var id:int
var entrada_pitch:float
var entrada_roll:float
var entrada_yaw:float
var caminho_imagem:String
var nome_cena:String
var offset_roll:float
var Panorama:ImageTexture
var Hotspots_dict := {}
var Hotspots_array := []

func SetProperties(pitch:float, roll:float, yaw:float, offset_roll:float, imgpath:String, nome:String)->void:
	entrada_pitch = pitch
	entrada_yaw = yaw
	entrada_roll = roll
	caminho_imagem = imgpath
	nome_cena = nome

func GetVector()->Vector3:
	var js_rotations = Vector3(entrada_pitch,entrada_yaw,entrada_roll)
	return js_rotations

func SetTexFromBuffer(buffer:PoolByteArray)->ImageTexture:
	var imagem:Image = Image.new()
	var textura:ImageTexture = ImageTexture.new()
	if imagem.load_jpg_from_buffer(buffer) == OK:
		textura.create_from_image(imagem, Texture.FLAG_MIPMAPS | Texture.FLAG_FILTER | Texture.FLAG_ANISOTROPIC_FILTER | Texture.FLAG_REPEAT)
	Panorama = textura
	return Panorama

func CreateScene(props:SceneProperties):
	pass
