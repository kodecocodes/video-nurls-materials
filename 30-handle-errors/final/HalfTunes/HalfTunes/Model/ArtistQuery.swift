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
import Combine

struct ArtistInfo: Codable {
  let biography: String
  let photo: String
  let totalAlbums: Int
}

final class ArtistQuery: ObservableObject {
 
  enum Error: Swift.Error, CustomStringConvertible {
    case network
    case parsing
    case unknown
    
    var description: String {
      switch self {
      case .network:
        return "A network error occurred."
      case .parsing:
        return "Unable to parse server response."
      case .unknown:
        return "An unknown error occurred"
      }
    }
    
    init(_ error: Swift.Error) {
      switch error {
      case is URLError:
        self = .network
      case is DecodingError:
        self = .parsing
      default:
        self = error as? ArtistQuery.Error ?? .unknown
      }
    }
    
  }
  
  @Published var photo = UIImage(named: "c_urlsession_card_artwork")!
  @Published var bio = "Loading..."
  @Published var errorMessage: String = ""
  @Published var didFail = false
  
  var cancellables: Set<AnyCancellable> = []
  
  init() {
    
    let locationURL = URL(string: "https://api.npoint.io/f09b834bc4aa9aee035c")!
    let artistPublisher = URLSession.shared.dataTaskPublisher(for: locationURL)
      .tryMap { result in
        guard let response = result.response as? HTTPURLResponse else {
          throw ArtistQuery.Error.network
        }
        guard (200..<300).contains(response.statusCode) else {
          throw ArtistQuery.Error.network
        }
        return result.data
      }
      //.retry(2)
      .decode(type: ArtistInfo.self, decoder: JSONDecoder())
      .mapError(ArtistQuery.Error.init)
    
    let photoPublisher = artistPublisher
      .compactMap { URL(string: $0.photo)}
      .flatMap {
        URLSession.shared.dataTaskPublisher(for: $0)
          .compactMap { UIImage(data: $0.data)}
          .mapError(ArtistQuery.Error.init)
      }
    
    Publishers.Zip(artistPublisher, photoPublisher)
      .receive(on: DispatchQueue.main)
      .sink(receiveCompletion: { completion in
        switch completion {
        case .failure(let error):
          self.didFail = true
          self.errorMessage = error.description
        default:
          break
        }
      }, receiveValue: { artist, photo in
        self.bio = artist.biography
        self.photo = photo
      })
      .store(in: &cancellables)
    
  }
}

  

  



  



