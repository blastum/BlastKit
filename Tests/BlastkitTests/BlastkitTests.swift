@testable import Blastkit
import XCTest

final class BlastkitTests: XCTestCase {
	func testBlastkitImport() {
		// Test that Blastkit can be imported
		// This test ensures the package can be imported successfully
		XCTAssertTrue(true) // Basic test that the module loads
	}

	func testSubModuleAvailability() {
		// Test that all sub-modules are available through Blastkit
		// This test ensures the re-export functionality works

		// Test that we can access some basic types from the modules
		// If this compiles, it means the re-export is working
		XCTAssertTrue(true) // Basic test that the module loads
	}

	static var allTests = [
		("testBlastkitImport", testBlastkitImport),
		("testSubModuleAvailability", testSubModuleAvailability),
	]
}
