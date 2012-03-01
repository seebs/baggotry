--[[ Baggotry
     A bag addon of no specific functionality

]]--

local bag = {}
local lbag = Library.LibBaggotry
local filt = Library.LibEnfiltrate
bag.version = "VERSION"
Baggotry = bag

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

function bag.strsplit(s, p)
  local idx = string.find(s, p)
  if idx then
    return s.sub(s, 1, idx - 1), bag.strsplit(string.sub(s, idx + 1), p)
  else
    return s
  end
end

function bag.filtery(filter, ...)
  local args = { ... }
  last = table.getn(args)
  if last and last > 0 then
    local char = string.sub(args[last], 1, 1)
    if char == '+' then
      args[last] = string.sub(args[last], 2)
      filter:require(unpack(args))
    elseif char == '!' then
      args[last] = string.sub(args[last], 2)
      filter:exclude(unpack(args))
    else
      filter:include(unpack(args))
    end
  end
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


Library.LibGetOpt.makeslash(filt.Filter:argstring() .. lbag.argstring() .. "d:Df:glM:mS#v", "Baggotry", "bag", bag.slashcommand)
