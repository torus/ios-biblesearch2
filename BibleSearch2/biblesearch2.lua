UITableViewStylePlain = 0
UITableViewCellStyleDefault = 0

local document_index
local source_file
local result_upper_bound = 0
local result_lower_bound = 0
local index_position_map = {}

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
   local src = datasrccls('new')
   tableview('setDataSource:', -src)

   -- search bar
   local headerframe = make_frame(st, 0, 0, w, 44)
   local searchbar = ctx:wrap(objc.class.UISearchBar)('alloc')('initWithFrame:', headerframe)
   local searchdelegate = create_searchbar_delegate_class(ctx, tableview)
   local searchdel = searchdelegate('new')
   searchbar('setDelegate:', -searchdel)
   tableview('setTableHeaderView:', -searchbar)

   local viewcntrl = ctx:wrap(viewController)
   local delegate = create_tableview_delegate_class(ctx, searchbar, viewcntrl, bodyframe)
   local del = delegate('new')
   tableview('setDelegate:', -del)

   rootview('addSubview:', -tableview)
   viewcntrl('setView:', -rootview)

   -- Suffix Array
   print('sufarr', sufarr)

   local bundle = ctx:wrap(objc.class.NSBundle)('mainBundle')
   local idxpath = bundle('pathForResource:ofType:', 'kjv', 'idx')
   local srcpath = bundle('pathForResource:ofType:', 'kjv', 'txt')
   print('index', idxpath, srcpath)

   document_index = sufarr.load_index(idxpath, srcpath)
   source_file = io.open(srcpath)
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

function create_searchbar_delegate_class(ctx, table_view)
   local st = ctx.stack

   objc.push(st, 'BSSearchBarDelegate')
   objc.push(st, objc.class.NSObject)
   objc.operate(st, 'addClass')

   add_method(ctx, objc.class.BSSearchBarDelegate, 'searchBar:textDidChange:', 'v@:@@',
              function (self, cmd, search_bar, search_text)
                 print ('search', search_text)

		 if search_text == "" then
		    result_upper_bound = 0
		    result_lower_bound = 0
		 else
		    local lb = sufarr.search_lower_bound(document_index, search_text)
		    local ub = sufarr.search_upper_bound(document_index, search_text)

		    print (string.format ("%s - %s", lb, ub))
		    result_lower_bound = lb
		    result_upper_bound = ub
		 end

		 table_view('reloadData')
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
                 -- print("cell", table_view, index_path)
                 local ctx = objc.context:create()
                 local index = ctx:wrap(index_path)
                 -- print("index", index('section'), index('row'))
                 local cell = ctx:wrap(objc.class.UITableViewCell)('alloc')(
                    'initWithStyle:reuseIdentifier:', UITableViewCellStyleDefault, 'hoge')

		 local num = index('row')
		 local p = sufarr.get_position(document_index, result_lower_bound + num)
		 source_file:seek ("set", p)
		 local str = source_file:read()

		 index_position_map[num] = p

                 cell('textLabel')('setText:', str)
                 return -cell
              end
   )

   add_method(ctx, objc.class.BSTableViewDataSource, 'tableView:numberOfRowsInSection:', 'l@:@l',
              function (self, cmd, view, section)
                 print("num of rows", section)
                 if section < 1 then
                    return result_upper_bound - result_lower_bound
                 else
                    return 0
                 end
              end
   )

   return ctx:wrap(objc.class.BSTableViewDataSource)
end

function create_webview_delegate_class(ctx, view_controller)
   local st = ctx.stack

   objc.push(st, 'BSWebViewDelegate')
   objc.operate(st, 'addLuaBridgedClass')

   add_method(ctx, objc.class.BSWebViewDelegate, 'webView:shouldStartLoadWithRequest:navigationType:',
	      'i@:@@i',
	      function (self, cmd, webview, request, navtype)
		 print('webView:shouldStartLoadWithRequest:navigationType:', webview, request, navtype)

		 local url = ctx:wrap(request)('URL')
		 local scheme, path = url('scheme'), url('path')
		 print('URL', scheme, path)

                 objc.push(ctx.stack, self)
                 objc.operate(ctx.stack, 'getLuaTable')
                 local tbl = objc.pop(st)

                 print("WebView Delegate", tbl.text)

		 if path == "/back" then
		    print('back!')
		    local sel = objc.getselector('dismiss')
		    print('onclick: BSWebViewDelegate instance', self)
		    ctx:wrap(self)('performSelectorOnMainThread:withObject:waitUntilDone:',
				   sel, webview, 0)
		    return 0
		 elseif path == "/ready" then
                    local verse, text = string.match(tbl.text, "^([^%s]+)%s+(.*)$")
                    local jsexp = string.format("setContent(%q, %q)", verse, text)
                    print("executing:", jsexp)
                    ctx:wrap(webview)('stringByEvaluatingJavaScriptFromString:', jsexp)
                    return 0
		 end

		 return 1
	      end
   )

   add_method(ctx, objc.class.BSWebViewDelegate, 'dismiss',
	      'v@:@',
	      function (self, cmd, webview)
		 print('dismiss:', webview)
		 print('dismiss: BSWebViewDelegate instance', self)

                 view_controller("dismissViewControllerAnimated:completion:", 1, nil)
	      end
   )

   return ctx:wrap(objc.class.BSWebViewDelegate)
end

function create_tableview_delegate_class(ctx, search_bar, view_controller, frame)
   local st = ctx.stack

   local delecls = create_webview_delegate_class(ctx, view_controller)

   -- data source class
   objc.push(st, 'BSTableViewDelegate')
   objc.push(st, objc.class.NSObject)
   objc.operate(st, 'addClass')

   add_method(ctx, objc.class.BSTableViewDelegate, 'tableView:didSelectRowAtIndexPath:', 'v@:@@',
              function (self, cmd, table_view, index_path)
                 print("selected cell", table_view, index_path)
                 local child = ctx:wrap(objc.class.UIViewController)('new')
                 local webview = ctx:wrap(objc.class.UIWebView)('alloc')('initWithFrame:', frame)
		 local dele = delecls('new')
		 webview('setDelegate:', -dele)
		 print('BSWebViewDelegate instance', -dele)

                 local rootview = ctx:wrap(objc.class.UIView)('new')

                 rootview('setBackgroundColor:', -ctx:wrap(objc.class.UIColor)('whiteColor'))
                 rootview('addSubview:', -webview)

                 local row = ctx:wrap(index_path)('row')
                 local p = index_position_map[row]
                 print('row', row, p)

                 while p > 0 do
                    source_file:seek ("set", p)
                    local ch = source_file:read(1)
                    if ch == '\n' then
                       break
                    end
                    p = p - 1
                 end
                 local text = source_file:read()
                 print("text", text)
                 
                 objc.push(ctx.stack, -dele)
                 objc.push(ctx.stack, {text = text})
                 objc.operate(ctx.stack, 'setLuaTable')

                 local url = ctx:wrap(objc.class.NSBundle)('mainBundle')(
                    'URLForResource:withExtension:', 'template', 'html')
                 print("URL:", url('absoluteString'))
                 webview('loadRequest:', -ctx:wrap(objc.class.NSURLRequest)('requestWithURL:', -url))
                 rootview('addSubview:', -webview)
                 child('setView:', -rootview)
                 view_controller("presentViewController:animated:completion:", -child, 1, nil)
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
