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

struct ArtistBio: Codable {
  let text: String
  
  enum CodingKeys: String, CodingKey {
    case text = "biography"
  }
}

struct ArtistImage: Codable {
  let photo: String
}

final class ArtistQuery: ObservableObject {
  
  @Published var photo = UIImage(named: "c_urlsession_card_artwork")!
  @Published var bio = ""
  
  var subscriptions: Set<AnyCancellable> = []
  
  init() {
    let bioURL = URL(string: "https://api.npoint.io/94eb9171de74dd682f6c")!
    let bioPublisher = URLSession.shared.dataTaskPublisher(for: bioURL)
      .map(\.data)
      .decode(type: ArtistBio.self, decoder: JSONDecoder())
    
    
    let photoUrl = URL(string: "https://api.npoint.io/661957f61f715ef25112")!
    let photoPublisher = URLSession.shared.dataTaskPublisher(for: photoUrl)
      .map(\.data)
      .decode(type: ArtistImage.self, decoder: JSONDecoder())
      .compactMap { URL(string: $0.photo) }
      .flatMap {
        URLSession.shared.dataTaskPublisher(for: $0)
          .compactMap { UIImage(data: $0.data) }
          .mapError { $0 as Error }
      }
    
    Publishers.Zip(bioPublisher, photoPublisher)
      .receive(on: DispatchQueue.main)
      .sink(receiveCompletion: { completion in
        print(completion)
      }, receiveValue: { bio, photo in
        self.photo = photo
        self.bio = bio.text
      })
    .store(in: &subscriptions)
    
  }
}
