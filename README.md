Harry's ASM Operating System
============================

**Warning**: This project is intended for my own learning. The code in here is guaranteed to be horrible, poorly commented, etc. Attempt to use it at your own risk!

##What is the point?
The aim is to build a functional operating system, in x86 assembly. Ideally, it will include many basic commands (date, ls, cat) and be able to interact with filesystems. It will (probably) never have any fancy features like privileges, but it's functional!

##Building
###Main OS
Building the main OS code is as simple as running

    make build
Or alternatively

    nasm src/hasmos.asm -f bin -o bin/hasmos.bin

###Bootloader
The boot loader is just a slightly modified version of John S. Fine's FAT12 boot loader, and can be compiled by running

    make buildbl
    
Or alternatively

    nasm src/bootloader.asm -f bin -o bin/bootloader.bin
    
###Assembling an image
This is more complicated. To do this, you may be able to just run 

    make image
However, this will not work on any computer that isn't running OS X. To make an image, you must:

1. Make a new 1.4MB floppy image (1440 * 1KB) (e.g. `dd if=/dev/zero of=img/boot bs=1k count=1440`)
2. Format it as FAT12. You may do this however you wish, or in fact you may not need to do it at all, depending on how you proceed.
3. Copy the boot loader onto the image. To do this, you may either copy the whole thing over the image `dd conv=notrunc if=bin/bootloader.bin of=img/boot.img`, required if you haven't formatted the image, or by copying the first 3 bytes and bytes 0x3E through to 0x1FF onto the same location on the image. This will preserve the properties of the original image
4. Copy `hasmos.bin` onto the image
5. Run the OS from the image. This can be through a VM, by using the image as a virtual floppy, or on an *actual* floppy disk! Right now, booting from USB seems to be very hit-and-miss.

If you are on an OS X system, you can use `make run` to assemble the image, attach it to the VM, and run the VM. First you need to have a blank virtualbox VM set up, and put the UID into the makefile.

#Resources
#####[Wikipedia - BIOS Interrupts](https://en.wikipedia.org/wiki/BIOS_interrupt_call)

#####[Wikibooks - x86 Assembly](https://en.wikibooks.org/wiki/X86_Assembly)

#####[OSDev.org Wiki](http://wiki.osdev.org/Main_Page)

#####[Joel Gompert's Write Your Own Operating System Tutorial](http://joelgompert.com/OS/TableOfContents.htm)

#####[James Molloy's kernel development tutorials](khttp://www.jamesmolloy.co.uk/tutorial_html/index.html)

#####[Brandon F.'s *Bona Fide OS Development*](http://www.osdever.net/bkerndev/index.php)

#####[Arjun Sreedharan's Kernel 101](http://arjunsreedharan.org/post/82710718100/kernel-101-lets-write-a-kernel)
