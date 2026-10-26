# Lembrete do agendamento na Dynamic Island (iOS)

Uma hora antes do serviço, o app mostra uma Live Activity com a contagem
regressiva: na Dynamic Island (iPhone 14 Pro em diante) e na tela de bloqueio
dos outros iPhones com iOS 16.2+.

## Como funciona

- Só com o app aberto: ao abrir, ao voltar para o app e a cada minuto, o app
  confere os agendamentos (`lib/functions/lembrete_agendamento.dart`).
- Mostra o agendamento pendente que começa em até 1h (ou que está em
  andamento). Cancelado, concluído ou terminado: o lembrete some.
- O cronômetro roda sozinho no iOS, mesmo com o app fechado depois de iniciado.
  Na hora do serviço ele troca para "É agora".

## Arquivos

| Onde | O quê |
| --- | --- |
| `ios/Shared/AgendamentoActivityAttributes.swift` | Dados da atividade (app e extensão) |
| `ios/RazorLiveActivity/` | Extensão: visual da ilha e da tela de bloqueio |
| `ios/Runner/LembreteAgendamentoPlugin.swift` | Canal `razor/lembrete_agendamento` usado pelo Dart |
| `ios/scripts/adicionar_live_activity.rb` | Cria o target da extensão no `Runner.xcodeproj` |

O target `RazorLiveActivity` não fica salvo no projeto: o Codemagic roda o
script a cada build (passo "Add Live Activity Extension", antes do CocoaPods).
Num Mac, para abrir no Xcode com a extensão: `cd ios && ruby scripts/adicionar_live_activity.rb`.

## Assinatura (uma vez)

Sem um perfil para a extensão, o build do Codemagic gera o app **sem** o
lembrete (o log mostra "AVISO: nenhum perfil para ..."). Para incluir:

1. developer.apple.com → Certificates, Identifiers & Profiles → Identifiers:
   registre o App ID `com.net.convertix.scissor.RazorLiveActivity`
   (tipo App IDs → App, sem capabilities extras).
2. Profiles → `+` → Distribution → **App Store Connect** → escolha esse App ID
   → o mesmo certificado de distribuição do app → dê um nome (ex.:
   `Razor LiveActivity App Store`).
3. Codemagic → Teams → Code signing identities → iOS provisioning profiles →
   **Fetch profiles** → marque o perfil novo e salve com uma referência.
4. Rode o build de novo. O `ios_signing` instala os perfis com o prefixo
   `com.net.convertix.scissor`, o passo "Add Live Activity Extension" acha o
   da extensão e o `xcode-project use-profiles` aplica cada perfil no seu target.
