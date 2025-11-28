extends PathFollow2D
class_name BaseEnemy

@export var max_hp: float = 100.0 # 最大生命值/冷静值
@export var current_hp: float # 当前生命值/冷静值
@export var move_speed: float = 50.0 # 移动速度 (单位/秒)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_hp = max_hp
	# 当PathFollow2D的循环被禁用时，它会在路径末端停止。
	# 我们可以在这里或通过信号处理敌人到达终点的逻辑。
	# set_loop(false) # 确保默认不循环

# Called every physics frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# 只需增加进度，PathFollow2D会自动处理位置和旋转
	progress += move_speed * delta
	
	# TODO: 检查是否到达路径终点
	# 可以通过检查 progress >= get_path().curve.get_baked_length()
	# 或者监听PathFollow2D的相关信号（如果适用）
