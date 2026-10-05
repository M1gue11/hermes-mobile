#!/usr/bin/env python3
"""Valida os artefatos versionados do contrato do gateway TUI com stdlib."""

from __future__ import annotations

import json
from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[1]
SNAPSHOT = ROOT / "docs/dashboard-api/tui-gateway-contract-0.18.2.json"
DOCUMENTS = (
    ROOT / "docs/dashboard-api/README.md",
    ROOT / "docs/dashboard-api/websockets.md",
    ROOT / "docs/dashboard-api/tui-gateway-json-rpc.md",
    ROOT / "docs/dashboard-api/mobile-live-chat-plan.md",
    ROOT / "docs/hermes-api/04-runs-streaming.md",
)
MVP_METHODS = (
    "session.create",
    "session.list",
    "session.most_recent",
    "session.resume",
    "session.history",
    "prompt.submit",
    "session.steer",
    "session.interrupt",
    "clarify.respond",
    "approval.respond",
)


def fail(message: str) -> None:
    print(f"ERRO: {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    try:
        data = json.loads(SNAPSHOT.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"snapshot JSON inválido: {exc}")

    methods = data.get("methods")
    events = data.get("events_from_tui_readme")
    if not isinstance(methods, list) or len(methods) != 117:
        fail("esperados 117 métodos")
    if len(set(methods)) != 117:
        fail("métodos não são únicos")
    transport = data.get("transport")
    if not isinstance(transport, dict) or transport.get("framing") != "one JSON-RPC object per WebSocket text message":
        fail("framing deve exigir um objeto JSON-RPC por frame de texto")
    mvp_contract = data.get("mvp_observed_contract")
    if not isinstance(mvp_contract, dict) or mvp_contract.get("source") != "Observed in Hermes 0.18.2 source at source_commit; not OpenAPI.":
        fail("contrato MVP observado ausente ou sem procedência")
    mvp_methods = mvp_contract.get("methods")
    if not isinstance(mvp_methods, list) or tuple(item.get("method") for item in mvp_methods if isinstance(item, dict)) != MVP_METHODS:
        fail("contrato MVP deve conter exatamente os 10 métodos confirmados, na ordem registrada")
    if any(not isinstance(item.get("required_params"), list) or not isinstance(item.get("optional_params"), list) or not isinstance(item.get("result"), list) for item in mvp_methods):
        fail("métodos MVP devem declarar parâmetros e resultado observados")
    identifier_semantics = mvp_contract.get("identifier_semantics")
    if not isinstance(identifier_semantics, dict) or identifier_semantics.get("durable") != ["stored_session_id", "session_key"]:
        fail("semântica de identificadores duráveis ausente")
    if not isinstance(events, list) or len(events) != 37:
        fail("esperados 37 eventos")
    event_types = [event.get("type") for event in events if isinstance(event, dict)]
    if len(event_types) != 37 or len(set(event_types)) != 37 or any(not value for value in event_types):
        fail("eventos não são únicos ou não têm type")
    missing = [str(path.relative_to(ROOT)) for path in DOCUMENTS if not path.is_file()]
    if missing:
        fail("documentos ausentes: " + ", ".join(missing))
    contract = (ROOT / "docs/dashboard-api/tui-gateway-json-rpc.md").read_text(encoding="utf-8")
    missing_methods = [method for method in methods if f"`{method}`" not in contract]
    missing_events = [event_type for event_type in event_types if f"`{event_type}`" not in contract]
    if missing_methods:
        fail("métodos sem documentação: " + ", ".join(missing_methods))
    if missing_events:
        fail("eventos sem documentação: " + ", ".join(missing_events))
    for document in (
        ROOT / "docs/dashboard-api/tui-gateway-json-rpc.md",
        ROOT / "docs/dashboard-api/mobile-live-chat-plan.md",
    ):
        text = document.read_text(encoding="utf-8")
        if "## Contrato MVP observado no código" not in text:
            fail(f"seção de contrato MVP ausente: {document.relative_to(ROOT)}")
        if "Não é OpenAPI" not in text and "não é OpenAPI" not in text:
            fail(f"seção MVP deve declarar que não é OpenAPI: {document.relative_to(ROOT)}")
        missing_mvp_methods = [method for method in MVP_METHODS if f"`{method}`" not in text]
        if missing_mvp_methods:
            fail(f"métodos MVP sem documentação em {document.relative_to(ROOT)}: " + ", ".join(missing_mvp_methods))
    broken_links: list[str] = []
    for document in DOCUMENTS:
        text = document.read_text(encoding="utf-8")
        for target in re.findall(r"\[[^]]+\]\(([^)#]+)(?:#[^)]+)?\)", text):
            if "://" not in target and not (document.parent / target).resolve().is_file():
                broken_links.append(f"{document.relative_to(ROOT)} -> {target}")
    if broken_links:
        fail("links locais ausentes: " + "; ".join(broken_links))
    print("OK: JSON válido; 117 métodos e 37 eventos únicos/documentados; documentos e links locais presentes.")


if __name__ == "__main__":
    main()
