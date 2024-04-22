//
//  NumberFormatter+Extensions.swift
//  ProPaint AR
//
//  Created by Davido Hyer on 11/14/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation

extension NumberFormatter {
    ///    Formatter which creates Decimal numbers format with exactly two decimal places,
    ///    uses Locale.current
    public private(set) static var moneyFormatter: NumberFormatter = moneyFormatterBuilder

    private static var moneyFormatterBuilder: NumberFormatter {
        let nf = NumberFormatter()
        nf.locale = Locale.current
        nf.generatesDecimalNumbers = true
        nf.maximumFractionDigits = 2
        nf.minimumFractionDigits = 2
        nf.numberStyle = .decimal
        return nf
    }

    ///    Formatter which creates Decimal numbers format with exactly two decimal places,
    ///    uses Locale.current + includes the currency symbol / code
    public private(set) static var currencyFormatter: NumberFormatter = currencyFormatterBuilder

    private static var currencyFormatterBuilder: NumberFormatter = {
        let nf = NumberFormatter()
        nf.locale = Locale.current
        nf.generatesDecimalNumbers = true
        nf.maximumFractionDigits = 2
        nf.numberStyle = .currency
        return nf
    }()

    ///    Locale aware formatter to output 1st, 2nd etc
    public private(set) static var ordinalFormatter: NumberFormatter = ordinalFormatterBuilder

    private static var ordinalFormatterBuilder: NumberFormatter = {
        let nf = NumberFormatter()
        nf.locale = Locale.current
        nf.numberStyle = .ordinal
        return nf
    }()

    ///    Call this function after your in-app Locale changes
    ///    see https://github.com/radianttap/LanguageSwitcher/
    public static func resetupEssentialFormatters() {
        moneyFormatter = moneyFormatterBuilder
        currencyFormatter = currencyFormatterBuilder
        ordinalFormatter = ordinalFormatterBuilder
    }
}
