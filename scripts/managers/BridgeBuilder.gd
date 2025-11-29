extends Node2D
class_name BridgeBuilder

# 预加载桥梁段场景
const BridgeScene = preload("res://scenes/bridge/bridge.tscn")

var grid_manager: GridManager
var connection_manager: ConnectionManager
var ui_manager: Node

# 建造状态
var build_mode: bool = false
var start_pipe: Pipe = null
var start_pos: Vector2i # 记录起始连接点的网格坐标
var current_path: Array[Vector2i] = []

@onready var preview_line: Line2D = $PreviewLine

# 用于存放桥梁段的容器节点
@export var bridges_container: Node2D

func _ready() -> void:
	# 获取对全局管理器的引用
	grid_manager = get_node("/root/Main/GridManager")
	if not grid_manager:
		printerr("BridgeBuilder 错误: 找不到 GridManager")
	
	connection_manager = get_node("/root/Main/ConnectionManager")
	if not connection_manager:
		printerr("BridgeBuilder 错误: 找不到 ConnectionManager")
	
	ui_manager = get_node("/root/Main/UIManager")
	if not ui_manager:
		printerr("BridgeBuilder 错误: 找不到 UIManager")

	if not bridges_container:
		printerr("BridgeBuilder 错误: 'bridges_container' 未设置！请在编辑器中指定。")

	# 确保预览线在顶层渲染且不可见
	preview_line.z_index = 1
	preview_line.visible = false

	# 连接到SceneTree的mouse_exited信号，以便在鼠标离开窗口时取消建造
	get_tree().get_root().mouse_exited.connect(_on_mouse_exited)

# 主输入处理
func _unhandled_input(event: InputEvent) -> void:
	if not build_mode:
		return

	# 鼠标移动时更新预览
	if event is InputEventMouseMotion:
		var new_grid_pos = grid_manager.world_to_grid(event.position)
		var last_grid_pos = current_path.back() if not current_path.is_empty() else Vector2i(-1, -1)
		
		# 只有当鼠标进入新的格子时才更新路径
		if new_grid_pos != last_grid_pos:
			# 检查新位置是否与上一个位置相邻（水平或垂直）
			var dx = abs(new_grid_pos.x - last_grid_pos.x)
			var dy = abs(new_grid_pos.y - last_grid_pos.y)

			if current_path.is_empty() or (dx <= 1 and dy <= 1 and (dx == 0 or dy == 0)):
				# 如果是相邻的（水平或垂直），直接添加
				_add_point_to_path(new_grid_pos)
			elif dx > 1 or dy > 1:
				# 如果跳过了格子，则进行插值填充
				var interpolated_points = _interpolate_path(last_grid_pos, new_grid_pos)
				for point in interpolated_points:
					_add_point_to_path(point)
			
			_update_preview()

	# 鼠标左键释放，尝试完成建造
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		var grid_pos = grid_manager.world_to_grid(event.position)
		var target_node = grid_manager.get_grid_object(grid_pos)

		if target_node is Pipe and target_node != start_pipe:
			# 如果是有效的管道，完成建造
			_finish_building(target_node, grid_pos)
		else:
			# 否则取消建造
			_cancel_building()

# --- 辅助函数：添加点到路径，并处理重复点 ---
func _add_point_to_path(point: Vector2i):
	# 检查新点是否在边界内
	if not grid_manager.is_within_bounds(point):
		return # 如果超出边界，则不添加

	if current_path.has(point):
		# 如果点已经在路径中，截断路径到该点
		var idx = current_path.find(point)
		current_path = current_path.slice(0, idx + 1)
	else:
		# 如果点是新的，添加到路径末尾
		current_path.append(point)

# --- 辅助函数：插值填充路径（简化版，仅用于填补鼠标快速移动导致的跳格）---
func _interpolate_path(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	var interpolated_points: Array[Vector2i] = []
	var dx = abs(end.x - start.x)
	var dy = abs(end.y - start.y)

	# 优先填补水平方向
	if dx > dy:
		var step_x = 1 if end.x > start.x else -1
		for x in range(start.x + step_x, end.x + step_x, step_x):
			interpolated_points.append(Vector2i(x, start.y))
	# 然后填补垂直方向
	else:
		var step_y = 1 if end.y > start.y else -1
		for y in range(start.y + step_y, end.y + step_y, step_y):
			interpolated_points.append(Vector2i(start.x, y))
	
	return interpolated_points


# --- 建造流程 ---

func start_building(pipe: Pipe, start_pos: Vector2i):
	if build_mode:
		return
	
	build_mode = true
	start_pipe = pipe
	self.start_pos = start_pos
	current_path = [start_pos]
	
	preview_line.visible = true
	grid_manager.show_grid()
	Input.set_default_cursor_shape(Input.CURSOR_CROSS)

func _finish_building(end_pipe: Pipe, end_pos: Vector2i):
	print("--- 开始建造流程 ---")
	if not current_path.has(end_pos):
		current_path.append(end_pos)
		
	var path_to_check = current_path.slice(1, current_path.size() - 1)
	var is_available = grid_manager.is_grid_available(path_to_check)

	if is_available:
		if start_pipe.pipe_type != end_pipe.pipe_type:
			printerr("管道类型不匹配！")
			_cancel_building()
			return
			
		_create_bridge_segments()
		connection_manager.add_connection(start_pipe, end_pipe)
		
		start_pipe.mark_pipe_as_used()
		end_pipe.mark_pipe_as_used()
	else:
		print("!!! 建造失败: 路径被阻挡")
	
	_reset_build_mode()
	print("--- 建造流程结束 ---")

func _cancel_building():
	print("--- 建造取消 ---")
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
	if current_path.size() < 2:
		return # 路径太短，无法创建桥梁

	# 为了进行邻居检查，我们需要一个包含所有连接点的集合，
	# 包括管道背后的“虚拟”点。
	var full_connection_set = {}
	for pos in current_path:
		full_connection_set[pos] = true
	
	# 添加起始管道背后的虚拟点
	var start_dir = (current_path[0] - current_path[1])
	full_connection_set[current_path[0] + start_dir] = true
	
	# 添加末端管道背后的虚拟点
	var end_dir = (current_path.back() - current_path[current_path.size() - 2])
	full_connection_set[current_path.back() + end_dir] = true

	# 现在为路径中的每个真实点创建桥梁段
	for grid_pos in current_path:
		var neighbors = {
			"north": full_connection_set.has(grid_pos + Vector2i.UP),
			"south": full_connection_set.has(grid_pos + Vector2i.DOWN),
			"east": full_connection_set.has(grid_pos + Vector2i.RIGHT),
			"west": full_connection_set.has(grid_pos + Vector2i.LEFT)
		}
		
		var bridge_segment = BridgeScene.instantiate()
		var world_pos = grid_manager.grid_to_world(grid_pos)
		
		if not bridges_container:
			printerr("无法创建桥梁段: 'bridges_container' 未在编辑器中指定!")
			return

		bridges_container.add_child(bridge_segment)
		bridge_segment.global_position = world_pos
		
		bridge_segment.bridge_selected.connect(ui_manager._on_bridge_selected)
		bridge_segment.setup_segment(grid_pos)
		bridge_segment.setup_bridge_tile(neighbors)

	print("桥梁段创建完毕")

func _on_mouse_exited():
	if build_mode:
		print("鼠标移出窗口，建造取消。")
		_cancel_building()


# --- 路径预览 ---

func _update_preview():
	preview_line.clear_points()
	if current_path.size() < 2:
		return
		
	for grid_pos in current_path:
		preview_line.add_point(grid_manager.grid_to_world(grid_pos))
