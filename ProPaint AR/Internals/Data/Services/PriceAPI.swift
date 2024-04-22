//
//  PriceAPI.swift
//  ProPaint AR
//
//  Created by Davido Hyer on 11/9/22.
//  Copyright © 2022 Passio Inc. All rights reserved.
//

import Foundation

protocol PriceAPI {
    func getPrice(
        asinNumber: String,
        callback: @escaping ((Double?) -> Void)
    )
}

class PriceAPIImpl: PriceAPI {
    func getPrice(asinNumber: String, callback: @escaping ((Double?) -> Void)) {
        let sessionConfig = URLSessionConfiguration.default
        
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        
        guard var URL = URL(string: "https://api.asindataapi.com/request")
        else { return }
        
        let URLParams = [
            "api_key": "EEE717F2E7964A6299F705E427DE5F2F",
            "type": "offers",
            "amazon_domain": "amazon.com",
            "asin": asinNumber,
            "offers_prime": "true",
            "offers_condition_new": "true"
        ]
        URL = URL.appendingQueryParameters(URLParams)
        var request = URLRequest(url: URL)
        request.httpMethod = "GET"
        
        let task = session.dataTask(
            with: request,
            completionHandler: { (data: Data?, _, error: Error?) -> Void in
                let decoder = JSONDecoder()
                if (error == nil),
                   let data = data {
                    do {
                        let obj = try decoder.decode(PriceResult.self,
                                                     from: data)
                        if let price = obj.offers.first(
                            where: { $0.price.value > 0 }
                        ) {
                            callback(price.price.value)
                        }
                    } catch {
                        print("Error: \(error.localizedDescription)")
                        callback(nil)
                    }
                } else {
                    if let error = error {
                        print("URL Session Task Failed: %@", error.localizedDescription)
                    }
                    callback(nil)
                }
            }
        )
        task.resume()
        session.finishTasksAndInvalidate()
    }
}
