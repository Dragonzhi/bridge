extends Node2D
class_name Pipe

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var area_2d: Area2D = $Area2D

enum PipeType {
	LIFE,
	SUPPLY,
	SIGNAL
}

@export var pipe_type : PipeType
## 每秒传输的资源量
@export var resource_per_second: float = 1.0

var is_connected_local: bool = false
var grid_manager: GridManager

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 获取GridManager引用
	grid_manager = get_node("/root/Main/GridManager")
	if not grid_manager:
		print("错误: 找不到GridManager")
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	pass

func on_connected():
	is_connected_local = true
	# 根据管道类型触发不同效果
	match pipe_type:
		PipeType.LIFE:
			pass
			#GameManager.add_health_flow(resource_per_second)
		PipeType.SUPPLY:
			pass
			#ResourceManager.add_income(resource_per_second)
		PipeType.SIGNAL:
			pass
			#SignalManager.activate_signal_zone(self)

func get_pipe_under_mouse():
	pass

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			print("鼠标左键按下 - 管道类型: ", pipe_type)
			print("管道位置: ", global_position)
			
			# 显示网格
			if grid_manager:
				grid_manager.toggle_grid()
			
			# 显示网格坐标
			var grid_pos = grid_manager.world_to_grid(global_position)
			print("管道网格坐标: ", grid_pos)
			
			# 可以在这里添加高亮效果
			sprite_2d.modulate = Color.YELLOW
			
		else:
			#print("鼠标左键释放")
			# 恢复原始颜色
			sprite_2d.modulate = Color.WHITE

# 当鼠标进入管道区域时
func _on_area_2d_mouse_entered() -> void:
	# 鼠标悬停效果
	sprite_2d.modulate = Color.LIGHT_BLUE

# 当鼠标离开管道区域时
func _on_area_2d_mouse_exited() -> void:
	# 如果不是被点击状态，恢复原始颜色
	#if not (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
	sprite_2d.modulate = Color.WHITE
