//
//  PriceResult.swift
//  ProPaint AR
//
//  Created by Davido Hyer on 11/9/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation

struct PriceResult: Codable {
    let product: PriceProduct
    let offers: [Offer]

    enum CodingKeys: String, CodingKey {
        case product, offers
    }
}

// MARK: - Offer
struct Offer: Codable {
    let price: Price
    let condition: Condition
    let delivery: Delivery
    let seller: Seller
    let offerID: String
    let isPrime: Bool
    let position: Int
    let buyboxWinner: Bool
    let offerAsin: String

    enum CodingKeys: String, CodingKey {
        case price, condition, delivery, seller
        case offerID = "offer_id"
        case isPrime = "is_prime"
        case position
        case buyboxWinner = "buybox_winner"
        case offerAsin = "offer_asin"
    }
}

// MARK: - Condition
struct Condition: Codable {
    let isNew: Bool
    let title: String?

    enum CodingKeys: String, CodingKey {
        case isNew = "is_new"
        case title
    }
}

// MARK: - Delivery
struct Delivery: Codable {
    let fulfilledByAmazon: Bool
    let countdown, comments: String
    let price: Price

    enum CodingKeys: String, CodingKey {
        case fulfilledByAmazon = "fulfilled_by_amazon"
        case countdown, comments, price
    }
}

// MARK: - Price
struct Price: Codable {
    let symbol, currency: String
    let value: Double
    let raw: String
    let isFree: Bool?

    enum CodingKeys: String, CodingKey {
        case symbol, currency, value, raw
        case isFree = "is_free"
    }
}

// MARK: - Seller
struct Seller: Codable {
    let name: String
}

// MARK: - Product
struct PriceProduct: Codable {
    let title: String
    let rating, reviewsTotal: Int
    let image: String
    let asin: String
    let link: String

    enum CodingKeys: String, CodingKey {
        case title, rating
        case reviewsTotal = "reviews_total"
        case image, asin, link
    }
}
