extends Node2D
class_name BridgeBuilder

var grid_manager = GridManager

var build_mode: bool = false
var start_pipe: Pipe = null
var current_path: Array[Vector2i] = [] # 存储当前路径的网格坐标
var preview_segments: Array[Line2D] = [] # 预览线段

# 开始建造模式
func start_building(pipe: Pipe):
	if build_mode:
		return
	
	build_mode = true
	start_pipe = pipe
	Input.set_default_cursor_shape(Input.CURSOR_CROSS)

# 更新路径预览
func update_preview(end_world_pos: Vector2):
	if not build_mode:
		return
	
	# 清除旧预览
	clear_preview()
	
	# 计算路径
	var start_grid = grid_manager.world_to_grid(start_pipe.global_position)
	var end_grid = grid_manager.world_to_grid(end_world_pos)
	
	current_path = calculate_path(start_grid, end_grid)
	
	# 可视化预览路径
	visualize_path(current_path, Color.LIGHT_BLUE)

# 计算直角路径 (A*算法或简单直线)
func calculate_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	path.append(from)
	
	# 简单的直角路径：先水平后垂直
	path.append(Vector2i(to.x, from.y))
	path.append(to)
	
	return path

# 可视化路径
func visualize_path(path: Array[Vector2i], color: Color):
	for i in range(path.size() - 1):
		var segment = Line2D.new()
		segment.width = 6
		segment.default_color = color
		segment.add_point(grid_manager.grid_to_world(path[i]))
		segment.add_point(grid_manager.grid_to_world(path[i + 1]))
		add_child(segment)
		preview_segments.append(segment)

# 完成建造
func finish_building(end_pipe: Pipe):
	if not build_mode or current_path.is_empty():
		return
	
	# 检查路径是否可用
	for grid_pos in current_path:
		if not grid_manager.is_grid_available(grid_pos):
			# 路径被阻挡，不能建造
			clear_preview()
			build_mode = false
			return
	
	# 创建桥梁
	create_bridge_segments(current_path)
	
	clear_preview()
	build_mode = false
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

# 创建实际的桥梁段
func create_bridge_segments(path: Array[Vector2i]):
	for i in range(path.size() - 1):
		var segment = BridgeSegment.new()
		segment.setup_segment(path[i], path[i + 1], grid_manager)
		get_parent().get_node("World/Bridges").add_child(segment)

func clear_preview():
	for segment in preview_segments:
		segment.queue_free()
	preview_segments.clear()

func _input(event):
	if event is InputEventMouseMotion and build_mode:
		update_preview(event.position)
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed and build_mode: # 鼠标释放
			var end_pipe:Pipe
			if end_pipe and end_pipe != start_pipe:
				finish_building(end_pipe)
			else:
				# 点击在空处，取消建造
				clear_preview()
				build_mode = false
