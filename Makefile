DFHACKVER ?= 0.43.05-beta1

DFVERNUM = `echo $(DFHACKVER) | sed -e s/-.*// -e s/\\\\.//g`

DF ?= /Users/vit/Downloads/df_43_05_osx
DH ?= /Users/vit/Downloads/buildagent-2/workspace/root/dfhack/0.43.05

SRC = remote.cpp sha256.cpp QR_Encode.cpp
DEP = dwarfmode.hpp commands.hpp plugin.hpp patches.hpp itemcache.hpp config.hpp corehacks.hpp sha256.h connect.hpp Makefile

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

CFLAGS = $(INC) -m64 -DLINUX_BUILD -g -O3 -DUSE_FILE32API
LDFLAGS = $(LIB) -shared 

ifeq ($(shell uname -s), Darwin)
	export MACOSX_DEPLOYMENT_TARGET=10.6
	CXX = g++-4.8
	CFLAGS += -std=gnu++0x #-stdlib=libstdc++
	CFLAGS += -Wno-tautological-compare
	LDFLAGS += -framework Security -undefined dynamic_lookup #-mmacosx-version-min=10.6 
else
	CFLAGS += -std=c++0x
endif


all: $(OUT)

$(OUT): $(SRC) $(DEP)
	-@mkdir -p `dirname $(OUT)`
	$(CXX) $(SRC) -o $(OUT) -DDF_$(DFVERNUM) $(CFLAGS) $(LDFLAGS)

inst: $(OUT)
	cp $(OUT) "$(DF)/hack/plugins/"

clean:
	-rm $(OUT)
