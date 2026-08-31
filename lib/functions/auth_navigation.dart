import 'package:app_razor/pages/menu/menu.dart';
import 'package:muller_package/muller_package.dart';

Future<void> openHomeAfterAuth() async {
  open(screen: const MenuScreen(), closePrevious: true);
}
