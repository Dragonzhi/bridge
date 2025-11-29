extends Node2D
class_name Bridge

@onready var sprite: Sprite2D = $Sprite2D
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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# 设置桥梁段并将其注册到GridManager
func setup_segment(grid_pos: Vector2i):
	self.grid_pos = grid_pos
	if not grid_manager:
		grid_manager = get_node("/root/Main/GridManager")

	if grid_manager:
		grid_manager.set_grid_occupied(grid_pos, self)
	else:
		printerr("无法注册桥梁段: 找不到GridManager")

func take_damage(amount: float):
	if is_destroyed:
		return # 桥段已损坏，不再接受伤害

	current_health -= amount
	print("桥段 %s 受到 %s点伤害, 剩余生命值: %s" % [grid_pos, amount, current_health])

	if current_health <= 0:
		current_health = 0
		is_destroyed = true
		sprite.modulate = Color(0.2, 0.2, 0.2) # 变暗表示损坏
		print("桥段 %s 已被摧毁！" % grid_pos)

func repair():
	print("桥段 %s 已修复！" % grid_pos)
	is_destroyed = false
	current_health = max_health
	sprite.modulate = Color.WHITE

func _on_area_2d_mouse_entered() -> void:
	# 仅在桥梁未被摧毁且未在修理时显示悬浮效果
	if not is_destroyed and repair_timer.is_stopped():
		sprite.modulate = Color(0.8, 0.8, 0.5) # 淡黄色

func _on_area_2d_mouse_exited() -> void:
	# 仅在桥梁未被摧毁且未在修理时恢复颜色
	if not is_destroyed and repair_timer.is_stopped():
		sprite.modulate = Color.WHITE

func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	# 检测鼠标左键点击事件
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		# 如果桥梁被摧毁且修理计时器未运行，则开始修理
		if is_destroyed and repair_timer.is_stopped():
			print("开始修理桥段 %s..." % grid_pos)
			sprite.modulate = Color(0.2, 0.5, 1.0) # 蓝色表示正在修理
			repair_timer.start()
		# 否则，如果桥梁是好的，则发出选中信号
		elif not is_destroyed:
			emit_signal("bridge_selected", self)
		
		get_viewport().set_input_as_handled() # 阻止事件进一步传播
