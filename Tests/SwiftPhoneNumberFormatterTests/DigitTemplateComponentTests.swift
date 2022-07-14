//
//  DigitTemplateComponentTests.swift
//  SwiftPhoneNumberFormatter
//
//  Created by Ben Spratling on 3/12/22.
//

import XCTest
@testable import SwiftPhoneNumberFormatter


class DigitTemplateComponentTests: XCTestCase {

	func testDigitTemplateComponentParsingEmpty() {
		let emptyString = ""
		let output = [DigitTemplateComponent](template:emptyString)
		XCTAssertEqual(output, [])
	}
	
	func testDigitTemplateComponentParsingLiteral() {
		let testCases:[(String, [DigitTemplateComponent])] = [
			("(", [.literal("(")]),
			("-", [.literal("-")]),
			(" ", [.literal(" ")]),
			(",", [.literal(",")]),
			("+", [.literal("+")]),
		]
		for (string, array) in testCases {
			let output = [DigitTemplateComponent](template:string)
			XCTAssertEqual(output, array)
		}
	}
	
	func testDigitTemplateComponentParsingCombiningLiteral() {
		let testCases:[(String, [DigitTemplateComponent])] = [
			("( -", [.literal("( -")]),
		]
		for (string, array) in testCases {
			let output = [DigitTemplateComponent](template:string)
			XCTAssertEqual(output, array)
		}
	}
	
	func testDigitTemplateComponentParsingDigitLiteral() {
		let testCases:[(String, [DigitTemplateComponent])] = [
			("0", [.digitLiteral("0")]),
			("1", [.digitLiteral("1")]),
			("2", [.digitLiteral("2")]),
			("3", [.digitLiteral("3")]),
			("4", [.digitLiteral("4")]),
			("5", [.digitLiteral("5")]),
			("6", [.digitLiteral("6")]),
			("7", [.digitLiteral("7")]),
			("8", [.digitLiteral("8")]),
			("9", [.digitLiteral("9")]),
		]
		for (string, array) in testCases {
			let output = [DigitTemplateComponent](template:string)
			XCTAssertEqual(output, array)
		}
	}
	
	func testDigitTemplateComponentParsingDigitTemplate() {
		let testCases:[(String, [DigitTemplateComponent])] = [
			("#", [.digit]),
		]
		for (string, array) in testCases {
			let output = [DigitTemplateComponent](template:string)
			XCTAssertEqual(output, array)
		}
	}
	
	func testDigitTemplateComponentParsingCombinedTemplate() {
		let testCases:[(String, [DigitTemplateComponent])] = [
			("(N##) 867-5309", [
				.literal("("),
				.digitSet(.digitsExceptOneAndZero), .digit, .digit,
				.literal(") "),
				.digitLiteral("8"),
				.digitLiteral("6"),
				.digitLiteral("7"),
				.literal("-"),
				.digitLiteral("5"),
				.digitLiteral("3"),
				.digitLiteral("0"),
				.digitLiteral("9"),
			]),
			("(###) N##-####", [
				.literal("("),
				.digit, .digit, .digit,
				.literal(") "),
				.digitSet(.digitsExceptOneAndZero), .digit, .digit,
				.literal("-"),
				.digit, .digit, .digit, .digit,
			]),
		]
		for (string, array) in testCases {
			let output = [DigitTemplateComponent](template:string)
			XCTAssertEqual(output, array)
		}
	}
	
	
	func testDropNonDigitLiterals() {
		let testCases:[([DigitTemplateComponent], [DigitTemplateComponent])] = [
			//no digits to drop
			([
				.literal("("),
				.digit, .digit, .digit,
				.literal(") "),
				.digitLiteral("8"),
				.digitLiteral("6"),
				.digitLiteral("7"),
				.literal("-"),
				.digitLiteral("5"),
				.digitLiteral("3"),
				.digitLiteral("0"),
				.digitLiteral("9"),
			],
			 [
				 .literal("("),
				 .digit, .digit, .digit,
				 .literal(") "),
				 .digitLiteral("8"),
				 .digitLiteral("6"),
				 .digitLiteral("7"),
				 .literal("-"),
				 .digitLiteral("5"),
				 .digitLiteral("3"),
				 .digitLiteral("0"),
				 .digitLiteral("9"),
			 ]),
			//everything drops
			([
				.literal("("),
				.digit, .digit, .digit,
				.literal(") "),
				.digit, .digit, .digit,
				.literal("-"),
				.digit, .digit, .digit, .digit,
			],
			 []),
			//some drop
			([
				.literal("("),
				.digit, .digit, .digit,
				.literal(") "),
				.digitLiteral("5"),
				.digitLiteral("5"),
				.digitLiteral("5"),
				.literal("-"),
				.digit, .digit, .digit, .digit,
			],
			 [
				.literal("("),
				.digit, .digit, .digit,
				.literal(") "),
				.digitLiteral("5"),
				.digitLiteral("5"),
				.digitLiteral("5"),
			 ]),
		]
		
		for (input, output) in testCases {
			XCTAssertEqual(input.droppingLastNonDigitLiterals, output)
		}
	}
	
	
}
