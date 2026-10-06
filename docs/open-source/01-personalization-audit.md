# Auditoria de preparação para abertura pública

> [!note]
> Registro histórico desta etapa. Posteriormente, o mantenedor escolheu MIT;
> consulte `LICENSE` e a seção Licença do `README.md` para o estado atual.

**Escopo:** documentação e exemplos rastreados na árvore de trabalho. Esta
revisão não altera código do app ou do Gateway, não escolhe licença e não audita
o histórico Git.

## Entregas desta etapa

- README reescrito para descrever o cliente Flutter experimental e seus limites.
- Guias de contribuição e reporte de segurança adicionados sem contatos privados.
- Referências pessoais, caminhos locais e exemplos de infraestrutura privada
  removidos da documentação selecionada.
- Registros operacionais e históricos sem valor geral removidos; contratos
  técnicos e snapshots de API foram preservados.

## Pendências antes de qualquer abertura pública

1. **Licença:** decisão e autorização dependem do mantenedor. Nenhuma licença foi
   escolhida nesta etapa.
2. **Histórico Git:** executar auditoria dedicada de commits, blobs e referências
   antigas; limpar a árvore atual não remove dados de versões anteriores.
3. **CI e release:** revisar pipelines, processo de publicação, artefatos e
   instruções de distribuição.
4. **Assinatura:** definir gestão e proteção do signer de release, sem publicar
   chaves privadas.
5. **Atribuições:** revisar licenças de dependências, fontes, ícones e demais
   assets antes de redistribuir builds.

## Limites

Esta auditoria não prova a ausência de segredos no histórico, nos artefatos de
build ou em serviços externos. Antes de alterar a visibilidade do projeto, o
mantenedor deve revisar esses itens e definir a estratégia de histórico e
publicação.
