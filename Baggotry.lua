--[[ Baggotry
     A bag addon of no specific functionality

]]--

local bag = {}
local lbag = Library.LibBaggotry
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
  local sum = false
  local move = false
  local slotspecs = {}
  local filter
  local stack_size = nil
  if not args then
    return
  end
  if args['v'] then
    bag.printf("version %s", bag.version)
    return
  end
  if args['f'] then
    if not bag.filters[args['f']] then
      filter = lbag.filter()
      bag.filters[args['f']] = filter
    else
      filter = bag.filters[args['f']]
    end
    args['f'] = nil
  else
    filter = lbag.filter()
    filter:slot(Utility.Item.Slot.Inventory())
  end

  if args['M'] then
    if args['M'] == 'bank' then
      move = Utility.Item.Slot.Bank()
    elseif args['M'] == 'inventory' then
      move = Utility.Item.Slot.Inventory()
    elseif lbag.slotspec_p(args['M']) then
      move = args['M']
    else
      bag.printf("Unknown slotspec '%s': should be slotspec, 'bank', or 'inventory'.", args['M'])
    end
  end

  if args['d'] then
    filter:describe(args['d'])
    args['d'] = nil
  end

  if args['l'] then
    local ordered = {}
    for k, v in pairs(bag.filters) do
      table.insert(ordered, k)
    end
    table.sort(ordered)
    for _, v in ipairs(ordered) do
      bag.printf("Filter %s:", v)
      bag.filters[v]:dump()
    end
    return
  end
  if args['S'] then
    stack = true
    stack_size = args['S']
    args['S'] = nil
  end
  if args['D'] then
    dump = true
    args['D'] = nil
  end
  if args['s'] then
    sum = true
    args['s'] = nil
  end

  filter:from_args(args)

  if dump then
    filter:dump()
    return
  end

  if sum then
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
    lbag.stack(filter, stack_size)
  end
  if move then
    lbag.move_items(filter, move, true)
  end
  if not (stack or move) then
    lbag.dump(filter)
  end
end

local f

f = lbag.filter()
f:require('category', 'collectible')
f:require('stackMax', 99)
f:describe("Collectibles (such as artifacts)")
bag.filters['a'] = f

f = lbag.filter()
f:include('category', 'material')
f:describe("Materials")
bag.filters['m'] = f

f = lbag.filter()
f:exclude('rarity', 'common')
f:describe("Trash (grey items)")
bag.filters['t'] = f

Library.LibGetOpt.makeslash(lbag.filter():argstring() .. "d:Df:lM:sS#v", "Baggotry", "bag", bag.slashcommand)
