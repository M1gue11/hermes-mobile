# Referência de endpoints REST do Dashboard

Gerado a partir de `openapi-0.18.2.json` (269 operações). Não edite este arquivo manualmente.

O snapshot descreve REST; autenticação efetiva é a política da implantação em `:9119`, não uma inferência de `security` ausente. Veja `README.md` e `mobile-mapping.md` para escopo e decisão de produto.

## /api/actions

### GET /api/actions/{name}/status

- **Operation ID:** get_action_status_api_actions__name__status_get
- **Resumo:** Get Action Status
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| name | path | sim | tipo=string |
| lines | query | não | tipo=integer; padrão=200 |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

## /api/analytics

### GET /api/analytics/models

- **Operation ID:** get_models_analytics_api_analytics_models_get
- **Resumo:** Get Models Analytics
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| days | query | não | tipo=integer; padrão=30 |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/analytics/usage

- **Operation ID:** get_usage_analytics_api_analytics_usage_get
- **Resumo:** Get Usage Analytics
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| days | query | não | tipo=integer; padrão=30 |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

## /api/audio

### GET /api/audio/elevenlabs/voices

- **Operation ID:** get_elevenlabs_voices_api_audio_elevenlabs_voices_get
- **Resumo:** Get Elevenlabs Voices
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

### POST /api/audio/speak

- **Operation ID:** speak_text_api_audio_speak_post
- **Resumo:** Speak Text
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `TTSSpeakRequest` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/audio/transcribe

- **Operation ID:** transcribe_audio_upload_api_audio_transcribe_post
- **Resumo:** Transcribe Audio Upload
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `AudioTranscriptionRequest` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

## /api/auth

### GET /api/auth/me

- **Operation ID:** auth_me_api_auth_me_get
- **Resumo:** Auth Me
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

### GET /api/auth/providers

- **Operation ID:** auth_providers_api_auth_providers_get
- **Resumo:** Auth Providers
- **Autenticação:** Fluxo público de bootstrap nesta implantação. Segurança OpenAPI: não especificada.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado |

### POST /api/auth/ws-ticket

- **Operation ID:** auth_ws_ticket_api_auth_ws_ticket_post
- **Resumo:** Auth Ws Ticket
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

## /api/chat

### POST /api/chat/image-upload

- **Operation ID:** upload_chat_image_api_chat_image_upload_post
- **Resumo:** Upload Chat Image
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `ChatImageUpload` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

## /api/config

### GET /api/config

- **Operation ID:** get_config_api_config_get
- **Resumo:** Get Config
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### PUT /api/config

- **Operation ID:** update_config_api_config_put
- **Resumo:** Update Config
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `ConfigUpdate` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/config/defaults

- **Operation ID:** get_defaults_api_config_defaults_get
- **Resumo:** Get Defaults
- **Autenticação:** Allowlist do gate de sessão nesta implantação. Segurança OpenAPI: não especificada.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

### GET /api/config/raw

- **Operation ID:** get_config_raw_api_config_raw_get
- **Resumo:** Get Config Raw
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### PUT /api/config/raw

- **Operation ID:** update_config_raw_api_config_raw_put
- **Resumo:** Update Config Raw
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `RawConfigUpdate` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/config/schema

- **Operation ID:** get_schema_api_config_schema_get
- **Resumo:** Get Schema
- **Autenticação:** Allowlist do gate de sessão nesta implantação. Segurança OpenAPI: não especificada.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

## /api/credentials

### GET /api/credentials/pool

- **Operation ID:** list_credential_pool_api_credentials_pool_get
- **Resumo:** List Credential Pool
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

### POST /api/credentials/pool

- **Operation ID:** add_credential_pool_entry_api_credentials_pool_post
- **Resumo:** Add Credential Pool Entry
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `CredentialPoolAdd` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### DELETE /api/credentials/pool/{provider}/{index}

- **Operation ID:** remove_credential_pool_entry_api_credentials_pool__provider___index__delete
- **Resumo:** Remove Credential Pool Entry
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| provider | path | sim | tipo=string |
| index | path | sim | tipo=integer |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

## /api/cron

### GET /api/cron/blueprints

- **Operation ID:** list_cron_blueprints_api_cron_blueprints_get
- **Resumo:** List Cron Blueprints
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

### POST /api/cron/blueprints/instantiate

- **Operation ID:** instantiate_blueprint_api_cron_blueprints_instantiate_post
- **Resumo:** Instantiate Blueprint
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile | query | não | tipo=string; padrão="default" |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `AutomationBlueprintInstantiate` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/cron/delivery-targets

- **Operation ID:** get_cron_delivery_targets_api_cron_delivery_targets_get
- **Resumo:** Get Cron Delivery Targets
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

### POST /api/cron/fire

- **Operation ID:** cron_fire_webhook_api_cron_fire_post
- **Resumo:** Cron Fire Webhook
- **Autenticação:** Exceção ao gate de sessão: exige autenticação JWT própria; não é rota de app mobile. Segurança OpenAPI: não especificada.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

### GET /api/cron/jobs

- **Operation ID:** list_cron_jobs_api_cron_jobs_get
- **Resumo:** List Cron Jobs
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile | query | não | tipo=string; padrão="all" |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/cron/jobs

- **Operation ID:** create_cron_job_api_cron_jobs_post
- **Resumo:** Create Cron Job
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile | query | não | tipo=string; padrão="default" |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `CronJobCreate` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/cron/jobs/{job_id}

- **Operation ID:** get_cron_job_api_cron_jobs__job_id__get
- **Resumo:** Get Cron Job
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| job_id | path | sim | tipo=string |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### PUT /api/cron/jobs/{job_id}

- **Operation ID:** update_cron_job_api_cron_jobs__job_id__put
- **Resumo:** Update Cron Job
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| job_id | path | sim | tipo=string |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `CronJobUpdate` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### DELETE /api/cron/jobs/{job_id}

- **Operation ID:** delete_cron_job_api_cron_jobs__job_id__delete
- **Resumo:** Delete Cron Job
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| job_id | path | sim | tipo=string |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/cron/jobs/{job_id}/pause

- **Operation ID:** pause_cron_job_api_cron_jobs__job_id__pause_post
- **Resumo:** Pause Cron Job
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| job_id | path | sim | tipo=string |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/cron/jobs/{job_id}/resume

- **Operation ID:** resume_cron_job_api_cron_jobs__job_id__resume_post
- **Resumo:** Resume Cron Job
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| job_id | path | sim | tipo=string |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/cron/jobs/{job_id}/runs

- **Operation ID:** list_cron_job_runs_api_cron_jobs__job_id__runs_get
- **Resumo:** List Cron Job Runs
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| job_id | path | sim | tipo=string |
| profile | query | não | anyOf=tipo=string \| tipo=null |
| limit | query | não | tipo=integer; padrão=20 |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/cron/jobs/{job_id}/trigger

- **Operation ID:** trigger_cron_job_api_cron_jobs__job_id__trigger_post
- **Resumo:** Trigger Cron Job
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| job_id | path | sim | tipo=string |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

## /api/curator

### GET /api/curator

- **Operation ID:** get_curator_status_api_curator_get
- **Resumo:** Get Curator Status
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

### PUT /api/curator/paused

- **Operation ID:** set_curator_paused_api_curator_paused_put
- **Resumo:** Set Curator Paused
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `CuratorPause` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/curator/run

