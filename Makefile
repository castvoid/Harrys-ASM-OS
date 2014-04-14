#  Makefile for Harry's ASM Operating System.
# 
#  This isn't even remotely portable, but it shows
#  how I do things on my system, so it could help
#  get it working on yours.

OS-ASM-FILENAME=hasmos.asm
OS-BIN-FILENAME=hasmos.bin

BOOTLOADER-ASM-FILENAME=bootloader.asm
BOOTLOADER-BIN-FILENAME=bootloader.bin

IMG-OUTPUT-NAME=boot.img
TMP-IMG-DIR=$(CURDIR)/img/tmp

VIRTUALBOX-VM-ID=b6e6ba5c-b15c-46ae-aa9a-8a53ccb3b68d
INSPECTOR-APP=Hex Fiend

ASM-COMPILER=/usr/bin/nasm

help:
		@echo "Makefile for Harry's ASM Operating System."
		@echo "Usage: make [build | buildbl | image | run | inspect] " 

build:
		@if [ ! -d "$(CURDIR)/bin" ]; then echo "Creating $(CURDIR)/bin" && mkdir "$(CURDIR)/bin"; fi
		@echo "Building $(OS-BIN-FILENAME)"
		@$(ASM-COMPILER) "$(CURDIR)/src/$(OS-ASM-FILENAME)" -f bin -o "$(CURDIR)/bin/$(OS-BIN-FILENAME)"	
buildbl:
		@if [ ! -d "$(CURDIR)/bin" ]; then echo "Creating $(CURDIR)/bin" && mkdir "$(CURDIR)/bin"; fi
		@echo "Building $(BOOTLOADER-BIN-FILENAME)"
		@$(ASM-COMPILER) "src/$(BOOTLOADER-ASM-FILENAME)" -f bin -o "bin/$(BOOTLOADER-BIN-FILENAME)"
image: build buildbl
		@if [ ! -d "$(CURDIR)/img" ]; then echo "Creating $(CURDIR)/img" && mkdir "$(CURDIR)/img"; fi
		@echo "Creating $(IMG-OUTPUT-NAME)"
		@dd if=/dev/zero of="img/$(IMG-OUTPUT-NAME)" bs=1k count=1440 >& /dev/null
		@dd conv=notrunc if="bin/$(BOOTLOADER-BIN-FILENAME)" of="img/$(IMG-OUTPUT-NAME)" >& /dev/null
		@mkdir -p "$(TMP-IMG-DIR)"
		@echo "Mounting $(IMG-OUTPUT-NAME)"
		@hdiutil attach -readwrite -mount required -nobrowse -mountpoint "$(TMP-IMG-DIR)" -noverify -noautofsck "img/$(IMG-OUTPUT-NAME)" >& /dev/null
		@echo "Copying files..."
		@cp "bin/$(OS-BIN-FILENAME)" "$(TMP-IMG-DIR)/hasmos.bin"
		@echo "Unmounting $(IMG-OUTPUT-NAME)"
		@hdiutil detach "$(TMP-IMG-DIR)"
		@rmdir "$(TMP-IMG-DIR)"

run: image
		@/usr/bin/VBoxManage storageattach "$(VIRTUALBOX-VM-ID)" --storagectl Floppy --device 0 --type fdd --medium "img/$(IMG-OUTPUT-NAME)"
		@echo "Running VM..."
		@/usr/bin/VirtualBox -startvm "$(VIRTUALBOX-VM-ID)"

inspect: image
		@echo "Opening $(INSPECTOR-APP)"
		@/usr/bin/open -a "$(INSPECTOR-APP)" "img/$(IMG-OUTPUT-NAME)"
