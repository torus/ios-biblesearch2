UITableViewStylePlain = 0
UITableViewCellStyleDefault = 0

function init(viewController)
   print("init", viewController)

   local ctx = objc.context:create()
   local tableview = ctx:wrap(objc.class.UITableView)('alloc')(
      'initWithFrame:style:',
         -(ctx:wrap(objc.class.UIApplication)('sharedApplication')('keyWindow')('frame')),
      UITableViewStylePlain)

   local st = ctx.stack
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
                cell('textLabel')('setText:', 'ahoaho')
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
                   return 1
                else
                   return 0
                end
             end
   )
   objc.operate(st, 'addMethod')

   local src = ctx:wrap(objc.class.BSTableViewDataSource)('alloc')('init')
   tableview('setDataSource:', -src)

   ctx:wrap(viewController)('setView:', -tableview)
end

print "biblesearch2 loaded"
