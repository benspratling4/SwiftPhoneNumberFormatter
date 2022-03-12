//
//  String+extensions.swift
//  SwiftPhoneNumberFormatter
//
//  Created by Ben Spratling on 3/12/22.
//

import Foundation

extension String {
	public var digits:String {
		return self.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
	}
	
	///if there are letters in the string, they are replaced with the corresponding phone key pad digit
	var convertingPhoneWords:String {
		return self
			.replacingOccurrences(of: "[a-c]", with: "2", options: [.regularExpression, .caseInsensitive])
			.replacingOccurrences(of: "[d-f]", with: "3", options: [.regularExpression, .caseInsensitive])
			.replacingOccurrences(of: "[g-i]", with: "4", options: [.regularExpression, .caseInsensitive])
			.replacingOccurrences(of: "[j-l]", with: "5", options: [.regularExpression, .caseInsensitive])
			.replacingOccurrences(of: "[m-o]", with: "6", options: [.regularExpression, .caseInsensitive])
			.replacingOccurrences(of: "[p-s]", with: "7", options: [.regularExpression, .caseInsensitive])
			.replacingOccurrences(of: "[t-v]", with: "8", options: [.regularExpression, .caseInsensitive])
			.replacingOccurrences(of: "[w-z]", with: "9", options: [.regularExpression, .caseInsensitive])
	}
	
	var deletingNonE164Characters:String {
		replacingOccurrences(of: "[^0-9+]", with: "", options: [.regularExpression])
	}
	
	public func nsRangePosition(at stringIndex:Int)->Int? {
		let index:String.Index = self.index(startIndex, offsetBy: stringIndex)
		let utf16version: String.UTF16View = utf16
		guard let utf16VersionOfIndex = index.samePosition(in: utf16version) else { return nil }
		return utf16version.distance(from: utf16version.startIndex, to: utf16VersionOfIndex)
		
	}
	
}
