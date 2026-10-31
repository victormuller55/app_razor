# RAZ-13 — Relatório de implementação

Busca e descoberta de barbearias no aplicativo do cliente e na API. Branch `RAZ-13`, criada a partir de `dev`, nos repositórios `api_razor` e `app_razor`. O painel gestor não entrou no escopo: a descoberta é do cliente.

## 1. Resumo da implementação

A listagem que já existia (`GET /api/v1/barbearias`) passou a pesquisar no banco, com paginação, em vez de o aplicativo baixar um lote e filtrar na memória. O mesmo endpoint cobre nome da barbearia, descrição, cidade, bairro, serviço ativo e profissional ativo. Distância, preço, nota e “aberto agora” também são aplicados na consulta, não no aparelho.

Não foi criado um segundo índice de busca, um banco à parte nem um serviço pago. A vitrine continua autenticada, como o restante do aplicativo.

## 2. Diagnóstico da busca existente

Antes desta tarefa:

- A grade do aplicativo já pedia páginas de 30 em `GET /api/v1/barbearias`, com cidade, bairro, nota, aberto e distância máxima.
- A tela de pesquisa carregava até 100 barbearias e filtrava nome, bairro e cidade no aparelho, sem debounce e sem serviço ou profissional.
- A distância era calculada em Java com Haversine, depois de carregar as candidatas. “Próximas” lia todas as ativas com coordenada e cortava em 10.
- O banco é MySQL 8. Não há PostGIS, `unaccent` nem FULLTEXT. O esquema é atualizado pelo Hibernate (`ddl-auto=update`) e por `DatabaseSchemaMigrator`. Os arquivos `db/V*.sql` documentam o schema e não rodam sozinhos.
- Não existe status de onboarding, aprovação ou cadastro incompleto. O que publica a barbearia é `ativa = true`, gravado pelo gestor. RAZ-12, neste `dev`, não acrescentou outro estado.
- Avaliação de barbearia já existe (`nota_media` e `total_avaliacoes`, ignorando avaliações ocultas). Avaliação de atendimento não entra nessa nota.
- Horário livre de agendamento continua só em `AgendamentoService`. A vitrine não duplica essa grade.

## 3. Arquivos criados e alterados

API (`api_razor`):

- Criados: `OrdenacaoBusca.java`, `ConsultaBarbearias.java`, `TextoBuscaUtil.java`, `DistanciaSql.java`, `V18__busca_barbearias.sql`, `BuscaBarbeariaTest.java`, `BuscaBarbeariaDesempenhoTest.java`, `TextoBuscaUtilTest.java`, este relatório.
- Alterados: `BarbeariaController.java`, `BarbeariaConsultaService.java`, `BarbeariaSpecification.java`, `BarbeariaServicoRepository.java`, `BarbeariaHomeResponse.java`, `DatabaseSchemaMigrator.java`, `BarbeariaControllerTest.java`.

Aplicativo (`app_razor`):

- Criados: `pesquisa_barbearias_bloc.dart`, `pesquisa_barbearias_event.dart`, `pesquisa_barbearias_state.dart`, `test/pages/pesquisa_barbearias/pesquisa_barbearias_bloc_test.dart`, este relatório.
- Alterados: `pesquisa_barbearias_page.dart`, `barbearias_filtros.dart`, `barbearias_filtros_modal.dart`, `home_proxima_card.dart`, `home_barbearia_logo.dart`, `permissoes.dart`, `permissoes_page.dart`, `barbearias_filtros_test.dart`.

## 4. Alterações no banco de dados e índices

Nenhuma coluna nova. Índices criados pelo migrador (e documentados em `V18__busca_barbearias.sql`):

| Índice | Colunas | Para quê |
|---|---|---|
| `idx_barbearia_ativa_geo` | `ativa, latitude, longitude` | faixa geográfica das ativas |
| `idx_barbearia_servico_ativo_preco` | `id_barbearia, ativo, preco` | preço mínimo e filtro de faixa |
| `idx_barbearia_servico_ativo_nome` | `id_barbearia, ativo, nome` | serviço da barbearia |
| `idx_funcionario_barbearia_ativo` | `id_barbearia, ativo` | profissional da barbearia |

Não foi criado índice em `nome`, `cidade` ou `bairro`. A pesquisa é por trecho (`%termo%`) com `REPLACE` de acento. Um B-tree não acelera curinga no início, e a expressão de acento impede o uso do índice na ordenação por nome. O horário da barbearia já tem índice único em `(id_barbearia, dia_semana)`.

