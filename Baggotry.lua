--[[ Baggotry
     A bag addon of no specific functionality

]]--

local addoninfo, bag = ...
local lbag = Library.LibBaggotry
local filt = Library.LibEnfiltrate
bag.version = "VERSION"

bag.filters = {}

function bag.printf(fmt, ...)
  print(string.format(fmt or 'nil', ...))
end

function valuation(details, slot, value)
  value = value or 0
  if details.sell then
    value = value + details.sell
  end
  return value
end

function bag.slashcommand(args)
  local stack = false
  local dump = false
  local gold = false
  local merge = false
  local move = false
  local slotspecs = {}
  local filter
  local temporary = false
  local created = false
  local stack_size = nil
  if not args then
    return
  end
  if args.v then
    bag.printf("version %s", bag.version)
    return
  end
  if args.f then
    filter = filt.Filter:load(args.f, 'Baggotry')
    if not filter then
      filter = filt.Filter:new(args.f, 'item', 'Baggotry')
      created = true
    end
    args.f = nil
  else
    filter = filt.Filter:new(nil, 'item', 'Baggotry')
    temporary = true
  end

  if args.M then
    if args.M == 'bank' then
      move = Utility.Item.Slot.Bank()
    elseif args.M == 'inventory' then
      move = Utility.Item.Slot.Inventory()
    elseif lbag.slotspec_p(args.M) then
      move = args.M
    else
      bag.printf("Unknown slotspec '%s': should be slotspec, 'bank', or 'inventory'.", args.M)
    end
  end

  if args.d then
    if filter then
      filter:dump()
    end
    args.d = nil
  end

  if args.l then
    local ordered = {}
    local filters = filt.Filter:list('Baggotry')
    for k, v in pairs(filt.Filter:list('Baggotry')) do
      table.insert(ordered, k)
    end
    table.sort(ordered)
    for _, v in ipairs(ordered) do
      local filter = filt.Filter:load(v, 'Baggotry')
      if filter then
        filter:dump()
      else
        bag.printf("Filter <%s>: Can't load.", v)
      end
    end
    return
  end
  if args.S then
    stack = true
    stack_size = args.S
    args.S = nil
  end
  if args.D then
    dump = true
    args.D = nil
  end
  if args.m then
    merge = true
    args.m = nil
  end
  if args.g then
    gold = true
    args.g = nil
  end

  local changed= false
  if lbag.apply_args(filter, args) then changed = true end
  if filter:apply_args(args, true) then changed = true end
  if changed then
    if not temporary then
      filter:save()
    end
  else
    if created then
      bag.printf("Found no filter named '%s'.", filter.name)
      return
    end
  end

  if dump then
    filter:dump()
    return
  end

  if gold then
    local total, count

    total, count = lbag.iterate(filter, valuation)

    local silver = total % 100
    local gold = math.floor(total / 100)
    local plat = math.floor(gold / 100)
    gold = gold % 100
    if plat > 0 then
      bag.printf("%d item(s), total value: %dp%dg%ds.", count, plat, gold, silver)
    elseif gold > 0 then
      bag.printf("%d item(s), total value: %dg%ds.", count, gold, silver)
    elseif silver > 0 then
      bag.printf("%d item(s), total value: %ds.", count, silver)
    else
      bag.printf("Total value: none.")
    end
    return
  end
  if stack then
    lbag.stack(filter, stack_size, true)
  end
  if move then
    lbag.move_items(filter, move, true)
  end
  if not (stack or move) then
    if merge then
      filter = lbag.merge_items(lbag.expand(filter))
    end
    lbag.dump(filter)
  end
end

