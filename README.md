
# react-native-regula-document-reader

## Getting started

`$ npm install react-native-regula-document-reader --save`

### Mostly automatic installation

`$ react-native link react-native-regula-document-reader`

### Manual installation


#### iOS

1. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2. Go to `node_modules` ➜ `react-native-regula-document-reader` and add `RNRegulaDocumentReader.xcodeproj`
3. In XCode, in the project navigator, select your project. Add `libRNRegulaDocumentReader.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
4. Run your project (`Cmd+R`)<

#### Android

1. Open up `android/app/src/main/java/[...]/MainActivity.java`
  - Add `import com.regula.documentreader.RNRegulaDocumentReaderPackage;` to the imports at the top of the file
  - Add `new RNRegulaDocumentReaderPackage()` to the list returned by the `getPackages()` method
2. Append the following lines to `android/settings.gradle`:
  	```
  	include ':react-native-regula-document-reader'
  	project(':react-native-regula-document-reader').projectDir = new File(rootProject.projectDir, 	'../node_modules/react-native-regula-document-reader/android')
  	```
3. Insert the following lines inside the dependencies block in `android/app/build.gradle`:
  	```
      compile project(':react-native-regula-document-reader')
  	```


## Usage
```javascript
import RNRegulaDocumentReader from 'react-native-regula-document-reader';

// TODO: What to do with the module?
RNRegulaDocumentReader;
```
  