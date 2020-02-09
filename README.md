# Stories

Take a trip down memory lane

## Build

- Rename `credentials.example.json` to `credentials.json`, and fill in the required fields
- Create an app on Firebase, and download the provided files to the appropriate iOS and Android locations
- Run `flutter pub get`


## Adding your own services

I'd welcome public contributions of additional time synchronized services! The following is the basic flow for creating your own service

- Create a new dart file for it 
- Create a class that extends from `ServiceInterface` in `service_utils.dart`, as well as as connected `ServiceWidget` classes
- Add the class to the appropriate category in `main.dart`
- Add your name, and a description of your service to credits in settings

### If you'd like to publish your service in my build of the app

- If your service requires a paid API account, email me at my public github email to discuss the cost
- Make a pull request!