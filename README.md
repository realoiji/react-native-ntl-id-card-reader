
# react-native-ntl-id-card-reader

## Getting started

`$ npm install react-native-ntl-id-card-reader --save`

### Mostly automatic installation

`$ react-native link react-native-ntl-id-card-reader`

### Manual installation


#### iOS

1. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2. Go to `node_modules` ➜ `react-native-ntl-id-card-reader` and add `RNNtlIdCardReader.xcodeproj`
3. In XCode, in the project navigator, select your project. Add `libRNNtlIdCardReader.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
4. Run your project (`Cmd+R`)<

#### Android

1. Open up `android/app/src/main/java/[...]/MainActivity.java`
  - Add `import com.reactlibrary.RNNtlIdCardReaderPackage;` to the imports at the top of the file
  - Add `new RNNtlIdCardReaderPackage()` to the list returned by the `getPackages()` method
2. Append the following lines to `android/settings.gradle`:
  	```
  	include ':react-native-ntl-id-card-reader'
  	project(':react-native-ntl-id-card-reader').projectDir = new File(rootProject.projectDir, 	'../node_modules/react-native-ntl-id-card-reader/android')
  	```
3. Insert the following lines inside the dependencies block in `android/app/build.gradle`:
  	```
      compile project(':react-native-ntl-id-card-reader')
  	```

#### Windows
[Read it! :D](https://github.com/ReactWindows/react-native)

1. In Visual Studio add the `RNNtlIdCardReader.sln` in `node_modules/react-native-ntl-id-card-reader/windows/RNNtlIdCardReader.sln` folder to their solution, reference from their app.
2. Open up your `MainPage.cs` app
  - Add `using Ntl.Id.Card.Reader.RNNtlIdCardReader;` to the usings at the top of the file
  - Add `new RNNtlIdCardReaderPackage()` to the `List<IReactPackage>` returned by the `Packages` method


## Usage
```javascript
import RNNtlIdCardReader from 'react-native-ntl-id-card-reader';

// TODO: What to do with the module?
RNNtlIdCardReader;
```
  