Não foi adotado índice espacial (`POINT` / `ST_Distance_Sphere`). O H2 dos testes não reproduz isso, e o recorte por retângulo de latitude/longitude mais a fórmula de Haversine no SQL cobre o volume medido sem um segundo mecanismo.

## 5. Endpoints e consultas implementados

Continua sendo `GET /api/v1/barbearias`, com JWT. Parâmetros novos, todos opcionais:

- `busca` — texto livre, no máximo 80 caracteres
- `servico`, `profissional`
- `preco_min`, `preco_max`
- `ordenacao`: `relevancia`, `distancia`, `preco_asc`, `preco_desc`, `avaliacao`

Os que já existiam seguem: `cidade`, `bairro`, `aberto`, `nota_minima`, `distancia_maxima` (0 a 200 km), `latitude`, `longitude`, `num_pag`, `itens_pag` (padrão 30, máximo 100).

A resposta ganhou `nome_servico` e `preco_servico`: o serviço ativo mais barato da página, carregado numa única consulta. Não há N+1 de serviço.

`GET /api/v1/barbearias/proximas` deixou de ler todas as ativas. Usa a mesma consulta, exige coordenada, ordena por distância e devolve no máximo 10.

Filtro inválido responde 400 (`Ordenação inválida`, preço invertido, nota fora de 0–5, coordenada fora do intervalo, texto longo demais). Ordenar por distância sem as duas coordenadas também é 400.

## 6. Funcionamento da pesquisa textual

O termo é aparado, a caixa é ignorada, acentos são removidos e espaços repetidos viram um só. No SQL, `LOWER` mais `REPLACE` dos acentos do português faz o mesmo no MySQL e no H2. Coringas digitados (`%` e `_`) são escapados.

O texto encontra, em OU:

- nome e descrição da barbearia
- cidade e bairro
- nome ou descrição de serviço ativo
- nome do usuário de profissional ativo

Serviço ou profissional inativo não entra. Com termo, a ordem padrão é: nome que começa pelo termo, nome que contém o termo, demais correspondências; se houver localização, a distância desempata sem apagar essa ordem.

Não há correção de erro de digitação nem radical (“cortes” não equivale a “corte”). Isso exigiria um analisador à parte, e o `LIKE` atual resolve o que a base já guarda.

## 7. Funcionamento da busca geográfica

Com latitude e longitude válidas, a distância é a fórmula de Haversine em quilômetros, executada no banco para filtrar e ordenar. O valor mostrado no card continua o do `HaversineUtil` (duas casas, nunca negativo para coordenada válida). Estabelecimento sem latitude ou longitude não recebe distância, fica por último na ordenação por proximidade e sai do filtro de distância máxima.

Antes do Haversine, um retângulo em torno do cliente (com folga) restringe latitude e longitude, para não calcular a fórmula em toda a tabela quando há distância máxima.

A coordenada do cliente só vai na query da requisição. Não é gravada.

Sem permissão, a pesquisa por texto, cidade e bairro continua. A ordenação “Perto” não é enviada e o aplicativo avisa que dá para pesquisar por cidade, bairro ou nome. A tela de permissões não bloqueia mais a entrada no aplicativo por causa da localização.

## 8. Filtros e ordenações disponíveis

Combináveis, todos no banco:

- cidade, bairro, serviço, profissional
- faixa de preço de serviço ativo
- nota mínima (`nota_media`), que só passa quem já tem essa média
- aberto agora, pelo horário do dia em `America/Sao_Paulo` (o mesmo critério de `HorarioFuncionamentoUtil`)
- distância máxima, só quando há coordenada

Ordenação:

- padrão: relevância do nome e, se houver localização, distância; sem texto e com localização, distância; sem os dois, `id`
- `distancia`, `preco_asc`, `preco_desc`
- `avaliacao`: quem não tem avaliação (`total_avaliacoes` 0) vai para o fim. Nota gravada sem avaliações não sobe no ranking.

O preço da ordenação é o menor preço entre serviços ativos. Barbearia sem serviço ativo fica por último. Não há posição patrocinada.

“Aberto” é o expediente de hoje, não a existência de horário livre. A grade de 15 minutos permanece em `AgendamentoService`.

## 9. Estratégia de paginação

Permanece offset (`num_pag` / `itens_pag`), que o aplicativo já consumia. Cada ordem termina com `id`, para o desempate ser estável e a página seguinte não repetir o mesmo id enquanto os dados não mudam.

