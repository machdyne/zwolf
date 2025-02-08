CC = gcc
CFLAGS = -I../../include

zwolf:
	$(CC) $(CFLAGS) -DSTANDALONE -o zwolf ../../zwolf.c linux.c -lzmq

clean:
	rm -f zwolf

.PHONY: clean
