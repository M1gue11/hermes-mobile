# Contribuir

Contribuições para o Hermes Mobile são bem-vindas. O projeto é experimental e
seus contratos podem mudar; leia o README e os documentos de API relevantes
antes de propor alterações.

## Desenvolvimento

1. Instale uma versão do Flutter compatível com Dart `^3.12.2`.
2. Execute `flutter pub get`.
3. Antes de enviar uma alteração, execute `flutter analyze` e `flutter test`.
4. Descreva claramente o comportamento alterado e os comandos executados.

Organize mudanças de interface em `lib/features/`, regras e contratos em
`lib/domain/`, integrações em `lib/data/` e componentes transversais em
`lib/core/`. Evite adicionar dependências sem necessidade demonstrável e
preserve a separação entre interface, domínio e acesso a dados.

Não inclua credenciais, dados pessoais, logs brutos de sessão ou capturas com
conteúdo privado. Use valores fictícios e domínios reservados, como
`example.com`, em exemplos e fixtures.
