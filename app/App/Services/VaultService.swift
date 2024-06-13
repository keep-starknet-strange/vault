//
//  VaultService.swift
//  Vault
//
//  Created by Charles Lanier on 21/04/2024.
//

import Foundation

enum Endpoint {
    case getOTP(String, String)
    case verifyOTP(String, String, String, String)
    case executeFromOutside(String, [String], [String])
}

class VaultService {

    private func query(endpoint: Endpoint, completion: @escaping @Sendable (Result<[String: Any], Error>) -> Void) {
        var url = Constants.vaultBaseURL
        var body: [String: Any] = [:]

        switch endpoint {
        case let .getOTP(phoneNumber, nickname):
            url.append(path: "/get_otp")

            body["phone_number"] = phoneNumber
            body["nickname"] = nickname
            break

        case let .verifyOTP(phoneNumber, otp, publicKeyX, publicKeyY):
            url.append(path: "/verify_otp")

            body["phone_number"] = phoneNumber
            body["sent_otp"] = otp
            body["public_key_x"] = publicKeyX
            body["public_key_y"] = publicKeyY

        case let .executeFromOutside(address, calldata, signature):
            url.append(path: "/execute_from_outside")

            body["address"] = address
            body["calldata"] = calldata + [signature.count] + signature
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
            guard 
                let data = data,
                let httpResponse = response as? HTTPURLResponse,
                error == nil
            else {
                DispatchQueue.main.async {
                    completion(.failure(error ?? "Unknown error"))
                }
                return
            }

            #if DEBUG
            print(data.base64EncodedString())
            #endif

            do {
                // make sure this JSON is in the format we expect
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    DispatchQueue.main.async {
                        if httpResponse.isSuccessful {
                            completion(.success(json))
                        } else {
                            completion(.failure(json["message"] as? String ?? "Unkown error"))
                        }
                    }
                }
            } catch let error as NSError {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }

    func getOTP(phoneNumber: String, completion: @escaping (Result<Void, Error>) -> Void) {
        self.query(endpoint: .getOTP(phoneNumber, "chqrles")) { result in
            switch result {
            case .success(let json):
                guard let _ = json["ok"] as? Bool else {
                    completion(.failure("Unkown Error"))
                    return
                }

                completion(.success(Void()))

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func verifyOTP(
        phoneNumber: String,
        otp: String,
        publicKeyX: String,
        publicKeyY: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        self.query(endpoint: .verifyOTP(phoneNumber, otp, publicKeyX, publicKeyY)) { result in
            switch result {
            case .success(let json):
                guard let address = json["contract_address"] as? String else {
                    completion(.failure("Unkown Error"))
                    return
                }

                completion(.success(address))

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func executeFromOutside(
        address: String,
        calldata: [String],
        signature: [String],
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        self.query(endpoint: .executeFromOutside(address, calldata, signature)) { result in
            switch result {
            case .success(let json):
                guard let txHash = json["transaction_hash"] as? String else {
                    completion(.failure("Unkown Error"))
                    return
                }

                completion(.success(txHash))

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
