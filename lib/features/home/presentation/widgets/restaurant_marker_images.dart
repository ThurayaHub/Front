import 'dart:convert';
import 'dart:typed_data';

/// White POI glyphs based on Liberty's restaurant and cafe shapes. MapLibre
/// places them over a circle whose color comes directly from the app theme.
abstract final class RestaurantMarkerImages {
  static final Uint8List restaurant = base64Decode(_restaurantBase64);
  static final Uint8List cafe = base64Decode(_cafeBase64);

  static const String _restaurantBase64 =
      'iVBORw0KGgoAAAANSUhEUgAAACoAAAAqCAYAAADFw8lbAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMA'
      'AA7DAcdvqGQAAADnSURBVFhH7c5BCsMwEEPR3P/SKVkMiI+HjIK8qt+mLvlGvq7jOI5X933f9atndit6Z7uvD61+0kZ8eag+8q2N'
      '0KHuTPVNsYnToe5M9U2xidOh7rzqiV2cDnXnVU/s4nSoO696YhfFodW5/q/uKG3iONaZ3NEmjmOdyR1t4jjWmdzRZgsO0rRntwVH'
      'C7sHm8Jum+kwu8Jum+kwu8JuG2eY7YPNNl+G3T5CR6fDbh+ho9Nht4/Q0emw20fo6HTY7SN0dDLs9jHusNvHuMNuH+MOu32MO+z2'
      'Me6w28e4w24f5Y66/XEc/+wHPrmHsWPVqmEAAAAASUVORK5CYII=';

  static const String _cafeBase64 =
      'iVBORw0KGgoAAAANSUhEUgAAACoAAAAqCAYAAADFw8lbAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMA'
      'AA7DAcdvqGQAAACQSURBVFhH7dFBCoAwDETR3P/SiouCfpA4baII87a18wtGmJmZmUXEtoh7bRhWca8NwyrutWFYxb02DFdhZxkD'
      'ldhawnEV9w7Z+ZTz6AzuDdm57JrVcW/IzmXXrI57h+x8ynm0GlvLGKjARglGnuLOK/iIDO+/io+5w3uf4cMGfme/xt+r4l4bhlXc'
      'MzMz+7cd+3aviSGpvywAAAAASUVORK5CYII=';
}
