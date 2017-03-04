EXEC = raytracing

GIT_HOOKS := .git/hooks/pre-commit
.PHONY: all
all: $(GIT_HOOKS) $(EXEC)

$(GIT_HOOKS):
	@scripts/install-git-hooks
	@echo

CC ?= gcc
CFLAGS = \
	-std=gnu99 -Wall -O0 -g
LDFLAGS = \
	-lm

ifeq ($(strip $(PROFILE)),1)
PROF_FLAGS = -pg
CFLAGS += $(PROF_FLAGS)
LDFLAGS += $(PROF_FLAGS) -fopenmp
endif

OBJS := \
	objects.o \
	raytracing.o \
	main.o

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<


$(EXEC): $(OBJS)
	$(CC) -o $@ $^ $(LDFLAGS)

main.o: use-models.h
use-models.h: models.inc Makefile
	@echo '#include "models.inc"' > use-models.h
	@egrep "^(light|sphere|rectangular) " models.inc | \
	    sed -e 's/^light /append_light/g' \
	        -e 's/light[0-9]/(\&&, \&lights);/g' \
	        -e 's/^sphere /append_sphere/g' \
	        -e 's/sphere[0-9]/(\&&, \&spheres);/g' \
	        -e 's/^rectangular /append_rectangular/g' \
	        -e 's/rectangular[0-9]/(\&&, \&rectangulars);/g' \
	        -e 's/ = {//g' >> use-models.h

check: $(EXEC)
	@./$(EXEC) && diff -u baseline.ppm out.ppm || (echo Fail; exit)
	@echo "Verified OK"

astyle:
	astyle --style=kr --indent=spaces=4 --indent-switches --suffix=none *.[ch]

pthread:
	$(CC) -DPTHREAD=1 -o raytracing_pthread objects.o main.o raytracing.c $(LDFLAGS) -lpthread

openmp:
	$(CC) -DOMP=1 -o raytracing_openmp objects.o main.o raytracing.c $(LDFLAGS) -fopenmp

clean:
	$(RM) $(EXEC) $(OBJS) use-models.h \
		out.ppm gmon.out
