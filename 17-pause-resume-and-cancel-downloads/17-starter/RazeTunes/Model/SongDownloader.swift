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

// MARK: Song Downloader
class SongDownloader: ObservableObject {
  // MARK: Artwork Download Error
  enum ArtworkDownloadError: Error {
    case failedToDownloadArtwork
    case invalidResponse
  }

  // MARK: Song Download Error
  enum SongDownloadError: Error {
    case documentDirectoryError
    case failedToStoreSong
    case invalidResponse
  }

  // MARK: Properties
  @Published var downloadLocation: URL?

  private let session: URLSession
  private let sessionConfiguration: URLSessionConfiguration

  // MARK: Initialization
  init() {
    self.sessionConfiguration = URLSessionConfiguration.default
    self.session = URLSession(configuration: sessionConfiguration)
  }

  // MARK: Functions
  func download(songAt songURL: URL, artworkAt artworkURL: URL) async throws -> Data {
    typealias Download = (_ url: URL, _ response: URLResponse)

    async let song: Download = try session.download(from: songURL)
    async let artwork: Download = try session.download(from: artworkURL)

    let (songDownload, artworkDownload) = try await (song, artwork)

    guard let songHTTPResponse = songDownload.response as? HTTPURLResponse,
      let artworkHTTPResponse = artworkDownload.response as? HTTPURLResponse,
      songHTTPResponse.statusCode == 200,
      artworkHTTPResponse.statusCode == 200
    else {
      throw SongDownloadError.invalidResponse
    }

    let fileManager = FileManager.default

    guard let documentsPath = fileManager.urls(
      for: .documentDirectory,
      in: .userDomainMask).first
    else {
      throw SongDownloadError.documentDirectoryError
    }

    let lastPathComponent = songURL.lastPathComponent
    let destinationURL = documentsPath.appendingPathComponent(lastPathComponent)

    do {
      if fileManager.fileExists(atPath: destinationURL.path) {
        try fileManager.removeItem(at: destinationURL)
      }

      try await fileManager.copyItem(at: song.url, to: destinationURL)
    } catch {
      throw SongDownloadError.failedToStoreSong
    }

    await MainActor.run {
      downloadLocation = destinationURL
    }

    do {
      return try Data(contentsOf: artworkDownload.url)
    } catch {
      throw ArtworkDownloadError.failedToDownloadArtwork
    }
  }

  func downloadArtwork(at url: URL) async throws -> Data {
    let (downloadURL, response) = try await session.download(from: url)

    guard let httpResponse = response as? HTTPURLResponse,
      httpResponse.statusCode == 200
    else {
      throw ArtworkDownloadError.invalidResponse
    }

    do {
      return try Data(contentsOf: downloadURL)
    } catch {
      throw ArtworkDownloadError.failedToDownloadArtwork
    }
  }

  func downloadSong(at url: URL) async throws {
    let (downloadURL, response) = try await session.download(from: url)

    guard let httpResponse = response as? HTTPURLResponse,
      httpResponse.statusCode == 200
    else {
      throw SongDownloadError.invalidResponse
    }

    let fileManager = FileManager.default

    guard let documentsPath = fileManager.urls(
      for: .documentDirectory,
      in: .userDomainMask).first
    else {
      throw SongDownloadError.documentDirectoryError
    }

    let lastPathComponent = url.lastPathComponent
    let destinationURL = documentsPath.appendingPathComponent(lastPathComponent)

    do {
      if fileManager.fileExists(atPath: destinationURL.path) {
        try fileManager.removeItem(at: destinationURL)
      }

      try fileManager.copyItem(at: downloadURL, to: destinationURL)
    } catch {
      throw SongDownloadError.failedToStoreSong
    }

    await MainActor.run {
      downloadLocation = destinationURL
    }
  }

  func downloadSongBytes(at url: URL, progress: Binding<Float>) async throws {
    let (asyncBytes, response) = try await session.bytes(from: url)

    let contentLength = Float(response.expectedContentLength)
    var data = Data(capacity: Int(contentLength))

    for try await byte in asyncBytes {
      data.append(byte)

      let currentProgress = Float(data.count) / contentLength

      if Int(progress.wrappedValue * 100) != Int(currentProgress * 100) {
        progress.wrappedValue = currentProgress
      }
    }

    let fileManager = FileManager.default

    guard let documentsPath = fileManager.urls(
      for: .documentDirectory,
      in: .userDomainMask).first
    else {
      throw SongDownloadError.documentDirectoryError
    }

    let lastPathComponent = url.lastPathComponent
    let destinationURL = documentsPath.appendingPathComponent(lastPathComponent)

    do {
      if fileManager.fileExists(atPath: destinationURL.path) {
        try fileManager.removeItem(at: destinationURL)
      }

      try data.write(to: destinationURL)
    } catch {
      throw SongDownloadError.failedToStoreSong
    }

    await MainActor.run {
      downloadLocation = destinationURL
    }
  }
}
