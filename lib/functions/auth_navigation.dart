import 'package:app_razor/functions/permissoes.dart';
import 'package:app_razor/pages/menu/menu.dart';
import 'package:app_razor/pages/permissoes/permissoes_page.dart';
import 'package:muller_package/muller_package.dart';

Future<void> openHomeAfterAuth() async {
  final bool tudoLiberado = await todasPermissoesConcedidas();

  open(
    screen: tudoLiberado ? const MenuScreen() : const PermissoesPage(),
    closePrevious: true,
  );
}
