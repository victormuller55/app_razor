# Lembrete do agendamento na Dynamic Island (iOS)

Live Activity do agendamento: na Dynamic Island (iPhone 14 Pro em diante) e na
tela bloqueada de qualquer iPhone com iOS 16.2+. É uma só implementação: o app
cria e ajusta a atividade quando está aberto, e a API a atualiza por push
quando está fechado.

## Estados

| Status na API | Estado | Ilha fechada (direita) | Expandida / tela bloqueada (direita) |
| --- | --- | --- | --- |
| `AGENDADO`, até o início | aguardando | contagem | "Começa em" + contagem (azul `#60A5FA`) |
| `AGENDADO`, do início ao fim do horário | aguardando | ícone de QR | botão **QR Code · Confirmar chegada** |
| `CONFIRMADO` (QR lido) | confirmado | ✓ | "Horário agendado" + HH:mm (`#34D399`) |
| `EM_ATENDIMENTO` | emAtendimento | cronômetro | "Em atendimento há" + cronômetro (`#10B981`) |
| `CONCLUIDO`, por 15 min | finalizado | ✓ (selo) | botão **Avaliar atendimento** (`#A78BFA`) |
| `CANCELADO`, `NO_SHOW` | — | a atividade termina e some | — |

À esquerda ficam sempre a foto do profissional, com borda na cor do estado, o
serviço e o chip do estado; o item da direita fica centralizado na altura da
foto. Na ilha fechada aparece a foto
pequena. Quando não há foto, aparecem as iniciais num círculo neutro.

Regras de segurança:
- Chegar a hora não confirma nada. Só a leitura do QR pela barbearia
  (`POST /agenda/confirmar-presenca`, que já valida o código e recusa
  duplicidade) leva a `CONFIRMADO`.
- O botão do QR só abre o QR se o agendamento ainda estiver `AGENDADO` na API.
  Confirmado ou cancelado: abre só a agenda.

## Lado iOS

| Arquivo | O quê |
| --- | --- |
| `ios/Shared/AgendamentoActivityAttributes.swift` | Atributos e `ContentState` (contrato com a API) e caminho da foto no App Group |
| `ios/RazorLiveActivity/AgendamentoLiveActivity.swift` | Visual: ilha (compacta, mínima, expandida) e tela bloqueada |
| `ios/RazorLiveActivity/RazorLiveActivity.entitlements` | App Group da extensão |
| `ios/Runner/LembreteAgendamentoPlugin.swift` | Canal `razor/lembrete_agendamento`, tokens das atividades (`TokensAtividade`), links `razor://` (eventos da cena via `addSceneDelegate`), foto |
| `ios/Runner/AppDelegate.swift` | Começa a ouvir os tokens antes do Flutter |
| `ios/Runner/Info.plist` | Esquema `razor`, `FlutterDeepLinkingEnabled = false` |
| `ios/Runner/Runner.entitlements` | App Group do app |
| `ios/scripts/adicionar_live_activity.rb` | Cria o target da extensão (agora com entitlements) |

- **Tempo sem timer no app:** contagem e cronômetro são `Text(timerInterval:)`
  com datas absolutas. Aguardando, a atividade fica obsoleta (`staleDate`) no
  início do horário. O iOS a redesenha sozinho e a contagem vira o botão do QR,
  mesmo com o app fechado.
- **Foto:** a extensão não acessa a rede. O app baixa a foto, reduz para 120 px
  e grava no App Group `group.com.net.convertix.scissor`. A extensão lê o
  arquivo de lá. Numa atividade iniciada pelo servidor, o app baixa a foto
  quando o iOS o acorda para entregar o token.
- **Links:**
  - `razor://agendamento/{id}`: toque na atividade; abre a agenda.
  - `razor://agendamento/{id}/qrcode`: abre o QR.
  - `razor://agendamento/{id}/avaliar`: abre a avaliação.

  Os botões usam `Link`, que funciona na ilha expandida e na tela bloqueada
  com o app fechado.
