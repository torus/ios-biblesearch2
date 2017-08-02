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

   local bodyframe = make_frame(st, x, statbarheight, w, h - statbarheight)
   print_frame(st, bodyframe)

   local rootview = ctx:wrap(objc.class.UIView)('alloc')('initWithFrame:', frame)
   rootview('setBackgroundColor:', -ctx:wrap(objc.class.UIColor)('whiteColor'))

   local tableview = ctx:wrap(objc.class.UITableView)('alloc')(
      'initWithFrame:style:', bodyframe, UITableViewStylePlain)

   local datasrccls = create_data_source_class(ctx)
   local src = datasrccls('alloc')('init')
   tableview('setDataSource:', -src)

   local delegate = create_delegate_class(ctx)
   local del = delegate('alloc')('init')
   tableview('setDelegate:', -del)

   -- search bar
   local headerframe = make_frame(st, 0, 0, w, 44)
   local searchbar = ctx:wrap(objc.class.UISearchBar)('alloc')('initWithFrame:', headerframe)
   tableview('setTableHeaderView:', -searchbar)
   local searchdelegate = create_searchbar_delegate_class(ctx)
   local searchdel = searchdelegate('alloc')('init')
   searchbar('setDelegate:', -searchdel)

   rootview('addSubview:', -tableview)
   ctx:wrap(viewController)('setView:', -rootview)
end

function print_frame(st, frame, name)
   objc.push(st, frame)
   local x, y, w, h = objc.extract(st, 'CGRect')
   print(name or "frame", x, y, w, h)
end

function create_searchbar_delegate_class(ctx)
   local st = ctx.stack

   -- data source class
   objc.push(st, 'BSSearchBarDelegate')
   objc.push(st, objc.class.NSObject)
   objc.operate(st, 'addClass')

   objc.push(st, objc.class.BSSearchBarDelegate)
   objc.push(st, 'searchBar:textDidChange:')
   objc.push(st, 'v@:@@')
   objc.push(st,
             function (self, cmd, search_bar, search_text)
                print ('search', search_text)
             end
   )
   objc.operate(st, 'addMethod')

   return ctx:wrap(objc.class.BSSearchBarDelegate)
end

function create_data_source_class(ctx)
   local st = ctx.stack

   -- data source class
   objc.push(st, 'BSTableViewDataSource')
   objc.push(st, objc.class.NSObject)
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

   return ctx:wrap(objc.class.BSTableViewDataSource)
end

function create_delegate_class(ctx)
   local st = ctx.stack

   -- data source class
   objc.push(st, 'BSTableViewDelegate')
   objc.push(st, objc.class.NSObject)
   objc.operate(st, 'addClass')

   objc.push(st, objc.class.BSTableViewDelegate)
   objc.push(st, 'tableView:didSelectRowAtIndexPath:')
   objc.push(st, 'v@:@@')
   objc.push(st,
             function (self, cmd, table_view, index_path)
                print("selected cell", table_view, index_path)
             end
   )
   objc.operate(st, 'addMethod')

   objc.push(st, objc.class.BSTableViewDelegate)
   objc.push(st, 'tableView:willSelectRowAtIndexPath:')
   objc.push(st, '@@:@@')
   objc.push(st,
             function (self, cmd, table_view, index_path)
                print("will select cell", table_view, index_path)
                return index_path
             end
   )
   objc.operate(st, 'addMethod')

   return ctx:wrap(objc.class.BSTableViewDelegate)
end

function make_frame(st, x, y, w, h)
   objc.push(st, h)
   objc.push(st, w)
   objc.push(st, y)
   objc.push(st, x)
   objc.operate(st, 'cgrectmake')
   return objc.pop(st)
end

print "biblesearch2 loaded"
