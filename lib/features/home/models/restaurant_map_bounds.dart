class RestaurantMapBounds {
  const RestaurantMapBounds({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  }) : assert(north >= south),
       assert(east >= west);

  final double north;
  final double south;
  final double east;
  final double west;

  Map<String, String> toQueryParameters({required int limit, int? afterId}) {
    return <String, String>{
      'north': north.toString(),
      'south': south.toString(),
      'east': east.toString(),
      'west': west.toString(),
      'limit': limit.toString(),
      if (afterId != null) 'afterId': afterId.toString(),
    };
  }
}
