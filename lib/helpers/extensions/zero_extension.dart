/// isNull extension to show if this [object] is null or not
extension ZeroChecker on num?{

  /// isNull function to show if this [object] is null or not
  bool get isEqualZero{
    return this == 0;
  }

  /// isNull function to show if this [object] is not null or not
  bool get isNotEqualZero{
    return this != 0;
  }
}