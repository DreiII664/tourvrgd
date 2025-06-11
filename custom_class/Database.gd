extends Node
class_name Database

const PROJECT_ID = "tvrn29475ao4u67gffk312gh9bc8h3"
const FIRESTORE_URL = "https://firestore.googleapis.com/v1/projects/"+ PROJECT_ID+"/databases/(default)/documents/"
const HEADER = ["Content-Type: application/json"]
const COLL_ENVIRONMENTS = FIRESTORE_URL+"Environments"

var Enviro:Dictionary = {
	"Hotspots": {
		0 : [[0, 0, 0], "patio_interno"]
	},
	"Hotspot1": {
		0 : [[0, -60, 0], "entrada_Tiaraju"]
	}
}
var payload = {
	"fields": {}
}
func _ready():
	pass

# caminho da foto && dicionario de hotspots && método PATCH/POST && nome do documento do ambiente
func send_to_database(fpath:String, HotspotsDict:Dictionary, method:int, nomeDoc:String):
	var fields = payload["fields"]
	var foto = File.new()
	var buffer := PoolByteArray()

	foto.open(fpath, File.READ)
	buffer = foto.get_buffer(foto.get_len())
	var string_buffer = str(buffer)
	var string_hotspots = JSON.print(HotspotsDict)
	fields["Hotspots"] = {"stringValue": string_hotspots}
	fields["buffer"] = {"stringValue": string_buffer}
	fields["DocName"] = {"stringValue" : nomeDoc}
	match method:
		HTTPClient.METHOD_PATCH:
			$Store.request(
				COLL_ENVIRONMENTS+"/"+nomeDoc,
				HEADER,
				true,
				method,
				JSON.print(payload)
			)
		HTTPClient.METHOD_POST:
			$Store.request(
				COLL_ENVIRONMENTS+"?documentId="+nomeDoc,
				HEADER,
				true,
				method,
				JSON.print(payload)
			)
		_:print("insert a valid method")

func _on_Store_request_completed(_result, response_code, _headers, _body:PoolByteArray):
	print(response_code)
