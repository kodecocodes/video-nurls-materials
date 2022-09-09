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

// MARK: Media View
public struct MediaView: View {
  // MARK: Media Error
  public enum MediaError: Error {
    case requestFailed
    case responseDecodingFailed
    case urlCreationFailed
  }
  
  // MARK: Properties
  @State private var musicItems: [MusicItem] = []
  
  // MARK: Body
  public var body: some View {
    VStack {
      Button {
        Task {
          do {
            try await fetchMusic()
          } catch {
            print(error)
          }
        }
      } label: {
        Text("Fetch Music")
      }
      .padding(.top, 16.0)
      
      List(musicItems) { item in
        VStack(alignment: .leading) {
          Text(item.trackName)
            .font(.system(.body))
          Text(item.artistName)
            .font(.system(.caption))
        }
      }
      
      Spacer()
    }
    .frame(width: 320.0, height: 400.0, alignment: .center)
  }
  
  // MARK: - Initialization
  public init() {
    
  }
  
  // MARK: Functions
  func fetchMusic() async throws {
    guard let url =  URL(string:"https://itunes.apple.com/search?media=music&entity=song&term=starlight") else {
      throw MediaError.urlCreationFailed
    }
    
    let configuration = URLSessionConfiguration.default
    let session = URLSession(configuration: configuration)
    
    Task {
      let (data, response) = try await session.data(from: url)
      
      guard let httpResponse = response as? HTTPURLResponse,
            (200..<300).contains(httpResponse.statusCode)
      else {
        throw MediaError.requestFailed
      }
      
      guard let mediaResponse = try? JSONDecoder().decode(MediaResponse.self, from: data) else {
        throw MediaError.responseDecodingFailed
      }
      
      await MainActor.run {
        musicItems = mediaResponse.results
      }
    }
  }
}


