#custom
program_NAME := gtalk-shared-status
program_VERSION := 0.2.5
program_ARCH := i386
program_INCLUDE_DIRS := 
program_LIBRARY_DIRS := 
program_LIBRARIES :=


# common
program_BINARY := $(program_NAME).so
program_WIN_BINARY := $(program_NAME).dll
program_FULLNAME := $(program_NAME)-$(program_VERSION)
program_TAR := $(program_FULLNAME).$(program_ARCH).tar.gz
program_SRC_TAR := $(program_FULLNAME).src.tar.gz
program_WIN_ZIP := $(program_FULLNAME).win32.zip
program_C_SRCS := $(wildcard *.c)
program_C_HEADERS := $(wildcard *.h)
program_C_OBJS := ${program_C_SRCS:.c=.o}
program_OBJS := $(program_C_OBJS)


prefix := ~/.purple/plugins

CFLAGS := -shared -fPIC -Wall -D_REENTRANT -pthread
LDFLAGS := $(foreach library,$(program_LIBRARIES),-l$(library))

CFLAGS += $(shell pkg-config --cflags purple)
LDFLAGS += $(shell pkg-config --libs purple)

.PHONY: all clean distclean install

all: $(program_BINARY)

$(program_BINARY): $(program_OBJS)
	$(LINK.c) $(program_OBJS) -o $(program_BINARY)

clean:
	$(RM) $(program_BINARY)
	$(RM) $(program_OBJS)
	$(RM) $(program_TAR)
	$(RM) $(program_SRC_TAR)
	$(RM) $(program_WIN_ZIP)

distclean: clean

install: $(program_BINARY)
	@- mkdir -p ~/.purple/plugins
	install -m 0755 $(program_BINARY) $(prefix)/$(program_BINARY)

tar: $(program_BINARY)
	@- mkdir -p ./$(program_FULLNAME)
	@- cp $(program_C_SRCS) $(program_C_HEADERS) $(program_BINARY) Makefile \
            Makefile.mingw README INSTALL ChangeLog LICENSE COPYING \
            $(program_FULLNAME)
	tar --remove-files --create --gzip --file $(program_TAR) $(program_FULLNAME)

src: 
	@- mkdir -p ./$(program_FULLNAME)
	@- cp $(program_C_SRCS) $(program_C_HEADERS) Makefile Makefile.mingw README \
	        INSTALL ChangeLog LICENSE COPYING $(program_FULLNAME)
	tar --remove-files --create --gzip --file $(program_SRC_TAR) $(program_FULLNAME)

# only for packaging
win: 
	@- mkdir -p ./$(program_FULLNAME)
	@- cp $(program_C_SRCS) $(program_C_HEADERS) $(program_WIN_BINARY) Makefile \
	        Makefile.mingw README INSTALL ChangeLog LICENSE COPYING \
	        $(program_FULLNAME)
	zip -T -r -m $(program_WIN_ZIP) $(program_FULLNAME)

	
