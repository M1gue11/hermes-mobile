# Hermes Mobile

Hermes Mobile é um cliente Flutter experimental e não oficial para interagir com
o agente Hermes em dispositivos móveis. O projeto explora conversas, streaming,
histórico e integrações documentadas do Hermes. Não é distribuído nem mantido
como aplicativo estável, e compatibilidade entre versões do Hermes não é
garantida.

## Requisitos

- Flutter SDK compatível com Dart `^3.12.2` (ver `environment` em `pubspec.yaml`).
- Um dispositivo ou emulador Android para executar o cliente. O projeto também
  contém suporte Flutter para iOS, mas o fluxo de desenvolvimento documentado
  aqui é Android.
- Acesso a uma instalação Hermes configurada pelo próprio usuário. O app não
  inclui servidor, conta de demonstração ou endpoint público.

## Começar

Na raiz do repositório:

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

`flutter analyze` e `flutter test` são os comandos de análise e teste existentes
do projeto. Para gerar uma build local de depuração Android, use
`flutter build apk --debug`. Não há canal de distribuição ou build de release
suportado neste momento.

## Arquitetura

O app é organizado em camadas Flutter/Dart:

- `lib/features/` contém telas e controladores de interface.
- `lib/domain/` define modelos e contratos de repositório.
- `lib/data/` implementa acesso às APIs e adaptadores de dados.
- `lib/core/` reúne configuração, navegação, rede e componentes transversais.

Riverpod fornece estado e injeção de dependências; `go_router` organiza as rotas.
O cliente usa APIs HTTP do Hermes e o gateway TUI para recursos de chat ao vivo.
Os contratos e as limitações observadas estão em [`docs/hermes-api/`](docs/hermes-api/)
e [`docs/dashboard-api/`](docs/dashboard-api/).

## Segurança e limites

O cliente lida com conteúdo e credenciais de uma instalação Hermes escolhida
por cada usuário. Tokens, cookies, tickets e chaves não devem ser incluídos em
logs, issues, screenshots, testes ou documentação. Use armazenamento seguro do
sistema para segredos e revise cuidadosamente qualquer dado antes de compartilhá-lo.

O suporte de segurança é limitado ao código disponível neste repositório; não
há garantia de resposta, atualização ou correção em prazo específico. O Hermes
Mobile não declara auditoria independente, compatibilidade estável ou aptidão
para uso crítico. Integrações e contratos podem mudar conforme evoluem o cliente
e o Hermes.

## Licença

O código e os ícones/splash criados pelo mantenedor com Claude Design são
disponibilizados sob a [licença MIT](LICENSE). Dependências, fontes e demais
materiais de terceiros mantêm suas respectivas licenças; consulte os
[avisos de terceiros](THIRD_PARTY_NOTICES.md). A licença deste repositório não
substitui os direitos desses materiais.

## Contribuir

Consulte [`CONTRIBUTING.md`](CONTRIBUTING.md) para orientações de desenvolvimento
e [`SECURITY.md`](SECURITY.md) para reportar vulnerabilidades.
