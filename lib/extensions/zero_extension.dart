/// ZeroChecker extension to show if this [num] is zero or not
extension ZeroChecker on num?{

  /// ZeroChecker extension to show if this [num] is zero or not
  bool get isEqualZero{
    return this == 0;
  }

  /// ZeroChecker extension to show if this [num] is not zero or not
  bool get isNotEqualZero{
    return this != 0;
  }
}