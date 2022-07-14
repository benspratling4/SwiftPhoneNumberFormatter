//
//  DigitTemplateFormatter.swift
//  SwiftPhoneNumberFormatter
//
//  Created by Ben Spratling on 3/6/22.
//

import Foundation
import SwiftPatterns

///Internal component of PhoneNumber.Formatter
struct DigitTemplateFormatter {
	
	init(template:String) {
		templateComponents = .init(template: template)
	}
	
	init(templateComponents:[DigitTemplateComponent]) {
		self.templateComponents = templateComponents
	}
	
	///may contain
	/// `#` characters where user digits are substituted,
	/// digit literals which are required
	/// The letter N which means any digit except 0 or 1
	/// other characters like " " or "-" which get inserted when formatted
	let templateComponents:[DigitTemplateComponent]
	
	///value should consist entirely of digits, which you should already know should fit this template
	func string(for value:String)->String? {
		return string(for: value, index: nil)?.0
	}
	
	
	///value should consist entirely of digits, which you should already know should fit this template
	///takes an optional index parameter; if non-nil the returned Int will be the index of the similar position
	///the indexes are swift string indexes, not NSString or UITextPosition offsets
	func string(for value:String, index:Int?)->(String, Int)? {
		var valueToReturn:[DigitTemplateComponent] = []
		var remainingValue:String = value
		var indexesRemaining:Int = index ?? value.count	//the index of the cursor in the original string
		var buildUpIndexes:Int = 0	//the index of the cursor at the end
		templateLoop: for remainingComponent in templateComponents {
			if remainingValue.isEmpty {
				break
			}
			switch remainingComponent {
			case .digit:
				guard let digit = remainingValue.first else {
					break templateLoop	//if we've run out of digits, we don't need to keep adding things on from the template
				}
				let digitString = "\(digit)"
				valueToReturn.append(.digitLiteral(digitString))
				remainingValue = String(remainingValue.dropFirst())
				if indexesRemaining > 0 {
					buildUpIndexes += digitString.count
				}
				indexesRemaining -= 1
				
			case .digitSet(_):	//allowedDigits ignored because you should already the value fitits this template
				guard let digit = remainingValue.first else {
					break templateLoop	//if we've run out of digits, we don't need to keep adding things on from the template
				}
				let digitString = "\(digit)"
				valueToReturn.append(.digitLiteral(digitString))
				remainingValue = String(remainingValue.dropFirst())
				if indexesRemaining > 0 {
					buildUpIndexes += digitString.count
				}
				indexesRemaining -= 1
				
			case .literal(let literalValue):
				if indexesRemaining > 0 {
					buildUpIndexes += literalValue.count
				}	//do not decrement indexesRemaining because we have not removed a digit from our value
				valueToReturn.append(remainingComponent)
				
			case .digitLiteral(let string):
				guard let digit = remainingValue.first else {
					break templateLoop	//if we've run out of digits, we don't need to keep adding things on from the template
				}
				let digitString = "\(digit)"
				if indexesRemaining > 0 {
					buildUpIndexes += digitString.count
				}
				indexesRemaining -= 1
				
				if digitString != string {
					return nil
				}
				valueToReturn.append(.digitLiteral(digitString))
				remainingValue = String(remainingValue.dropFirst())
				
			}
		}
		let finalString = valueToReturn
			.droppingLastNonDigitLiterals
			.digitTemplateString
		return (finalString, min(buildUpIndexes, finalString.count))
	}
	
	
	///takes a user-entered string and returns an array
	///the input string should have digits only
	func value(for string:String)->([DigitTemplateComponent], isPartial:Bool)? {
		guard let finalValue = value(for: string, index: string.count) else { return nil }
		return (finalValue.0, isPartial:finalValue.isPartial)
	}
	
