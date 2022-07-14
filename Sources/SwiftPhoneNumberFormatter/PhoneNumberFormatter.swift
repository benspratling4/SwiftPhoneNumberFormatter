//
//  PhoneNumberFormatter.swift
//  SwiftPhoneNumberFormatter
//
//  Created by Ben Spratling on 3/6/22.
//

import Foundation
import SwiftPatterns


extension PhoneNumber {
	
	public struct Formatter {
		
		public init(
			///allowedCountries must have at least one entry
			allowedCountries:[PhoneNumber.CountryCode] = PhoneNumber.CountryCode.allCases
			///will assume the first country in your allowedCountries
			 ,assumedCountry:PhoneNumber.CountryCode? = nil
			 ,allowedOptions:PhoneNumber.Template.Options = .default
			,formatOptions:FormatOptions = .default
		) {
			self.allowedCountries = allowedCountries
			self.assumedCountry = assumedCountry ?? allowedCountries.first ?? .usAndCanada
			self.templates = Self.allTemplatesByCountry.filter({allowedCountries.contains($0.key) })
			self.allowedOptions = allowedOptions
			self.templateCache = ParsedTemplateCache(templates)
			self.formatOptions = formatOptions
		}
		
		public struct FormatOptions : OptionSet {
			
			public static let `default` = FormatOptions([])
			
			public static let useNonBreakingSpace:FormatOptions = FormatOptions(rawValue: 1<<0)
			
			//MARK: - RawRepresentable
			public var rawValue: Int
			public init(rawValue: Int) {
				self.rawValue = rawValue
			}
		}
		
		public func enteredPhoneNumber(_ input:String)->PhoneNumber? {
			return enteredPhoneNumber(input, originalIndex: nil)?.0
		}
		
