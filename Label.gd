extends Label


onready var Player = get_parent().get_parent()

func update_stamina(stm, max_stm):
	set_text(str(stm) + "/" + str(max_stm))

func _ready():
	Player.connect("staminaHUD", self, "update_stamina")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
