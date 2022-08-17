extends Node
class_name InfluenceBody
# Container object for constructing hierarchies of influence objects

var parent_body
var child_body
var body


func _init(init_body, init_parent_body = null, init_child_body = null):
	self.parent_body = init_parent_body
	self.body = init_body
	self.child_body = init_child_body