		public func enteredPhoneNumber(_ input:String, originalIndex:Int?)->(PhoneNumber, Int)? {
			//get the sanitized string which contains only digits that we should care about
			let sanitizedString:String = input
				.convertingPhoneWords
				.deletingNonE164Characters
			
			//find out how many digits there are before the originalIndex in the original string
			let digitsBeforeIndex:Int
			if let stringIndex = originalIndex {
				digitsBeforeIndex = String(input[..<input.index(input.startIndex, offsetBy: stringIndex)])
					.convertingPhoneWords
					.digits
					.count
			}
			else {
				digitsBeforeIndex = sanitizedString.digits.count
			}
			
			//look for explicit E.164 format, by looking for the leading +
			if let withoutPlus:String = sanitizedString.withoutPrefix("+") {
				//find the matching country code and the digits after it
				guard let (countryCode, digits) = allowedCountries
						.compactMap({ code->(CountryCode, String)? in
							//we will not consider the country code if the digits aren't there
							guard let digits = withoutPlus.withoutPrefix(code.rawValue) else { return nil }
							return (code, digits)
						})
						.first
					else { return nil }	//if we have +, but can't match an allowed country code, return nil
				let cursorDigitsAfterCountryCode:Int = digitsBeforeIndex - countryCode.rawValue.count
				guard let templates:[(template:[DigitTemplateComponent], options:PhoneNumber.Template.Options, trunkCode:String?)] = templateCache.templates[countryCode] else { return nil }
				//find all the matching templates
				let matchingTemplates = templates.compactMap({ template->([DigitTemplateComponent], Bool, Int, Template.Options)? in
					guard let (components, isPartial, index) = DigitTemplateFormatter(templateComponents: template.template)
							.value(for: digits, index: cursorDigitsAfterCountryCode)
						else { return nil }
					return (components, isPartial, index, template.options)
				})
				//if we have any exact matches, consider only them
				let matchesToConsider:[([DigitTemplateComponent], Bool, Int, Template.Options)]
				let exactTemplateMatches = matchingTemplates.filter({ !$0.1 })
				if exactTemplateMatches.count > 0 {
					//ignore all partial matches
					matchesToConsider = exactTemplateMatches
				}
				else {
					matchesToConsider = matchingTemplates
				}
				
				//if one of the matched templates is disallowed, return nil
				if matchesToConsider
					//if a template's options, without the allowed options, is not empty, then it has matched a bad options set
					.filter({ !$0.3.subtracting(allowedOptions).isEmpty })
					.count > 0 {
					//if we have any of those, we get to here
					return nil
				}
				
				//return the first match
				return matchesToConsider.first.flatMap {
					//we have several partial matches, just return any
					(PhoneNumber(countryCode: countryCode, digits: $0.0.digitTemplateString, isPartial: $0.1)
					 ,$0.2)
					}
			}
			
			
			//look for leading country codes
			let countryCodeDigitPairs:[(PhoneNumber, Int)] = allowedCountries
				.compactMap({ code->(CountryCode, String)? in
					//we will not consider the country code if the digits aren't there
					guard let digits = sanitizedString.withoutPrefix(code.rawValue) else { return nil }
					return (code, digits)
				})
				.compactMap { (countryCode, digits) in
					guard let templates:[(template:[DigitTemplateComponent], options:PhoneNumber.Template.Options, trunkCode:String?)] = templateCache.templates[countryCode]
						else { return nil }
					//if there is a country code, there should not be a trunk code
					let cursorDigitsAfterCountryCode:Int = digitsBeforeIndex - countryCode.rawValue.count
					//find all the matching templates
					let matchingTemplates = templates.compactMap({ template->([DigitTemplateComponent], Bool, Int, Template.Options)? in
						guard let (components, isPartial, index) = DigitTemplateFormatter(templateComponents: template.template).value(for: digits, index: cursorDigitsAfterCountryCode) else {
							return nil
						}
						return (components, isPartial, index, template.options)
					})
					let matchesToConsider:[([DigitTemplateComponent], Bool, Int, Template.Options)]
					let exactTemplateMatches = matchingTemplates.filter({ !$0.1 })
					if exactTemplateMatches.count > 0 {
						//ignore all partial matches
						matchesToConsider = exactTemplateMatches
					}
					else {
						matchesToConsider = matchingTemplates
					}
					//if one of the matched templates is disallowed, return nil
					if matchesToConsider.filter({ !$0.3.subtracting(allowedOptions).isEmpty }).count > 0 {
						return nil
					}
					
					//return the first match
					return matchesToConsider.first.flatMap {
						(PhoneNumber(countryCode: countryCode, digits: $0.0.digitTemplateString, isPartial: $0.1)
						 ,$0.2)
						 }
				}
			
			if let exactMatch = countryCodeDigitPairs.filter({ !$0.0.isPartial }).first {
				return exactMatch
			}
			else if let matchingAssumedCountry = countryCodeDigitPairs.filter({ $0.0.countryCode == assumedCountry }).first {
				return matchingAssumedCountry
			}
			else {
				//we should look to see if we get a non-partial match by assuming the country code and return that first
			}
			
			
			//see if we can assume a country code, either by matching a template, or by assuming the country code.
			
			let matchings:[(PhoneNumber, Int)] = allowedCountries
				.compactMap({ countryCode in
					guard let templates:[(template:[DigitTemplateComponent], options:PhoneNumber.Template.Options, trunkCode:String?)] = templateCache.templates[countryCode]
						else { return nil }
					//find all the matching templates
					let matchingTemplates = templates.compactMap({ template->([DigitTemplateComponent], Bool, Int, Template.Options)? in
						//if there is a trunk code, optionally remove it from the front
						let withoutTrunkCode:String = template.trunkCode.flatMap({ sanitizedString.withoutPrefix($0) }) ?? sanitizedString
						guard let (components, isPartial, index) = DigitTemplateFormatter(templateComponents: template.template).value(for: withoutTrunkCode, index: digitsBeforeIndex) else {
							return nil
						}
						return (components, isPartial, index, template.options)
					})
					let matchesToConsider:[([DigitTemplateComponent], Bool, Int, Template.Options)]
//					let exactTemplateMatches = matchingTemplates.filter({ !$0.1 })
//					if exactTemplateMatches.count > 0 {
//						//ignore all partial matches
//						matchesToConsider = exactTemplateMatches
//					}
//					else {
						matchesToConsider = matchingTemplates
//					}
					//if one of the matched templates is disallowed, return nil
					if matchesToConsider.filter({ !$0.3.subtracting(allowedOptions).isEmpty }).count > 0 {
						return nil
					}
					
					//return the first match
					return matchesToConsider.first.flatMap {
						(PhoneNumber(countryCode: countryCode, digits: $0.0.digitTemplateString, isPartial: $0.1)
						 ,$0.2)
						 }
				})
			
			let exactMatchesWithAllCountryCodes = matchings.filter({ !$0.0.isPartial })
			//look for a matching non-partial code, with the assumed country code
			if let assumedCountryMatch = exactMatchesWithAllCountryCodes
				.filter({ $0.0.countryCode == assumedCountry }).first {
				return assumedCountryMatch
			}
			
			//return any non-partial match without a leading country code
			if let anyNonPartialMatch = exactMatchesWithAllCountryCodes.first {
				return anyNonPartialMatch
			}
			
			//return partial matches with leading country codes before partial matches without them
			if let anyNonPartialLeadingCountryCodeMatch = countryCodeDigitPairs.first {
				return anyNonPartialLeadingCountryCodeMatch
			}
			
			//any partial non-leading country code, with the assumed country
			if let anyMatch = matchings.filter({ $0.0.countryCode == assumedCountry }).first {
				return anyMatch
			}
			
			//anything
			return matchings.first
		}
		
