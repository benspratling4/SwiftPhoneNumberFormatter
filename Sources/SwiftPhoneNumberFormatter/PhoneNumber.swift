//
//  PhoneNumber.swift
//  SwiftPhoneNumberFormatter
//
//  Created by Ben Spratling on 3/12/22.
//

import Foundation
import SwiftPatterns


public struct PhoneNumber : Equatable {
	
	public init(countryCode:CountryCode, digits:String, isPartial:Bool = false) {
		self.countryCode = countryCode
		self.digits = digits
		self.isPartial = isPartial
	}
	
	public var countryCode:CountryCode
	///excluding countryCode
	public var digits:String
	///digits may not be complete
	public var isPartial:Bool
	
	///E.164 format but without the spaces
	public var e164:String {
		return "+" + countryCode.rawValue + digits
	}
	
}

//Encodable and Decodable work by serializing an E.164 string
extension PhoneNumber : Encodable {
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(e164)
	}
}

extension PhoneNumber : Decodable {
	
	static let phoneNumberDecoderFormatter:PhoneNumber.Formatter = PhoneNumber.Formatter(allowedOptions: .all)
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let string = try container.decode(String.self)
		//assuming the string starts with +, the PhoneNumber.Formatter will find the number amongst all known country codes with any options
		guard let value = PhoneNumber.phoneNumberDecoderFormatter.enteredPhoneNumber(string, originalIndex: nil)?.0 else {
			throw DecodeError.unableToDecodee164Value
		}
		self = value
	}
	
	public enum DecodeError:Error {
		case unableToDecodee164Value
	}
	
}

extension PhoneNumber {
	public enum CountryCode : String, Codable, Hashable, CaseIterable {
		case austrailia = "61"
		case mexico = "52"
		case unitedKingdom = "44"
		//North American Numbering Plan
		case usAndCanada = "1"
	}
}

