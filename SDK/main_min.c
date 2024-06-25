#include <stdlib.h>
#include "hardware/gpio.h"

#include "bsp/board.h"
#include "pico/bootrom.h"

static uint32_t bootPin = 0;
static uint32_t ledPin = 25;

int main(void) {

	// Set up the LED
	gpio_init(ledPin);
	gpio_set_dir(ledPin, true);
	gpio_put(ledPin, 1);

	// Set up reset button
	// This will put the Pico into BOOTSEL mode without mass storage
	gpio_init(bootPin);
	gpio_set_dir(bootPin, false);
	gpio_pull_down(bootPin);

	while (1) {

		// Restart the board if the boot pin is high
		if (gpio_get(bootPin)) {
			reset_usb_boot(0, 1);
		}
	}
}