		public enum CountryCodeOptions {
			///formatted for internaitonal numbers
			case includeCountryCode
			///if you're going to draw the country code leading in some other way, this option will not draw the country code or the trunk code
			case countryCodeDrawnSeparately
			///if the country has a trunk code, it will be included
			case noCountryCode
		}
		
		public func formattedNumber(_ entry:PhoneNumber, includeCountryCode:CountryCodeOptions = .noCountryCode)->String? {
			return formattedNumber(entry, index: nil, includeCountryCode: includeCountryCode)?.0
		}
		
		public func formattedNumber(_ entry:PhoneNumber, index:Int?, includeCountryCode:CountryCodeOptions = .noCountryCode)->(String, Int)? {
			guard let countryProperties = self.templates[entry.countryCode] else { return nil }
			let templates = countryProperties.templates
				.filter({ $0.options.subtracting(allowedOptions).isEmpty })
			guard templates.count > 0 //don't use templates which can render options we aren't using
				else { return nil }
			guard let formattedValue = templates
			//something about removing templates with disallowed options
				.compactMap({ template in
					return DigitTemplateFormatter(template: template.template)
						.string(for: entry.digits, index: index)
				})
				.first
			else { return nil }
			switch includeCountryCode {
			case .includeCountryCode:
				let preString = "+" + entry.countryCode.rawValue + " "
				let finalString:String = preString + formattedValue.0
				let finalIndex = preString.count + formattedValue.1
				if formatOptions.contains(.useNonBreakingSpace) {
					return (finalString.replacingOccurrences(of: " ", with: "\u{00a0}"), finalIndex)
				}
				else {
					return (finalString, finalIndex)
				}
				
			case .countryCodeDrawnSeparately:
				if formatOptions.contains(.useNonBreakingSpace) {
					return (formattedValue.0.replacingOccurrences(of: " ", with: "\u{00a0}"), formattedValue.1)
				}
				else {
					return formattedValue
				}
				
			case .noCountryCode:
				let spaceReplaced:String
				if formatOptions.contains(.useNonBreakingSpace) {
					spaceReplaced = formattedValue.0.replacingOccurrences(of: " ", with: "\u{00a0}")
				}
				else {
					spaceReplaced = formattedValue.0
				}
				
				if let trunkCode = countryProperties.trunkCode {
					return (trunkCode + spaceReplaced, formattedValue.1 + trunkCode.count)
				}
				return (spaceReplaced, formattedValue.1)
			}
		}
		
		public var allowedCountries:[PhoneNumber.CountryCode]
		public var assumedCountry:PhoneNumber.CountryCode
		public var allowedOptions:PhoneNumber.Template.Options
		
		///if set to true, spaces in the digit template will be replaced with \u{00a0}
		public var formatOptions:FormatOptions
		public var templates:[PhoneNumber.CountryCode:(templates:[PhoneNumber.Template], trunkCode:String?)] {
			didSet {
				templateCache = ParsedTemplateCache(templates)
			}
		}
		
		fileprivate var templateCache:ParsedTemplateCache
		
