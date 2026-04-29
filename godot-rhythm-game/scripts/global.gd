extends Node

var selected_chart: String = "test"

# Stores the user's selected arrow type ("arrow", "circle", "triangle", "star")
var arrow_type: String = "arrow"


var achievements = {
        "first_note": {
                "title": "First Steps",
                "description": "Hit your first note.",
                "unlocked": false
        },
        "full_combo": {
                "title": "Full Combo!",
                "description": "Complete a song without missing.",
                "unlocked": false
        },
        "play_story": {
                "title": "Story Time",
                "description": "Click on Story Mode.",
                "unlocked": false
        }
}

func unlock_achievement(id: String) -> void:
        if achievements.has(id) and not achievements[id]["unlocked"]:
                achievements[id]["unlocked"] = true
                show_achievement_popup(achievements[id])

func show_achievement_popup(data: Dictionary) -> void:
        var canvas = CanvasLayer.new()
        canvas.layer = 100 
        add_child(canvas)
        
        var panel = PanelContainer.new()
        canvas.add_child(panel)
        
        
        var style = StyleBoxFlat.new()
        style.bg_color = Color(0.15, 0.15, 0.15, 0.9)
        style.border_width_left = 2
        style.border_width_top = 2
        style.border_width_right = 2
        style.border_width_bottom = 2
        style.border_color = Color(0.8, 0.8, 0.3)
        style.corner_radius_top_left = 5
        style.corner_radius_top_right = 5
        style.corner_radius_bottom_right = 5
        style.corner_radius_bottom_left = 5
        panel.add_theme_stylebox_override("panel", style)
        
        var margin = MarginContainer.new()
        margin.add_theme_constant_override("margin_left", 10)
        margin.add_theme_constant_override("margin_top", 10)
        margin.add_theme_constant_override("margin_right", 10)
        margin.add_theme_constant_override("margin_bottom", 10)
        panel.add_child(margin)
        
        var vbox = VBoxContainer.new()
        margin.add_child(vbox)
        
        var title = Label.new()
        title.text = "Achievement Unlocked!"
        title.add_theme_color_override("font_color", Color(1, 1, 0))
        vbox.add_child(title)
        
        var name_label = Label.new()
        name_label.text = data["title"]
        vbox.add_child(name_label)
        
        
        panel.size = Vector2(250, 70)
        panel.position = Vector2(-300, 20)
        
      
        var tween = create_tween()
        tween.tween_property(panel, "position", Vector2(20, 20), 0.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
        tween.tween_interval(3.0)
       
        tween.tween_property(panel, "position", Vector2(-300, 20), 0.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
        tween.tween_callback(canvas.queue_free)
