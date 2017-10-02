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

   -- search bar
   local headerframe = make_frame(st, 0, 0, w, 44)
   local searchbar = ctx:wrap(objc.class.UISearchBar)('alloc')('initWithFrame:', headerframe)
   tableview('setTableHeaderView:', -searchbar)
   local searchdelegate = create_searchbar_delegate_class(ctx)
   local searchdel = searchdelegate('alloc')('init')
   searchbar('setDelegate:', -searchdel)

   local viewcntrl = ctx:wrap(viewController)
   local delegate = create_tableview_delegate_class(ctx, searchbar, viewcntrl, bodyframe)
   local del = delegate('alloc')('init')
   tableview('setDelegate:', -del)

   rootview('addSubview:', -tableview)
   viewcntrl('setView:', -rootview)
end

function print_frame(st, frame, name)
   objc.push(st, frame)
   local x, y, w, h = objc.extract(st, 'CGRect')
   print(name or "frame", x, y, w, h)
end

function add_method(ctx, cls, name, signature, proc)
   local st = ctx.stack

   objc.push(st, cls)
   objc.push(st, name)
   objc.push(st, signature)
   objc.push(st, proc)
   objc.operate(st, 'addMethod')
end

function create_searchbar_delegate_class(ctx)
   local st = ctx.stack

   -- data source class
   objc.push(st, 'BSSearchBarDelegate')
   objc.push(st, objc.class.NSObject)
   objc.operate(st, 'addClass')

   add_method(ctx, objc.class.BSSearchBarDelegate, 'searchBar:textDidChange:', 'v@:@@',
              function (self, cmd, search_bar, search_text)
                 print ('search', search_text)
              end
   )

   add_method(ctx, objc.class.BSSearchBarDelegate, 'searchBarSearchButtonClicked:', 'v@:@',
              function (self, cmd, search_bar)
                 print('search button clicked!')
                 ctx:wrap(search_bar)('resignFirstResponder')
              end
   )

   return ctx:wrap(objc.class.BSSearchBarDelegate)
end

function create_data_source_class(ctx)
   local st = ctx.stack

   -- data source class
   objc.push(st, 'BSTableViewDataSource')
   objc.push(st, objc.class.NSObject)
   objc.operate(st, 'addClass')

   add_method(ctx, objc.class.BSTableViewDataSource, 'tableView:cellForRowAtIndexPath:', '@@:@@',
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

   add_method(ctx, objc.class.BSTableViewDataSource, 'tableView:numberOfRowsInSection:', 'l@:@l',
              function (self, cmd, view, section)
                 print("num of rows", section)
                 if section < 1 then
                    return 5
                 else
                    return 0
                 end
              end
   )

   return ctx:wrap(objc.class.BSTableViewDataSource)
end

function create_webview_delegate_class(ctx)
   local st = ctx.stack

   objc.push(st, 'BSWebViewDelegate')
   objc.push(st, objc.class.NSObject)
   objc.operate(st, 'addClass')

   add_method(ctx, objc.class.BSWebViewDelegate, 'webView:decidePolicyForNavigationAction:decisionHandler:',
	      'v@:@@@',
	      function (self, cmd, web_view, action, handler)
		 print(web_view, action, handler)
	      end
   )

   return ctx:wrap(objc.class.BSWebViewDelegate)
end

function create_tableview_delegate_class(ctx, search_bar, view_controller, frame)
   local st = ctx.stack

   local delecls = create_webview_delegate_class(ctx)

   -- data source class
   objc.push(st, 'BSTableViewDelegate')
   objc.push(st, objc.class.NSObject)
   objc.operate(st, 'addClass')

   add_method(ctx, objc.class.BSTableViewDelegate, 'tableView:didSelectRowAtIndexPath:', 'v@:@@',
              function (self, cmd, table_view, index_path)
                 print("selected cell", table_view, index_path)
                 local child = ctx:wrap(objc.class.UIViewController)('new')
                 local webview = ctx:wrap(objc.class.WKWebView)(
                    'alloc')(
                    'initWithFrame:configuration:',
                    frame, -(ctx:wrap(objc.class.WKWebViewConfiguration)('new')))
		 local dele = delecls('new')
		 webview('setNavigationDelegate:', -dele)

                 local rootview = ctx:wrap(objc.class.UIView)('new')

                 rootview('setBackgroundColor:', -ctx:wrap(objc.class.UIColor)('whiteColor'))
                 rootview('addSubview:', -webview)

                 local url = ctx:wrap(objc.class.NSBundle)('mainBundle')(
                    'URLForResource:withExtension:', 'template', 'html')
                 print("URL:", url('absoluteString'))
                 webview('loadRequest:', -ctx:wrap(objc.class.NSURLRequest)('requestWithURL:', -url))
                 -- webview('loadHTMLString:baseURL:', '<h1>fujiko</h1>',
                 --            -(ctx:wrap(objc.class.NSURL)('URLWithString:', 'file://')))
                 rootview('addSubview:', -webview)
                 child('setView:', -rootview)
                 -- view_controller("addChildViewController:", -child)
                 view_controller("showViewController:sender:",
                                 -child, -view_controller)
              end
   )

   add_method(ctx, objc.class.BSTableViewDelegate, 'tableView:willSelectRowAtIndexPath:', '@@:@@',
              function (self, cmd, table_view, index_path)
                 print("will select cell", table_view, index_path)
                 return index_path
              end
   )

   add_method(ctx, objc.class.BSTableViewDelegate, 'scrollViewWillBeginDragging:', 'v@:@',
              function (self, cmd, table_view)
                 print("will drag", table_view)
                 search_bar('resignFirstResponder')
              end
   )

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