- **Operation ID:** run_curator_api_curator_run_post
- **Resumo:** Run Curator
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

## /api/dashboard

### POST /api/dashboard/agent-plugins/install

- **Operation ID:** post_agent_plugin_install_api_dashboard_agent_plugins_install_post
- **Resumo:** Post Agent Plugin Install
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `_AgentPluginInstallBody` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### DELETE /api/dashboard/agent-plugins/{name}

- **Operation ID:** delete_agent_plugin_api_dashboard_agent_plugins__name__delete
- **Resumo:** Delete Agent Plugin
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| name | path | sim | tipo=string |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/dashboard/agent-plugins/{name}/disable

- **Operation ID:** post_agent_plugin_disable_api_dashboard_agent_plugins__name__disable_post
- **Resumo:** Post Agent Plugin Disable
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| name | path | sim | tipo=string |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/dashboard/agent-plugins/{name}/enable

- **Operation ID:** post_agent_plugin_enable_api_dashboard_agent_plugins__name__enable_post
- **Resumo:** Post Agent Plugin Enable
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| name | path | sim | tipo=string |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/dashboard/agent-plugins/{name}/update

- **Operation ID:** post_agent_plugin_update_api_dashboard_agent_plugins__name__update_post
- **Resumo:** Post Agent Plugin Update
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| name | path | sim | tipo=string |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/dashboard/font

- **Operation ID:** get_dashboard_font_api_dashboard_font_get
- **Resumo:** Get Dashboard Font
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

### PUT /api/dashboard/font

- **Operation ID:** set_dashboard_font_api_dashboard_font_put
- **Resumo:** Set Dashboard Font
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `FontSetBody` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### PUT /api/dashboard/plugin-providers

- **Operation ID:** put_plugin_providers_api_dashboard_plugin_providers_put
- **Resumo:** Put Plugin Providers
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `_PluginProvidersPutBody` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/dashboard/plugins

- **Operation ID:** get_dashboard_plugins_api_dashboard_plugins_get
- **Resumo:** Get Dashboard Plugins
- **Autenticação:** Allowlist do gate de sessão nesta implantação. Segurança OpenAPI: não especificada.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

### GET /api/dashboard/plugins/hub

- **Operation ID:** get_plugins_hub_api_dashboard_plugins_hub_get
- **Resumo:** Get Plugins Hub
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

### GET /api/dashboard/plugins/rescan

- **Operation ID:** rescan_dashboard_plugins_api_dashboard_plugins_rescan_get
- **Resumo:** Rescan Dashboard Plugins
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

### POST /api/dashboard/plugins/{name}/visibility

- **Operation ID:** post_plugin_visibility_api_dashboard_plugins__name__visibility_post
- **Resumo:** Post Plugin Visibility
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| name | path | sim | tipo=string |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `_PluginVisibilityBody` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### PUT /api/dashboard/theme

- **Operation ID:** set_dashboard_theme_api_dashboard_theme_put
- **Resumo:** Set Dashboard Theme
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `ThemeSetBody` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/dashboard/themes

- **Operation ID:** get_dashboard_themes_api_dashboard_themes_get
- **Resumo:** Get Dashboard Themes
- **Autenticação:** Allowlist do gate de sessão nesta implantação. Segurança OpenAPI: não especificada.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

## /api/env

### GET /api/env

- **Operation ID:** get_env_vars_api_env_get
- **Resumo:** Get Env Vars
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### PUT /api/env

- **Operation ID:** set_env_var_api_env_put
- **Resumo:** Set Env Var
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `EnvVarUpdate` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### DELETE /api/env

- **Operation ID:** remove_env_var_api_env_delete
- **Resumo:** Remove Env Var
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `EnvVarDelete` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/env/reveal

- **Operation ID:** reveal_env_var_api_env_reveal_post
- **Resumo:** Reveal Env Var
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `EnvVarReveal` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

## /api/files

### GET /api/files

- **Operation ID:** list_managed_files_api_files_get
- **Resumo:** List Managed Files
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| path | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### DELETE /api/files

- **Operation ID:** delete_managed_file_api_files_delete
- **Resumo:** Delete Managed File
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `ManagedFileDelete` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/files/download

- **Operation ID:** download_managed_file_api_files_download_get
- **Resumo:** Download Managed File
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| path | query | sim | tipo=string |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/files/mkdir

- **Operation ID:** create_managed_directory_api_files_mkdir_post
- **Resumo:** Create Managed Directory
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `ManagedDirectoryCreate` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/files/read

- **Operation ID:** read_managed_file_api_files_read_get
- **Resumo:** Read Managed File
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| path | query | sim | tipo=string |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/files/upload

- **Operation ID:** upload_managed_file_api_files_upload_post
- **Resumo:** Upload Managed File
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `ManagedFileUpload` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/files/upload-stream

- **Operation ID:** upload_managed_file_stream_api_files_upload_stream_post
- **Resumo:** Upload Managed File Stream
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| multipart/form-data | `Body_upload_managed_file_stream_api_files_upload_stream_post` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

## /api/fs

### GET /api/fs/default-cwd

- **Operation ID:** fs_default_cwd_api_fs_default_cwd_get
- **Resumo:** Fs Default Cwd
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

### GET /api/fs/git-root

- **Operation ID:** fs_git_root_api_fs_git_root_get
- **Resumo:** Fs Git Root
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| path | query | sim | tipo=string |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/fs/list

- **Operation ID:** fs_list_api_fs_list_get
- **Resumo:** Fs List
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| path | query | sim | tipo=string |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/fs/read-data-url

- **Operation ID:** fs_read_data_url_api_fs_read_data_url_get
- **Resumo:** Fs Read Data Url
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| path | query | sim | tipo=string |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/fs/read-text

- **Operation ID:** fs_read_text_api_fs_read_text_get
- **Resumo:** Fs Read Text
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| path | query | sim | tipo=string |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/fs/write-text

- **Operation ID:** fs_write_text_api_fs_write_text_post
- **Resumo:** Fs Write Text
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `FsWriteText` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

## /api/gateway

### POST /api/gateway/drain

- **Operation ID:** gateway_drain_api_gateway_drain_post
- **Resumo:** Gateway Drain
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

### POST /api/gateway/restart

- **Operation ID:** restart_gateway_api_gateway_restart_post
- **Resumo:** Restart Gateway
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/gateway/start

- **Operation ID:** start_gateway_api_gateway_start_post
- **Resumo:** Start Gateway
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/gateway/stop

- **Operation ID:** stop_gateway_api_gateway_stop_post
- **Resumo:** Stop Gateway
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

## /api/git

### GET /api/git/base-branches

- **Operation ID:** git_base_branches_route_api_git_base_branches_get
- **Resumo:** Git Base Branches Route
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| path | query | sim | tipo=string |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/git/branch/switch

- **Operation ID:** git_branch_switch_route_api_git_branch_switch_post
- **Resumo:** Git Branch Switch Route
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `GitBranchSwitchBody` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/git/branches

- **Operation ID:** git_branches_route_api_git_branches_get
- **Resumo:** Git Branches Route
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| path | query | sim | tipo=string |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/git/file-diff

- **Operation ID:** git_file_diff_route_api_git_file_diff_get
- **Resumo:** Git File Diff Route
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| path | query | sim | tipo=string |
| file | query | sim | tipo=string |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/git/review/commit

