#!/usr/bin/env python3
"""Gera a referência REST do Dashboard a partir do snapshot OpenAPI versionado."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
from typing import Any


ROOT = Path(__file__).resolve().parent.parent
DEFAULT_SNAPSHOT = ROOT / "docs/dashboard-api/openapi-0.18.2.json"
OUTPUT = ROOT / "docs/dashboard-api/endpoint-reference.md"
METHODS = ("get", "put", "post", "delete", "patch", "head", "options", "trace")
PUBLIC_BOOTSTRAP = {
    "/login", "/auth/login", "/auth/callback", "/auth/password-login", "/auth/logout",
    "/api/auth/providers",
}
SESSION_EXEMPT_APIS = {
    "/api/status", "/api/config/defaults", "/api/config/schema", "/api/model/info",
    "/api/dashboard/themes", "/api/dashboard/plugins", "/api/cron/fire",
}


def dereference(value: Any, components: dict[str, Any]) -> Any:
    """Resolve somente referências locais de parâmetros, corpos e respostas."""
    if not isinstance(value, dict) or "$ref" not in value:
        return value
    ref = value["$ref"]
    if not ref.startswith("#/components/"):
        return value
    current: Any = components
    for part in ref.removeprefix("#/components/").split("/"):
        if not isinstance(current, dict) or part not in current:
            return value
        current = current[part]
    return current


def schema_text(schema: Any) -> str:
    if not schema:
        return "não especificado (schema vazio)"
    if not isinstance(schema, dict):
        return "não especificado"
    if "$ref" in schema:
        return "`" + schema["$ref"].rsplit("/", 1)[-1] + "`"
    parts: list[str] = []
    if "type" in schema:
        parts.append("tipo=" + str(schema["type"]))
    if "format" in schema:
        parts.append("formato=" + str(schema["format"]))
    if "enum" in schema:
        parts.append("enum=" + json.dumps(schema["enum"], ensure_ascii=False, sort_keys=True))
    if "const" in schema:
        parts.append("const=" + json.dumps(schema["const"], ensure_ascii=False, sort_keys=True))
    if "default" in schema:
        parts.append("padrão=" + json.dumps(schema["default"], ensure_ascii=False, sort_keys=True))
    for keyword in ("anyOf", "oneOf", "allOf"):
        if keyword in schema:
            parts.append(keyword + "=" + " | ".join(schema_text(item) for item in schema[keyword]))
    if "items" in schema:
        parts.append("itens=(" + schema_text(schema["items"]) + ")")
    if "additionalProperties" in schema:
        value = schema["additionalProperties"]
        parts.append("propriedades adicionais=" + schema_text(value) if isinstance(value, dict) else "propriedades adicionais=" + str(value).lower())
    return "; ".join(parts) if parts else "não especificado"


def cell(value: str) -> str:
    return value.replace("|", "\\|").replace("\n", " ")


def group_for(path: str) -> str:
    pieces = [part for part in path.split("/") if part]
    if not pieces:
        return "Raiz"
    if pieces[0] == "api" and len(pieces) > 1:
        return "/api/" + pieces[1]
    if pieces[0] == "dashboard-plugins":
        return "/dashboard-plugins"
    if pieces[0] in {"login", "auth"}:
        return "Autenticação e bootstrap"
    return "/" + pieces[0]


def auth_note(path: str, operation: dict[str, Any], path_item: dict[str, Any]) -> str:
    declared = operation.get("security", path_item.get("security"))
    openapi_note = "não especificada" if declared is None else "declarada no snapshot"
    if path in PUBLIC_BOOTSTRAP:
        return f"Fluxo público de bootstrap nesta implantação. Segurança OpenAPI: {openapi_note}."
    if path == "/api/cron/fire":
        return ("Exceção ao gate de sessão: exige autenticação JWT própria; não é rota de app mobile. "
                f"Segurança OpenAPI: {openapi_note}.")
    if path in SESSION_EXEMPT_APIS:
        return f"Allowlist do gate de sessão nesta implantação. Segurança OpenAPI: {openapi_note}."
    if path == "/{full_path}":
        return ("Rota curinga: assets são exceção pública do gate, mas o snapshot não permite "
                "classificar um `full_path` individual como asset. Não inferir publicidade. "
                f"Segurança OpenAPI: {openapi_note}.")
    suffix = " Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`." if path.startswith("/api/") else ""
    return ("Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. "
            f"Segurança OpenAPI: {openapi_note}." + suffix)


def content_rows(content: Any) -> list[tuple[str, str]]:
    if not isinstance(content, dict) or not content:
        return [("—", "sem conteúdo/schema especificado")]
    return [(str(media_type), schema_text(media.get("schema"))) for media_type, media in sorted(content.items())]


def render_operation(path: str, method: str, operation: dict[str, Any], path_item: dict[str, Any], components: dict[str, Any]) -> list[str]:
    lines = [f"### {method.upper()} {path}", ""]
    operation_id = operation.get("operationId", "não especificado")
    summary = operation.get("summary", "não especificado")
    lines += [f"- **Operation ID:** {operation_id}", f"- **Resumo:** {summary}", f"- **Autenticação:** {auth_note(path, operation, path_item)}", ""]
    parameters = []
    for raw in list(path_item.get("parameters", [])) + list(operation.get("parameters", [])):
        parameters.append(dereference(raw, components))
    if parameters:
        lines += ["#### Parâmetros", "", "| Nome | Local | Obrigatório | Schema / padrão |", "| --- | --- | --- | --- |"]
        for parameter in parameters:
            if not isinstance(parameter, dict):
                continue
            lines.append("| {name} | {where} | {required} | {schema} |".format(
                name=cell(str(parameter.get("name", "não especificado"))),
                where=cell(str(parameter.get("in", "não especificado"))),
                required="sim" if parameter.get("required") else "não",
                schema=cell(schema_text(parameter.get("schema"))),
            ))
        lines.append("")
    else:
        lines += ["#### Parâmetros", "", "Nenhum parâmetro especificado no snapshot.", ""]
    request_body = operation.get("requestBody")
    if request_body is not None:
        request_body = dereference(request_body, components)
        lines += ["#### Corpo da requisição", "", "Obrigatório: " + ("sim" if request_body.get("required") else "não") + ".", "", "| Content-Type | Schema |", "| --- | --- |"]
        for media_type, schema in content_rows(request_body.get("content")):
            lines.append(f"| {cell(media_type)} | {cell(schema)} |")
        lines.append("")
    else:
        lines += ["#### Corpo da requisição", "", "Nenhum corpo de requisição especificado no snapshot.", ""]
    lines += ["#### Respostas", "", "| Status | Content-Type | Schema |", "| --- | --- | --- |"]
    responses = operation.get("responses", {})
    for status, response in sorted(responses.items(), key=lambda item: item[0]):
        response = dereference(response, components)
        for media_type, schema in content_rows(response.get("content") if isinstance(response, dict) else None):
            lines.append(f"| {cell(str(status))} | {cell(media_type)} | {cell(schema)} |")
    lines.append("")
    return lines


def generate(document: dict[str, Any]) -> str:
    info = document.get("info", {})
    components = document.get("components", {})
    operations: list[tuple[str, str, dict[str, Any], dict[str, Any]]] = []
    for path, path_item in document.get("paths", {}).items():
        if not isinstance(path_item, dict):
            continue
        for method in METHODS:
            if isinstance(path_item.get(method), dict):
                operations.append((path, method, path_item[method], path_item))
    operations.sort(key=lambda item: (group_for(item[0]), item[0], METHODS.index(item[1])))
    lines = [
        "# Referência de endpoints REST do Dashboard",
        "",
        f"Gerado a partir de `openapi-{info.get('version', 'desconhecida')}.json` ({len(operations)} operações). Não edite este arquivo manualmente.",
        "",
        "O snapshot descreve REST; autenticação efetiva é a política da implantação em `:9119`, não uma inferência de `security` ausente. Veja `README.md` e `mobile-mapping.md` para escopo e decisão de produto.",
        "",
    ]
    current_group = None
    for path, method, operation, path_item in operations:
        group = group_for(path)
        if group != current_group:
            lines += [f"## {group}", ""]
            current_group = group
        lines.extend(render_operation(path, method, operation, path_item, components))
    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--snapshot",
        type=Path,
        default=DEFAULT_SNAPSHOT,
        help="caminho para o snapshot OpenAPI (padrão: docs/dashboard-api/openapi-0.18.2.json)",
    )
    parser.add_argument("--check", action="store_true", help="falha se o Markdown versionado estiver desatualizado")
    args = parser.parse_args()
    try:
        document = json.loads(args.snapshot.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        print(f"erro ao ler {args.snapshot}: {error}", file=sys.stderr)
        return 2
    generated = generate(document)
    if args.check:
        try:
            current = OUTPUT.read_text(encoding="utf-8")
        except OSError:
            current = ""
        if current != generated:
            print(f"desatualizado: execute python3 tools/generate_dashboard_contract_docs.py ({OUTPUT})", file=sys.stderr)
            return 1
        print(f"ok: {OUTPUT} está sincronizado com {args.snapshot}")
        return 0
    OUTPUT.write_text(generated, encoding="utf-8")
    print(f"gerado: {OUTPUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
