class Place {
  double latitude;
  double longitude;
  String? name;

  Place({required this.latitude, required this.longitude, this.name});

  Map toJson() => {'latitude': latitude, 'longitude': longitude, 'name': name};
}
