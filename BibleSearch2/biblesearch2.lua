UITableViewStylePlain = 0
UITableViewCellStyleDefault = 0

function init(viewController)
   print("init", viewController)

   local ctx = objc.context:create()
   local st = ctx.stack

   local frame = -(ctx:wrap(objc.class.UIApplication)('sharedApplication')('keyWindow')('frame'))
   local statbarheight = 20

   objc.push(st, frame)
   local x, y, w, h = objc.extract(st, 'CGRect')
   print('frame', x, y, w, h)

   -- search bar
   objc.push(st, 44)
   objc.push(st, w)
   objc.push(st, 0)
   objc.push(st, 0)
   objc.operate(st, 'cgrectmake')
   local headerframe = objc.pop(st)

   local searchbar = ctx:wrap(objc.class.UISearchBar)('alloc')('initWithFrame:', headerframe)

   objc.push(st, h - statbarheight)
   objc.push(st, w)
   objc.push(st, statbarheight)
   objc.push(st, x)
   objc.operate(st, 'cgrectmake')
   local bodyframe = objc.pop(st)

   objc.push(st, bodyframe)
   local x, y, w, h = objc.extract(st, 'CGRect')
   print('frame', x, y, w, h)

   local rootview = ctx:wrap(objc.class.UIView)('alloc')('initWithFrame:', bodyframe)
   rootview('setBackgroundColor:', -ctx:wrap(objc.class.UIColor)('whiteColor'))

   local tableview = ctx:wrap(objc.class.UITableView)('alloc')(
      'initWithFrame:style:', bodyframe, UITableViewStylePlain)

   -- data source class
   objc.push(st, 'BSTableViewDataSource')
   objc.operate(st, 'addClass')
   objc.push(st, objc.class.BSTableViewDataSource)
   objc.push(st, 'tableView:cellForRowAtIndexPath:')
   objc.push(st, '@@:@@')
   objc.push(st,
             function (self, cmd, table_view, index_path)
                print("cell", table_view, index_path)
                local ctx = objc.context:create()
                local index = ctx:wrap(index_path)
                print("index", index('section'), index('row'))
                local cell = ctx:wrap(objc.class.UITableViewCell)('alloc')(
                   'initWithStyle:reuseIdentifier:', UITableViewCellStyleDefault, 'hoge')
                cell('textLabel')('setText:', 'ahoaho' .. index('section') .. index('row'))
                return -cell
             end
   )
   objc.operate(st, 'addMethod')

   objc.push(st, objc.class.BSTableViewDataSource)
   objc.push(st, 'tableView:numberOfRowsInSection:')
   objc.push(st, 'l@:@l')
   objc.push(st,
             function (self, cmd, view, section)
                print("num of rows", section)
                if section < 1 then
                   return 5
                else
                   return 0
                end
             end
   )
   objc.operate(st, 'addMethod')

   local src = ctx:wrap(objc.class.BSTableViewDataSource)('alloc')('init')
   tableview('setDataSource:', -src)
   tableview('setTableHeaderView:', -searchbar)

   rootview('addSubview:', -tableview)
   ctx:wrap(viewController)('setView:', -rootview)
end

print "biblesearch2 loaded"