function bag.tooltip_update(data)
  -- do nothing
  local whoami = string.lower(Inspect.Unit.Detail('player').name)
  local maxwidth = 0
  local counter = 0
  local charcounts = {}
  local characters = {}
  local mine = {}
  local found_any = false
  for _, details in pairs(data) do
    local c = details._character
    local s = details._slotspec
    if c == whoami then
      local ok, val = pcall(function() return Utility.Item.Slot.Parse(s) end)
      if ok then
        c = val or s or 'nil'
      else
        c = 'owned'
	bag.printf("error: %s", type)
      end
      mine[c] = true
    end
    if charcounts[c] then
      charcounts[c] = charcounts[c] + (details.stack or 1)
    else
      charcounts[c] = details.stack or 1
      table.insert(characters, c)
    end
    found_any = true
  end
  if not found_any then
    return false
  end
  table.sort(characters, function(a, b) return a > b end)
  for _, c in ipairs(characters) do
    local cap = string.upper(string.sub(c, 1, 1)) .. string.sub(c, 2)
    local pretty = string.format("%s: %d", cap, charcounts[c])
    counter = counter + 1
    if counter > #bag.labels then
      table.insert(bag.labels, UI.CreateFrame('Text', 'Baggotry Tooltip', bag.subframe))
      bag.labels[counter]:SetPoint("BOTTOMRIGHT", bag.labels[counter - 1], "TOPRIGHT", 0, 1)
      bag.labels[counter]:SetFontSize(bag.labels[counter]:GetFontSize() + 2)
    end
    bag.labels[counter]:SetText(pretty)
    if mine[c] then
      bag.labels[counter]:SetFontColor(0.95, 0.95, 0.6)
    else
      bag.labels[counter]:SetFontColor(0.85, 0.85, 0.85)
    end
    bag.labels[counter]:SetVisible(true)
    local width = bag.labels[counter]:GetWidth()
    if width > maxwidth then
      maxwidth = width
    end
  end
  bag.subframe:SetPoint("TOP", bag.labels[counter], "TOP", nil, -2)
  bag.subframe:SetWidth(maxwidth + 4)
  if counter < #bag.labels then
    for i = counter + 1, #bag.labels do
      bag.labels[i]:SetVisible(false)
    end
  end
  return true
end

function bag.show_tooltip(data)
  if not bag.tooltip then
    bag.labels = {}
    bag.tooltip = UI.CreateFrame('Frame', 'Baggotry Tooltip', bag.ui)
    if not bag.tooltip then
      bag.printf("Couldn't create a tooltip.  Oops.")
      return
    end
    bag.tooltip:SetBackgroundColor(0.4, 0.4, 0.3, 1.0)
    bag.subframe = UI.CreateFrame('Frame', 'Baggotry Tooltip', bag.tooltip)
    bag.subframe:SetBackgroundColor(0.1, 0.1, 0.1, 1.0)
    table.insert(bag.labels, UI.CreateFrame('Text', 'Baggotry Tooltip', bag.subframe))

    bag.tooltip:SetPoint("TOPLEFT", bag.subframe, "TOPLEFT", -1, -1)
    bag.tooltip:SetPoint("BOTTOMRIGHT", UI.Native.Tooltip, "TOPRIGHT", -5, 5)
    bag.subframe:SetPoint("BOTTOMRIGHT", bag.tooltip, "BOTTOMRIGHT", -1, -1)
    bag.labels[1]:SetPoint("BOTTOMRIGHT", bag.subframe, "BOTTOMRIGHT", -2, -2)
    bag.labels[1]:SetFontSize(bag.labels[1]:GetFontSize() + 2)

    bag.labels[1]:SetText("hello")
  end
  bag.tooltip:SetVisible(bag.tooltip_update(data))
end

function bag.hide_tooltip()
  if bag.tooltip then
    bag.tooltip:SetVisible(false)
  end
end

function bag.tooltip_handler(tt_type, shown, buff)
  if tt_type == 'item' or tt_type == 'itemtype' then
    bag.this_frame = Inspect.Time.Frame()
    details = Inspect.Item.Detail(shown)
    if details and details.type then
      local filter = filt.Filter:new(nil, 'item', 'Baggotry')
      filter:require({ field = 'type', relation = '==', value = details.type })
      lbag.apply_args(filter, { C = '*', s = 'all' })
      local items = lbag.expand(filter)
      bag.show_tooltip(items)
    else
      bag.printf("Invalid tooltip %s.", shown)
      bag.hide_tooltip()
    end
  else
    if Inspect.Time.Frame() ~= bag.this_frame then
      bag.hide_tooltip()
    end
  end
end


Library.LibGetOpt.makeslash(filt.Filter:argstring() .. lbag.argstring() .. "d:Df:glM:mS#v", "Baggotry", "bag", bag.slashcommand)

bag.ui = UI.CreateContext("Baggotry")
bag.ui:SetStrata('tutorial')

table.insert(Event.Tooltip, { bag.tooltip_handler, "Baggotry", "tooltip hook" } )