- **Operation ID:** git_commit_route_api_git_review_commit_post
- **Resumo:** Git Commit Route
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `GitCommitBody` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/git/review/commit-context

- **Operation ID:** git_commit_context_route_api_git_review_commit_context_get
- **Resumo:** Git Commit Context Route
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| path | query | sim | tipo=string |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/git/review/create-pr

- **Operation ID:** git_create_pr_route_api_git_review_create_pr_post
- **Resumo:** Git Create Pr Route
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `GitPathBody` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/git/review/diff

- **Operation ID:** git_review_diff_route_api_git_review_diff_get
- **Resumo:** Git Review Diff Route
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| path | query | sim | tipo=string |
| file | query | sim | tipo=string |
| scope | query | não | tipo=string; padrão="uncommitted" |
| base | query | não | anyOf=tipo=string \| tipo=null |
| staged | query | não | tipo=boolean; padrão=false |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/git/review/list

- **Operation ID:** git_review_list_route_api_git_review_list_get
- **Resumo:** Git Review List Route
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| path | query | sim | tipo=string |
| scope | query | não | tipo=string; padrão="uncommitted" |
| base | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/git/review/push

- **Operation ID:** git_push_route_api_git_review_push_post
- **Resumo:** Git Push Route
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `GitPathBody` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/git/review/rev-parse

- **Operation ID:** git_rev_parse_route_api_git_review_rev_parse_get
- **Resumo:** Git Rev Parse Route
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| path | query | sim | tipo=string |
| ref | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/git/review/revert

- **Operation ID:** git_revert_route_api_git_review_revert_post
- **Resumo:** Git Revert Route
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `GitFileBody` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/git/review/ship-info

- **Operation ID:** git_ship_info_route_api_git_review_ship_info_get
- **Resumo:** Git Ship Info Route
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| path | query | sim | tipo=string |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/git/review/stage

- **Operation ID:** git_stage_route_api_git_review_stage_post
- **Resumo:** Git Stage Route
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `GitFileBody` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/git/review/unstage

- **Operation ID:** git_unstage_route_api_git_review_unstage_post
- **Resumo:** Git Unstage Route
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `GitFileBody` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/git/status

- **Operation ID:** git_status_route_api_git_status_get
- **Resumo:** Git Status Route
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| path | query | sim | tipo=string |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/git/worktree/add

- **Operation ID:** git_worktree_add_route_api_git_worktree_add_post
- **Resumo:** Git Worktree Add Route
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `GitWorktreeAddBody` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/git/worktree/remove

- **Operation ID:** git_worktree_remove_route_api_git_worktree_remove_post
- **Resumo:** Git Worktree Remove Route
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `GitWorktreeRemoveBody` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/git/worktrees

- **Operation ID:** git_worktrees_route_api_git_worktrees_get
- **Resumo:** Git Worktrees Route
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| path | query | sim | tipo=string |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

## /api/hermes

### POST /api/hermes/update

- **Operation ID:** update_hermes_api_hermes_update_post
- **Resumo:** Update Hermes
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

### GET /api/hermes/update/check

- **Operation ID:** check_hermes_update_api_hermes_update_check_get
- **Resumo:** Check Hermes Update
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| force | query | não | tipo=boolean; padrão=false |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

## /api/learning

### GET /api/learning/graph

- **Operation ID:** get_learning_graph_api_learning_graph_get
- **Resumo:** Get Learning Graph
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/learning/node

- **Operation ID:** get_learning_node_api_learning_node_get
- **Resumo:** Get Learning Node
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| id | query | sim | tipo=string |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### PUT /api/learning/node

- **Operation ID:** update_learning_node_api_learning_node_put
- **Resumo:** Update Learning Node
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `LearningNodeEdit` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### DELETE /api/learning/node

- **Operation ID:** delete_learning_node_api_learning_node_delete
- **Resumo:** Delete Learning Node
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `LearningNodeRef` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

## /api/logs

### GET /api/logs

- **Operation ID:** get_logs_api_logs_get
- **Resumo:** Get Logs
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| file | query | não | tipo=string; padrão="agent" |
| lines | query | não | tipo=integer; padrão=100 |
| level | query | não | anyOf=tipo=string \| tipo=null |
| component | query | não | anyOf=tipo=string \| tipo=null |
| search | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

## /api/mcp

### GET /api/mcp/catalog

- **Operation ID:** list_mcp_catalog_api_mcp_catalog_get
- **Resumo:** List Mcp Catalog
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/mcp/catalog/install

- **Operation ID:** install_mcp_catalog_entry_api_mcp_catalog_install_post
- **Resumo:** Install Mcp Catalog Entry
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `MCPCatalogInstall` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/mcp/servers

- **Operation ID:** list_mcp_servers_api_mcp_servers_get
- **Resumo:** List Mcp Servers
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### PUT /api/mcp/servers

- **Operation ID:** replace_mcp_servers_api_mcp_servers_put
- **Resumo:** Replace Mcp Servers
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `MCPServersReplace` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/mcp/servers

- **Operation ID:** add_mcp_server_api_mcp_servers_post
- **Resumo:** Add Mcp Server
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `MCPServerCreate` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### DELETE /api/mcp/servers/{name}

- **Operation ID:** remove_mcp_server_api_mcp_servers__name__delete
- **Resumo:** Remove Mcp Server
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| name | path | sim | tipo=string |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/mcp/servers/{name}/auth

- **Operation ID:** auth_mcp_server_api_mcp_servers__name__auth_post
- **Resumo:** Auth Mcp Server
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| name | path | sim | tipo=string |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### PUT /api/mcp/servers/{name}/enabled

- **Operation ID:** set_mcp_server_enabled_api_mcp_servers__name__enabled_put
- **Resumo:** Set Mcp Server Enabled
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| name | path | sim | tipo=string |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `MCPEnabledToggle` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/mcp/servers/{name}/test

- **Operation ID:** test_mcp_server_api_mcp_servers__name__test_post
- **Resumo:** Test Mcp Server
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| name | path | sim | tipo=string |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

## /api/media

### GET /api/media

- **Operation ID:** get_media_api_media_get
- **Resumo:** Get Media
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| path | query | sim | tipo=string |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

## /api/memory

### GET /api/memory

- **Operation ID:** get_memory_status_api_memory_get
- **Resumo:** Get Memory Status
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

### PUT /api/memory/provider

- **Operation ID:** set_memory_provider_api_memory_provider_put
- **Resumo:** Set Memory Provider
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `MemoryProviderSelect` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/memory/providers/{name}/config

- **Operation ID:** get_memory_provider_config_api_memory_providers__name__config_get
- **Resumo:** Get Memory Provider Config
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| name | path | sim | tipo=string |
| surface | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### PUT /api/memory/providers/{name}/config

- **Operation ID:** update_memory_provider_config_api_memory_providers__name__config_put
- **Resumo:** Update Memory Provider Config
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| name | path | sim | tipo=string |
| surface | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `MemoryProviderConfigUpdate` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/memory/providers/{name}/setup

- **Operation ID:** setup_memory_provider_api_memory_providers__name__setup_post
- **Resumo:** Setup Memory Provider
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| name | path | sim | tipo=string |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `MemoryProviderSetupRequest` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/memory/providers/{provider}/oauth/start

