/// How a member is related to the user. [name] is the value the API uses.
enum Relation {
  self('Self'),
  father('Father'),
  mother('Mother'),
  spouse('Spouse'),
  son('Son'),
  daughter('Daughter'),
  other('Other');

  const Relation(this.label);

  final String label;

  static Relation fromApi(String? value) =>
      Relation.values.firstWhere((r) => r.name == value, orElse: () => other);
}

/// [name] is the value the API uses ("male", "female", "other").
enum Gender {
  male('Male'),
  female('Female'),
  other('Other');

  const Gender(this.label);

  final String label;

  static Gender? fromApi(String? value) {
    for (final g in Gender.values) {
      if (g.name == value) return g;
    }
    return null;
  }
}
