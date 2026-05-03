extends CanvasLayer

@onready var master_slider = $CenterContainer/VBoxContainer/HBoxMaster/MasterSlider
@onready var master_val_label = $CenterContainer/VBoxContainer/HBoxMaster/MasterVal

@onready var music_slider = $CenterContainer/VBoxContainer/HBoxMusic/MusicSlider
@onready var music_val_label = $CenterContainer/VBoxContainer/HBoxMusic/MusicVal

@onready var sfx_slider = $CenterContainer/VBoxContainer/HBoxSFX/SFXSlider
@onready var sfx_val_label = $CenterContainer/VBoxContainer/HBoxSFX/SFXVal

@onready var back_button = $CenterContainer/VBoxContainer/BackButton

func _ready() -> void:
    if Global:
        master_slider.value = Global.master_volume * 100
        music_slider.value = Global.music_volume * 100
        sfx_slider.value = Global.sfx_volume * 100

    _update_labels()

    master_slider.value_changed.connect(_on_master_changed)
    music_slider.value_changed.connect(_on_music_changed)
    sfx_slider.value_changed.connect(_on_sfx_changed)
    back_button.pressed.connect(_on_back_pressed)

func _update_labels():
    master_val_label.text = str(int(master_slider.value)) + "%"
    music_val_label.text = str(int(music_slider.value)) + "%"
    sfx_val_label.text = str(int(sfx_slider.value)) + "%"

func _on_master_changed(value: float) -> void:
    if Global:
        Global.master_volume = value / 100.0
        Global.apply_volumes()
    _update_labels()

func _on_music_changed(value: float) -> void:
    if Global:
        Global.music_volume = value / 100.0
        Global.apply_volumes()
    _update_labels()

func _on_sfx_changed(value: float) -> void:
    if Global:
        Global.sfx_volume = value / 100.0
        Global.apply_volumes()
    _update_labels()

func _on_back_pressed() -> void:
    if Global:
        Global.save_settings_to_disk()
    queue_free()