- **Tokens:**
  - Ao criar a atividade (`pushType: .token`), o iOS entrega um token de
    atualização. O app o manda para `PUT /api/v1/atividades-ao-vivo` com a
    chave assinada que veio da API, sem o login. Isso funciona em segundo plano.
  - No iOS 17.2+, o token de push-to-start vai junto com o cadastro do aparelho
    (`PUT /api/v1/dispositivos`, campo `token_inicio_atividade`).
- **Uma atividade por vez, nunca recriada:** a que já existe é atualizada
  (`update`), e as de outros agendamentos são encerradas.

## Lado Dart

- `lib/functions/lembrete_agendamento.dart`:
  - `estadoDaAtividade` e `agendamentoParaLembrete` (mesmas regras da API).
  - `dadosDaAtividade`.
  - `LinkAtividade`.
  - Busca do agendamento de um link.
- `lib/pages/menu/menu.dart`: abre a agenda e, conforme a situação atual, o QR
  (`showQrConfirmacaoModal`) ou a avaliação (`showAvaliarServicoModal`).
- `lib/functions/push_notificacoes.dart`: manda o token de push-to-start no
  cadastro do aparelho.
- `lib/models/agendamento_model.dart`: `fotoFuncionario`,
  `dataInicioAtendimento`, `dataConclusao`, `chaveAtividade`.

## Lado da API

- `AtividadeAoVivoService` faz uma conciliação, não uma fila. A cada 15 s
  (`NotificacoesConfig`) e logo depois de cada mudança de status, ele:
  1. Compara o estado atual do agendamento com o último mandado a cada
     atividade aberta. Se for igual, não manda nada, o que cobre eventos
     duplicados.
  2. Manda `update` ou `end`. O `timestamp` é sempre crescente, e o iOS
     descarta os mais velhos, o que cobre a ordem trocada.
  3. Mostra um `alert` só na mudança real de estado: confirmado, em
     atendimento, finalizado. Não alerta no primeiro envio nem no término.
  4. No iOS 17.2+, inicia por push (`start`) os agendamentos que começam na
     próxima hora, uma vez por aparelho, se ainda não houver atividade.
  5. Encerra o registro quando manda `end`, quando o token é recusado ou depois
     de 12 h.
- Envio pelo FCM HTTP v1 (`FcmPushGateway.corpoAtividade`): o token do FCM do
  aparelho + `apns.live_activity_token` + o `aps`, com a mesma chave APNs
  (.p8) que já está no Firebase.
- Disparo imediato em: confirmação pelo QR, início e conclusão do atendimento
  (inclusive a automática), cancelamento pela barbearia e não comparecimento
  manual. Os demais casos (cancelamento pelo cliente, não comparecimento
  automático) entram na passada de 15 s.
- Novos campos (só acréscimos, nada mudou nos existentes):
  - Resposta do agendamento: `foto_funcionario` e `data_inicio_atendimento`;
    `chave_atividade` só na listagem do próprio cliente.
  - Cadastro do aparelho: `token_inicio_atividade` (opcional).
  - Rota nova: `PUT /api/v1/atividades-ao-vivo`.
- Tabela nova `atividade_ao_vivo` e coluna
  `dispositivo_push.token_inicio_atividade`, criadas pelo
  `ddl-auto=update`.

## Configuração extra na Apple (antes do próximo build)

1. **App Group:**
   1. developer.apple.com → Identifiers → **App Groups** → `+` →
      `group.com.net.convertix.scissor`.
   2. Ative **App Groups** nos App IDs `com.net.convertix.scissor` e
      `com.net.convertix.scissor.SessionLiveActivity`, marcando esse grupo nos
      dois.
2. **Perfis:** gere de novo os dois perfis App Store, "Scissor App Store" e
   `app_scissor_activity` (Edit → Save). Depois, no Codemagic, Code signing
   identities → **Fetch profiles**.
