DFHACKVER ?= 0.47.05-r8

DFVERNUM = `echo $(DFHACKVER) | sed -e s/-.*// -e s/\\\\.//g`

DF ?= /Users/vpronkin/Downloads/df_47_05_osx
DH ?= /Users/vpronkin/Downloads/dfhack

BITS ?= 64
GCCVER ?= 7

SRC = remote.cpp sha256.cpp QR_Encode.cpp
DEP = dwarfmode.hpp embark.hpp commands.hpp plugin.hpp patches.hpp itemcache.hpp config.hpp corehacks.hpp sha256.h connect.hpp units.hpp items.hpp buildings.hpp civlist.hpp Makefile

ifeq ($(shell uname -s), Darwin)
	ifneq (,$(findstring 0.34,$(DFHACKVER)))
		EXT = so
	else
		EXT = dylib
	endif
else
	EXT = so
endif
OUT = dist/$(DFHACKVER)/remote.plug.$(EXT)

INC = -I"$(DH)/library/include" -I"$(DH)/library/proto" -I"$(DH)/depends/protobuf" -I"$(DH)/depends/lua/include" -I"$(DH)/depends/tthread" -Ienet/include
LIB = -L"$(DH)/build/library" -ldfhack -ldfhack-version -L"$(DH)/build/depends/tthread" -ldfhack-tinythread ./enet/.libs/libenet.a

CFLAGS = $(INC) -m$(BITS) -DLINUX_BUILD -O3 -DUSE_FILE32API -D_GLIBCXX_USE_CXX11_ABI=0
LDFLAGS = $(LIB) -shared

ifeq ($(shell uname -s), Darwin)
	export MACOSX_DEPLOYMENT_TARGET=10.6
	CXX = g++-$(GCCVER)
	CFLAGS += -std=gnu++0x
	CFLAGS += -Wno-tautological-compare
	LDFLAGS += -framework Security -undefined dynamic_lookup #-mmacosx-version-min=10.6 
else
	CXX = g++-$(GCCVER)
	CFLAGS += -std=c++0x -fPIC
	LDFLAGS += -fuse-ld=gold --no-gnu-unique
endif


all: $(OUT)

$(OUT): $(SRC) $(DEP)
	-@mkdir -p `dirname $(OUT)`
	$(CXX) $(SRC) -o $(OUT) -DDF_$(DFVERNUM) $(CFLAGS) $(LDFLAGS)

inst: $(OUT)
	cp $(OUT) "$(DF)/hack/plugins/"

install: inst

clean:
	-rm $(OUT)
