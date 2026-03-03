DEPS = $(wildcard src/*.h)
SRC = $(wildcard src/*.c)
OBJ = $(patsubst %.c, %.o, $(SRC))
TARGET = libtlt_logger.so
RM = rm -f

CFLAGS += -std=gnu99 -fPIC
LDFLAGS += -shared

all: $(TARGET)

%.o: %.c $(DEPS)
	$(CC) -c -o $@ $< $(CFLAGS)

$(TARGET): $(OBJ)
	$(CC) -o $@ $^ $(LDFLAGS)

.PHONY: clean
clean:
	$(RM) $(OBJ) $(TARGET)
