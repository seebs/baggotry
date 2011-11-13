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

function bag.slashcommand(args)
  local merge, split
  local filter
  merge = false
  split = false
  local stack_size = nil
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

  if args['x'] then
    filtery = function(...) filter:exclude(...) end
  else
    filtery = function(...) filter:include(...) end
  end

  if args['n'] then
    stack_size = args['n']
  end

  if args['c'] then
    filtery('category', args['c'])
  end
  for k, item_name in pairs(args['leftover_args']) do
    filtery('name', item_name)
  end

  if args['M'] then
    merge = true
  end
  if args['S'] then
    split = true
  end
  if merge then
    lbag.merge(filter, stack_size)
  elseif split then
    lbag.split(filter, stack_size)
  else
    lbag.dump(filter)
  end
end

Library.LibGetOpt.makeslash("c:f:MSn#vx", "Baggotry", "bag", bag.slashcommand)
