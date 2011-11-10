--[[ Baggotry
     A bag addon of no specific functionality

]]--

local bag = {}
bag.version = "VERSION"
Baggotry = bag

function bag.printf(fmt, ...)
  print(string.format(fmt or 'nil', ...))
end

function bag.find(item_name)
  local found = 0
  local slots = {}
  if not item_name then
    return found, slots
  end
  for slot, v in pairs(Inspect.Item.Detail("si")) do
    if string.match(v['name'], item_name) then
      table.insert(slots, slot)
      if v['stack'] then
        found = found + v['stack']
      else
        found = found + 1
      end
    end
  end
  table.sort(slots)
  return found, slots
end

function bag.scratch_slot()
  for k, v in pairs(Inspect.Item.List("si")) do
    if v == false then
      return k
    end
  end
  return false
end

function bag.merge(item_name, slots)
  -- first, figure out whether we CAN merge them.
  local remove_us = {}
  local details = {}
  local keep_slots = {}
  local stack_size
  local found_items = 0
  local found_slots = 0
  for i, v in ipairs(slots) do
    local this_item = Inspect.Item.Detail(v)
    if this_item then
      if this_item.name == item_name then
	if not stack_size then
	  stack_size = this_item.stackMax or 1
	  if stack_size < 2 then
	    bag.printf("Can't merge items which don't stack.")
	    return
	  end
	end
	local stack = this_item.stack or 1
	-- we ignore full stacks, as they're irrelevant to a merge
	if stack < stack_size then
	  details[v] = this_item
	  table.insert(keep_slots, v)
	  found_slots = found_slots + 1
	  found_items = found_items + stack
	end
      end
    end
  end
  if table.getn(keep_slots) == 0 then
    bag.printf("Ended up with no slots that can be merged.")
    return
  end
  local needed = math.ceil(found_items / stack_size)
  bag.printf("%s: Found %d in %d slot%s (need %d).", item_name, found_items,
  	found_slots,
	(found_slots == 1) and "" or "s",
	needed)
  if needed > found_slots then
    return
  end
  -- if we got here, we think we could eliminate at least one slot.
  -- local scratch = bag.scratch_slot()


  bag.printf("Unimplemented.")
end

function bag.split(item_name, split_into)
  bag.printf("Unimplemented.")
end

function bag.slashcommand(args)
  bag.printf("version %s", bag.version)
  local count, merge, split
  count = false
  merge = false
  split = false
  split_into = 10
  if args['c'] then
    count = true
  end
  if args['m'] then
    merge = true
  end
  if args['s'] then
    split = args['s']
  end
  for k, item_name in pairs(args['leftover_args']) do
    local found, slots = bag.find(item_name)
    if count then
      if found > 0 then
        bag.printf("%s: %d", item_name, found)
      else
        bag.printf("%s: none found", item_name)
      end
    end
    if found > 0 and merge then
      bag.merge(item_name, slots)
    end
    if found > 0 and split then
      local found = bag.count(item_name)
      bag.printf("%s: %d to split into %d", item_name, found, split)
      if found > split then
        bag.split(item_name, split)
      end
    end
  end
end

Library.LibGetOpt.makeslash("cms#", "Baggotry", "bag", bag.slashcommand)