- **Operation ID:** start_memory_oauth_api_memory_providers__provider__oauth_start_post
- **Resumo:** Start Memory Oauth
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| provider | path | sim | tipo=string |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/memory/providers/{provider}/oauth/status

- **Operation ID:** memory_oauth_status_api_memory_providers__provider__oauth_status_get
- **Resumo:** Memory Oauth Status
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| provider | path | sim | tipo=string |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/memory/reset

- **Operation ID:** reset_memory_api_memory_reset_post
- **Resumo:** Reset Memory
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `MemoryReset` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

## /api/messaging

### GET /api/messaging/platforms

- **Operation ID:** get_messaging_platforms_api_messaging_platforms_get
- **Resumo:** Get Messaging Platforms
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### PUT /api/messaging/platforms/{platform_id}

- **Operation ID:** update_messaging_platform_api_messaging_platforms__platform_id__put
- **Resumo:** Update Messaging Platform
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| platform_id | path | sim | tipo=string |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `MessagingPlatformUpdate` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/messaging/platforms/{platform_id}/test

- **Operation ID:** test_messaging_platform_api_messaging_platforms__platform_id__test_post
- **Resumo:** Test Messaging Platform
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| platform_id | path | sim | tipo=string |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/messaging/telegram/onboarding/start

- **Operation ID:** start_telegram_onboarding_api_messaging_telegram_onboarding_start_post
- **Resumo:** Start Telegram Onboarding
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `TelegramOnboardingStart` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/messaging/telegram/onboarding/{pairing_id}

- **Operation ID:** get_telegram_onboarding_status_api_messaging_telegram_onboarding__pairing_id__get
- **Resumo:** Get Telegram Onboarding Status
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| pairing_id | path | sim | tipo=string |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### DELETE /api/messaging/telegram/onboarding/{pairing_id}

- **Operation ID:** cancel_telegram_onboarding_api_messaging_telegram_onboarding__pairing_id__delete
- **Resumo:** Cancel Telegram Onboarding
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| pairing_id | path | sim | tipo=string |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/messaging/telegram/onboarding/{pairing_id}/apply

- **Operation ID:** apply_telegram_onboarding_api_messaging_telegram_onboarding__pairing_id__apply_post
- **Resumo:** Apply Telegram Onboarding
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| pairing_id | path | sim | tipo=string |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `TelegramOnboardingApply` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/messaging/whatsapp/onboarding/start

- **Operation ID:** start_whatsapp_onboarding_api_messaging_whatsapp_onboarding_start_post
- **Resumo:** Start Whatsapp Onboarding
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `WhatsAppOnboardingStart` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/messaging/whatsapp/onboarding/{pairing_id}

- **Operation ID:** get_whatsapp_onboarding_status_api_messaging_whatsapp_onboarding__pairing_id__get
- **Resumo:** Get Whatsapp Onboarding Status
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| pairing_id | path | sim | tipo=string |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### DELETE /api/messaging/whatsapp/onboarding/{pairing_id}

- **Operation ID:** cancel_whatsapp_onboarding_api_messaging_whatsapp_onboarding__pairing_id__delete
- **Resumo:** Cancel Whatsapp Onboarding
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| pairing_id | path | sim | tipo=string |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/messaging/whatsapp/onboarding/{pairing_id}/apply

- **Operation ID:** apply_whatsapp_onboarding_api_messaging_whatsapp_onboarding__pairing_id__apply_post
- **Resumo:** Apply Whatsapp Onboarding
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| pairing_id | path | sim | tipo=string |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `WhatsAppOnboardingApply` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

## /api/model

### GET /api/model/auxiliary

- **Operation ID:** get_auxiliary_models_api_model_auxiliary_get
- **Resumo:** Get Auxiliary Models
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/model/info

- **Operation ID:** get_model_info_api_model_info_get
- **Resumo:** Get Model Info
- **Autenticação:** Allowlist do gate de sessão nesta implantação. Segurança OpenAPI: não especificada.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/model/moa

- **Operation ID:** get_moa_models_api_model_moa_get
- **Resumo:** Get Moa Models
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### PUT /api/model/moa

- **Operation ID:** set_moa_models_api_model_moa_put
- **Resumo:** Set Moa Models
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `MoaConfigPayload` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/model/options

- **Operation ID:** get_model_options_api_model_options_get
- **Resumo:** Get Model Options
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile | query | não | anyOf=tipo=string \| tipo=null |
| refresh | query | não | tipo=boolean; padrão=false |
| include_unconfigured | query | não | tipo=boolean; padrão=false |
| explicit_only | query | não | tipo=boolean; padrão=false |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/model/recommended-default

- **Operation ID:** get_recommended_default_model_api_model_recommended_default_get
- **Resumo:** Get Recommended Default Model
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| provider | query | não | tipo=string; padrão="" |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/model/set

- **Operation ID:** set_model_assignment_api_model_set_post
- **Resumo:** Set Model Assignment
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `ModelAssignment` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

## /api/ops

### POST /api/ops/backup

- **Operation ID:** run_backup_api_ops_backup_post
- **Resumo:** Run Backup
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `BackupRequest` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/ops/backup/download

- **Operation ID:** download_dashboard_backup_api_ops_backup_download_get
- **Resumo:** Download Dashboard Backup
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| archive | query | sim | tipo=string |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/ops/checkpoints

- **Operation ID:** list_checkpoints_api_ops_checkpoints_get
- **Resumo:** List Checkpoints
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

### POST /api/ops/checkpoints/prune

- **Operation ID:** prune_checkpoints_api_ops_checkpoints_prune_post
- **Resumo:** Prune Checkpoints
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

### POST /api/ops/config-migrate

- **Operation ID:** run_config_migrate_api_ops_config_migrate_post
- **Resumo:** Run Config Migrate
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

### POST /api/ops/debug-share

- **Operation ID:** run_debug_share_endpoint_api_ops_debug_share_post
- **Resumo:** Run Debug Share Endpoint
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: não.

| Content-Type | Schema |
| --- | --- |
| application/json | anyOf=`DebugShareRequest` \| tipo=null |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/ops/doctor

- **Operation ID:** run_doctor_api_ops_doctor_post
- **Resumo:** Run Doctor
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

### POST /api/ops/dump

- **Operation ID:** run_dump_api_ops_dump_post
- **Resumo:** Run Dump
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

### GET /api/ops/hooks

- **Operation ID:** list_hooks_api_ops_hooks_get
- **Resumo:** List Hooks
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

### POST /api/ops/hooks

- **Operation ID:** create_hook_api_ops_hooks_post
- **Resumo:** Create Hook
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `HookCreate` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### DELETE /api/ops/hooks

- **Operation ID:** delete_hook_api_ops_hooks_delete
- **Resumo:** Delete Hook
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `HookDelete` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/ops/import

- **Operation ID:** run_import_api_ops_import_post
- **Resumo:** Run Import
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `ImportRequest` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/ops/import-upload

- **Operation ID:** run_import_upload_api_ops_import_upload_post
- **Resumo:** Run Import Upload
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| multipart/form-data | `Body_run_import_upload_api_ops_import_upload_post` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/ops/prompt-size

- **Operation ID:** run_prompt_size_api_ops_prompt_size_post
- **Resumo:** Run Prompt Size
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

### POST /api/ops/security-audit

- **Operation ID:** run_security_audit_api_ops_security_audit_post
- **Resumo:** Run Security Audit
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

