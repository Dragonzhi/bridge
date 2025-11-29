extends Node2D
class_name Bridge

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var repair_timer: Timer = $RepairTimer

@export var max_health: float = 100.0
@export var repair_time: float = 3.0

var current_health: float
var grid_manager: GridManager
var grid_pos: Vector2i # 存储该桥段在网格中的位置
var is_destroyed: bool = false

signal bridge_selected(bridge: Bridge)

# 节点首次进入场景树时调用。
func _ready() -> void:
	current_health = max_health
	grid_manager = get_node("/root/Main/GridManager")
	if not grid_manager:
		printerr("错误: 找不到GridManager")
	repair_timer.wait_time = repair_time
	repair_timer.timeout.connect(repair)

func setup_segment(grid_pos: Vector2i):
	self.grid_pos = grid_pos
	if not grid_manager:
		grid_manager = get_node("/root/Main/GridManager")

	if grid_manager:
		grid_manager.set_grid_occupied(grid_pos, self)
	else:
		printerr("无法注册桥梁段: 找不到GridManager")

# 根据邻居信息设置桥梁瓦片样式和旋转
func setup_bridge_tile(neighbors: Dictionary):
	var has_north = neighbors.get("north", false)
	var has_south = neighbors.get("south", false)
	var has_east = neighbors.get("east", false)
	var has_west = neighbors.get("west", false)
	
	var connection_count = [has_north, has_south, has_east, has_west].count(true)
	
	match connection_count:
		4:
			animated_sprite.animation = "四向"
		3:
			animated_sprite.animation = "三向"
			if not has_west: # 默认样式: N, E, S
				animated_sprite.rotation_degrees = 0
			elif not has_north: # W, E, S
				animated_sprite.rotation_degrees = 90
			elif not has_east: # N, W, S
				animated_sprite.rotation_degrees = 180
			elif not has_south: # N, W, E
				animated_sprite.rotation_degrees = 270
		2:
			# 二向: 直线或拐角
			if (has_north and has_south): # 直线 (垂直)
				animated_sprite.animation = "二向"
				animated_sprite.rotation_degrees = 0
			elif (has_east and has_west): # 直线 (水平)
				animated_sprite.animation = "二向"
				animated_sprite.rotation_degrees = 90
			else: # 拐角
				# 假设 "二向" 是一个拐角瓦片, 默认朝向南-东
				# 这里需要一个专门的拐角动画，暂时用 "二向" 代替
				# print("警告: 缺少拐角专用的桥梁动画，使用'二向'代替。")
				animated_sprite.animation = "二向" 
				if has_south and has_east: # S-E corner
					animated_sprite.rotation_degrees = 0
				elif has_south and has_west: # S-W corner
					animated_sprite.rotation_degrees = 90
				elif has_north and has_west: # N-W corner
					animated_sprite.rotation_degrees = 180
				elif has_north and has_east: # N-E corner
					animated_sprite.rotation_degrees = 270
		1:
			animated_sprite.animation = "单向"
			if has_south:
				animated_sprite.rotation_degrees = 0
			elif has_west:
				animated_sprite.rotation_degrees = 90
			elif has_north:
				animated_sprite.rotation_degrees = 180
			elif has_east:
				animated_sprite.rotation_degrees = 270
		_:
			# 0个或未知数量的连接，可能只在路径的起点/终点发生
			# 可以设置一个默认或隐藏
			animated_sprite.animation = "单向"

func take_damage(amount: float):
	if is_destroyed:
		return

	current_health -= amount
	print("桥段 %s 受到 %s点伤害, 剩余生命值: %s" % [grid_pos, amount, current_health])

	if current_health <= 0:
		current_health = 0
		is_destroyed = true
		animated_sprite.modulate = Color(0.2, 0.2, 0.2) # 变暗表示损坏
		print("桥段 %s 已被摧毁！" % grid_pos)

func repair():
	print("桥段 %s 已修复！" % grid_pos)
	is_destroyed = false
	current_health = max_health
	animated_sprite.modulate = Color.WHITE

func _on_area_2d_mouse_entered() -> void:
	if not is_destroyed and repair_timer.is_stopped():
		animated_sprite.modulate = Color(0.8, 0.8, 0.5)

func _on_area_2d_mouse_exited() -> void:
	if not is_destroyed and repair_timer.is_stopped():
		animated_sprite.modulate = Color.WHITE

func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		if is_destroyed and repair_timer.is_stopped():
			print("开始修理桥段 %s..." % grid_pos)
			animated_sprite.modulate = Color(0.2, 0.5, 1.0)
			repair_timer.start()
		elif not is_destroyed:
			emit_signal("bridge_selected", self)
		
		get_viewport().set_input_as_handled()
