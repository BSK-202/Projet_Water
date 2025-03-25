class Family {
  final String id;
  final String name;
  final String avatar;
  final double latitude;
  final double longitude;
  final int score;
  Family({
    required this.id,
    required this.name,
    required this.avatar,
    required this.latitude,
    required this.longitude,
    required this.score,
  });

  // Méthode pour convertir JSON en objet User
  factory Family.fromJson(Map<String, dynamic> json) {
    String coordinates = json['localisation']
        .toString()
        /**************** */
        .replaceAll("(", "")
        .replaceAll(")", "");

    List<String> coord = coordinates.split(",");
    print("/***************************idjson********************** */");
    print(json['id']);
    print("/***************************namejson********************** */");
    print(json['nom']);
    Family family = Family(
      id: json['id'],
      name: json['nom'], //on doit recuperer le nom de la famille
      avatar: "assets/image.png", //on doit recuperer l'image de la famille
      latitude: double.parse(coord[0]),
      longitude: double.parse(coord[1]),
      score: int.tryParse(json['score'].toString()) ?? 0,
    );

    //print(family.id);
    return family;
  }
}