		public static var allTemplatesByCountry:[PhoneNumber.CountryCode:(templates:[PhoneNumber.Template], trunkCode:String?)] = [
			.austrailia:([
				.init("4## ### ###", options: .mobile),
				.init("5## ### ###", options: .mobile),
				
			], "0"),
			.danmark:([
				.init("112", options: .emergency),
				.init("114", options: .emergency),
				.init("80 ## ## ##", options: .tollFree),
				"## ## ## ##",
			], nil),
			.españa:([
				.init("112", options: .emergency),
				.init("6## ### ###", options:.mobile),
				.init("7## ### ###", options:.mobile),
				], nil),
			.ελλάδα:([
				"### #######",
			], nil),
			.ísland:([
				"3## ### ###",
				"### ####",
			], nil),
			.italia:([
				.init("112", options: .emergency),
				.init("113", options: .emergency),
				.init("114", options: .emergency),
				.init("115", options: .emergency),
				.init("118", options: .emergency),
				.init("3## ######", options: .mobile),
				.init("3## #######", options: .mobile),
			], nil),
			.mexico:(["(##) ####-####"], nil),
			.polska:([
				.init("800 ### ###", options: .tollFree),
				"## ### ## ##",
			], nil),
			.repúblicaPortuguesa:([
				.init("9## ### ###", options: .mobile),
			], nil),
			.unitedKingdom:([
				.init("999", options: [.emergency]),
				.init("112", options: [.emergency]),
				.init("7### ### ###", options: [.mobile]),
				.init("800 ### ###", options: [.tollFree]),
				.init("800 ### ####", options: [.tollFree]),
				.init("808 ### ####", options: [.tollFree]),
			], "0"),
			
			///North American Numbering Plan
			.usAndCanada:([
				.init("(800) ###-####", options: .tollFree),
				.init("(888) ###-####", options: .tollFree),
				.init("(666) ###-####", options: .forbidden),
				.init("(###) 555-####", options: .entertainment),
				.init("911", options: .emergency),
				"(###) ###-####",
			], nil),
			//TODO: add more information about other country's phone number formats
		]
	 
	}
}


extension PhoneNumber {
	public struct Template {
		
		public init(_ template:String, options:Options = .default) {
			self.template = template
			self.options = options
		}
		
		public var template:String
		public var options:Options
		//localizations?
		
	}
}


extension PhoneNumber.Template : ExpressibleByStringLiteral {
	public init(stringLiteral value: String) {
		self.init(value)
	}
}


extension PhoneNumber.Template {
	public struct Options : OptionSet, CustomStringConvertible {
		
		///the set of phone number options which real end users might provide as their number
		public static let `default`:Options = [.mobile, .service, .tollFree]
		
		public static let all:Options = [.mobile, .service, .tollFree, .emergency, .forbidden, .entertainment]
		
		///numbers which may only be used by mobile phones
		public static let mobile = Options(rawValue:1<<1)
		///used by businesses
		public static let service = Options(rawValue:1<<2)
		///used by businesses which will accept the charges
		public static let tollFree = Options(rawValue:1<<3)
		///used for contacting emergency services
		public static let emergency = Options(rawValue:1<<4)
		///patterns which cannot be real phone numbers
		public static let forbidden = Options(rawValue:1<<5)
		///patterns of phone numbers which may be stated in entertainment, but not assigned to real devices
		public static let entertainment = Options(rawValue:1<<6)
		
		
		//MARK: - CustomStringConvertible
		public var description:String {
			if self == Self.all {
				return ".all"
			}
			if self == Self.default {
				return ".default"
			}
			var finalString = "["
			if contains(.mobile) {
				finalString += ".mobile,"
			}
			if contains(.service) {
				finalString += ".service,"
			}
			if contains(.tollFree) {
				finalString += ".tollFree,"
			}
			if contains(.emergency) {
				finalString += ".emergency,"
			}
			if contains(.forbidden) {
				finalString += ".forbidden,"
			}
			if contains(.entertainment) {
				finalString += ".entertainment,"
			}
			finalString += "]"
			return finalString
		}
		
		
		//MARK: - RawRepresentable
		public var rawValue: Int
		public init(rawValue:Int) {
			self.rawValue = rawValue
		}
	}
}

private class ParsedTemplateCache {
	
	init(_ templates:[PhoneNumber.CountryCode:(templates:[PhoneNumber.Template], trunkCode:String?)]) {
		self.templates = templates.mapValues({ (tuple)->[(template:[DigitTemplateComponent], options:PhoneNumber.Template.Options, trunkCode:String?)] in
			tuple.templates.map { ([DigitTemplateComponent](template:$0.template), $0.options, tuple.trunkCode) }
		})
	}
	
	var templates:[PhoneNumber.CountryCode:[(template:[DigitTemplateComponent], options:PhoneNumber.Template.Options, trunkCode:String?)]] = [:]
	
}
