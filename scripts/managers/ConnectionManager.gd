extends Node
class_name ConnectionManager

# 存储所有连接的图状数据结构
var connections = {}

# 添加一个新的连接
func add_connection(pipe1: Pipe, pipe2: Pipe):
	# 使用实例ID作为键，确保唯一性
	var id1 = pipe1.get_instance_id()
	var id2 = pipe2.get_instance_id()
	
	if not connections.has(id1):
		connections[id1] = []
	if not connections.has(id2):
		connections[id2] = []
		
	connections[id1].append(pipe2)
	connections[id2].append(pipe1)
	
	pipe1.on_connected()
	pipe2.on_connected()
	
	print("连接已注册: ", pipe1.name, " <-> ", pipe2.name)

# 移除一个连接
func remove_connection(pipe1: Pipe, pipe2: Pipe):
	var id1 = pipe1.get_instance_id()
	var id2 = pipe2.get_instance_id()

	if connections.has(id1):
		connections[id1].erase(pipe2)
	if connections.has(id2):
		connections[id2].erase(pipe1)
		
	print("连接已移除: ", pipe1.name, " <-> ", pipe2.name)

# 获取一个管道的所有连接
func get_connections(pipe: Pipe) -> Array:
	var id = pipe.get_instance_id()
	if connections.has(id):
		return connections[id]
	return []
