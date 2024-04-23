//
//  VaultService.swift
//  Vault
//
//  Created by Charles Lanier on 21/04/2024.
//

import Foundation

enum Endpoint {
    case getOTP(String)
    case verifyOTP(String, String, String)
}

class VaultService {

    private func query(endpoint: Endpoint, completion: @escaping @Sendable ([String: Any]?) -> Void) {
        var url = Constants.vaultBaseURL
        var body: [String: String] = [:]

        switch endpoint {
        case let .getOTP(phoneNumber):
            url.append(path: "/get_otp")

            body["phone_number"] = phoneNumber
            break

        case let .verifyOTP(phoneNumber, otp, publicKey):
            url.append(path: "/verify_otp")

            body["phone_number"] = phoneNumber
            body["otp"] = otp
            body["public_key"] = publicKey
        }

        // Convert the dictionary into JSON data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body, options: []) else {
            print("Error: Unable to encode JSON")
            return
        }

        // Create a URLRequest object and configure it for a POST method
        var request = URLRequest(url: url)

        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // fetch request
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                // TODO: Handle errors
                print(error ?? "Unknown error")
                completion(nil)
                return
            }

            #if DEBUG
            print(data.base64EncodedString())
            #endif

            do {
                // make sure this JSON is in the format we expect
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    DispatchQueue.main.async {
                        completion(json)
                    }
                }
            } catch let error as NSError {
                // TODO: Handle errors
                print("Failed to load: \(error.localizedDescription)")
                completion(nil)
            }
        }.resume()
    }

    func getOTP(phoneNumber: String, completion: @escaping (Bool) -> Void) {
        self.query(endpoint: .getOTP(phoneNumber)) { json in
            if let ok = json?["ok"] as? Bool {
                completion(ok)
            } else {
                completion(false)
            }
        }
    }

    func verifyOTP(phoneNumber: String, otp: String, publicKey: String, completion: @escaping (String?) -> Void) {
        self.query(endpoint: .verifyOTP(phoneNumber, otp, publicKey)) { json in
            if let address = json?["address"] as? String {
                completion(address)
            } else {
                completion(nil)
            }
        }
    }
}
