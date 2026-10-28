/// Ambiente desta branch. Cada branch tem o seu (dev: API local; main: produção) e o .gitattributes
/// mantém este arquivo fora dos merges (merge=ours), então não precisa trocar nada antes de mesclar.
///
/// Emulador Android: use `http://10.0.2.2:5000` no lugar de `localhost`
/// (10.0.2.2 é o loopback do PC no emulador).
/// Dispositivo físico na mesma rede: use o IP Wi-Fi do notebook.
const String server = 'http://192.168.0.110:5000';

/// Mostra o botão de pagar o Pix de teste (só funciona com a API no provedor simulado).
const bool pixDeTeste = true;
