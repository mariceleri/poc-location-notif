import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:poc_location_notif/nearByPlaces/place.dart';

class NearbyPlacesView extends StatefulWidget {
  const NearbyPlacesView({Key? key}) : super(key: key);

  @override
  _NearbyPlacesViewState createState() => _NearbyPlacesViewState();
}

class _NearbyPlacesViewState extends State<NearbyPlacesView> {
  static const platform = MethodChannel('sample.fd.notif');
  double latitude = 0;
  double longitude = 0;
  Location location = new Location();
  double radius = 5000; //in meters
  List<Place> nearbyPlaces = [];
  List<Place> places = [
    Place(
        latitude: 10.319730952362907,
        longitude: 123.90590070333427,
        name: 'Ayala Life FGU Center'),
    Place(
        latitude: 10.332278596970012,
        longitude: 123.90524598854661,
        name: 'Sugbu Mercado IT Park'),
    Place(
        latitude: 10.337151433617427,
        longitude: 123.93406818928987,
        name: 'JCenter Mall'),
    Place(
        latitude: 10.342350102048295,
        longitude: 123.94736776214911,
        name: 'Pacific Mall'),
    Place(
        latitude: 10.333009378216174,
        longitude: 123.91482514286169,
        name: 'Cebu Country Club'),
    Place(
        latitude: 10.321309528705719,
        longitude: 123.93167072044356,
        name: 'UC Med')
  ];

  @override
  void initState() {
    initNotifState();
    // getInitState();
    super.initState();
  }

  Future<void> getInitState() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    LocationData _locationData;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationData = await location.getLocation();
    setState(() {
      latitude = _locationData.latitude ?? 0;
      longitude = _locationData.longitude ?? 0;
      getNearbyPlacesOfUser(latitude, longitude);
    });

    location.enableBackgroundMode(enable: true);

    location.onLocationChanged.listen((LocationData currentLocation) {
      print(
          "current location latitude: ${currentLocation.latitude} longitude: ${currentLocation.longitude}");
    });
  }

  Future<void> initNotifState() async {
    try {
      // final int result =
      await platform.invokeMethod("setNotif", jsonEncode(places));
      // await platform.invokeMethod("setNotif");
      log("notif set successfully");
    } on PlatformException catch (e) {
      log("failed setting notif");
    }
  }

  void getNearbyPlacesOfUser(double latitude, double longitude) {
    Place userLocation = Place(latitude: latitude, longitude: longitude);
    for (Place nearPlace in places) {
      double distance = getDistanceOfTwoPoints(userLocation, nearPlace);
      if (distance < radius) {
        nearbyPlaces.add(nearPlace);
      }
    }
  }

  double getDistanceOfTwoPoints(Place firstLocation, Place secondLocation) {
    var distance = DistanceHaversine();
    final meterDistance = distance(
        LatLng(firstLocation.latitude, firstLocation.longitude),
        LatLng(secondLocation.latitude, secondLocation.longitude));
    return meterDistance;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nearby Places'),
      ),
      body: Column(
        children: [
          Center(
              child: Text(
                  "User location latitude: $latitude longitude: $longitude")),
          Expanded(
              child: ListView.builder(
                  itemCount: nearbyPlaces.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: Icon(Icons.location_city),
                      title: Text("${nearbyPlaces[index].name}"),
                    );
                  })),
        ],
      ),
    );
  }
}
