
SRC_DIR = src
RELEASE_DIR = release
OBJ_DIR = obj
TOOL_DIR = tools
CC = gcc
APPNAME = js_analysis
THIRD_PARTY_DIR = third-party
THIRD_PARTY_DIST = $(THIRD_PARTY_DIR)/dist
OTHER_LIBS = $(THIRD_PARTY_DIST)/lib/libjs.a $(THIRD_PARTY_DIST)/lib/libnspr4.a
CFILES =  	   \
	analysis.c \
	jsfile.c   \
	main.c
INCLUDES = -I$(THIRD_PARTY_DIST)/include -I$(THIRD_PARTY_DIST)/include/nspr -I$(OBJ_DIR)
CFLAGS =  -Wall -Wno-format -O -fPIC
CFLAGS += -DXP_UNIX -DSVR4 -DSYSV -D_BSD_SOURCE -DPOSIX_SOURCE -DHAVE_LOCALTIME_R
CFLAGS += -DHAVE_VA_COPY -DVA_COPY=va_copy -DPIC -DJS_HAS_FILE_OBJECT
CFLAGS += $(INCLUDES)
LDFLAGS =
PROG_LIBS = -lm -lpthread -ldl
TOOL_LIBS = $(PROG_LIBS)
PROG = $(OBJ_DIR)/$(APPNAME)

PROG_OBJS  = $(addprefix $(OBJ_DIR)/, $(CFILES:.c=.o))
define MAKE_OBJDIR
if test ! -d $(@D); then rm -rf $(@D); mkdir -p $(@D); fi
endef

JS_FILE_DIR = lib
JS_LIB_DIR = $(OBJ_DIR)/lib
JS_FILES = 	        \
	common.js       \
	constants.js    \
	make_public.js  \
	console.js      \
	test_main.js
JS_OBJS  = $(addprefix $(JS_LIB_DIR)/, $(JS_FILES:.js=.js.h))
JS_CREATOR  = $(OBJ_DIR)/js_creator

$(PROG): $(THIRD_PARTY_DIST) $(JS_OBJS) $(OBJ_DIR)/js_lib.h $(PROG_OBJS)
	$(CC) -o $@ $(CFLAGS) $(PROG_OBJS) $(LDFLAGS) $(OTHER_LIBS) \
	$(PROG_LIBS)

$(OBJ_DIR)/js_lib.h: $(JS_OBJS)
	@echo "#ifndef js_lib_h___" > $@
	@echo "#define js_lib_h___" >> $@
	cat $(JS_LIB_DIR)/*.js.h >> $@
	@echo "#endif" >> $@

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
	@$(MAKE_OBJDIR)
	$(CC) -o $@ -c $(CFLAGS) $(SRC_DIR)/$*.c

$(JS_CREATOR): $(TOOL_DIR)/js_creator.c
	@$(MAKE_OBJDIR)
	$(CC) -o $(JS_CREATOR) $(CFLAGS) $(TOOL_DIR)/js_creator.c $(LDFLAGS) $(OTHER_LIBS) $(TOOL_LIBS)

$(JS_LIB_DIR)/%.js.h: $(JS_LIB_DIR)/%.js
	@echo "unsigned char js_lib_$*[] = {" > $@
	cat $(JS_LIB_DIR)/$*.js | xxd -i >> $@
	@echo ",0};" >> $@

$(JS_LIB_DIR)/%.js: $(JS_FILE_DIR)/%.js
	@if test ! -d $(JS_LIB_DIR); then rm -rf $(JS_LIB_DIR); mkdir -p $(JS_LIB_DIR); fi
	cp $(JS_FILE_DIR)/$*.js $@

$(JS_LIB_DIR)/constants.js: $(JS_CREATOR)
	cat $(JS_FILE_DIR)/constants.js.in > $@
	$(JS_CREATOR) >> $@

$(THIRD_PARTY_DIST):
	@cd $(THIRD_PARTY_DIR); ./build.sh

all: $(PROG)

clean:
	rm -rf $(OBJ_DIR)
	rm -rf $(RELEASE_DIR)
	@cd $(THIRD_PARTY_DIR); ./clean.sh

clean_temp:
	rm -rf $(OBJ_DIR)
	@cd $(THIRD_PARTY_DIR); ./clean.sh

release: $(PROG)
	@if test ! -d $(RELEASE_DIR); then rm -rf $(RELEASE_DIR); mkdir -p $(RELEASE_DIR); fi
	cp $(PROG) $(RELEASE_DIR) && cp -r $(JS_LIB_DIR) $(RELEASE_DIR)
	@cd $(RELEASE_DIR); strip -s $(APPNAME) || strip -x $(APPNAME)