## /api/pairing

### GET /api/pairing

- **Operation ID:** list_pairing_api_pairing_get
- **Resumo:** List Pairing
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

### POST /api/pairing/approve

- **Operation ID:** approve_pairing_api_pairing_approve_post
- **Resumo:** Approve Pairing
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `PairingApprove` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/pairing/clear-pending

- **Operation ID:** clear_pending_pairing_api_pairing_clear_pending_post
- **Resumo:** Clear Pending Pairing
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

### POST /api/pairing/revoke

- **Operation ID:** revoke_pairing_api_pairing_revoke_post
- **Resumo:** Revoke Pairing
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `PairingRevoke` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

## /api/plugins

### GET /api/plugins/hermes-achievements/achievements

- **Operation ID:** achievements_api_plugins_hermes_achievements_achievements_get
- **Resumo:** Achievements
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

### GET /api/plugins/hermes-achievements/recent-unlocks

- **Operation ID:** recent_unlocks_api_plugins_hermes_achievements_recent_unlocks_get
- **Resumo:** Recent Unlocks
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

### POST /api/plugins/hermes-achievements/rescan

- **Operation ID:** rescan_api_plugins_hermes_achievements_rescan_post
- **Resumo:** Rescan
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

### POST /api/plugins/hermes-achievements/reset-state

- **Operation ID:** reset_state_api_plugins_hermes_achievements_reset_state_post
- **Resumo:** Reset State
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

### GET /api/plugins/hermes-achievements/scan-status

- **Operation ID:** scan_status_api_plugins_hermes_achievements_scan_status_get
- **Resumo:** Scan Status
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

### GET /api/plugins/hermes-achievements/sessions/{session_id}/badges

- **Operation ID:** session_badges_api_plugins_hermes_achievements_sessions__session_id__badges_get
- **Resumo:** Session Badges
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| session_id | path | sim | tipo=string |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/plugins/kanban/assignees

- **Operation ID:** get_assignees_api_plugins_kanban_assignees_get
- **Resumo:** Get Assignees
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| board | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/plugins/kanban/attachments/{attachment_id}

- **Operation ID:** download_attachment_api_plugins_kanban_attachments__attachment_id__get
- **Resumo:** Download Attachment
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| attachment_id | path | sim | tipo=integer |
| board | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### DELETE /api/plugins/kanban/attachments/{attachment_id}

- **Operation ID:** remove_attachment_api_plugins_kanban_attachments__attachment_id__delete
- **Resumo:** Remove Attachment
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| attachment_id | path | sim | tipo=integer |
| board | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/plugins/kanban/board

- **Operation ID:** get_board_api_plugins_kanban_board_get
- **Resumo:** Get Board
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| tenant | query | não | anyOf=tipo=string \| tipo=null |
| include_archived | query | não | tipo=boolean; padrão=false |
| board | query | não | anyOf=tipo=string \| tipo=null |
| workflow_template_id | query | não | anyOf=tipo=string \| tipo=null |
| current_step_key | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/plugins/kanban/boards

- **Operation ID:** list_boards_api_plugins_kanban_boards_get
- **Resumo:** List Boards
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| include_archived | query | não | tipo=boolean; padrão=false |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/plugins/kanban/boards

- **Operation ID:** create_board_endpoint_api_plugins_kanban_boards_post
- **Resumo:** Create Board Endpoint
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `CreateBoardBody` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### DELETE /api/plugins/kanban/boards/{slug}

- **Operation ID:** delete_board_api_plugins_kanban_boards__slug__delete
- **Resumo:** Delete Board
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| slug | path | sim | tipo=string |
| delete | query | não | tipo=boolean; padrão=false |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### PATCH /api/plugins/kanban/boards/{slug}

- **Operation ID:** rename_board_api_plugins_kanban_boards__slug__patch
- **Resumo:** Rename Board
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| slug | path | sim | tipo=string |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `RenameBoardBody` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/plugins/kanban/boards/{slug}/switch

- **Operation ID:** switch_board_api_plugins_kanban_boards__slug__switch_post
- **Resumo:** Switch Board
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| slug | path | sim | tipo=string |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/plugins/kanban/config

- **Operation ID:** get_config_api_plugins_kanban_config_get
- **Resumo:** Get Config
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

### GET /api/plugins/kanban/diagnostics

- **Operation ID:** list_diagnostics_api_plugins_kanban_diagnostics_get
- **Resumo:** List Diagnostics
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| board | query | não | anyOf=tipo=string \| tipo=null |
| severity | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/plugins/kanban/dispatch

- **Operation ID:** dispatch_api_plugins_kanban_dispatch_post
- **Resumo:** Dispatch
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| dry_run | query | não | tipo=boolean; padrão=false |
| max | query | não | tipo=integer; padrão=8 |
| board | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/plugins/kanban/home-channels

- **Operation ID:** get_home_channels_api_plugins_kanban_home_channels_get
- **Resumo:** Get Home Channels
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| task_id | query | não | anyOf=tipo=string \| tipo=null |
| board | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/plugins/kanban/links

- **Operation ID:** add_link_api_plugins_kanban_links_post
- **Resumo:** Add Link
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| board | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `LinkBody` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### DELETE /api/plugins/kanban/links

- **Operation ID:** delete_link_api_plugins_kanban_links_delete
- **Resumo:** Delete Link
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| parent_id | query | sim | tipo=string |
| child_id | query | sim | tipo=string |
| board | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/plugins/kanban/orchestration

- **Operation ID:** get_orchestration_settings_api_plugins_kanban_orchestration_get
- **Resumo:** Get Orchestration Settings
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

### PUT /api/plugins/kanban/orchestration

- **Operation ID:** set_orchestration_settings_api_plugins_kanban_orchestration_put
- **Resumo:** Set Orchestration Settings
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `OrchestrationSettingsBody` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/plugins/kanban/profiles

- **Operation ID:** list_profile_roster_api_plugins_kanban_profiles_get
- **Resumo:** List Profile Roster
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

### PATCH /api/plugins/kanban/profiles/{profile_name}

- **Operation ID:** update_profile_description_api_plugins_kanban_profiles__profile_name__patch
- **Resumo:** Update Profile Description
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile_name | path | sim | tipo=string |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `DescribeBody` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/plugins/kanban/profiles/{profile_name}/describe-auto

- **Operation ID:** auto_describe_profile_api_plugins_kanban_profiles__profile_name__describe_auto_post
- **Resumo:** Auto Describe Profile
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile_name | path | sim | tipo=string |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `DescribeAutoBody` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/plugins/kanban/runs/{run_id}

- **Operation ID:** get_run_endpoint_api_plugins_kanban_runs__run_id__get
- **Resumo:** Get Run Endpoint
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| run_id | path | sim | tipo=integer |
| board | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/plugins/kanban/runs/{run_id}/inspect

- **Operation ID:** inspect_run_endpoint_api_plugins_kanban_runs__run_id__inspect_get
- **Resumo:** Inspect Run Endpoint
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| run_id | path | sim | tipo=integer |
| board | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/plugins/kanban/runs/{run_id}/terminate

- **Operation ID:** terminate_run_endpoint_api_plugins_kanban_runs__run_id__terminate_post
- **Resumo:** Terminate Run Endpoint
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| run_id | path | sim | tipo=integer |
| board | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `TerminateRunBody` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/plugins/kanban/stats

