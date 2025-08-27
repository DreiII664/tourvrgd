extends Object

class_name FirestoreFields
var Fields = {}

const FIELD_STRING = "stringValue"

func init_firestore_fields(body:PoolByteArray):
	var stringBody = body.get_string_from_utf8()
	var DictBody:Dictionary = JSON.parse(stringBody).result
	var info:Dictionary = DictBody["fields"]
	Fields = info

func get_field(field_name:String, value_type):
	var value = Fields[field_name]
	var target = value[value_type]
	return target

func get_full_fields()->Dictionary:return Fields
