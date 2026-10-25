export TARGET_DIRS  = $(CURDIR)/targets/SlacPgpCardG4/SlacPgpCardG4Pgp4_6Gbps \
                      $(CURDIR)/targets/SlacPgpCardG4/SlacPgpCardG4Pgp4_10Gbps \
                      $(CURDIR)/targets/XilinxKcu1500/XilinxKcu1500Pgp4_6Gbps \
                      $(CURDIR)/targets/XilinxKcu1500/XilinxKcu1500Pgp4_10Gbps \
                      $(CURDIR)/targets/XilinxVariumC1100/XilinxVariumC1100Pgp4_6Gbps \
                      $(CURDIR)/targets/XilinxVariumC1100/XilinxVariumC1100Pgp4_10Gbps \
                      $(CURDIR)/targets/XilinxVariumC1100/XilinxVariumC1100Pgp4_15Gbps \
                      $(CURDIR)/targets/XilinxVariumC1100/XilinxVariumC1100Pgp4_25Gbps_Fec \
                      $(CURDIR)/targets/XilinxVariumC1100/XilinxVariumC1100Htsp100GbpsBifurcatedPcie

.PHONY: all build clean syn

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

# Synthesis-only check of all targets (faster than a full build), stops on the first failure
syn:
	for i in $(TARGET_DIRS); do \
      echo $$i; cd $$i; make clean; make syn || exit 1; \
   done
