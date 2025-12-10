extends Node

signal dados_carregados(data, identification)
signal dados_carregados_nuvem(cena)

var CLOUD_NAME = "dsg9hvvo7"
var UPLOAD_PRESET = "scene_images"
var UPLOAD_URL = "https://api.cloudinary.com/v1_1/" + CLOUD_NAME + "/image/upload"

var loading_scene := SceneProperties.new()

var current_image_url = ""
signal link_got(image_link)
signal scene_register_success()

func _ready():
	add_to_group("LocalDB")
#	fetch_data("cenas", 1)
#	var cena = carregar_dados_cena(0)
#	register_scene(
#		cena.nome_cena,
#		cena.GetVector(),
#		cena.caminho_imagem,
#		cena.offset_roll
#	)

"retorna dados específicos da cena"
func carregar_dados_cena(id:int) ->SceneProperties:
	var cenap := SceneProperties.new()
	var path = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS) + "/Environments/%d/" % id
	var foto_path = path+"panorama.jpg"
	
	var nome_arq = File.new()
	nome_arq.open(path+"/nome.txt", File.READ)
	var nome = nome_arq.get_as_text()
	nome_arq.close()
	
	var propriedades = File.new()
	propriedades.open(path+"/scene_properties.txt", File.READ)
	var prop_conteudo = JSON.parse(propriedades.get_as_text()).result
	propriedades.close()
	
	cenap.SetProperties(
		prop_conteudo["pitch"],
		prop_conteudo["roll"],
		prop_conteudo["yaw"],
		prop_conteudo["offset_roll"],
		foto_path,
		nome
	)
	return cenap

func carregar_dados(id: int, recursivo: bool = false) -> String:
	var path:String = GlobalLoad.ROOT_PATH_ENVIRONMENTS + "%d/" % id
#	var nome_file = File.new()
#	if nome_file.open(path + "nome.txt", File.READ) != OK:
#		print("Erro ao abrir nome.txt para id: %d" % id)
#		return ""
	var nome = "nome_file.get_as_text().strip_edges()"
#	nome_file.close()
	
	if recursivo:
		return nome
	
	# Carregar imagem apenas na chamada inicial
	var img_path = path+"panorama.jpg"
	var textura:ImageTexture = ImageTexture.new()
	if File.new().file_exists(img_path):
		var file = File.new()
		if file.open(img_path, File.READ) == OK:
			var file_size = file.get_len()
			var file_data = file.get_buffer(file_size)
			var image = Image.new()
			if image.load_jpg_from_buffer(file_data) == OK:
#				image.generate_mipmaps()
				textura.create_from_image(image, Texture.FLAG_MIPMAPS | Texture.FLAG_FILTER | Texture.FLAG_ANISOTROPIC_FILTER | Texture.FLAG_REPEAT)
				textura.create_from_image(image)
				# Use a textura para um Sprite, por exemplo
			file.close()
		else:
			print("Erro ao abrir o arquivo!")
	else:
		print("Arquivo não encontrado em: ", img_path)
	
	textura.flags = ImageTexture.FLAG_REPEAT & ImageTexture.FLAG_FILTER & ImageTexture.FLAG_ANISOTROPIC_FILTER & ~ImageTexture.FLAG_MIPMAPS
	
	# Ler adjacents.json
	#caso ocorra um erro, a função retorna e envia um erro
	var adj_file = File.new()
	if adj_file.open(path + "adjacents.json", File.READ) != OK:
		print("Erro ao abrir adjacents.json para id: %d" % id)
		return nome
	
	var json_text = adj_file.get_as_text()
	adj_file.close()
	
	var json_parse = JSON.parse(json_text)
	if json_parse.error != OK:
		print("Erro ao parsear JSON para id: %d" % id)
		return nome
	var raw_adj = json_parse.result
	if not raw_adj is Dictionary:
		print("JSON não é um dicionário para id: %d" % id)
		return nome
	var adjacentes = {}
	for key in raw_adj.keys():
		var adj_id:int = int(key)
		var list:Array = raw_adj[key]
		adjacentes[key] = [list[0], list[1]]
		# 0 é o ângulo do hotspot
		# 1 é o texto do hotspot
	
	var infos_file = File.new()
	if infos_file.open(path + "infospots.json", File.READ) != OK:
		print("Erro ao abrir infospots.json para id: %d" % id)
		return nome
	var info_json_text = infos_file.get_as_text()
	adj_file.close()
	var info_json_parse = JSON.parse(info_json_text)
	if info_json_parse.error != OK:
		print("Erro ao parsear JSON para id: %d" % id)
		return nome
	var infospots = info_json_parse.result
	if not infospots is Dictionary:
		print("JSON não é um dicionário para id: %d" % id)
		return nome
	
#	var blurs_file = File.new()
#	if blurs_file.open(path + "blur.json", File.READ) != OK:
#		print("Erro ao abrir blur.json para id: %d" % id)
#		return nome
#	var blurs_json_text = blurs_file.get_as_text()
#	adj_file.close()
#	var blurs_json_parse = JSON.parse(blurs_json_text)
#	if blurs_json_parse.error != OK:
#		print("Erro ao parsear blur JSON para id: %d" % id)
#		return nome
#	var blurs = blurs_json_parse.result
#	if not blurs is Dictionary:
#		print("blurs JSON não é um dicionário para id: %d" % id)
#		return nome
	
	var prop_path = path + "/scene_properties.txt"
	var prop_file = File.new()
	prop_file.open(prop_path, File.READ)
	var scene_properties = JSON.parse(prop_file.get_as_text()).result
	
	var data_dict = {
		"textura": textura,
		"nome": nome,
		"adjacentes": adjacentes,
		"infospots": infospots,
		"scene_properties": scene_properties
	}
	emit_signal("dados_carregados", data_dict, id)
