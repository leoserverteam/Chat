# GitHub Workflow Deployment Guide

## 🤖 Self-Hosted Runner Setup

Этот проект использует **Self-Hosted GitHub Runner** для деплоя контейнеров. Runner запускается на вашем сервере (без Ubuntu требирует).

### 1️⃣ Установка Self-Hosted Runner

**На вашем сервере (независимо от ОС):**

```bash
# Создайте директорию для runner
mkdir -p ~/github-runner
cd ~/github-runner

# Скачайте latest runner для вашей ОС
# Для Linux x64
curl -o actions-runner-linux-x64.tar.gz -L https://github.com/actions/runner/releases/download/v2.313.0/actions-runner-linux-x64.tar.gz
tar xzf actions-runner-linux-x64.tar.gz

# Для других ОС - см. https://github.com/actions/runner/releases

# Скачайте dependencies (если требуется)
./bin/installdependencies.sh

# Настройте runner
./config.sh --url https://github.com/your-username/Chat --token <REGISTRATION_TOKEN>
```

**Получить токен регистрации:**
1. Перейдите в репозиторий → `Settings` → `Actions` → `Runners`
2. Нажмите `New self-hosted runner`
3. Копируйте команду из шага "Configure"

### 2️⃣ Запуск Runner

**Вариант 1: Как systemd сервис (рекомендуется)**
```bash
cd ~/github-runner
sudo ./svc.sh install
sudo ./svc.sh start
```

**Вариант 2: Интерактивный режим**
```bash
cd ~/github-runner
./run.sh
```

Проверьте статус: Репозиторий → `Settings` → `Actions` → `Runners` (должен быть зелёный "Idle")

## 📋 Структура Workflows

### 1. `deploy.yml` — Deploy Services + nginx
Запускается на **self-hosted runner** при push в `main` и `develop` ветки.

**Этапы:**
- ✅ Валидация Docker Compose (на ubuntu-latest)
- 🚀 docker-compose pull & up (на self-hosted runner)
  - Создание директорий `/mnt/Share/chat/`
  - Запуск Synapse, PostgreSQL, Element, LiveKit
- ✔️ Проверка health всех сервисов
- 🔧 **call-nginx:** Вызывает `leoserverteam/DevOpsTemplates/.github/workflows/deploynginx.yml`
  - nginx конфигурация управляется отдельным workflow
- ⏮️ Auto-rollback при ошибке

**Данные хранятся:**
```
/mnt/Share/chat/
├── synapse/          # Synapse конфиг и данные
├── postgres/         # PostgreSQL база данных
└── livekit/          # LiveKit записи (если включены)
```

### 2. `lint.yml` — PR Validation
Запускается при PR и push в `develop`.

**Проверки:**
- 📝 YAML/JSON валидация
- 🔐 Security check (поиск exposed secrets)

## 🚀 Автоматизация процесса

### Первый деплой

1. **Установите self-hosted runner** (см. выше)
   
2. **Проверьте, что runner активен:**
   Репозиторий → `Settings` → `Actions` → `Runners` → должен быть зелёный статус "Idle"

3. **Первый push в main:**
```bash
git push origin main
```

Workflow автоматически запустится на вашем runner!

### Последующие деплои

Просто делайте commits и push:
```bash
git add .
git commit -m "Update configuration"
git push origin main  # Автоматический deploy на runner
```

## 🔍 Мониторинг деплоя

1. Перейдите в `Actions` на GitHub
2. Посмотрите статус текущего workflow
3. Нажмите на run чтобы увидеть логи
4. Или на сервере прямо:
```bash
docker-compose logs -f
docker-compose ps
```

## 🆘 Troubleshooting

## 🆘 Troubleshooting

### Runner не активен
```
Settings → Actions → Runners
```
Если runner не видна - перезапустите:
```bash
cd ~/github-runner
sudo ./svc.sh restart
# или
./run.sh  # для интерактивного режима
```

### Ошибка при деплое
```bash
# Посмотрите логи на сервере
docker-compose logs synapse
docker-compose logs postgres

# Проверьте, что директория существует
ls -la /mnt/Share/chat/
```

### Деплой зависает на health check
```bash
# Проверьте, запустилась ли Synapse
docker-compose exec -T synapse curl http://localhost:8008/_synapse/admin/v1/server_version

# Если не запустилась, посмотрите ошибку
docker-compose logs synapse | tail -50
```

### nginx не проксирует
nginx конфигурируется отдельным workflow `leoserverteam/DevOpsTemplates/.github/workflows/deploynginx.yml`.

Убедитесь, что nginx проксирует эти адреса:
- `matrix.leonet.site` → `127.0.0.1:8008`
- `chat.leonet.site` → `127.0.0.1:8080`
- `sfo.leonet.site` → `127.0.0.1:7880`

## 📌 OIDC Integration (Authentik) — Roadmap

OIDC интеграция с Authentik сделана для следующего этапа:

**Что потребуется:**
1. Установленный Authentik сервер
2. Создание OIDC Application в Authentik
3. Обновление Synapse конфигурации (`homeserver.yaml`):
   ```yaml
   oidc_providers:
     - idp_name: "Authentik"
       idp_brand: "authentik"
       client_id: "your-client-id"
       client_secret: "your-client-secret"
       issuer: "https://authentik.example.com"
       scopes: ["openid", "profile", "email"]
       authorization_endpoint: "https://authentik.example.com/application/o/authorize/"
       token_endpoint: "https://authentik.example.com/application/o/token/"
       userinfo_endpoint: "https://authentik.example.com/application/o/userinfo/"
       user_mapping_provider:
         config:
           localpart_template: "{{ user.preferred_username }}"
           display_name_template: "{{ user.name }}"
   ```
4. Обновление Element конфигурации

**Когда потребуется — дай знать, и я это всё настрою!** 🔐
