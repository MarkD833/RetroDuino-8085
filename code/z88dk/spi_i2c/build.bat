zcc +z80 -clib=8085 main.c sys\hardware.c sys\low_level.asm -crt0=.\sys\rd85_crt0.asm -lndos -create-app -m -Cz--ihex