#	print(data_dict)
	return nome

#onready var http_request = $UploaderCloudinary
#onready var GetCloudinary = $GetCloudinary

#func start_upload_cloudinary(path:String):
#	print("Iniciando upload para: ", path)
#
#	# 1. Carregar a imagem do disco como bytes
#	var file = File.new()
#	var err = file.open(path, File.READ)
#	if err != OK:
#		print("Erro ao abrir o arquivo: ", err)
#		return
#
#	var image_data = file.get_buffer(file.get_len())
#	file.close()
#
#	# 2. Codificar os bytes da imagem em Base64
#	var base64_image = Marshalls.raw_to_base64(image_data)
#
#	# 3. Criar o "Data URI"
#	# (Assumindo que é um PNG. Mude para 'image/jpeg' se for o caso)
#	var data_uri = "data:image/png;base64," + base64_image
#
#	# 4. Criar o corpo (body) da requisição em JSON
#	var body = {
#		"file": data_uri,
#		"upload_preset": UPLOAD_PRESET
#	}
#	var json_body = JSON.print(body)
#
#	# 5. Configurar e enviar a requisição HTTP POST
#	var headers = ["Content-Type: application/json"]
#	var error = http_request.request(UPLOAD_URL, headers, true, HTTPClient.METHOD_POST, json_body)
#
#	if error != OK:
#		print("Erro ao iniciar a requisição HTTP: ", error)

# 4. Lidar com a resposta do Cloudinary
#func _on_request_completed(result, response_code, headers, body):
#	if result != HTTPRequest.RESULT_SUCCESS:
#		print("Erro na requisição: ", result)
#		return
#
#	print("Resposta recebida. Código: ", response_code)
#
#	# Converte o corpo da resposta (que são bytes) para String
#	var response_string = body.get_string_from_utf8()
#
#	# Analisa o JSON da resposta
#	var json = JSON.parse(response_string)
#
#	if json.error != OK:
#		print("Erro ao analisar JSON da resposta: ", json.error_string)
#		return
#
#	var response_data = json.result
#
#	if response_code == 200:
#		# Sucesso!
#		current_image_url = response_data.secure_url
#		emit_signal("link_got", current_image_url)
#		print("Upload completo!")
#		print("URL Segura: ", response_data.secure_url)
#		print("Public ID: ", response_data.public_id)
#	else:
#		# Erro do Cloudinary
#		print("Erro no upload: ", response_data.error.message)

#func load_from_cloudinary(url:String):
#	var h =[]
#	GetCloudinary.request(url, h, false, HTTPClient.METHOD_GET)
#
#func _on_Get_request_completed(result, response_code, headers, body:PoolByteArray):
#	print(response_code)
#	if response_code == 200:
#		loading_scene.SetTexFromBuffer(body)
#		emit_signal("dados_carregados_nuvem", loading_scene)
#	else:
#		print(response_code)

#func _on_SupaRequest_registering_completed(result, response_code, headers, body:PoolByteArray):
#	if response_code == 200:
#		print("enviado com sucesso: %s" % body.get_string_from_utf8())
#	else:
#		print(response_code, ": %s" % body.get_string_from_utf8())
#
#var Supaconnections = [
#	"_on_SupaRequest_registering_completed",
#	"_on_SupaRequest_request_completed"
#]
#func SupaSetConnection(id:int):
#	for i in Supaconnections:
#		if $SupaRequest.is_connected("request_completed", self, i):
#			$SupaRequest.disconnect("request_completed", self, i)
#	$SupaRequest.connect("request_completed", self, Supaconnections[id])

#func register_scene(nome:String, vetor:Vector3, image_path:String, offset_roll):
#	var headers = [
#		"apikey: " + VITE_SUPABASE_KEY,
#		"Authorization: Bearer " + VITE_SUPABASE_KEY,
#		"Content-Type: application/json",
#		"Prefer: return=minimal" # Opcional: não retorna os dados inseridos, economiza banda
#	]
#	var url = "%s/rest/v1/%s" % [VITE_SUPABASE_URL, "cenas"]
#	var content = {
#		"entrada_rotacao_pitch":vetor.x,
#		"entrada_rotacao_y":vetor.y,
#		"entrada_rotacao_roll": vetor.z,
#		"offset_roll": offset_roll
#	}
#	SupaSetConnection(0)
#	start_upload_cloudinary(image_path)
#	yield(self, "link_got")
#	content["caminho_imagem"] = current_image_url
#
#	$SupaRequest.request(
#		url, 
#		headers, 
#		true, 
#		HTTPClient.METHOD_POST, 
#		JSON.print(content)
#	)
#
#func register_oldregister_scene(nome:String, vetor:Vector3, image_link:String, offset_roll):
#	var headers = [
#		"apikey: " + VITE_SUPABASE_KEY,
#		"Authorization: Bearer " + VITE_SUPABASE_KEY,
#		"Content-Type: application/json",
#		"Prefer: return=minimal" # Opcional: não retorna os dados inseridos, economiza banda
#	]
#	var url = "%s/rest/v1/%s" % [VITE_SUPABASE_URL, "cenas"]
#	var content = {
#		"entrada_rotacao_pitch":vetor.x,
#		"entrada_rotacao_y":vetor.y,
#		"entrada_rotacao_roll": vetor.z,
#		"offset_roll": offset_roll,
#		"caminho_imagem": image_link
#	}
#	SupaSetConnection(0)
