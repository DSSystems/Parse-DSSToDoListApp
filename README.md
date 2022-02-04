# Simple To Do List App

This project is an example to show how to use the [Parse](https://www.back4app.com/docs/ios/parse-swift-sdk/install-sdk) framework (A serverless backend by [back4app](https://www.back4app.com/)) to implement a simple To Do List App with basic user capabilities in the cloud.

# Setting up the project

As usual, the first step is to open terminal and go to the directory where we want to download the project. We then clone the repository with the command
~~~sh
git clone https://github.com/DSSystems/Parse-DSSToDoListApp.git
~~~

Once the repository download is complete, before opening the `DSSToDoListApp.xcworkspace` file on [XCode](https://developer.apple.com/xcode/) and run the app, it is necessary to update the Pods. In order to do this, from terminal we simply run the command
~~~sh
pod update
~~~
Now we proceed to open `DSSToDoListApp.xcworkspace` on Xcode.
The following step is to set up your Parse app and link it to your iOS App. A detailed procedure to create a Parse app can be found in [here](https://www.back4app.com/docs/get-started/new-parse-app).

To link your new Parse app to `DSSToDoListApp`, follow the following steps
- Go to your  [dashboard](https://dashboard.back4app.com/apps) and select your new Parse App.
- In XCode, navigate to `Environment.swift` file and paste your `applacation id` and `cient id` of your Parse App, i.e., The `Environment.swift` file should look like this
~~~swift
class Environment {
    class AppSettings {
        static let applicationId = "MY_PARSE_APPLICATION_ID"
        static let clientKey = "MY_PARSE_CLIENT_KEY"
        static let server = "https://parseapi.back4app.com"
    }
    
    class ServerClass {
        static let toDoList = "ToDoList"  // The class name in your Parse App
    }
}
~~~

It is straightforward to identify where your `application id` and `client id` go.

Now the last step is simply to run the proyect and have fun.
