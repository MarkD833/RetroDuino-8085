# RetroDuino-8085

I've been toying with the idea of creating an 8085 based microprocessor board around the size of an Arduino UNO ever since I came across the [65uino](https://hackaday.io/project/190260-65uino) board on the hackaday website.

# Table of contents
* [The wish list](#the-basics-of-the-design)
  - [The Microprocessor](#the-microprocessor)
  - [ROM](#rom)
  - [RAM](#ram)
  - [Serial](#serial)
  - [I/O](#digital-input-output)
  - [ADC](#analogue-to-digital-converter)
* [Board Layout](#the-board-layout)
* [Assembly Instructions](#assembly-instructions)
* [The 16V8 GAL](#the-16v8-gal)
* [Software](#software)
  - [The Monitor](#the-8085-monitor)
* [PCB Files](#the-board-design-files)
* [Known Errors](#known-errors)
* [History](#history)
## The basics of the design

I started off with some basics:
| Item | Notes |
| :---- | :---- |
| Microprocessor | an 8085 device but which one and what clock speed |
| ROM | At least 8K maybe 16K - but do I need that much?  |
| RAM | 32K would be good to aim for |
| Serial | 1 serial port but bit bang or hardware? |
| I/O | Bit programmable i/o |
| Analogue In | A multi channel ADC if there's room |
| LEDs | At least 1 user LED |

Oh, and one other requirement - no surface mount chips or hard to solder parts!

That's quite a lot to cram into the footprint on an Arduino UNO!

After a lot of playing around with an Arduino UNO prototyping board and various chip sockets I came up with a basic design and layout.

## The Microprocessor

The 8085 is mostly seen in a 40-pin DIL package. That's a huge amount of real estate on a footprint the size of an Arduino UNO. I discovered that OKI Semiconductor manufactured an 80C85 in a 44-pin PLCC package (MSM80C85AHGS-2K). After a quick bit of digging I located the datasheet and also a source on ebay that was selling some of the chips as NOS (New Old Stock).

Additional board space is consumed as the 8085 has a multiplexed address and data bus. The lower 8-bits are shared between D0..D7 and A0..A7 and an 8-bit latch (74LS573) is used to capture A0..A7.

Another design challenge is that the 8085 interrupts (if I were to use them) are active high rather than active low! 

The 8085 is clocked from an 11.0592MHz crystal, which gives an actual clock of 5.5296MHz (the 8085 divides the crystal frequency by 2). I've yet to experiment to see the effects of a higher frequency even though I'm exceeding the manufacturers 10MHz clock by 10% already.

## ROM

There are quite a few ROM devices available in a PLCC package as well, but I decided to go with a Winbond W27C512 64K x 8 EEPROM in a 28-pin DIL package. There's plenty for sale on ebay too. The reason for going the DIL package route will become clear with the choice of RAM device.

## RAM

I couldn't find any suitable RAM devices in PLCC format so the project success was looking rather bleak. Then I discovered that there were some SRAM devices available in DIL packages that were only 0.3in wide (called Skinny-DIP if I recall correctly). I then got lucky and sourced some UMC UM61512AK 64K x 8 SRAMs in a skinny 32-pin DIL package.

The RAM chip could sit underneath the ROM chip and I would save a lot of board space.

## Serial

I thought about bit banging the serial port using the SID and SOD pins of the 8085 but decided to try and go with real hardware. Again board space was at a premium so the hunt was on for a small UART device. A lot of serial chips have a large number of pins dedicated to various handshaking signals as well as synchronous data transfer - although some devices allow repurposing of these signals as discrete inputs or outputs. They are all still quite large chips in either PLCC or 0.6in DIL packages.

I then discovered a Philips SCC2691 UART (SCC2691AC1N24) that was available in a 0.3in wide 24-pin DIL package. It had an internal baud rate generator and a single 16-bit timer/counter as well. 

## Digital Input Output

I really wanted the I/O chip to have pin programmable direction control. That ruled out the 8155 and 8255 chips. It took a lot of searching but I then discovered a Zilog Z85C36. It had 2x 8-bit bit programmable I/O ports as well as 3x 16-bit timer/counters. That would be perfect!

Except that it wasn't! In my v1.0 design, I couldn't get the Z85C36 to respond at all. I don't know quite what the issue was as I was sure that I was meeting the timing requirements - but clearly something wasn't right.

In order to salvage the situation, I changed the I/O chip to a WDC W65C22S device. The chip still gave me 2x 8-bit bit programmable I/O ports, but only 2x 16-bit timer/counters.

## Analogue to Digital Converter

If I could fit it in, then an a National Semiconductor ADC0844 might work out - it's a 4 channel ADC in a 20-pin DIL package. 

# The board layout

There was quite a bit of massaging to get everything to fit as I also used a GAL16V8 to handle address decoding and interrupt inversion. The result was a board slightly longer than an Arduino UNO (but the same width).

This is an annotated 3D view of the board generated by Kicad as it stands at v1.2.
![](./images/board3.png)

The thick white lines on the silkscreen just to the right of the FTDI serial port connector and the ADC0844 chip show the outline of an actual Arduino UNO board.

# Assembly Instructions

Assembly of the board is pretty straightforward with a few things of note.

1. Solder all the small SMD resistors and capacitors first - especially on the top of the board as there is very little room once the IC sockets are fitted.
2. Solder the microprocessor crystal and Reset device before fitting the 44-pin PLCC sockets otherwise you may find that the crystal will not fit down between the 44-pin PLCC sockets. 
3. Depending on the particular DIL socket(s) used for the SCC2691 UART, you may need to remove some of the plastic from the socket so that the 3.6864MHz crystal fits. I used 2 turned-pin sockets, an 8-pin and a 16-pin, to create the 24-pin socket needed. I found that the turned pin socket was less bulky than a regular socket.
4. The 28-pin DIL socket for the W27C512 ROM needs modifying. As the RAM chip will be sitting underneath the ROM chip, I removed the 3 pieces of plastic between the 2 rows of pins - effectively creating two separate 14-pin SIL sockets.

This is a photo of the RetroDuino-8085 board showing the location of the 3.6864MHz UART crystal and the modified 28-pin DIL socket.

![](./images/realboard.jpg)

# The 16V8 GAL

There's so little space on this board that a GAL seemed the logical choice to handle the usual discrete logic. The GAL does address and i/o decoding as follows:
* Memory space
  * 0x0000 - 0x3FFF selects the ROM
  * 0x4000 - 0xFFFF selets the RAM
* I/O space
  * 0x00 - 0x3F selects the SCC2692 UART
  * 0x40 - 0x7F selects the W65C22S digital i/o chip
  * 0x80 - 0xBF selects the ADC0844 ADC chip
 
In addition, the GAL inverts the SCC2692 and W65C22S interrupt signals.

Finally, the GAL has the ability to completely switch out the ROM to give access to the full 64K or RAM. The 8085 SOD pin is used to control this feature.

The GAL files are in the code folder.

# Software
## The 8085 Monitor 
I recently discovered the excellent 8085 monitor program written by [Dave Dunfield](https://dunfield.themindfactory.com/). You can find the source code to the 8085 monitor along with monitors for other micros in the MONITORS.ZIP file on Dave's website. The monitor code needs tweeking to support the specific UART hardware I am using but that simply involves providing code to initialise the UART and code to output a characher/byte as well as read in a character/byte.

The MON85 user manual can be found in the code folder and MON85 can be assembled using the free online assembler at [ASM80.COM](https://asm80.com) - select the 8080 CPU.

I've modified MON85 to work with the SCC2691 UART such that there are 2 versions of MON85 available:

| Software | Notes |
| :---- | :---- |
| Mon85_ROM | Monitor runs in ROM and 48K RAM is available from 0x4000 - 0xFFFF. |
| Mon85_RAM | Monitor runs in RAM and the whole 64K RAM is available but the monitor resides at 0x0000 - 0x1100. |

# The board design files

The board folder holds the gerber files that were sent to JLCPCB to make the board. It's a 4 layer board but small enough to get it made very cheaply.

The design was done using Kicad 7.0. I'm not sure exactly which files I need to share for the schematic and board layout so I've put the .kicad_pro, .kicad_sch & .kicad_sch files into the board folder. There's also the BOM as a CSV file showing the components used.

# Known errors

Yep, there are errors with v1.2. So far:
* LED D2 wrong way round
* LED D3 wrong way round

# History
* v1.2
  * Used ALE to clock the GAL rather than SYSCLK.
  * Removed the CompactFlash socket and associated passives.
  * Used 8085 SOD discrete to switch out the ROM.
  * Addition of 2nd user LED.
  * Repositioning of the FTDI connector.
* v1.1 
  * Updated design using the W65C22 PIA chip.
* v1.0
  * Initial design using the Z85C36 CIO chip.
