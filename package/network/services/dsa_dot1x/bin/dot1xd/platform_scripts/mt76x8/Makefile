SOURCES = $(wildcard *.c)
OBJECTS = lua_code.o $(SOURCES:.c=.o) 
TARGET = runner

LDFLAGS += -lcap -llua -lm

RM = rm -f

$(TARGET): $(OBJECTS)
	$(CC) $^ -o $@ $(LDFLAGS)

lua_code.o: mt76x8.lua
	$(LD) -s -r -b binary -o lua_code.o mt76x8.lua

clean:
	$(RM) $(TARGET) $(OBJECTS)

