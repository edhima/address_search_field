# Address Search Field

Widget builders to create 'address search widgets' which helps to autocomplete an address using a reference. They can be used to get Directions beetwen two places with optional waypoints. These widgets are made to be showed by `onTap` in a `TextField` with the `showDialog` function.
It uses [HTTP](https://pub.dev/packages/http/versions/0.12.2), [Google Maps for Flutter](https://pub.dev/packages/google_maps_flutter/versions/1.0.5) plugins. (This last plugin is to use extended objects that can be usable with `GoogleMap` Widget).

![](https://raw.githubusercontent.com/JosLuna98/address_search_field/master/screenshot/untitled.gif)

## Getting Started

To use this plugin, add `address_search_field` as a [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/). For example:

```yaml
dependencies:
  address_search_field: ^3.0.0
```

## Permissions

### Android

On Android you'll need to add the internet permission to your Android Manifest file (located under android/app/src/main). To do so add next lines as direct child of the `<manifest>` tag:

``` xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

### iOS

On iOS you'll need to add the `NSLocationWhenInUseUsageDescription` to your Info.plist file (located under ios/Runner) in order to access the device's location. Simply open your Info.plist file and add the following:

``` xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Permission to get your location</string>
```

## Usage

Import the package:
```dart
import 'package:address_search_field/address_search_field.dart';
```

## GeoMethods

```dart
GeoMethods(
  googleApiKey: String,
  language: String,
  countryCode: String,
  country: String,
  city: String,
  mode: String,
);
```

* This object makes calls to Google APIs using the parameters set. It can do requests to Google places, geocode and directions APIs.
* Language support list [here](https://developers.google.com/maps/faq#languagesupport).
* List of countries [here](https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes).

## AddressSearchBuilder

This widget is a builder which provides of parameters and methods to create a widget that can search addresses and permits to work with them using an `Address` object.

```dart
AddressSearchBuilder(
  geoMethods: GeoMethods,
  controller: TextEditingController,
  builder: (
    BuildContext context,
    AsyncSnapshot<List<Address>> snapshot, {
    TextEditingController controller,
    Future<void> Function() searchAddress,
    Future<Address> Function(Address address) getGeometry,
  }) {
    // building example
    return AddressSearchDialog(
      snapshot: snapshot,
      controller: controller,
      searchAddress: searchAddress,
      getGeometry: getGeometry,
      onDone: (address) => null,
    );
  },
);
```

>`AddressSearchDialog` shouldn't be used alone. It needs parameters from `AddressSearchBuilder`. The best way to use this widget is using `AddressSearchBuilder.deft`, which will just use an `AddressDialogBuilder` and it's an easier implementation.

```dart
AddressSearchBuilder.deft(
  geoMethods: GeoMethods,
  controller: TextEditingController,
  builder: AddressDialogBuilder(),
  onDone: (Address address) {},
);
```

## AddressDialogBuilder

This builder uses parameters to customize an `AddressSearchDialog` which is called from `AddressSearchBuilder`.

```dart
AddressDialogBuilder(
  color: Color,
  backgroundColor: Color,
  hintText: String,
  noResultText: String,
  cancelText: String,
  continueText: String,
  useButtons: bool,
);
```

## RouteSearchBox

This is a special widget with a builder which provides of three `AddressSearchBuilder` to search an origin `Address`, destination `Address` and optionally waypoints in a `List<Address>`. This widget is used to get directions from the points got by the builder's `AddressSearchBuilder`s.
A completed example of how to use this widget could be found [here](https://pub.dev/packages/address_search_field/example).

```dart
RouteSearchBox(
  originIsMyLocation: bool,
  onOriginLoading: String,
  onOriginError: String,
  geoMethods: GeoMethods,
  originCtrlr: TextEditingController,
  destinationCtrlr: TextEditingController,
  waypointCtrlr:TextEditingController,
  builder: (
    BuildContext context,
    AddressSearchBuilder originBuilder,
    AddressSearchBuilder destinationBuilder,
    AddressSearchBuilder waypointBuilder, {
    WaypointsManager waypointsMgr,
    Future<Directions> Function() getDirections,
  }) {
    // building example
    return TextField(
      controller: originCtrlr,
      onTap: () => showDialog(
        context: context,
        builder:
            (context) => 
                originBuilder.buildDefault(
          builder: AddressDialogBuilder(),
          onDone: (address) => null,
        ),
      ),
    );
  },
);
```

##  License

MIT License