3. **Push:** nada novo. A Live Activity usa a mesma capability Push
   Notifications e a mesma chave .p8 do Firebase.

Sem o passo 1, o build falha na assinatura: os entitlements pedem o App Group.

## Como testar cada transição

Pré-requisitos: iPhone com iOS 16.2+ (17.2+ para o início pelo servidor), build
do Codemagic, push ligado na API e o app com permissão de notificação.

| Transição | Como provocar | Esperado |
| --- | --- | --- |
| Início pelo app | Agendar para daqui a menos de 1 h e abrir o app | Atividade "aguardando" com contagem |
| Início pelo servidor (17.2+) | App fechado, horário entrando na janela de 1 h | Alerta "⏰ Seu horário está chegando" e atividade aguardando |
| Contagem → QR | Esperar o horário começar (app fechado) | Botão do QR, sem nenhum envio da API |
| QR com o app fechado | Tocar no botão | App abre no QR do agendamento |
| Aguardando → confirmado | Gestor lê o QR | Alerta "✅ Chegada confirmada", ✓ na ilha, "Horário agendado" |
| QR depois de confirmado | Tocar num link de QR antigo | Abre só a agenda (o QR não reaparece) |
| Confirmado → em atendimento | Gestor inicia | Alerta "✂️ Atendimento começou", cronômetro |
| Em atendimento → finalizado | Gestor finaliza (ou prazo vence) | Alerta "💈 Atendimento finalizado", botão Avaliar |
| Avaliar | Tocar no botão | App abre a avaliação daquele atendimento |
| Finalizado → fim | Esperar 15 min | Some da ilha; fica um pouco na tela bloqueada |
| Cancelamento | Gestor cancela (ou cliente) | A atividade some, sem alerta |
| Não compareceu | Gestor marca, ou a rotina | A atividade some |
| Duplicado | Repetir a mesma ação no gestor | Nenhum envio novo (log `ATIVIDADE_ATUALIZADA` uma vez) |

Logs da API: `ATIVIDADE_TOKEN`, `ATIVIDADE_INICIADA`, `ATIVIDADE_ATUALIZADA`,
`ATIVIDADE_ENCERRADA` (o token nunca aparece).

Testes automáticos:
- App: `test/functions/lembrete_agendamento_test.dart` e
  `test/functions/push_notificacoes_test.dart`.
- API: `AtividadeAoVivoRegrasTest` e os itens 20 e 21 de `NotificacoesTest`.

O Swift não é compilado nos testes daqui (Windows). Ele só é validado no build
do Codemagic.

## Limitações

- O iOS limita a frequência de atualizações por push e pode atrasar as de
  prioridade alta. Mandamos só mudanças reais (poucas por atendimento).
- Push-to-start só no iOS 17.2+. Abaixo disso, a atividade começa quando o app
  é aberto e, a partir daí, é atualizada pela API com o app fechado.
- O usuário pode desligar as Live Activities do app nos Ajustes. Nesse caso nada
  aparece, e os avisos por push continuam.
- A foto de uma atividade iniciada pelo servidor depende de o iOS acordar o app
  para baixá-la. Até lá, aparecem as iniciais.
- Se o servidor iniciar a atividade de um agendamento enquanto outra (o
  "avaliar" de um anterior) ainda está aberta, podem aparecer duas até o app ser
  aberto.
- O FCM exige um token de aparelho junto com o da atividade. A API usa o
  aparelho iOS mais recente do cliente.

## Assinatura da extensão

A extensão usa o bundle id `com.net.convertix.scissor.SessionLiveActivity`, com
o perfil App Store `app_scissor_activity` no Codemagic. Sem esse perfil, o build
gera o app sem a extensão: o log mostra "AVISO: nenhum perfil para ...". O
target não fica salvo no projeto: o Codemagic roda
`ios/scripts/adicionar_live_activity.rb` a cada build. Num Mac, rode
`cd ios && ruby scripts/adicionar_live_activity.rb` para abrir com a extensão.
