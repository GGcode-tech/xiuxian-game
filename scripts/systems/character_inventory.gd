## CharacterInventory - 角色物品管理
## 从character.gd拆分出来的物品相关方法
class_name CharacterInventory
extends RefCounted


var _owner  # Character type (avoid circular dependency with class_name)


func init(p_owner) -> void:
	_owner = p_owner


func add_item(item) -> bool:
	# 检查是否可堆叠
	if item is Dictionary:
		var item_id = item.get("id", item.get("item_id", ""))
		var count = item.get("count", 1)
		# 简化版：直接添加到inventory数组
		_owner.inventory.append(item)
		return true

	var item_data = item.get_item_data() if item.has_method("get_item_data") else null
	if item_data and item_data.get("stackable", false):
		for inv_item in _owner.inventory:
			if inv_item.get("item_id", "") == item.get("item_id", "") \
					and inv_item.get("count", 0) < item_data.get("max_stack", 99):
				var can_add = item_data.get("max_stack", 99) - inv_item.get("count", 0)
				var to_add = mini(can_add, item.get("count", 1))
				inv_item["count"] = inv_item.get("count", 0) + to_add
				item["count"] = item.get("count", 1) - to_add
				if item.get("count", 1) <= 0:
					return true

	# 添加到背包
	if _owner.inventory.size() < DataManager.constants.get("max_inventory_slots", 50):
		_owner.inventory.append(item)
		return true

	return false


func remove_item(item_id: String, amount: int = 1) -> bool:
	for i in range(_owner.inventory.size()):
		if _owner.inventory[i].item_id == item_id:
			if _owner.inventory[i].count <= amount:
				_owner.inventory.remove_at(i)
				return true
			_owner.inventory[i].count -= amount
			return true
	return false


func has_item(item_id: String, amount: int = 1) -> bool:
	for inv_item in _owner.inventory:
		var iid = inv_item.get(
			"item_id",
			inv_item.get("id", "")
		) if inv_item is Dictionary else inv_item.get(
			"item_id", "")
		var cnt = inv_item.get("count", 1) if inv_item is Dictionary else 1
		if iid == item_id and cnt >= amount:
			return true
	return false


func get_item_count(item_id: String) -> int:
	var count = 0
	for inv_item in _owner.inventory:
		var iid = inv_item.get("item_id", inv_item.get("id", "")) if inv_item is Dictionary else ""
		var cnt = inv_item.get("count", 1) if inv_item is Dictionary else 1
		if iid == item_id:
			count += cnt
	return count
