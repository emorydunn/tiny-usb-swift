enum BlinkInterval: UInt32 {
	case notMounted = 250
	case mounted = 1000
	case suspended = 2500
}

@main
struct Main {

	static var ledPin: UInt32 = 25
	static var bootPin: UInt32 = 0

	static var interval = BlinkInterval.notMounted

	static var startMS: UInt32 = 0
	static var ledState = false

	static func main() {

		// Set up TinyUSB
		tusb_init()

		// Set up the LED
		gpio_init(ledPin)
		gpio_set_dir(ledPin, true)

		// Set up reset button
		// This will put the Pico into BOOTSEL mode without mass storage
		gpio_init(bootPin)
		gpio_set_dir(bootPin, false)
		gpio_pull_down(bootPin)

		while true {
			// Restart the board if the boot pin is high
			if gpio_get(bootPin) {
				reset_usb_boot(0, 1)
			}

			tud_task() // tinyusb device task
			ledBlinkingTask()
		}

	}

	/// Blink the LED to show the status of the board.
	static func ledBlinkingTask() {

		let time = get_absolute_time()
		let bootMS = to_ms_since_boot(time)


		if bootMS - startMS < interval.rawValue {
			return
		}

		startMS += interval.rawValue

		gpio_put(ledPin, ledState)
		ledState.toggle()
	}
}