- **Operation ID:** get_stats_api_plugins_kanban_stats_get
- **Resumo:** Get Stats
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| board | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/plugins/kanban/tasks

- **Operation ID:** create_task_api_plugins_kanban_tasks_post
- **Resumo:** Create Task
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| board | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `CreateTaskBody` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/plugins/kanban/tasks/bulk

- **Operation ID:** bulk_update_api_plugins_kanban_tasks_bulk_post
- **Resumo:** Bulk Update
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| board | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `BulkTaskBody` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/plugins/kanban/tasks/{task_id}

- **Operation ID:** get_task_api_plugins_kanban_tasks__task_id__get
- **Resumo:** Get Task
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| task_id | path | sim | tipo=string |
| board | query | não | anyOf=tipo=string \| tipo=null |
| run_state_type | query | não | anyOf=tipo=string \| tipo=null |
| run_state_name | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### DELETE /api/plugins/kanban/tasks/{task_id}

- **Operation ID:** delete_task_api_plugins_kanban_tasks__task_id__delete
- **Resumo:** Delete Task
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| task_id | path | sim | tipo=string |
| board | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### PATCH /api/plugins/kanban/tasks/{task_id}

- **Operation ID:** update_task_api_plugins_kanban_tasks__task_id__patch
- **Resumo:** Update Task
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| task_id | path | sim | tipo=string |
| board | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `UpdateTaskBody` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/plugins/kanban/tasks/{task_id}/attachments

- **Operation ID:** list_task_attachments_api_plugins_kanban_tasks__task_id__attachments_get
- **Resumo:** List Task Attachments
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| task_id | path | sim | tipo=string |
| board | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/plugins/kanban/tasks/{task_id}/attachments

- **Operation ID:** upload_task_attachment_api_plugins_kanban_tasks__task_id__attachments_post
- **Resumo:** Upload Task Attachment
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| task_id | path | sim | tipo=string |
| board | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| multipart/form-data | `Body_upload_task_attachment_api_plugins_kanban_tasks__task_id__attachments_post` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/plugins/kanban/tasks/{task_id}/comments

- **Operation ID:** add_comment_api_plugins_kanban_tasks__task_id__comments_post
- **Resumo:** Add Comment
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| task_id | path | sim | tipo=string |
| board | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `CommentBody` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/plugins/kanban/tasks/{task_id}/decompose

- **Operation ID:** decompose_task_endpoint_api_plugins_kanban_tasks__task_id__decompose_post
- **Resumo:** Decompose Task Endpoint
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| task_id | path | sim | tipo=string |
| board | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `DecomposeBody` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/plugins/kanban/tasks/{task_id}/home-subscribe/{platform}

- **Operation ID:** subscribe_home_api_plugins_kanban_tasks__task_id__home_subscribe__platform__post
- **Resumo:** Subscribe Home
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| task_id | path | sim | tipo=string |
| platform | path | sim | tipo=string |
| board | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### DELETE /api/plugins/kanban/tasks/{task_id}/home-subscribe/{platform}

- **Operation ID:** unsubscribe_home_api_plugins_kanban_tasks__task_id__home_subscribe__platform__delete
- **Resumo:** Unsubscribe Home
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| task_id | path | sim | tipo=string |
| platform | path | sim | tipo=string |
| board | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/plugins/kanban/tasks/{task_id}/log

- **Operation ID:** get_task_log_api_plugins_kanban_tasks__task_id__log_get
- **Resumo:** Get Task Log
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| task_id | path | sim | tipo=string |
| tail | query | não | anyOf=tipo=integer \| tipo=null |
| board | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/plugins/kanban/tasks/{task_id}/reassign

- **Operation ID:** reassign_task_endpoint_api_plugins_kanban_tasks__task_id__reassign_post
- **Resumo:** Reassign Task Endpoint
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| task_id | path | sim | tipo=string |
| board | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `ReassignBody` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/plugins/kanban/tasks/{task_id}/reclaim

- **Operation ID:** reclaim_task_endpoint_api_plugins_kanban_tasks__task_id__reclaim_post
- **Resumo:** Reclaim Task Endpoint
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| task_id | path | sim | tipo=string |
| board | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `ReclaimBody` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/plugins/kanban/tasks/{task_id}/specify

- **Operation ID:** specify_task_endpoint_api_plugins_kanban_tasks__task_id__specify_post
- **Resumo:** Specify Task Endpoint
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| task_id | path | sim | tipo=string |
| board | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `SpecifyBody` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/plugins/kanban/workers/active

- **Operation ID:** list_active_workers_api_plugins_kanban_workers_active_get
- **Resumo:** List Active Workers
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| board | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

## /api/portal

### GET /api/portal

- **Operation ID:** get_portal_status_api_portal_get
- **Resumo:** Get Portal Status
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

## /api/profiles

### GET /api/profiles

- **Operation ID:** list_profiles_endpoint_api_profiles_get
- **Resumo:** List Profiles Endpoint
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

### POST /api/profiles

- **Operation ID:** create_profile_endpoint_api_profiles_post
- **Resumo:** Create Profile Endpoint
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `ProfileCreate` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/profiles/active

- **Operation ID:** get_active_profile_endpoint_api_profiles_active_get
- **Resumo:** Get Active Profile Endpoint
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

### POST /api/profiles/active

- **Operation ID:** set_active_profile_endpoint_api_profiles_active_post
- **Resumo:** Set Active Profile Endpoint
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `ProfileActiveUpdate` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/profiles/sessions

- **Operation ID:** get_profiles_sessions_api_profiles_sessions_get
- **Resumo:** Get Profiles Sessions
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| limit | query | não | tipo=integer; padrão=20 |
| offset | query | não | tipo=integer; padrão=0 |
| min_messages | query | não | tipo=integer; padrão=0 |
| archived | query | não | tipo=string; padrão="exclude" |
| order | query | não | tipo=string; padrão="recent" |
| profile | query | não | tipo=string; padrão="all" |
| source | query | não | tipo=string |
| exclude_sources | query | não | tipo=string |
| full | query | não | tipo=boolean; padrão=false |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### DELETE /api/profiles/{name}

- **Operation ID:** delete_profile_endpoint_api_profiles__name__delete
- **Resumo:** Delete Profile Endpoint
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| name | path | sim | tipo=string |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### PATCH /api/profiles/{name}

- **Operation ID:** rename_profile_endpoint_api_profiles__name__patch
- **Resumo:** Rename Profile Endpoint
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| name | path | sim | tipo=string |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `ProfileRename` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/profiles/{name}/describe-auto

- **Operation ID:** describe_profile_auto_endpoint_api_profiles__name__describe_auto_post
- **Resumo:** Describe Profile Auto Endpoint
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| name | path | sim | tipo=string |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `ProfileDescribeAuto` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### PUT /api/profiles/{name}/description

- **Operation ID:** update_profile_description_endpoint_api_profiles__name__description_put
- **Resumo:** Update Profile Description Endpoint
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| name | path | sim | tipo=string |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `ProfileDescriptionUpdate` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### PUT /api/profiles/{name}/model

- **Operation ID:** update_profile_model_endpoint_api_profiles__name__model_put
- **Resumo:** Update Profile Model Endpoint
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| name | path | sim | tipo=string |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `ProfileModelUpdate` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/profiles/{name}/open-terminal

