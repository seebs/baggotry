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

function bag.slashcommand(args)
  local stack = false
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
      filter:slot(Utility.Item.Slot.Inventory())
      bag.filters[args['f']] = filter
    else
      filter = bag.filters[args['f']]
    end
  else
    filter = lbag.filter()
    filter:slot(Utility.Item.Slot.Inventory())
  end

  if args['d'] then
    filter:descr(args['d'])
  end

  if args['x'] then
    filtery = function(...) filter:exclude(...) end
  else
    if args['r'] then
      filtery = function(...) filter:require(...) end
    else
      filtery = function(...) filter:include(...) end
    end
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

  if args['c'] then
    filtery('category', args['c'])
  end
  if args['q'] then
    if lbag.rarity_p(args['q']) then
      filtery('rarity', args['q'])
    else
      bag.printf("Error: '%s' is not a valid rarity.", args['q'])
    end
  end
  for k, item_name in pairs(args['leftover_args']) do
    filtery('name', item_name)
  end

  if args['S'] then
    stack = true
    stack_size = args['S']
  end
  if args['D'] then
    filter:dump()
    return
  end
  if args['s'] then
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
  else
    lbag.dump(filter)
  end
end

local f

f = lbag.filter()
f:require('category', 'collectible')
f:require('stackMax', 99)
f:descr("Collectibles (such as artifacts)")
bag.filters['a'] = f

f = lbag.filter()
f:include('category', 'material')
f:descr("Materials")
bag.filters['m'] = f

f = lbag.filter()
f:exclude('rarity', 'common')
f:descr("Trash (grey items)")
bag.filters['t'] = f

Library.LibGetOpt.makeslash("c:d:Df:lq:rsS#vx", "Baggotry", "bag", bag.slashcommand)
