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
}

struct Token: Codable {
  let location: String
}

final class ArtistQuery: ObservableObject {
  
  @Published var photo = UIImage(named: "c_urlsession_card_artwork")!
  @Published var bio = ""
  
  var cancellables: Set<AnyCancellable> = []
  
  init() {
    let locationUrl = URL(string: "https://api.npoint.io/e0b6213b830ade9ac1f8")!
    let artistInfoPublisher = URLSession.shared.dataTaskPublisher(for: locationUrl)
      .map(\.data)
      .decode(type: Token.self, decoder: JSONDecoder())
      .flatMap { item in
        self.getArtistInfo(forLocation: item.location)
      }
    
    let photoPublisher = artistInfoPublisher
      .compactMap { URL(string: $0.photo )}
      .flatMap { photoUrl in
        URLSession.shared.dataTaskPublisher(for: photoUrl)
          .compactMap { UIImage(data: $0.data) }
          .mapError { $0 as Error }
      }
    
    Publishers.Zip(artistInfoPublisher, photoPublisher)
      .receive(on: DispatchQueue.main)
      .sink(receiveCompletion: { completion in
          print(completion)
        },
        receiveValue: { info, photo in
          self.photo = photo
          self.bio = info.biography
        }
      ).store(in: &cancellables)
    
  }
  
  func getArtistInfo(forLocation location: String) -> AnyPublisher<ArtistInfo, Error> {
    
    let artistUrl = URL(string: "https://api.npoint.io/\(location)")!
    return URLSession.shared.dataTaskPublisher(for: artistUrl)
      .map { $0.data }
      .decode(type: ArtistInfo.self, decoder: JSONDecoder())
      .eraseToAnyPublisher()
  }
  
}
