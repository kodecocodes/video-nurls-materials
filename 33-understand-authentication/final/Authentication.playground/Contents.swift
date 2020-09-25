/// Copyright (c) 2020 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit

import Foundation
import PlaygroundSupport
PlaygroundPage.current.needsIndefiniteExecution = true
//: ## Authentication: How to login to get an authentication token
let config = URLSessionConfiguration.default
config.waitsForConnectivity = true
let session = URLSession(configuration: config)

//: Endpoints for web app:
let baseURL = URL(string: "https://tilftw.herokuapp.com/")
let newUserEndpoint = URL(string: "users", relativeTo: baseURL)
let loginEndpoint = URL(string: "login", relativeTo: baseURL)
let newEndpoint = URL(string: "new", relativeTo: baseURL)

//: `Codable` structs for User, Acronym, Auth:
struct User: Codable {
  let name: String
  let email: String
  let password: String
}

struct Acronym: Codable {
  let short: String
  let long: String
}

struct Auth: Codable {
  let token: String
}

let encoder = JSONEncoder()
let decoder = JSONDecoder()

//: Prep a new user
let user = User(name: "jo", email: "jo@razeware.com", password: "password")

let loginString = "\(user.email):\(user.password)"
guard let loginData = loginString.data(using: .utf8) else {
  fatalError()
}
let encodedString = loginData.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))

guard let endpointUrl = loginEndpoint else {
  fatalError()
}
var loginRequest = URLRequest(url: endpointUrl)
loginRequest.httpMethod = "POST"

loginRequest.allHTTPHeaderFields = [
  "accept": "application/json",
  "content-type": "application/json",
  "authorization": "Basic \(encodedString)"
]

var auth = Auth(token: "")
session.dataTask(with: loginRequest) { data, response, error in
  guard let response = response, let data = data else {
    fatalError()
  }
  print(response)
  
  do {
    auth = try decoder.decode(Auth.self, from: data)
    auth.token
  } catch {
    print(error)
  }
  
  guard let newAcronymUrl = newEndpoint else {
    fatalError()
  }
  var tokenAuthRequest = URLRequest(url: newAcronymUrl)
  tokenAuthRequest.httpMethod = "POST"
  tokenAuthRequest.allHTTPHeaderFields = [
    "accept": "application/json",
    "content-type": "application/json",
    "authorization": "Bearer \(auth.token)"
  ]
  
  let acronym = Acronym(short: "MATH", long: "Mental Assault To Humans")
  do {
    tokenAuthRequest.httpBody = try encoder.encode(acronym)
  } catch {
    print(error)
  }
  
  session.dataTask(with: tokenAuthRequest) { _, response, _ in
    guard let response = response else {
      fatalError()
    }
    print(response)
  }.resume()
}.resume()





