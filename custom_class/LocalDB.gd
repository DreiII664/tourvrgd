extends Node

signal dados_carregados(data, identification)

func carregar_dados(id: int, recursivo: bool = false) -> String:
	var path = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS) + "/Environments/%d/" % id
	var nome_file = File.new()
	if nome_file.open(path + "nome.txt", File.READ) != OK:
		print("Erro ao abrir nome.txt para id: %d" % id)
		return ""
	var nome = nome_file.get_as_text().strip_edges()
	nome_file.close()
	
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
				# Crie uma textura e carregue a imagem carregada nela
				textura.create_from_image(image)
				# Use a textura para um Sprite, por exemplo
			file.close()
		else:
			print("Erro ao abrir o arquivo!")
	else:
		print("Arquivo não encontrado em: ", img_path)
	
	textura.flags = Texture.FLAG_REPEAT & Texture.FLAG_ANISOTROPIC_FILTER & Texture.FLAG_MIPMAPS
	
	# Ler adjacents.json
	#caso ocorra um erro, a função retorna e envia um erro
	var adj_file = File.new()
	if adj_file.open(path + "adjacents.json", File.READ) != OK:
		push_error("Erro ao abrir adjacents.json para id: %d" % id)
		return nome
	
	var json_text = adj_file.get_as_text()
	adj_file.close()
	
	var json_parse = JSON.parse(json_text)
	if json_parse.error != OK:
		push_error("Erro ao parsear JSON para id: %d" % id)
		return nome
	
	var raw_adj = json_parse.result
	if not raw_adj is Dictionary:
		push_error("JSON não é um dicionário para id: %d" % id)
		return nome
	
	var adjacentes = {}
	for key in raw_adj.keys():
		var adj_id = int(key)
		var adj_nome = carregar_dados(adj_id, true)
		adjacentes[key] = [adj_nome, raw_adj[key]]
	
	var infos_file = File.new()
	if infos_file.open(path + "infospots.json", File.READ) != OK:
		push_error("Erro ao abrir infospots.json para id: %d" % id)
		return nome
	
	var info_json_text = infos_file.get_as_text()
	adj_file.close()
	
	var info_json_parse = JSON.parse(info_json_text)
	if json_parse.error != OK:
		push_error("Erro ao parsear JSON para id: %d" % id)
		return nome
	
	var infospots = info_json_parse.result
	if not infospots is Dictionary:
		push_error("JSON não é um dicionário para id: %d" % id)
		return nome
	
	var data_dict = {
		"textura": textura,
		"nome": nome,
		"adjacentes": adjacentes,
		"infospots": infospots
	}
	emit_signal("dados_carregados", data_dict, id)
	return nome