Cursor não foi introduzido: a API não tinha esse contrato, e um segundo modelo de página quebraria a grade e o mapa, que usam o mesmo endpoint. Se a lista mudar no meio da rolagem, o offset ainda pode pular ou repetir um item. O aplicativo descarta id já mostrado ao anexar a próxima página.

A página pedida além do fim volta para a última, como antes. A pesquisa pede 30 por vez e só busca a próxima perto do fim da lista.

## 10. Otimizações de desempenho

- Filtro, ordenação e página acontecem no banco. O caminho antigo, que carregava todas as candidatas quando havia “aberto” ou distância, foi removido da listagem.
- “Próximas” não materializa mais todas as ativas.
- Resumo de serviço e horário do dia são consultas em lote, só dos ids da página.
- O dono da barbearia não é carregado (associação preguiçosa, e o mapeamento da vitrine não a toca).
- A pesquisa do aplicativo usa `forceRefresh`, então não lê o cache HTTP de 5 minutos. A resposta nova ainda atualiza esse cache.
- Uma pesquisa nova incrementa uma geração antes do evento. A resposta de uma geração anterior é descartada, inclusive a da próxima página que ainda estava em andamento.
- O texto espera 400 ms depois da última tecla.
- O limite de 100 requisições por minuto por IP, já existente, cobre este GET. Não foi criado um balde separado.

## 11. Integração com o RAZ-12

No `dev` usado como base não há fluxo de aprovação nem flag de cadastro incompleto. A elegibilidade da vitrine é a mesma de antes e a mesma do agendamento quanto à barbearia: `ativa = true`.

- Ativar (`ativa = true`) faz a barbearia passar a aparecer, inclusive na mesma transação, sem cache de aplicação.
- Desativar tira ela da busca.
- Barbearia inativa não aparece. No modelo atual, rascunho é isso: `ativa = false`.
- Serviço e profissional entram só se o vínculo estiver ativo.
- A vitrine é o marketplace inteiro de barbearias ativas. Não há `tenant_id`. O isolamento por dono continua só nas rotas `/gestor` e `/admin`.

Se no futuro existir aprovação obrigatória ou checklist de cadastro, a specification precisa ganhar esse predicado. Hoje ele não existe para ser reutilizado.

## 12. Alterações na interface do aplicativo

A tela de pesquisa deixou de filtrar em memória. Passou a ter:

- campo com a dica “Barbearia, serviço, profissional ou bairro”
- limpar o texto
- espera de 400 ms entre uma digitação e a consulta
- chips de ordenação: Padrão, Perto, Menor preço, Maior preço, Avaliação
- filtros de cidade, bairro, serviço, profissional, preço, distância, nota e aberto, no modal que a grade já usava
- carregamento, lista vazia, erro com tentar de novo, aviso de localização negada ou indisponível, e indicador ao pedir a próxima página
- card já usado na home: foto ou inicial, nome, bairro e cidade, distância, nota só se houver avaliação, serviço mais barato e preço, selo aberto/fechado
- toque abre o perfil que já existia (`openBarbeariaPerfil`)

A localização deixou de ser obrigatória para entrar no aplicativo. Câmera, fotos e avisos continuam opcionais.

A grade e o mapa seguem no mesmo `getBarbearias`. Com GPS e sem ordenação explícita, a API ordena por distância. O mapa ainda percorre as páginas do raio de 50 km; isso não mudou.

A tela não foi aberta num emulador nem num aparelho. A verificação foi por testes do BLoC, dos filtros e dos cards.

## 13. Testes executados e resultados

API, com sucesso (`mvnw test` nos testes citados):

- `TextoBuscaUtilTest` — acento, caixa, espaços e escape de curinga
- `BuscaBarbeariaTest` — nome completo e parcial, acento, serviço, profissional, cidade, bairro, sem coordenada, proximidade, filtros combinados, preço, avaliação, paginação sem id repetido, lista vazia, inativa que passa a aparecer e some de novo, JSON sem e-mail, telefone ou dono, filtros inválidos, relevância do nome antes da correspondência só no serviço
- `BarbeariaConsultaServiceTest` — listagem, próximas, aberto e perfil que já existiam
- `BarbeariaControllerTest` — contrato HTTP, 400 para ordenação inválida, corpo da busca sem e-mail do dono e sem telefone
- `BuscaBarbeariaDesempenhoTest` — volume e duas buscas ao mesmo tempo

