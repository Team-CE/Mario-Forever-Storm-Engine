extends Node

export var connect_app_id: String
export var set_state: String
export var set_details: String
export var set_big_image_key: String
export var set_big_image_text: String
export var set_timestamp: bool

func _ready() -> void:
  call_deferred('configure_rpc')

func configure_rpc() -> void:
  if !DiscordManager.core:
    print('[DiscordManager] Creating a new core')
    var res = DiscordManager.create_core(int(connect_app_id))
    if !res: return
  else:
    print('[DiscordManager] Using an existing core')
    
  var activity: = Discord.Activity.new()
  if set_state:          activity.state = set_state
  if set_details:        activity.details = set_details
  if set_timestamp:      activity.timestamps.start = OS.get_unix_time()
  if set_big_image_key:  activity.assets.large_image = set_big_image_key
  if set_big_image_text: activity.assets.large_text = set_big_image_text

  DiscordManager.activities.update_activity(activity)

func _exit_tree() -> void:
  if DiscordManager.core:
    DiscordManager.destroy_core()
  queue_free()
