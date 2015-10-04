
bin = helloworld

gtk_CFLAGS = $(shell pkg-config --cflags gtk+-2.0)
gtk_LIBS   = $(shell pkg-config --libs gtk+-2.0)


all: $(bin)

$(bin): $(bin).c
	gcc -Wall $(CFLAGS) $(CPPFLAGS) $(gtk_CFLAGS) $(LDFLAGS) $< -o $@ $(gtk_LIBS)

clean:
	rm -f $(bin)