Aplicativo, com sucesso (`flutter test` nos arquivos citados): 25 testes, entre eles busca sem GPS, descarte da resposta antiga, próxima página sem duplicar e com o filtro preservado, erro, filtros na query, e cards de distância.

Não houve teste de interface no dispositivo nem uma chamada real do aplicativo contra a API no ar. Cada lado foi testado no próprio contrato.

## 14. Resultados dos testes de desempenho e volume

H2 em memória (perfil `test`), não o MySQL de produção.

| Medida | Valor |
|---|---|
| Barbearias ativas | 500 |
| Serviços ativos | 1.000 (2 por barbearia) |
| Consulta por cidade, página de 30 | 53 ms |
| Itens devolvidos | 30 |
| Total informado (`max_itens`) | 500 |
| Distância máxima de 2 km na mesma massa | menos que 500, página de no máximo 30, distância de cada item entre 0 e 2 km |

O tempo de 53 ms é o da consulta, depois dos dados gravados. Não inclui o insert. Duas pesquisas paralelas (“Alfa” e “Beta”, 30 barbearias cada) não misturaram resultados.

Isso não prova o comportamento com dezenas de milhares de linhas no MySQL. Prova que a página não devolve o conjunto inteiro e que o filtro geográfico reduz o total antes da resposta.

## 15. Limitações encontradas

- Não há status de cadastro incompleto nem de aprovação. Inativa é o único critério de exclusão.
- Acentos, caixa e espaços são tratados. Erro de digitação e plural não.
- `LIKE %termo%` não usa índice de nome. Com crescimento grande, o próximo passo seria FULLTEXT com ngram no MySQL, ainda sem serviço externo. Não foi feito agora para não criar um segundo sistema que o H2 não executa.
- Paginação por offset pode pular ou repetir se os dados mudarem durante a rolagem.
- “Aberto” não significa “tem horário livre”.
- O card mostra o serviço ativo mais barato, não necessariamente o serviço que casou com o texto.
- Promoções próximas da home ainda calculam distância em memória, fora desta busca.
- A descoberta exige usuário autenticado, como o restante da vitrine.
- A tela não foi exercitada num aparelho.

## 16. Pendências

- Abrir a pesquisa num aparelho ou emulador, com e sem permissão de localização, e conferir o perfil a partir de um resultado.
- Se surgir aprovação ou cadastro incompleto, incluir o predicado na specification.
- Reavaliar FULLTEXT se a tabela de barbearias crescer a ponto de o `LIKE` com curinga no início pesar no MySQL.
- A seção de promoções próximas ainda carrega as promoções vigentes para ordenar em memória.

## 17. Confirmação dos critérios de aceite

| Critério | Situação |
|---|---|
| Pesquisar barbearia, serviço e profissional | Atendido. Coberto por `BuscaBarbeariaTest` e pelo envio de `busca` no BLoC. |
| Correspondência parcial e acento | Atendido no SQL com `LOWER`/`REPLACE` e no teste “sao joao” / “São João”. |
| Busca por localização com autorização | Atendido. Haversine no banco, ordenação por distância, card com km. |
| Funcionar sem permissão de localização | Atendido. A API ignora distância sem coordenada; o app avisa e segue; a entrada no app não exige mais GPS. |
| Filtros combinados | Atendido. Cidade + serviço + preço + distância no teste. |
| Ordenação | Atendido para distância, menor preço, maior preço e avaliação. O padrão usa relevância do nome e, com GPS, distância. |
| Paginação na API e no aplicativo | Atendido. 30 por página, `max_pag` / `max_itens`, rolagem pede a próxima e preserva o filtro. |
| Não carregar todas as barbearias de uma vez | Atendido na listagem e em “próximas”. O teste de 500 devolve 30. Promoções próximas da home continuam em memória (pendência). |
| Só estabelecimentos elegíveis | Atendido para `ativa = true`, serviço ativo e profissional ativo. Não há outro estado de publicação no `dev`. |
| Consultas adequadas ao volume medido | Atendido para 500 barbearias e 1.000 serviços no H2 (53 ms na página). Não medido no MySQL de produção. |
| Dados privados protegidos | Atendido. A resposta da vitrine não leva e-mail, senha, telefone nem id do dono. Teste de serviço e de controller. |
| Testes pertinentes executados | Atendido nos testes citados acima. Sem teste manual no aparelho. |
| Limitações documentadas | Atendido na seção 15. |
