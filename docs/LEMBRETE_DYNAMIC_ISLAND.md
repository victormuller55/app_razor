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

## Configuração na Apple (uma vez)

1. Em Certificates, Identifiers & Profiles, registre o App ID
   `com.net.convertix.scissor.RazorLiveActivity`.
2. Crie o perfil App Store para esse App ID (ou deixe o Codemagic buscar/criar
   junto com o do app) e confira que ele aparece em Codemagic → Code signing
   identities → iOS provisioning profiles.
3. O `xcode-project use-profiles` aplica o perfil certo em cada target pelo
   bundle id.
