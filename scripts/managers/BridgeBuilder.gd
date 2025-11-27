extends Node2D
class_name BridgeBuilder

# 预加载桥梁段场景
const BridgeScene = preload("res://scenes/bridge/bridge.tscn")

var grid_manager: GridManager
var connection_manager: ConnectionManager

# 建造状态
var build_mode: bool = false
var start_pipe: Pipe = null
var current_path: Array[Vector2i] = []

@onready var preview_line: Line2D = $PreviewLine

func _ready() -> void:
	# 获取对全局管理器的引用
	grid_manager = get_node("/root/Main/GridManager")
	if not grid_manager:
		printerr("BridgeBuilder 错误: 找不到 GridManager")
	
	connection_manager = get_node("/root/Main/ConnectionManager")
	if not connection_manager:
		printerr("BridgeBuilder 错误: 找不到 ConnectionManager")

	# 确保预览线在顶层渲染且不可见
	preview_line.z_index = 1
	preview_line.visible = false

# 主输入处理
func _unhandled_input(event: InputEvent) -> void:
	if not build_mode:
		return

	# 鼠标移动时更新预览
	if event is InputEventMouseMotion:
		var end_grid_pos = grid_manager.world_to_grid(event.position)
		var start_grid_pos = grid_manager.world_to_grid(start_pipe.global_position)
		
		# 只有当鼠标格子位置变化时才重新计算路径，优化性能
		if end_grid_pos != current_path.back() if !current_path.is_empty() else start_grid_pos:
			current_path = _find_path(start_grid_pos, end_grid_pos)
			_update_preview()

	# 鼠标左键释放，尝试完成建造
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		var grid_pos = grid_manager.world_to_grid(event.position)
		var target_node = grid_manager.get_grid_object(grid_pos)

		if target_node is Pipe and target_node != start_pipe:
			# 如果是有效的管道，完成建造
			_finish_building(target_node)
		else:
			# 否则取消建造
			_cancel_building()

# --- 建造流程 ---

func start_building(pipe: Pipe):
	if build_mode:
		return
	
	build_mode = true
	start_pipe = pipe
	current_path = [grid_manager.world_to_grid(start_pipe.global_position)]
	
	preview_line.visible = true
	grid_manager.show_grid()
	Input.set_default_cursor_shape(Input.CURSOR_CROSS)

func _finish_building(end_pipe: Pipe):
	# 移除路径的起点和终点，因为我们只检查中间部分
	var path_to_check = current_path.slice(1, current_path.size() - 2)

	if grid_manager.is_grid_available(path_to_check):
		_create_bridge_segments()
		connection_manager.add_connection(start_pipe, end_pipe)
	
	_reset_build_mode()

func _cancel_building():
	_reset_build_mode()

func _reset_build_mode():
	build_mode = false
	start_pipe = null
	current_path.clear()
	preview_line.clear_points()
	preview_line.visible = false
	grid_manager.hide_grid()
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _create_bridge_segments():
	# 我们不在管道本身的位置创建桥梁段
	var segments_path = current_path.slice(1, current_path.size() - 2)
	
	for grid_pos in segments_path:
		var bridge_segment = BridgeScene.instantiate()
		var world_pos = grid_manager.grid_to_world(grid_pos)
		
		# 将新创建的节点添加到场景树中
		get_node("/root/Main/Bridges").add_child(bridge_segment)
		bridge_segment.global_position = world_pos
		bridge_segment.setup_segment(grid_pos)

# --- 路径预览 ---

func _update_preview():
	preview_line.clear_points()
	if current_path.size() < 2:
		return
		
	for grid_pos in current_path:
		preview_line.add_point(grid_manager.grid_to_world(grid_pos))

# --- A* 寻路算法 ---

# A* 启发式函数（曼哈顿距离）
func _heuristic(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

# A* 寻路主函数
func _find_path(start_pos: Vector2i, end_pos: Vector2i) -> Array[Vector2i]:
	var open_set: Array[Vector2i] = [start_pos]
	var came_from: Dictionary = {}
	
	var g_score: Dictionary = {start_pos: 0}
	var f_score: Dictionary = {start_pos: _heuristic(start_pos, end_pos)}

	while not open_set.is_empty():
		# 找到 open_set 中 f_score 最低的点
		var current = open_set[0]
		for node in open_set:
			if f_score.get(node, INF) < f_score.get(current, INF):
				current = node
		
		# 如果到达终点，重构路径并返回
		if current == end_pos:
			return _reconstruct_path(came_from, current)

		open_set.erase(current)

		# 探索邻居
		for neighbor_offset in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var neighbor = current + neighbor_offset
			
			# 检查邻居是否有效
			if not grid_manager.is_within_bounds(neighbor):
				continue
			
			# 如果邻居不是终点，且被占用，则跳过
			if neighbor != end_pos and grid_manager.get_grid_object(neighbor) != null:
				continue

			var tentative_g_score = g_score.get(current, INF) + 1
			if tentative_g_score < g_score.get(neighbor, INF):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g_score
				f_score[neighbor] = tentative_g_score + _heuristic(neighbor, end_pos)
				if not open_set.has(neighbor):
					open_set.append(neighbor)
	
	# 如果找不到路径，返回空数组
	return []

# 从 came_from 字典重构路径
func _reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array[Vector2i]:
	var total_path: Array[Vector2i] = [current]
	while current in came_from:
		current = came_from[current]
		total_path.push_front(current)
	return total_path
