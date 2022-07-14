//
//  File.swift
//  
//
//  Created by Ben Spratling on 7/14/22.
//

import Foundation


extension PhoneNumber.Formatter {
	
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
			"(N##) N##-####",
		], nil),
		//TODO: add more information about other country's phone number formats
	]
}
