class ControlOptions {
  ControlOptions({this.v, this.f});

  bool? v;
  bool? f;

  factory ControlOptions.fromJson(Map<String, dynamic> json) {
    return ControlOptions(
      v: json['v'] as bool?,
      f: json['f'] as bool?,
    );
  }
}
