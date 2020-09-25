import UIKit

let configuration = URLSessionConfiguration.default
let session = URLSession(configuration: configuration)

guard let url = URL(string: "https://itunes.apple.com/search?media=music&entity=song&term=cohen") else {
  fatalError()
}

let task = session.dataTask(with: url) { data, response, error in
  guard let httpResponse = response as? HTTPURLResponse,
        (200..<300).contains(httpResponse.statusCode) else {
    return
  }
  guard let data = data else {
    return
  }
  if let result = String(data: data, encoding: .utf8) {
    print(result)
  }
}
task.resume()
