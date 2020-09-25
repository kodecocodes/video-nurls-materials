import Vapor

func routes(_ app: Application) throws {
  app.webSocket("chat") { request, ws in
    
    ws.send("Connected")
    ws.onText { ws, text in
      ws.send("Text received: \(text)")
      print("received from client: \(text)")
    }
    ws.onClose.whenComplete { result in
      switch result {
      case .success():
        print("Closed")
      case .failure(let error):
        print("Error: \(error)")
      }
    }
    
  }
}
