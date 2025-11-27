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
var bridge_builder: BridgeBuilder

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 获取单例引用
	grid_manager = get_node("/root/Main/GridManager")
	bridge_builder = get_node("/root/Main/BridgeBuilder")
	if not grid_manager:
		printerr("错误: 找不到GridManager")
	if not bridge_builder:
		printerr("错误: 找不到BridgeBuilder")

	# 在GridManager中注册自己的位置
	var grid_pos = grid_manager.world_to_grid(global_position)
	grid_manager.set_grid_occupied(grid_pos, self)


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

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# 通知BridgeBuilder开始建造
			if bridge_builder:
				bridge_builder.start_building(self)
		else:
			# 释放鼠标按钮的逻辑（如果需要的话）现在由BridgeBuilder处理
			pass

# 当鼠标进入管道区域时
func _on_area_2d_mouse_entered() -> void:
	# 鼠标悬停效果
	sprite_2d.modulate = Color.LIGHT_BLUE

# 当鼠标离开管道区域时
func _on_area_2d_mouse_exited() -> void:
	# 恢复原始颜色
	sprite_2d.modulate = Color.WHITE
