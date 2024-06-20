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
}

enum Method {
    case get
    case post
}

public typealias ResultCallback<Value> = (Result<Value, Error>) -> Void

class VaultService {

    static let shared = VaultService()

    var healthCheck: Bool {
        return baseEndpointUrl != nil
    }

    private let baseEndpointUrl = AppConfiguration.API.baseURL
    private let session = URLSession(configuration: .default)

    /// Sends a request to Vault servers, calling the completion method when finished
    public func send<T: APIRequest>(_ request: T, completion: @escaping ResultCallback<T.Response>) {
        let urlRequest = self.endpoint(for: request)

        let task = session.dataTask(with: urlRequest) { data, response, error in
            if
                let data = data,
                let httpResponse = response as? HTTPURLResponse
            {

#if DEBUG
                print(data.base64EncodedString())
#endif

                if httpResponse.isSuccessful {
                    // request is successful

                    do {
                        // Decode the top level response as data
                        let vaultResponse = try JSONDecoder().decode(T.Response.self, from: data)

                        completion(.success(vaultResponse))
                    } catch {
                        completion(.failure(VaultError.decoding))
                    }
                } else {
                    // request failed

                    do {
                        // Decode the top level response as error
                        let vaultResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)

                        if let message = vaultResponse.message {
                            completion(.failure(VaultError.server(message: message)))
                        } else {
                            completion(.failure(VaultError.unknown))
                        }
                    } catch {
                        completion(.failure(VaultError.decoding))
                    }
                }
            } else if let error = error {
                completion(.failure(error))
            }
        }
        task.resume()
    }

    /// Encodes a URL based on the given request
    /// Everything needed for a public request to Vault servers is encoded directly in this URL
    private func endpoint<T: APIRequest>(for request: T) -> URLRequest {
        guard let baseUrl = URL(string: request.resourceName, relativeTo: baseEndpointUrl) else {
            fatalError("Bad resourceName: \(request.resourceName)")
        }

        var components = URLComponents(url: baseUrl, resolvingAgainstBaseURL: true)!

        // Add query parameters
        if (request.httpMethod == .GET) {
            // Custom query items needed for this specific request
            let customQueryItems: [URLQueryItem]

            do {
                customQueryItems = try URLQueryItemEncoder.encode(request)
            } catch {
                fatalError("Wrong parameters: \(error)")
            }

            components.queryItems = customQueryItems
        }

        // Construct the final URL with all the previous data
        var urlRequest = URLRequest(url: components.url!)

        // add Headers and body params
        if (request.httpMethod == .POST) {
            for (headerField, value) in request.headers {
                urlRequest.addValue(value, forHTTPHeaderField: headerField)
            }

            // Custom body params needed for this specific request
            let customBodyParams: Data

            do {
                customBodyParams = try BodyParamsEncoder.encode(request)
            } catch {
                fatalError("Wrong parameters: \(error)")
            }

            urlRequest.httpBody = customBodyParams
        }

        urlRequest.httpMethod = request.httpMethod.rawValue

        return urlRequest
    }
}
