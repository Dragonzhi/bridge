extends Node2D

@export var enemy_scene: PackedScene

var grid_manager: GridManager
@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D
@onready var path_node: Path2D = $Path
@onready var spawn_timer: Timer = $SpawnTimer

# 节点进入场景树时首次调用。
func _ready() -> void:
	# 延迟执行占用逻辑到下一帧，确保GridManager已准备就绪
	# 并且全局位置准确。
	call_deferred("_register_occupied_cells")
	
	# 连接计时器的timeout信号
	if spawn_timer:
		spawn_timer.timeout.connect(spawn_enemy)

func spawn_enemy():
	if not enemy_scene:
		printerr("敌人生成点错误: 未在编辑器中设置 'Enemy Scene'！")
		return
	
	if not path_node:
		printerr("敌人生成点错误: 未找到名为 'Path' 的Path2D子节点！")
		return
	
	var enemy_instance = enemy_scene.instantiate()
	
	# PathFollow2D通过成为Path2D的子节点来工作
	# 我们直接将敌人实例添加到路径节点下
	path_node.add_child(enemy_instance)
	
	print("一个敌人已被生成到路径上！")

func _register_occupied_cells():
	grid_manager = get_node("/root/Main/GridManager")
	if not grid_manager:
		printerr("敌人生成点错误: 未找到GridManager！")
		return
	
	if not collision_shape:
		printerr("敌人生成点错误: 未在'Area2D/CollisionShape2D'找到CollisionShape2D节点！")
		return

	# 获取碰撞体的全局变换及其本地边界框
	var shape_transform = collision_shape.global_transform
	var shape_rect = collision_shape.shape.get_rect()
	
	# 计算形状的全局边界框
	var global_aabb = shape_transform * shape_rect
	
	# 将边界框的角点转换为网格坐标
	var top_left_world = global_aabb.position
	var bottom_right_world = global_aabb.position + global_aabb.size
	
	var start_grid_pos = grid_manager.world_to_grid(top_left_world)
	var end_grid_pos = grid_manager.world_to_grid(bottom_right_world)
	
	# 确保循环方向始终是从较小坐标到较大坐标
	var min_x = min(start_grid_pos.x, end_grid_pos.x)
	var max_x = max(start_grid_pos.x, end_grid_pos.x)
	var min_y = min(start_grid_pos.y, end_grid_pos.y)
	var max_y = max(start_grid_pos.y, end_grid_pos.y)
	
	# 遍历边界框内的所有网格单元并占用它们
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			var grid_pos = Vector2i(x, y)
			if grid_manager.is_within_bounds(grid_pos):
				grid_manager.set_grid_occupied(grid_pos, self)
	
	print("敌人生成点在 %s 占用了从 %s 到 %s 的格子" % [global_position, start_grid_pos, end_grid_pos])
