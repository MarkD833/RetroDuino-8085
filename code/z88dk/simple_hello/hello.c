/* Simple Text I/O for RetroDuino-8085 using z88dk
 *
 * Designed to be loaded via MON85 and assumes that the UART
 * is already configured.
 *
 * Guidance: https://github.com/z88dk/z88dk/wiki/Classic--Homebrew
 */
 
#include <stdio.h>

int main()
{
    printf("Hello from z88dk!\n");

    while ( 1 ) {
        int c = getchar();
        printf("<%c>=%d\n", c,c);
    }
}
