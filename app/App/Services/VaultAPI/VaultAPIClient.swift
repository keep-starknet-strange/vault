//
//  VaultAPIClient.swift
//  Vault
//
//  Created by Charles Lanier on 14/06/2024.
//

import Foundation

enum Endpoint {
    case getOTP(String, String)
    case verifyOTP(String, String, String, String)
    case executeFromOutside(String, [String], [String])
    case getBalance(String)
}

enum Method {
    case get
    case post
}

public typealias ResultCallback<Value> = (Result<Value, Error>) -> Void

class VaultService {
    private let baseEndpointUrl = Constants.vaultBaseURL
    private let session = URLSession(configuration: .default)

    private func query(endpoint: Endpoint, completion: @escaping @Sendable (Result<[String: Any], Error>) -> Void) {
        var url = Constants.vaultBaseURL
        var body: [String: Any] = [:]
        var method: Method?

        switch endpoint {
        case let .getOTP(phoneNumber, nickname):
            url.append(path: "/get_otp")

            body["phone_number"] = phoneNumber
            body["nickname"] = nickname

            method = .post

        case let .verifyOTP(phoneNumber, otp, publicKeyX, publicKeyY):
            url.append(path: "/verify_otp")

            body["phone_number"] = phoneNumber
            body["sent_otp"] = otp
            body["public_key_x"] = publicKeyX
            body["public_key_y"] = publicKeyY

            method = .post

        case let .executeFromOutside(address, calldata, signature):
            url.append(path: "/execute_from_outside")

            body["address"] = address
            body["calldata"] = calldata + [signature.count] + signature

            method = .post

        case let .getBalance(address):
            url.append(path: "/get_balance")
            url.append(queryItems: [URLQueryItem(name: "address", value: address)])

            method = .get
        }

        // Convert the dictionary into JSON data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body, options: []) else {
            print("Error: Unable to encode JSON")
            return
        }

        // Create a URLRequest object and configure it for a POST method
        var request = URLRequest(url: url)

        switch method {
        case .get:
            request.httpMethod = "GET"

        case .post:
            request.httpMethod = "POST"
            request.httpBody = jsonData
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        case nil:
            fatalError("Unknown error.")
        }

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










    /// Sends a request to Vault servers, calling the completion method when finished
    public func send<T: APIRequest>(_ request: T, completion: @escaping ResultCallback<DataContainer<T.Response>>) {
        let endpoint = self.endpoint(for: request)

        let task = session.dataTask(with: URLRequest(url: endpoint)) { data, response, error in
            if let data = data {
                do {
                    // Decode the top level response, and look up the decoded response to see
                    // if it's a success or a failure
                    let vaultResponse = try JSONDecoder().decode(VaultResponse<T.Response>.self, from: data)

                    if let dataContainer = vaultResponse.data {
                        completion(.success(dataContainer))
                    } else if let message = vaultResponse.message {
                        completion(.failure(VaultError.server(message: message)))
                    } else {
                        completion(.failure(VaultError.decoding))
                    }
                } catch {
                    completion(.failure(error))
                }
            } else if let error = error {
                completion(.failure(error))
            }
        }
        task.resume()
    }

    /// Encodes a URL based on the given request
    /// Everything needed for a public request to Vault servers is encoded directly in this URL
    private func endpoint<T: APIRequest>(for request: T) -> URL {
        guard let baseUrl = URL(string: request.resourceName, relativeTo: baseEndpointUrl) else {
            fatalError("Bad resourceName: \(request.resourceName)")
        }

        var components = URLComponents(url: baseUrl, resolvingAgainstBaseURL: true)!

        // Custom query items needed for this specific request
        let customQueryItems: [URLQueryItem]

        do {
            customQueryItems = try URLQueryItemEncoder.encode(request)
        } catch {
            fatalError("Wrong parameters: \(error)")
        }

        components.queryItems = customQueryItems

        // Construct the final URL with all the previous data
        return components.url!
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

    func getBalance(of address: String, completion: @escaping (Result<String, Error>) -> Void) {
        self.query(endpoint: .getBalance(address)) { result in
            switch result {
            case .success(let json):
                guard let balance = json["balance"] as? String else {
                    completion(.failure("Unkown Error"))
                    return
                }

                completion(.success(balance))

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

