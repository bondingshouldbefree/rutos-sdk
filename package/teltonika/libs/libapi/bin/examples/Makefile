EXAMPLE_SRC = main.c
EXAMPLE_OBJS = $(EXAMPLE_SRC:.c=.o)
EXAMPLE_TARGET = example

RM = rm -f

CFLAGS += -Wall -Wextra -Werror -Wno-unused-parameter -I../libapi/include
LDFLAGS += -L../libapi -lapi

all: $(EXAMPLE_TARGET)

$(EXAMPLE_TARGET): $(EXAMPLE_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^

clean:
	$(RM) $(EXAMPLE_OBJS) $(EXAMPLE_TARGET)
