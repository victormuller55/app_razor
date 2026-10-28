/// Ambiente desta branch. Cada branch tem o seu (dev: API local; main: produção) e o .gitattributes
/// mantém este arquivo fora dos merges (merge=ours), então não precisa trocar nada antes de mesclar.
const String server = 'https://razor.api.codexin.com.br';

/// Mostra o botão de pagar o Pix de teste (só funciona com a API no provedor simulado).
const bool pixDeTeste = false;
