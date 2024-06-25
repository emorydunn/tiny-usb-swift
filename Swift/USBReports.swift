//--------------------------------------------------------------------+
// Device callbacks
//--------------------------------------------------------------------+


func tud_mount_cb() {
	Main.interval = .mounted
}

func tud_umount_cb() {
	Main.interval = .notMounted
}

func tud_suspend_cb() {
	Main.interval = .suspended
}

func tud_resume_cb() {
	Main.interval = .mounted
}

//--------------------------------------------------------------------+
// USB HID
//--------------------------------------------------------------------+

/// Invoked when received GET_REPORT control request
/// Application must fill buffer report's content and return its length.
/// Return zero will cause the stack to STALL request
public func tud_hid_get_report_cb(itf: UInt8, report_id: UInt8, report_type: hid_report_type_t, buffer: UnsafeMutablePointer<UInt8>, reqlen: UInt16) -> UInt16 {
	// TODO not Implemented
	// (void) itf;
	// (void) report_id;
	// (void) report_type;
	// (void) buffer;
	// (void) reqlen;

	return reqlen;
}

/// Invoked when received SET_REPORT control request or
/// received data on OUT endpoint ( Report ID = 0, Type = 0 )
public func tud_hid_set_report_cb(_ itf: UInt8, _ report_id: UInt8, report_type: hid_report_type_t, buffer: UnsafePointer<UInt8>, bufsize: UInt16) {

	var pointer: UInt8 = 0
	_ = withUnsafeMutablePointer(to: &pointer) { pointer in
		tud_hid_report(0, pointer, bufsize)
	}

}
