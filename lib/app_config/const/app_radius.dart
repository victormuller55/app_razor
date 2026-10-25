/// Padrão de raio do produto.
///
/// Cards e superfícies externas (folhas, modais, botões, campos): [externo].
/// Elementos internos (foto, chip, badge, campo dentro do card): metade ([interno]).
class AppRadii {
  AppRadii._();

  static const double externo = 20;
  static const double interno = externo / 2;
}
