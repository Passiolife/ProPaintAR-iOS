//
//  DateFormatter-Extensions.swift
//  Radiant Tap Essentials
//	https://github.com/radianttap/swift-essentials
//
//  Copyright © 2016 Radiant Tap
//  MIT License · http://choosealicense.com/licenses/mit/
//

import Foundation

extension DateFormatter {
	public static let iso8601Formatter: DateFormatter = {
		let df = DateFormatter()
		df.locale = Locale(identifier: "en_US_POSIX")
		df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
		return df
	}()

	public static let iso8601FractionalSecondsFormatter: DateFormatter = {
		let df = DateFormatter()
		df.locale = Locale(identifier: "en_US_POSIX")
		df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
		return df
	}()
}
