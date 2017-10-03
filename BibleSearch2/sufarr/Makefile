CXXFLAGS = -shared -fPIC -g -I../../../lualander/luaobjc/LuaObjCBridge/lua-5.3.4/src -I/usr/include/malloc
LDFLAGS = -shared -fPIC
ABOUT = xcode/Resources/about.html
MARKDOWN = perl -MText::Markdown -e '$$/=undef;print Text::Markdown->new->markdown(<>)'

all: sufarr.so $(ABOUT)

$(ABOUT): about.md
	$(MARKDOWN) $? > $@

sufarr.so: sufarr.o sufarr_wrap.o
	$(CXX) -flat_namespace -undefined suppress -o $@ $^ $(LDFLAGS)

sufarr_wrap.cpp: sufarr.i
	swig -o $@ -c++ -lua $?

%.o: %.cpp
	$(CXX) -c -o $@ $(CXXFLAGS) $?

clean:
	rm -f suftest *.o *_wrap.cpp *.a *.so *.dylib *~