- **Operation ID:** open_profile_terminal_endpoint_api_profiles__name__open_terminal_post
- **Resumo:** Open Profile Terminal Endpoint
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| name | path | sim | tipo=string |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/profiles/{name}/setup-command

- **Operation ID:** get_profile_setup_command_api_profiles__name__setup_command_get
- **Resumo:** Get Profile Setup Command
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| name | path | sim | tipo=string |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/profiles/{name}/soul

- **Operation ID:** get_profile_soul_api_profiles__name__soul_get
- **Resumo:** Get Profile Soul
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| name | path | sim | tipo=string |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### PUT /api/profiles/{name}/soul

- **Operation ID:** update_profile_soul_api_profiles__name__soul_put
- **Resumo:** Update Profile Soul
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| name | path | sim | tipo=string |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `ProfileSoulUpdate` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

## /api/providers

### GET /api/providers/oauth

- **Operation ID:** list_oauth_providers_api_providers_oauth_get
- **Resumo:** List Oauth Providers
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### DELETE /api/providers/oauth/sessions/{session_id}

- **Operation ID:** cancel_oauth_session_api_providers_oauth_sessions__session_id__delete
- **Resumo:** Cancel Oauth Session
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| session_id | path | sim | tipo=string |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### DELETE /api/providers/oauth/{provider_id}

- **Operation ID:** disconnect_oauth_provider_api_providers_oauth__provider_id__delete
- **Resumo:** Disconnect Oauth Provider
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| provider_id | path | sim | tipo=string |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/providers/oauth/{provider_id}/poll/{session_id}

- **Operation ID:** poll_oauth_session_api_providers_oauth__provider_id__poll__session_id__get
- **Resumo:** Poll Oauth Session
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| provider_id | path | sim | tipo=string |
| session_id | path | sim | tipo=string |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/providers/oauth/{provider_id}/start

- **Operation ID:** start_oauth_login_api_providers_oauth__provider_id__start_post
- **Resumo:** Start Oauth Login
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| provider_id | path | sim | tipo=string |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/providers/oauth/{provider_id}/submit

- **Operation ID:** submit_oauth_code_api_providers_oauth__provider_id__submit_post
- **Resumo:** Submit Oauth Code
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| provider_id | path | sim | tipo=string |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `OAuthSubmitBody` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/providers/validate

- **Operation ID:** validate_provider_credential_api_providers_validate_post
- **Resumo:** Validate Provider Credential
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `EnvVarUpdate` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

## /api/sessions

### GET /api/sessions

- **Operation ID:** get_sessions_api_sessions_get
- **Resumo:** Get Sessions
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| limit | query | não | tipo=integer; padrão=20 |
| offset | query | não | tipo=integer; padrão=0 |
| min_messages | query | não | tipo=integer; padrão=0 |
| archived | query | não | tipo=string; padrão="exclude" |
| order | query | não | tipo=string; padrão="created" |
| source | query | não | tipo=string |
| exclude_sources | query | não | tipo=string |
| cwd_prefix | query | não | tipo=string |
| full | query | não | tipo=boolean; padrão=false |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/sessions/bulk-delete

- **Operation ID:** bulk_delete_sessions_endpoint_api_sessions_bulk_delete_post
- **Resumo:** Bulk Delete Sessions Endpoint
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `BulkDeleteSessions` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### DELETE /api/sessions/empty

- **Operation ID:** delete_empty_sessions_endpoint_api_sessions_empty_delete
- **Resumo:** Delete Empty Sessions Endpoint
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/sessions/empty/count

- **Operation ID:** count_empty_sessions_endpoint_api_sessions_empty_count_get
- **Resumo:** Count Empty Sessions Endpoint
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/sessions/import

- **Operation ID:** import_sessions_endpoint_api_sessions_import_post
- **Resumo:** Import Sessions Endpoint
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

### POST /api/sessions/prune

- **Operation ID:** prune_sessions_endpoint_api_sessions_prune_post
- **Resumo:** Prune Sessions Endpoint
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `SessionPrune` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/sessions/search

- **Operation ID:** search_sessions_api_sessions_search_get
- **Resumo:** Search Sessions
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| q | query | não | tipo=string; padrão="" |
| limit | query | não | tipo=integer; padrão=20 |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/sessions/stats

- **Operation ID:** get_session_stats_api_sessions_stats_get
- **Resumo:** Get Session Stats
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/sessions/{session_id}

- **Operation ID:** get_session_detail_api_sessions__session_id__get
- **Resumo:** Get Session Detail
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| session_id | path | sim | tipo=string |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### DELETE /api/sessions/{session_id}

- **Operation ID:** delete_session_endpoint_api_sessions__session_id__delete
- **Resumo:** Delete Session Endpoint
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| session_id | path | sim | tipo=string |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### PATCH /api/sessions/{session_id}

- **Operation ID:** rename_session_endpoint_api_sessions__session_id__patch
- **Resumo:** Rename Session Endpoint
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| session_id | path | sim | tipo=string |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `SessionRename` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/sessions/{session_id}/export

- **Operation ID:** export_session_endpoint_api_sessions__session_id__export_get
- **Resumo:** Export Session Endpoint
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| session_id | path | sim | tipo=string |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/sessions/{session_id}/latest-descendant

- **Operation ID:** get_session_latest_descendant_api_sessions__session_id__latest_descendant_get
- **Resumo:** Get Session Latest Descendant
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| session_id | path | sim | tipo=string |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/sessions/{session_id}/messages

- **Operation ID:** get_session_messages_api_sessions__session_id__messages_get
- **Resumo:** Get Session Messages
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| session_id | path | sim | tipo=string |
| profile | query | não | anyOf=tipo=string \| tipo=null |
| limit | query | não | anyOf=tipo=integer \| tipo=null |
| offset | query | não | tipo=integer; padrão=0 |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

## /api/skills

### GET /api/skills

- **Operation ID:** get_skills_api_skills_get
- **Resumo:** Get Skills
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/skills

- **Operation ID:** create_skill_api_skills_post
- **Resumo:** Create Skill
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `SkillCreate` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/skills/content

- **Operation ID:** get_skill_content_api_skills_content_get
- **Resumo:** Get Skill Content
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| name | query | sim | tipo=string |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### PUT /api/skills/content

- **Operation ID:** update_skill_content_api_skills_content_put
- **Resumo:** Update Skill Content
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `SkillContentUpdate` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/skills/hub/install

- **Operation ID:** install_skill_hub_api_skills_hub_install_post
- **Resumo:** Install Skill Hub
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `SkillInstallRequest` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/skills/hub/preview

- **Operation ID:** preview_skill_hub_api_skills_hub_preview_get
- **Resumo:** Preview Skill Hub
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| identifier | query | não | tipo=string; padrão="" |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/skills/hub/scan

- **Operation ID:** scan_skill_hub_api_skills_hub_scan_get
- **Resumo:** Scan Skill Hub
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| identifier | query | não | tipo=string; padrão="" |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/skills/hub/search

- **Operation ID:** search_skills_hub_api_skills_hub_search_get
- **Resumo:** Search Skills Hub
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| q | query | não | tipo=string; padrão="" |
| source | query | não | tipo=string; padrão="all" |
| limit | query | não | tipo=integer; padrão=20 |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/skills/hub/sources

