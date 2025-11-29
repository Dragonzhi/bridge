extends Node2D
class_name Bridge

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var repair_timer: Timer = $RepairTimer

@export var max_health: float = 100.0
@export var repair_time: float = 3.0

var current_health: float
var grid_manager: GridManager
var grid_pos: Vector2i
var is_destroyed: bool = false
var tile_animation_name: String # 存储正确的瓦片动画名称

signal bridge_selected(bridge: Bridge)

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

func setup_bridge_tile(neighbors: Dictionary):
	var has_north = neighbors.get("north", false)
	var has_south = neighbors.get("south", false)
	var has_east = neighbors.get("east", false)
	var has_west = neighbors.get("west", false)
	
	var connection_count = [has_north, has_south, has_east, has_west].count(true)
	
	match connection_count:
		4:
			tile_animation_name = "四向"
		3:
			tile_animation_name = "三向"
			if not has_west: animated_sprite.rotation_degrees = 0
			elif not has_north: animated_sprite.rotation_degrees = 90
			elif not has_east: animated_sprite.rotation_degrees = 180
			elif not has_south: animated_sprite.rotation_degrees = 270
		2:
			# 二向: 直线或拐角
			if (has_north and has_south): # 直线 (垂直)
				tile_animation_name = "二向"
				animated_sprite.rotation_degrees = 0
			elif (has_east and has_west): # 直线 (水平)
				tile_animation_name = "二向"
				animated_sprite.rotation_degrees = 90
			else: # 拐角
				tile_animation_name = "拐角" 
				# 默认 "拐角" 连接北和东
				if has_north and has_east:
					animated_sprite.rotation_degrees = 0
				elif has_south and has_east:
					animated_sprite.rotation_degrees = 90
				elif has_south and has_west:
					animated_sprite.rotation_degrees = 180
				elif has_north and has_west:
					animated_sprite.rotation_degrees = 270
		1:
			tile_animation_name = "单向"
			if has_south: animated_sprite.rotation_degrees = 0
			elif has_west: animated_sprite.rotation_degrees = 90
			elif has_north: animated_sprite.rotation_degrees = 180
			elif has_east: animated_sprite.rotation_degrees = 270
		_:
			tile_animation_name = "单向"
	
	animated_sprite.animation = tile_animation_name

func take_damage(amount: float):
	if is_destroyed: return
	current_health -= amount
	print("桥段 %s 受到 %s点伤害, 剩余生命值: %s" % [grid_pos, amount, current_health])
	if current_health <= 0:
				current_health = 0
				is_destroyed = true
				animated_sprite.modulate = Color(0.4, 0.4, 0.4) # 变暗表示损坏，但更可见
				animated_sprite.stop()
				print("桥段 %s 已被摧毁！" % grid_pos)
func repair():
	print("桥段 %s 已修复！" % grid_pos)
	is_destroyed = false
	current_health = max_health
	animated_sprite.modulate = Color.WHITE
	animated_sprite.animation = tile_animation_name # 恢复正确的静态帧
	animated_sprite.frame = animated_sprite.sprite_frames.get_frame_count(tile_animation_name) - 1 # 显示最后一帧

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
			animated_sprite.animation = tile_animation_name # 播放正确的动画
			animated_sprite.play() # 开始播放修理动画
			repair_timer.start()
		elif not is_destroyed:
			emit_signal("bridge_selected", self)
		get_viewport().set_input_as_handled()
