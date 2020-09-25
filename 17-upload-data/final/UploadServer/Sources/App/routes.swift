import Vapor

struct VideoCourse: Content {
  let name: String
  let language: String
  let version: Double
}

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "It works" example
    router.get { req in
        return "It works!"
    }
    
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }
  
  router.post("upload") { req -> Future<HTTPStatus> in
    return try! req.content.decode(VideoCourse.self).map(to: HTTPStatus.self) { course in
      print(course.name)
      print(course.language)
      print(course.version)
      return .ok
    }
  }
  

    // Example of configuring a controller
    let todoController = TodoController()
    router.get("todos", use: todoController.index)
    router.post("todos", use: todoController.create)
    router.delete("todos", Todo.parameter, use: todoController.delete)
}
