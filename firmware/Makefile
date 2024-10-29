export TARGET_DIRS  = $(PWD)/targets/SlacPgpCardG4/SlacPgpCardG4Pgp2b \
                      $(PWD)/targets/SlacPgpCardG4/SlacPgpCardG4Pgp4_6Gbps \
                      $(PWD)/targets/SlacPgpCardG4/SlacPgpCardG4Pgp4_10Gbps \
                      $(PWD)/targets/XilinxKcu1500/XilinxKcu1500Pgp2b \
                      $(PWD)/targets/XilinxKcu1500/XilinxKcu1500Pgp4_6Gbps \
                      $(PWD)/targets/XilinxKcu1500/XilinxKcu1500Pgp4_10Gbps \
                      $(PWD)/targets/XilinxAlveoU200/XilinxAlveoU200Pgp2b \
                      $(PWD)/targets/XilinxAlveoU200/XilinxAlveoU200Pgp4_6Gbps \
                      $(PWD)/targets/XilinxAlveoU200/XilinxAlveoU200Pgp4_10Gbps \
                      $(PWD)/targets/XilinxAlveoU200/XilinxAlveoU200Pgp4_15Gbps \
                      $(PWD)/targets/XilinxVariumC1100/XilinxVariumC1100Pgp2b \
                      $(PWD)/targets/XilinxVariumC1100/XilinxVariumC1100Pgp4_6Gbps \
                      $(PWD)/targets/XilinxVariumC1100/XilinxVariumC1100Pgp4_10Gbps \
                      $(PWD)/targets/XilinxVariumC1100/XilinxVariumC1100Pgp4_15Gbps

.PHONY: all build clean

# Default
all: build

# Check variables
test:
	@echo TARGET_DIRS:
	@echo -e "$(foreach ARG,$(TARGET_DIRS),\t$(ARG)\n)"

# Clean all firmware builds
clean:
	for i in $(TARGET_DIRS); do \
      cd $$i; make clean; \
   done

# Build targets
build:
	for i in $(TARGET_DIRS); do \
      echo $$i; cd $$i; make clean; rm -rf images; make; \
   done
