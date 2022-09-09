/// Copyright (c) 2022 Razeware LLC
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

import SwiftUI
import Foundation

func fetchDomains() async throws -> [Domain] {
  let url = URL(string: "https://api.raywenderlich.com/api/domains")!
  let (data, _) = try await URLSession.shared.data(from: url)

  return try JSONDecoder().decode(Domains.self, from: data).data
}

// Asynchronous sequences.
func findTitle(url: URL) async throws -> String? {
  for try await line in url.lines {
    if line.contains("<title>") {
      return line.trimmingCharacters(in: .whitespaces)
    }
  }

  return nil
}

//Task {
//    if let title = try await findTitle(url: URL(string: "https://www.raywenderlich.com")!) {
//        print(title)
//    }
//}

// Asynchronous properties.
extension Domains {
  static var domains: [Domain] {
    get async throws {
      try await fetchDomains()
    }
  }
}

//Task {
//    dump(try await Domains.domains)
//}

// Asynchronous subscripts.
extension Domains {
  enum Error: Swift.Error { case outOfRange }

  static subscript(_ index: Int) -> String {
    get async throws {
      let domains = try await Self.domains
      guard domains.indices.contains(index) else {
        throw Error.outOfRange
      }
      return domains[index].attributes.name
    }
  }
}

//Task {
//    dump(try await Domains[4])
//}

// Actors.
let favoritesPlaylist = Playlist(title: "Favorite songs",
                                 author: "Felipe",
                                 songs: ["In And Out Of Love"])
let partyPlaylist = Playlist(title: "Party songs",
                             author: "Ray",
                             songs: ["Hello"])
//Task {
//    await favoritesPlaylist.move(song: "Hello", from: partyPlaylist)
//    await favoritesPlaylist.move(song: "In And Out Of Love", to: partyPlaylist)
//    await print(favoritesPlaylist.songs)
//    await print(partyPlaylist.songs)
//}
//
//print(favoritesPlaylist)

// Main Actor.
let url = URL(string: "https://api.raywenderlich.com/api/domains")!
let session = URLSession.shared.dataTask(with: url) { data, _, _ in
  guard let data = data,
        let domain = try? JSONDecoder().decode(Domains.self, from: data).data.first
  else {
    print("Request failed")

    return
  }

  //    Task {
  //        await MainActor.run {
  //            print(domain)
  //            print(Thread.isMainThread)
  //        }
  //    }
}

session.resume()

// Main Actor annotation.
extension Domains {
  @MainActor func domainNames() -> [String] {
    print("Getting domain names in main thread? \(Thread.isMainThread)")

    return data.map { $0.attributes.name }
  }
}

let session2 = URLSession.shared.dataTask(with: url) { data, _, _ in
  guard let data = data,
        let domains = try? JSONDecoder().decode(Domains.self, from: data)
  else {
    print("Request failed")

    return
  }

  Task {
    await print(domains.domainNames())
  }
}

session2.resume()