	func value(for string:String, index:Int?)->([DigitTemplateComponent], isPartial:Bool, index:Int)? {
		var valueToReturn:[DigitTemplateComponent] = []
		var isPartial:Bool = false
		var remainingString:String = string
		var stringIndexRemaining:Int = index ?? string.count
		var cursorIndex:Int = 0
		
		for remainingComponent in templateComponents {
			switch remainingComponent {
			case .literal(_):
				continue
				
			case .digit:
				guard let digit = remainingString.first else {
					isPartial = true
					continue
				}
				let digitString = "\(digit)"
				valueToReturn.append(.digitLiteral(digitString))
				remainingString = String(remainingString.dropFirst())
				if stringIndexRemaining > 0 {
					cursorIndex += 1
				}
				stringIndexRemaining -= 1
				
			case .digitSet(let allowedDigits):
				guard let digit = remainingString.first else {
					isPartial = true
					continue
				}
				let digitString = "\(digit)"
				guard allowedDigits.contains(digitString) else {
					//it had to be that in the set of allowed digits
					return nil
				}
				valueToReturn.append(.digitLiteral(digitString)) 	//remainingComponent == .digitLiteral("\(digit)") so either one works
				remainingString = String(remainingString.dropFirst())
				if stringIndexRemaining > 0 {
					cursorIndex += 1
				}
				stringIndexRemaining -= 1
				
			case .digitLiteral(let string):
				guard let digit = remainingString.first else {
					//if we're out of user input, and there are digit literals left to match, we did not match
					return nil
				}
				let digitString = "\(digit)"
				guard digitString == string else {
					//it had to be that precise one
					return nil
				}
				valueToReturn.append(.digitLiteral(digitString)) 	//remainingComponent == .digitLiteral("\(digit)") so either one works
				remainingString = String(remainingString.dropFirst())
				if stringIndexRemaining > 0 {
					cursorIndex += 1
				}
				stringIndexRemaining -= 1
			}
		}
		//if there are digit literals left, don't match
		if valueToReturn.isEmpty {
			return nil
		}
		return (valueToReturn, isPartial:isPartial, index:min(cursorIndex, valueToReturn.count))
	}
	
}

extension DigitTemplateFormatter : CustomStringConvertible {
	var description:String {
		return templateComponents.digitTemplateString
	}
}



enum DigitTemplateComponent : Equatable {
	//any digit, 0-9
	case digit
	
	//something other than a digit
	case literal(String)
	
	//a specific digit
	case digitLiteral(String)
	
	//right now you get this component by specifying N in the format, which supplies the set .digitsExceptOneAndZero
	case digitSet(Set<String>)
	
	//TODO: add optional digits	?
	
	var isDigitLiteral:Bool {
		switch self {
		case .digitLiteral(_):
			return true
		default:
			return false
		}
	}
}

extension Set where Element == String {
	static let digitsExceptOneAndZero:Set<String> = Set<String>(["2", "3", "4", "5", "6", "7", "8", "9"])
	static let digitsExceptZero:Set<String> = Set<String>(["1", "2", "3", "4", "5", "6", "7", "8", "9"])
}


extension DigitTemplateComponent : CustomStringConvertible {
	var description: String {
		switch self {
		case .literal(let value):
			return value
		case .digit:
			return "#"
		case .digitLiteral(let literal):
			return literal
			
		case .digitSet(let allowedDigits):
			if allowedDigits == .digitsExceptOneAndZero {
				return "N"
			}
			else {
				return "[" + "\([String](allowedDigits))" + "]"
			}
			
		}
	}
}


extension Array where Element == DigitTemplateComponent {
	init(template:String) {
		var components:[DigitTemplateComponent] = []
		for character in template {
			if CharacterSet.decimalDigits.contains(character.unicodeScalars.first!) {
				components.append(.digitLiteral("\(character)"))
			}
			else if character == "#" {
				components.append(.digit)
			}
			else if character == "N" {
				components.append(.digitSet(.digitsExceptOneAndZero))
			}
			else {
				if case .literal(let lastLiteral) = components.last  {
					components = components.dropLast() + [.literal(lastLiteral + "\(character)")]
				}
				else {
					components.append(.literal("\(character)"))
				}
			}
		}
		self = components
	}
	
	//drops .digit and .literal off the end until the last item is a .digitLiteral
	var droppingLastNonDigitLiterals:[DigitTemplateComponent] {
		[DigitTemplateComponent]( dropLast(while:{ !$0.isDigitLiteral }) )
	}
	
	var digitTemplateString:String {
		map(\.description)
		.joined()
	}
	
	//returns the number of digits in the final number
	var digitCount:Int {
		return self.filter({
			switch $0 {
			case .digit, .digitLiteral(_), .digitSet(_):
				return true
			case .literal(_):
				return false
			}
			
		}).count
	}
	
}
