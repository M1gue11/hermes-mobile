# Inventário estático de comandos — Hermes v0.22.5

Fonte: `hermes_cli/commands.py` e `tui_gateway/command_discovery.py`, tag
`v0.22.5` (`56b6a31fededdf7364e1a0a79548d144e7fd81a3`), do Hermes Agent.
Leitura estática por AST, sem executar o runtime.

O registro contém **104 comandos canônicos**. Aliases não contam como comandos adicionais.

A coluna de plataformas reflete `cli_only` e `gateway_config_gate`; permissões,
plataformas específicas e argumentos ainda podem restringir a execução. O catálogo
TUI exclui `gateway_only` e seus comandos ocultos. Skills, bundles, quick commands e
plugins são descobertos por perfil e sessão em tempo de execução, não copiados desta tabela.

O Mobile consulta o catálogo do servidor: esta tabela é documentação de diferenças,
não uma allowlist nem promessa de paridade literal com Telegram. A admissão final é do Hermes.

| Categoria | Comando | Aliases | Plataformas de mensagem | Mobile |
|---|---|---|---|---|
| Configuration | `/approvals` | — | Sim | Gateway; sujeito à capacidade da sessão |
| Configuration | `/autoprune` | — | Sim | Gateway; sujeito à capacidade da sessão |
| Configuration | `/battery` | — | Não (CLI) | Gateway; sujeito à capacidade da sessão |
| Configuration | `/busy` | — | Sim | Terminal; execução indisponível |
| Configuration | `/codex-runtime` | /codex_runtime | Sim | Gateway; sujeito à capacidade da sessão |
| Configuration | `/config` | — | Não (CLI) | Gateway; sujeito à capacidade da sessão |
| Configuration | `/export` | — | Não (CLI) | Gateway; sujeito à capacidade da sessão |
| Configuration | `/fast` | — | Sim | Gateway; sujeito à capacidade da sessão |
| Configuration | `/focus` | — | Não (CLI) | Gateway; sujeito à capacidade da sessão |
| Configuration | `/footer` | — | Sim | Terminal; execução indisponível |
| Configuration | `/import` | — | Não (CLI) | Gateway; sujeito à capacidade da sessão |
| Configuration | `/indicator` | — | Não (CLI) | Terminal; execução indisponível |
| Configuration | `/model` | — | Sim | Controle nativo do Mobile (sem argumentos) |
| Configuration | `/personality` | — | Sim | Gateway; sujeito à capacidade da sessão |
| Configuration | `/reasoning` | — | Sim | Gateway; sujeito à capacidade da sessão |
| Configuration | `/skin` | — | Não (CLI) | Gateway; sujeito à capacidade da sessão |
| Configuration | `/statusbar` | /sb | Não (CLI) | Terminal; execução indisponível |
| Configuration | `/timestamps` | /ts | Não (CLI) | Gateway; sujeito à capacidade da sessão |
| Configuration | `/verbose` | — | Conforme configuração | Terminal; execução indisponível |
| Configuration | `/voice` | — | Sim | Gateway; sujeito à capacidade da sessão |
| Configuration | `/wake` | — | Não (CLI) | Gateway; sujeito à capacidade da sessão |
| Configuration | `/yolo` | — | Sim | Gateway; sujeito à capacidade da sessão |
| Exit | `/quit` | /exit | Não (CLI) | Terminal; execução indisponível |
| Info | `/commands` | — | Sim | Só plataformas de mensagem |
| Info | `/copy` | — | Não (CLI) | Terminal; execução indisponível |
| Info | `/debug` | — | Sim | Gateway; sujeito à capacidade da sessão |
| Info | `/diff` | — | Sim | Gateway; sujeito à capacidade da sessão |
| Info | `/help` | — | Sim | Gateway; sujeito à capacidade da sessão |
| Info | `/image` | — | Não (CLI) | Terminal; execução indisponível |
| Info | `/insights` | — | Sim | Gateway; sujeito à capacidade da sessão |
| Info | `/login` | — | Sim | Gateway; sujeito à capacidade da sessão |
| Info | `/palette` | — | Não (CLI) | Gateway; sujeito à capacidade da sessão |
| Info | `/paste` | — | Não (CLI) | Terminal; execução indisponível |
| Info | `/platform` | — | Sim | Só plataformas de mensagem |
| Info | `/platforms` | /gateway | Não (CLI) | Terminal; execução indisponível |
| Info | `/profile` | — | Sim | Gateway; sujeito à capacidade da sessão |
| Info | `/subscription` | /upgrade | Não (CLI) | Gateway; sujeito à capacidade da sessão |
| Info | `/topup` | — | Sim | Gateway; sujeito à capacidade da sessão |
| Info | `/update` | — | Sim | Terminal; execução indisponível |
| Info | `/usage` | — | Sim | Gateway; sujeito à capacidade da sessão |
| Info | `/version` | /v | Sim | Gateway; sujeito à capacidade da sessão |
| Info | `/whoami` | — | Sim | Gateway; sujeito à capacidade da sessão |
| Session | `/agents` | /tasks | Sim | Gateway; sujeito à capacidade da sessão |
| Session | `/approve` | — | Sim | Só plataformas de mensagem |
| Session | `/bg` | — | Sim | Gateway; sujeito à capacidade da sessão |
| Session | `/branch` | /fork | Sim | Gateway; sujeito à capacidade da sessão |
| Session | `/btw` | — | Sim | Gateway; sujeito à capacidade da sessão |
| Session | `/clear` | — | Não (CLI) | Controle nativo do Mobile (sem argumentos) |
| Session | `/compress` | /compact | Sim | Gateway; sujeito à capacidade da sessão |
| Session | `/context` | /ctx | Sim | Gateway; sujeito à capacidade da sessão |
| Session | `/deny` | — | Sim | Só plataformas de mensagem |
| Session | `/discard` | — | Sim | Só plataformas de mensagem |
| Session | `/egress` | — | Sim | Gateway; sujeito à capacidade da sessão |
| Session | `/goal` | — | Sim | Gateway; sujeito à capacidade da sessão |
| Session | `/handoff` | — | Não (CLI) | Gateway; sujeito à capacidade da sessão |
| Session | `/heartbeat` | /hb | Sim | Gateway; sujeito à capacidade da sessão |
| Session | `/history` | — | Não (CLI) | Gateway; sujeito à capacidade da sessão |
| Session | `/journey` | /learning, /memory-graph | Não (CLI) | Gateway; sujeito à capacidade da sessão |
| Session | `/loop` | /proactive | Sim | Gateway; sujeito à capacidade da sessão |
| Session | `/moa` | — | Sim | Gateway; sujeito à capacidade da sessão |
| Session | `/new` | /reset | Sim | Controle nativo do Mobile (sem argumentos) |
| Session | `/pause` | — | Sim | Só plataformas de mensagem |
| Session | `/plan` | — | Sim | Gateway; sujeito à capacidade da sessão |
| Session | `/prompt` | /compose | Não (CLI) | Gateway; sujeito à capacidade da sessão |
| Session | `/queue` | /q | Sim | Gateway; sujeito à capacidade da sessão |
| Session | `/redraw` | — | Não (CLI) | Terminal; execução indisponível |
| Session | `/refine` | — | Sim | Gateway; sujeito à capacidade da sessão |
| Session | `/restart` | — | Sim | Só plataformas de mensagem |
| Session | `/resume` | — | Sim | Gateway; sujeito à capacidade da sessão |
| Session | `/retry` | — | Sim | Gateway; sujeito à capacidade da sessão |
| Session | `/review` | — | Sim | Gateway; sujeito à capacidade da sessão |
| Session | `/rollback` | — | Sim | Gateway; sujeito à capacidade da sessão |
| Session | `/save` | — | Sim | Gateway; sujeito à capacidade da sessão |
| Session | `/sessions` | — | Sim | Controle nativo do Mobile (sem argumentos) |
| Session | `/sethome` | /set-home | Sim | Só plataformas de mensagem |
| Session | `/snapshot` | /snap | Não (CLI) | Terminal; execução indisponível |
| Session | `/start` | — | Sim | Só plataformas de mensagem |
| Session | `/status` | — | Sim | Gateway; sujeito à capacidade da sessão |
| Session | `/steer` | /s | Sim | Gateway; sujeito à capacidade da sessão |
| Session | `/stop` | — | Sim | Controle nativo do Mobile (sem argumentos) |
| Session | `/subgoal` | — | Sim | Gateway; sujeito à capacidade da sessão |
| Session | `/title` | — | Sim | Gateway; sujeito à capacidade da sessão |
| Session | `/topic` | — | Sim | Só plataformas de mensagem |
| Session | `/undo` | — | Sim | Gateway; sujeito à capacidade da sessão |
| Session | `/worktree` | — | Não (CLI) | Terminal; execução indisponível |
| Tools & Skills | `/blueprint` | /bp | Sim | Gateway; sujeito à capacidade da sessão |
| Tools & Skills | `/browser` | — | Não (CLI) | Gateway; sujeito à capacidade da sessão |
| Tools & Skills | `/bundles` | — | Sim | Gateway; sujeito à capacidade da sessão |
| Tools & Skills | `/cron` | — | Não (CLI) | Terminal; execução indisponível |
| Tools & Skills | `/curator` | — | Sim | Gateway; sujeito à capacidade da sessão |
| Tools & Skills | `/hatch` | /generate-pet | Não (CLI) | Gateway; sujeito à capacidade da sessão |
| Tools & Skills | `/init` | — | Sim | Gateway; sujeito à capacidade da sessão |
| Tools & Skills | `/kanban` | — | Sim | Gateway; sujeito à capacidade da sessão |
| Tools & Skills | `/learn` | — | Sim | Gateway; sujeito à capacidade da sessão |
| Tools & Skills | `/memory` | — | Sim | Gateway; sujeito à capacidade da sessão |
| Tools & Skills | `/pet` | — | Não (CLI) | Gateway; sujeito à capacidade da sessão |
| Tools & Skills | `/plugins` | — | Não (CLI) | Terminal; execução indisponível |
| Tools & Skills | `/reload` | — | Não (CLI) | Terminal; execução indisponível |
| Tools & Skills | `/reload-mcp` | /reload_mcp | Sim | Gateway; sujeito à capacidade da sessão |
| Tools & Skills | `/reload-skills` | /reload_skills | Sim | Gateway; sujeito à capacidade da sessão |
| Tools & Skills | `/skills` | — | Conforme configuração | Gateway; sujeito à capacidade da sessão |
| Tools & Skills | `/suggestions` | /suggest | Sim | Gateway; sujeito à capacidade da sessão |
| Tools & Skills | `/tools` | — | Não (CLI) | Gateway; sujeito à capacidade da sessão |
| Tools & Skills | `/toolsets` | — | Não (CLI) | Terminal; execução indisponível |
