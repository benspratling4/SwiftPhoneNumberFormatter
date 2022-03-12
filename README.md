# SwiftPhoneNumberFormatter
Phone number formatting in pure swift


## Representing phone numbers
Phone numbers are represented as PhoneNumber struct instances.  Country codes and digits of the number are kept separate.


## Codable
PhoneNumber serializes to a E.164 format String for encoding.  


## PhoneNumber.Formatter

Use instances of PhoneNumber.Formatter to parse or format strings.

Initialize the PhoneNumber.Formatter  with the list of allowed country codes (`enum PhoneNumber.CountryCode`).  If you can assume the country code from outside data, provide a `assumedCountry`, if you don't, it will use the first one in `allowedCountries`.  `allowedOptions` let's you identify and reject phone numbers which match templates of kinds of numbers you don't want to allow.  See `PhoneNumber.Template.Options` for the options.

PhoneNumber.Formatter will get the list of templates matching the countries you specify from its default list of all templates,  `PhoneNumber.Formatter.allTemplatesByCountry`, but you can override that list by setting the instance's `.templates` with specific templates you want.


### Parsing phone number strings

Use `func enteredPhoneNumber(_ input:String)->PhoneNumber?` to get a phone number from a user-entered string.  It has 3 phases:

1) Check for E.164 format.  If the string begins with `+`, then the formatter will only accept the string if it matches a E.164 format.
2) Check for a leading country code.  Even if your app disallows typing country codes directly, some users store phone numbers in their contacts app with a country code. So if we detect a leading valid country code, the formatter will include it.
3) If there is no leading country code, the formatter will find the template which matches best, and if it matches multiple countries, it will assume the `assumedCountry`, otherwise, it'll pick a template which is non-partial.

There is a variant, `func enteredPhoneNumber(_ input:String, originalIndex:Int?)->(PhoneNumber, Int)?`, which tracks a cursor insertion point.  On input, the `originalIndex` is a `distance` from usable in Swift's String.Index functions.  On output, the Int is the number of digits before the insertion point.


### Formatting Phone number strings

To get a human-readable string from the number, call
`func formattedNumber(_ entry:PhoneNumber, includeCountryCode:Bool = false)->String?`.

The country code of the PhoneNumber must be in the formatter's array of allowed countries (and in its templates).

Similarly, there is a variant of this function which tracks the insertion cursor.
`func formattedNumber(_ entry:PhoneNumber, index:Int?, includeCountryCode:Bool = false)->(String, Int)?` takes the input of the number of digits before the cursor, and outputs an integer suitable for use in Swift String.Index functions. 


## Templates

SwiftPhoneNumberFormatter comes with a few sample phone number formats.

`PhoneNumber.Template` is contains both an array of template components, and also a OptionSet.

### Template components

There are 3 kinds of things allowed in templates:, digits, digit literals and literals.

#### Digits

Include the character `#` to represent a user-entered digit.

#### Digit Literals

Include an actual digit, such as `5` or `6` or `1`.  The template will not be considered matched if the input does not include the specific digit in the specific location. This is especially useful in creating categories of numbers which are allowed or disallowed.  For instance, in the US, phone numbers starting with `555` are not assigned to actual devices, but may be stated in entertainment.  By including a specific template with these literals and setting the options to `.entertainment`, and disallowing entertainment options from the formatter, your app won't get PhoneNumber instances matching this template. 

#### Literals

Characters other than digits or `#` will be interpretted as "literals".  Users are not required to enter these characters, but they are included in formatted output.  For instance, in the US phone number `(666) 555-1234`, the `(`, `)`, ` `, and `-` characters are "literals".  The format string for a generic number would be `(###) ###-####`, where the user would enter up to 10 digits and the formatter would insert the additiona literals as needed.

When being interpreted, user input has all characters except for digits and `+` stripped out.  When being formatted, the literals are inserted.  However, if the input is partial, then no literals will be inserted after the last user-entered digit.  Similarly cursor output indexes will always be immdiately after digits, not immediately after a literal, allowing the delete key to always alter the output by affecting an input digit.
   

### Options

`PhoneNumber.Template.Options` is an `OptionSet` which represents categories of phone numbers.  By using digit literals, a template may associate specific subsets of phone numbers as being assigned only for use in the specific categories.  Some countries assign all mobile numbers in particular ranges.  Others assign specific ranges as disallowed, such as the area code `666` in the US.  Most assign emergency numbers.
While `PhoneNumber.Template.Options.allCases` includes all the options, the `PhoneNumber.Template.Options.default` includes numbers users would be allowed to have devices assigned, excluding .emergency, .forbidden and .entertainment options.


## Sample of using this in a UITextField delegate `(_:,shouldChangeCharactersIn:,...)`

 PhoneNumber.Formatter is designed to provide a great UX for validating phone numbers
 
```swift
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		guard let finalString = textField.changingCharacters(in: range, replacementString: string) else {
			return false
		}
		let mediumNSRange:NSRange = textField.selectedRangeAfterChangingCharacters(in: range, replacementString: string)
		let initialCursorIndex:Int?
		if let rangeBound = Range(mediumNSRange, in:finalString)?.upperBound {
			initialCursorIndex = finalString.distance(from: finalString.startIndex, to: rangeBound)
		}
		else {
			initialCursorIndex = nil
		}
		guard let (newValue, newIndex) = phoneFormatter.enteredPhoneNumber(finalString, originalIndex: initialCursorIndex) else {
			if finalString.digits.isEmpty {
				textField.text = ""
			}
			return false
		}
		
		guard let (newFormattedString, newFormattedCursor) = phoneFormatter.formattedNumber(newValue, index: newIndex) else {
			return false
		}
		textField.text = newFormattedString
		if let newSelectionNSRangePosition = newFormattedString.nsRangePosition(at: newFormattedCursor) {
			textField.selectedNSRange = NSRange(location: newSelectionNSRangePosition, length: 0)
		}
		return false
	}
```
