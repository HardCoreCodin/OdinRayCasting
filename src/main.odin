package main

when ODIN_OS == "windows" do import platform "platform/windows"

import "test"
	
main :: proc() {
	platform.run_application();

	// test.doit();	
}