- **Operation ID:** list_skills_hub_sources_api_skills_hub_sources_get
- **Resumo:** List Skills Hub Sources
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/skills/hub/uninstall

- **Operation ID:** uninstall_skill_hub_api_skills_hub_uninstall_post
- **Resumo:** Uninstall Skill Hub
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `SkillUninstallRequest` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/skills/hub/update

- **Operation ID:** update_skills_hub_api_skills_hub_update_post
- **Resumo:** Update Skills Hub
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Obrigatório: não.

| Content-Type | Schema |
| --- | --- |
| application/json | anyOf=`SkillsUpdateRequest` \| tipo=null |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### PUT /api/skills/toggle

- **Operation ID:** toggle_skill_api_skills_toggle_put
- **Resumo:** Toggle Skill
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `SkillToggle` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

## /api/status

### GET /api/status

- **Operation ID:** get_status_api_status_get
- **Resumo:** Get Status
- **Autenticação:** Allowlist do gate de sessão nesta implantação. Segurança OpenAPI: não especificada.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

## /api/system

### GET /api/system/stats

- **Operation ID:** get_system_stats_api_system_stats_get
- **Resumo:** Get System Stats
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

## /api/tools

### POST /api/tools/computer-use/permissions/grant

- **Operation ID:** grant_computer_use_permissions_api_tools_computer_use_permissions_grant_post
- **Resumo:** Grant Computer Use Permissions
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/tools/computer-use/status

- **Operation ID:** get_computer_use_status_api_tools_computer_use_status_get
- **Resumo:** Get Computer Use Status
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/tools/toolsets

- **Operation ID:** get_toolsets_api_tools_toolsets_get
- **Resumo:** Get Toolsets
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### PUT /api/tools/toolsets/{name}

- **Operation ID:** toggle_toolset_api_tools_toolsets__name__put
- **Resumo:** Toggle Toolset
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| name | path | sim | tipo=string |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `ToolsetToggle` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/tools/toolsets/{name}/config

- **Operation ID:** get_toolset_config_api_tools_toolsets__name__config_get
- **Resumo:** Get Toolset Config
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| name | path | sim | tipo=string |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### PUT /api/tools/toolsets/{name}/env

- **Operation ID:** save_toolset_env_api_tools_toolsets__name__env_put
- **Resumo:** Save Toolset Env
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| name | path | sim | tipo=string |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `ToolsetEnvUpdate` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### PUT /api/tools/toolsets/{name}/model

- **Operation ID:** select_toolset_model_api_tools_toolsets__name__model_put
- **Resumo:** Select Toolset Model
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| name | path | sim | tipo=string |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `ToolsetModelSelect` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /api/tools/toolsets/{name}/models

- **Operation ID:** get_toolset_models_api_tools_toolsets__name__models_get
- **Resumo:** Get Toolset Models
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| name | path | sim | tipo=string |
| provider | query | não | anyOf=tipo=string \| tipo=null |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/tools/toolsets/{name}/post-setup

- **Operation ID:** run_toolset_post_setup_api_tools_toolsets__name__post_setup_post
- **Resumo:** Run Toolset Post Setup
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| name | path | sim | tipo=string |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `ToolsetPostSetup` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### PUT /api/tools/toolsets/{name}/provider

- **Operation ID:** select_toolset_provider_api_tools_toolsets__name__provider_put
- **Resumo:** Select Toolset Provider
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| name | path | sim | tipo=string |
| profile | query | não | anyOf=tipo=string \| tipo=null |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `ToolsetProviderSelect` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

## /api/webhooks

### GET /api/webhooks

- **Operation ID:** list_webhooks_api_webhooks_get
- **Resumo:** List Webhooks
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

### POST /api/webhooks

- **Operation ID:** create_webhook_api_webhooks_post
- **Resumo:** Create Webhook
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `WebhookCreate` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /api/webhooks/enable

- **Operation ID:** enable_webhooks_api_webhooks_enable_post
- **Resumo:** Enable Webhooks
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

### DELETE /api/webhooks/{name}

- **Operation ID:** delete_webhook_api_webhooks__name__delete
- **Resumo:** Delete Webhook
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| name | path | sim | tipo=string |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### PUT /api/webhooks/{name}/enabled

- **Operation ID:** set_webhook_enabled_api_webhooks__name__enabled_put
- **Resumo:** Set Webhook Enabled
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada. Para APIs, um 401 usa envelope com `error`, `detail`, `reason` e `login_url`.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| name | path | sim | tipo=string |

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `WebhookEnabledToggle` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

## /dashboard-plugins

### GET /dashboard-plugins/{plugin_name}/{file_path}

- **Operation ID:** serve_plugin_asset_dashboard_plugins__plugin_name___file_path__get
- **Resumo:** Serve Plugin Asset
- **Autenticação:** Exige sessão por cookie nesta implantação; ausência de `security` no OpenAPI não indica rota pública. Segurança OpenAPI: não especificada.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| plugin_name | path | sim | tipo=string |
| file_path | path | sim | tipo=string |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

## /{full_path}

### GET /{full_path}

- **Operation ID:** no_frontend__full_path__get
- **Resumo:** No Frontend
- **Autenticação:** Rota curinga: assets são exceção pública do gate, mas o snapshot não permite classificar um `full_path` individual como asset. Não inferir publicidade. Segurança OpenAPI: não especificada.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| full_path | path | sim | tipo=string |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

## Autenticação e bootstrap

### GET /auth/callback

- **Operation ID:** auth_callback_auth_callback_get
- **Resumo:** Auth Callback
- **Autenticação:** Fluxo público de bootstrap nesta implantação. Segurança OpenAPI: não especificada.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| code | query | não | tipo=string; padrão="" |
| state | query | não | tipo=string; padrão="" |
| error | query | não | tipo=string; padrão="" |
| error_description | query | não | tipo=string; padrão="" |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /auth/login

- **Operation ID:** auth_login_auth_login_get
- **Resumo:** Auth Login
- **Autenticação:** Fluxo público de bootstrap nesta implantação. Segurança OpenAPI: não especificada.

#### Parâmetros

| Nome | Local | Obrigatório | Schema / padrão |
| --- | --- | --- | --- |
| provider | query | sim | tipo=string |
| next | query | não | tipo=string; padrão="" |

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### POST /auth/logout

- **Operation ID:** auth_logout_auth_logout_post
- **Resumo:** Auth Logout
- **Autenticação:** Fluxo público de bootstrap nesta implantação. Segurança OpenAPI: não especificada.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |

### POST /auth/password-login

- **Operation ID:** auth_password_login_auth_password_login_post
- **Resumo:** Auth Password Login
- **Autenticação:** Fluxo público de bootstrap nesta implantação. Segurança OpenAPI: não especificada.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Obrigatório: sim.

| Content-Type | Schema |
| --- | --- |
| application/json | `_PasswordLoginBody` |

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
| 422 | application/json | `HTTPValidationError` |

### GET /login

- **Operation ID:** login_page_login_get
- **Resumo:** Login Page
- **Autenticação:** Fluxo público de bootstrap nesta implantação. Segurança OpenAPI: não especificada.

#### Parâmetros

Nenhum parâmetro especificado no snapshot.

#### Corpo da requisição

Nenhum corpo de requisição especificado no snapshot.

#### Respostas

| Status | Content-Type | Schema |
| --- | --- | --- |
| 200 | application/json | não especificado (schema vazio) |
