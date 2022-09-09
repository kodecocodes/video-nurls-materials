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

// MARK: Song Detail View
struct SongDetailView: View {
  // MARK: Properties
  @Binding var musicItem: MusicItem

  @ObservedObject private var downloader = SongDownloader()
  @ObservedObject private var mutableDownloader = MutableSongDownloader()

  // swiftlint:disable:next force_unwrapping
  @MainActor @State private var artworkImage = UIImage(named: "URLSessionArtwork")!
  @MainActor @State private var downloadProgress: Float = 0.0
  @MainActor @State private var isDownloading = false
  @MainActor @State private var playMusic = false
  @MainActor @State private var showDownloadFailedAlert = false

  // MARK: Body
  var body: some View {
    // swiftlint:disable:next trailing_closure
    VStack {
      GeometryReader { reader in
        VStack {
          Image(uiImage: artworkImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: reader.size.width, height: reader.size.height * 0.2)
            .shadow(radius: 10)

          Text(musicItem.trackName)

          Text(musicItem.artistName)

          Text(musicItem.collectionName)

          Spacer()

          VStack(spacing: 16) {
            Button<Text>(action: mutableDownloadTapped) {
              switch mutableDownloader.state {
              case .downloading:
                return Text("Pause")

              case .failed:
                return Text("Retry")

              case .finished:
                return Text("Listen")

              case .paused:
                return Text("Resume")

              case .waiting:
                return Text("Download")
              }
            }

            if mutableDownloader.state == .paused || mutableDownloader.state == .downloading {
              ProgressView(value: mutableDownloader.downloadProgress)
            }
          }

          Spacer()
        }
      }
    }
    .padding()
    .onAppear(perform: {
      Task {
        await downloadArtwork()
      }
    })
    .sheet(isPresented: $playMusic) {
      // swiftlint:disable:next force_unwrapping
      AudioPlayer(songUrl: mutableDownloader.downloadLocation!)
    }
  }

  // MARK: Functions
  private func downloadArtwork() async {
    guard let artworkURL = URL(string: musicItem.artwork) else {
      return
    }

    do {
      let data = try await downloader.downloadArtwork(at: artworkURL)

      guard let image = UIImage(data: data) else {
        return
      }

      artworkImage = image
    } catch {
      print(error)
    }
  }

  private func downloadSongTapped() async {
    if downloader.downloadLocation == nil {
      guard let artworkURL = URL(string: musicItem.artwork),
        let previewURL = musicItem.previewURL
      else {
        return
      }

      isDownloading = true

      defer {
        isDownloading = false
      }

      do {
        let data = try await downloader.download(songAt: previewURL, artworkAt: artworkURL)

        guard let image = UIImage(data: data) else {
          return
        }

        artworkImage = image
      } catch {
        print(error)

        showDownloadFailedAlert = true
      }
    } else {
      playMusic = true
    }
  }

  private func downloadTapped() async {
    if downloader.downloadLocation == nil {
      isDownloading = true

      defer {
        isDownloading = false
      }

      guard let previewURL = musicItem.previewURL else {
        return
      }

      do {
        // try await downloader.downloadSong(at: previewURL)
        try await downloader.downloadSongBytes(at: previewURL, progress: $downloadProgress)
      } catch {
        print(error)

        showDownloadFailedAlert = true
      }
    } else {
      playMusic = true
    }
  }

  private func mutableDownloadTapped() {
    switch mutableDownloader.state {
    case .downloading:
      mutableDownloader.pause()

    case .failed, .waiting:
      guard let previewURL = musicItem.previewURL else {
        return
      }

      mutableDownloader.downloadSong(at: previewURL)

    case .finished:
      playMusic = true

    case .paused:
      mutableDownloader.resume()
    }
  }
}

// MARK: - Preview Provider
struct SongDetailView_Previews: PreviewProvider {
  // MARK: Preview Wrapper
  struct PreviewWrapper: View {
    // MARK: Properties
    @State private var musicItem = MusicItem.demo()

    // MARK: Body
    var body: some View {
      SongDetailView(musicItem: $musicItem)
    }
  }

  // MARK: Previews
  static var previews: some View {
    PreviewWrapper()
  }
}
