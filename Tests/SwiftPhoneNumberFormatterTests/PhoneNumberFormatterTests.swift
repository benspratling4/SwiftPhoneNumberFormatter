//
//  PhoneNumberFormatterTests.swift
//  SwiftPhoneNumberFormatter
//
//  Created by Ben Spratling on 3/6/22.
//

import XCTest
import SwiftPhoneNumberFormatter


class PhoneNumberFormatterTests: XCTestCase {
	
	func testParsingE164() {
		let formatter = PhoneNumber.Formatter(allowedCountries: [.usAndCanada], allowedOptions: .all)
		let value = formatter.enteredPhoneNumber("+12024041234")
		XCTAssertEqual(value, PhoneNumber(countryCode: .usAndCanada, digits: "2024041234", isPartial: false))
	}
	
	func testParsingLeadingCountryCode() {
		let formatter = PhoneNumber.Formatter(allowedCountries: [.usAndCanada], allowedOptions: .all)
		let value = formatter.enteredPhoneNumber("1 202 404 1234")
		XCTAssertEqual(value, PhoneNumber(countryCode: .usAndCanada, digits: "2024041234", isPartial: false))
	}
	
	func testParsingEmergency() {
		let formatter = PhoneNumber.Formatter(allowedCountries: [.usAndCanada], allowedOptions: .all)
		let value = formatter.enteredPhoneNumber("911")
		XCTAssertEqual(value, PhoneNumber(countryCode: .usAndCanada, digits: "911", isPartial: false))
	}
	
	func testParsingNoLeadingCountryCode() {
		let formatter = PhoneNumber.Formatter(allowedCountries: [.usAndCanada])
		let value = formatter.enteredPhoneNumber("202 404-1234")
		XCTAssertEqual(value, PhoneNumber(countryCode: .usAndCanada, digits: "2024041234", isPartial: false))
	}
	
	func testParsingIncompleteNoLeadingCountryCode() {
		let formatter = PhoneNumber.Formatter(allowedCountries: [.usAndCanada])
		let value = formatter.enteredPhoneNumber("(202) 404-123")
		XCTAssertEqual(value, PhoneNumber(countryCode: .usAndCanada, digits: "202404123", isPartial: true))
	}
	
	func testParsingIncompleteNoLeadingCountryCodeWithIndex() {
		let formatter = PhoneNumber.Formatter(allowedCountries: [.usAndCanada])
		guard let (value, index) = formatter.enteredPhoneNumber("(202) 404-123", originalIndex: 13) else {
			XCTFail()
			return
		}
		XCTAssertEqual(value, PhoneNumber(countryCode: .usAndCanada, digits: "202404123", isPartial: true))
		XCTAssertEqual(index, 9)
	}
	
	func testParsingIncompleteNoLeadingCountryCodeWithIndexMiddle() {
		let formatter = PhoneNumber.Formatter(allowedCountries: [.usAndCanada])
		guard let (value, index) = formatter.enteredPhoneNumber("(202) 44-123", originalIndex: 7) else {
			XCTFail()
			return
		}
		XCTAssertEqual(value, PhoneNumber(countryCode: .usAndCanada, digits: "20244123", isPartial: true))
		XCTAssertEqual(index, 4)
	}
	
	func testFormattingIncompleteNoLeadingCountryCodeWithIndexMiddle() {
		let formatter = PhoneNumber.Formatter(allowedCountries: [.usAndCanada])
		let value = PhoneNumber(countryCode: .usAndCanada, digits: "20244123", isPartial: true)
		
		guard let (formattedValue, index) = formatter.formattedNumber(value, index: 4) else {
			XCTFail()
			return
		}
		
		XCTAssertEqual(formattedValue, "(202) 441-23")
		XCTAssertEqual(index, 7)
	}
	
	func testParsingIncompleteNoLeadingCountryCodeWithIndexAfterLeadingLiterals() {
		let formatter = PhoneNumber.Formatter(allowedCountries: [.usAndCanada])
		guard let (value, index) = formatter.enteredPhoneNumber("(202) 44-123", originalIndex: 1) else {
			XCTFail()
			return
		}
		XCTAssertEqual(value, PhoneNumber(countryCode: .usAndCanada, digits: "20244123", isPartial: true))
		XCTAssertEqual(index, 0)
	}
	
	func testFormattingIncompleteNoLeadingCountryCodeWithIndexAfterLeadingLiterals() {
		let formatter = PhoneNumber.Formatter(allowedCountries: [.usAndCanada])
		let value = PhoneNumber(countryCode: .usAndCanada, digits: "20244123", isPartial: true)
		
		guard let (formattedValue, index) = formatter.formattedNumber(value, index: 0) else {
			XCTFail()
			return
		}
		
		XCTAssertEqual(formattedValue, "(202) 441-23")
		XCTAssertEqual(index, 1)
	}
	
	func testFormatting() {
		let formatter = PhoneNumber.Formatter(allowedCountries: [.usAndCanada])
		let value = PhoneNumber(countryCode: .usAndCanada, digits: "2024041234", isPartial: true)
		
		guard let formattedValue = formatter.formattedNumber(value) else {
			XCTFail()
			return
		}
		
		XCTAssertEqual(formattedValue, "(202) 404-1234")
	}
	
	
	func testPhoneNumberCoding() {
		let value = PhoneNumber(countryCode:.usAndCanada, digits: "6664041234")
		let encodedData = try! JSONEncoder().encode(value)
		let encodedString = String(data: encodedData, encoding: .utf8)!
		XCTAssertEqual(encodedString, "\"+16664041234\"")
		let decoded = try! JSONDecoder().decode(PhoneNumber.self, from: encodedData)
		XCTAssertEqual(value, decoded)
	}
	
	
	
}
