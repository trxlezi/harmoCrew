# Validacao da Correcao de Autoria

## Problema original

Ao enviar uma mensagem na tela de comunicacao, o usuario autenticado Rafael Yukio podia aparecer como Gabriel Caetano. O comportamento vinha de uma resolucao insegura de identidade no mobile: quando a sessao nao tinha `artistId`, o app usava o primeiro artista carregado da lista.

## Causa

O backend nao retornava `artistId` nas respostas de `/auth/register` e `/auth/login`. O mobile esperava esse campo para associar a sessao ao artista correto. Sem ele, a tela de mensagens usava um fallback para `_store.artists.first.id`, o que podia atribuir mensagens ao artista errado.

## Arquivos alterados

Backend `api-harmocrew`:

- `src/main/java/br/edu/ifsp/harmocrew_api/dtos/AuthResponse.java`
- `src/main/java/br/edu/ifsp/harmocrew_api/services/AuthService.java`
- `src/test/java/br/edu/ifsp/harmocrew_api/controllers/ApiIntegrationTest.java`

Mobile `harmoCrew`:

- `mobile/lib/features/collaboration/models/artist_profile.dart`
- `mobile/lib/features/members/data/artist_api_service.dart`
- `mobile/lib/features/collaboration/screens/messages_screen.dart`
- `mobile/lib/features/projects/presentation/projects_screen.dart`
- `mobile/lib/features/profile/presentation/profile_screen.dart`

## Correcao no backend

`AuthResponse` agora inclui `artistId`. O `AuthService` retorna o id do artista vinculado ao usuario autenticado:

- se o usuario tem `Artist`, retorna `user.getArtist().getId()`;
- se o usuario nao tem `Artist`, retorna `null`;
- a senha continua fora da resposta.

O teste de integracao de auth foi reforcado para validar que register/login retornam `token`, `userId`, `artistId`, `email` e nao retornam `password`.

## Correcao no mobile

O mobile passou a:

- guardar `userId` em `ArtistProfile`;
- ler `userId` vindo de `/api/artists`;
- usar `AuthStore.currentUser.artistId` como fonte principal;
- usar `userId` para resolver o artista quando uma sessao antiga ainda nao tem `artistId`;
- bloquear envio de mensagem/candidatura se nao conseguir identificar o artista logado;
- evitar fallback para o primeiro artista da lista;
- usar `artistId/userId` no perfil em vez de comparar e-mail com artista.

## Testes executados

Backend:

- `git status --branch --short`
- `git diff --check`
- `.\mvnw -v`
- Maven cacheado direto: `C:\Users\d-_-b\.m2\wrapper\dists\apache-maven-3.9.16\...\bin\mvn.cmd clean test`
- `docker compose down --remove-orphans`
- `docker compose up -d --build`
- `Invoke-RestMethod http://localhost:8080/health`
- POST `/auth/register`
- POST `/auth/login`
- GET `/api/artists`
- POST `/api/projects`
- POST `/api/projects/{projectId}/messages`

Mobile:

- `git status --branch --short`
- `git diff --check`
- `dart format` nos arquivos Dart alterados
- `dart analyze`
- tentativa de `flutter --version`
- tentativa de `flutter analyze`
- tentativa de `flutter test`
- tentativa de `flutter build apk --debug`

## Resultado do backend

- Maven wrapper `.\mvnw` falhou antes de iniciar Maven com `Cannot start maven from wrapper`.
- Causa diagnosticada: wrapper `only-script` 3.3.4 acessa `(Get-Item $MAVEN_M2_PATH).Target[0]`; em uma pasta `.m2` normal, `Target` vem nulo e o script quebra.
- Maven local `mvn` nao esta instalado no PATH.
- Maven ja existia no cache do wrapper e foi executado diretamente.
- `mvn clean test` pelo Maven cacheado passou com 10 testes, 0 falhas, 0 erros.
- Docker build/subida passou.
- `/health` respondeu `UP`.
- Register/login retornaram `artistId`.
- As respostas de auth nao retornaram `password`.
- O `artistId` retornado em auth existia na lista de artistas e pertencia ao mesmo `userId`.
- Mensagem criada via API retornou `senderArtistId` igual ao `artistId` autenticado.

## Resultado do Flutter

- `dart pub get` precisou de acesso ao pub.dev e concluiu com sucesso.
- `dart analyze` concluiu com `No issues found!`.
- `flutter.bat` continuou travando ate timeout para `--version`, `analyze`, `test` e `build apk --debug`.
- O travamento ocorre no tooling Flutter local, nao no analisador Dart, pois `dart --version`, `dart format`, `dart pub get` e `dart analyze` executaram corretamente.
- `dart test` nao e aplicavel diretamente porque os testes usam o ecossistema Flutter (`flutter_test`) e requerem o CLI Flutter.

## Resultado do teste integrado

O backend foi testado por HTTP real em `http://localhost:8080`:

- cadastro de Rafael Yukio retornou `userId` e `artistId`;
- login retornou o mesmo `artistId`;
- `/api/artists` confirmou artista com `id == artistId` e `userId == userId`;
- criacao de mensagem retornou `senderArtistId` igual ao artista autenticado.

Nao foi possivel automatizar o fluxo no emulador porque o Computer Use falhou ao inicializar e o `flutter.bat` travou. O teste manual esperado no app e:

1. subir o backend com `docker compose up -d --build`;
2. rodar o app com API real;
3. fazer logout/login como Rafael Yukio;
4. enviar nova mensagem em Comunicacao;
5. confirmar que a mensagem nova aparece como Rafael Yukio;
6. login com outro usuario;
7. enviar mensagem;
8. confirmar que o autor muda para o outro usuario.

Mensagens antigas gravadas com autor errado continuam antigas no banco. A correcao afeta novas mensagens.

## Limitacoes

- O CLI Flutter local precisa ser corrigido fora da alteracao de codigo; ele trava antes de retornar versao.
- O Computer Use nao conseguiu listar janelas do Android Studio por erro de runtime do plugin.
- O modo mock nao foi removido nem alterado diretamente. No estado atual do `mobile/lib`, nao foi encontrado `USE_MOCKS` por busca textual, entao essa capacidade deve ser confirmada pelo historico/arquivos de configuracao do app antes de apresentar como validada via CLI.

## Evidencias recomendadas

- Print do `/health` com status `UP`.
- Print do JSON de `/auth/login` mostrando `artistId`.
- Print de `/api/artists` mostrando o artista com mesmo `userId`.
- Print da tela de Comunicacao com nova mensagem enviada pelo usuario correto.
- Print dos logs do backend mostrando POST de auth e messages.

## Como testar manualmente

Backend:

```powershell
cd "C:\Users\d-_-b\Documents\ambos harmocrews\api-harmocrew"
docker compose down --remove-orphans
docker compose up -d --build
Invoke-RestMethod http://localhost:8080/health
```

Mobile:

```powershell
cd "C:\Users\d-_-b\Documents\ambos harmocrews\harmoCrew\mobile"
flutter run --dart-define=USE_MOCKS=false --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Depois faca logout/login para renovar a sessao e receber o `artistId` novo do backend.
