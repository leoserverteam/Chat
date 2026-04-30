# Matrix Chat Server (Synapse + Element + LiveKit)

Полнофункциональный чат-сервер на основе Matrix протокола с веб-клиентом Element и видеосвязью через LiveKit.

## 🏗️ Компоненты

- **Synapse** — Matrix homeserver
- **PostgreSQL** — база данных (production)
- **Element Web** — веб-клиент
- **LiveKit** — сервер видеосвязи
- **Nginx** — reverse proxy с SSL/TLS

## 📋 Требования

- Docker & Docker Compose
- nginx (установлен отдельно на сервере)
- SSL сертификат (Wildcard для *.leonet.site)
- Домены:
  - `matrix.leonet.site` — Matrix сервер (проксирует на `127.0.0.1:8008`)
  - `chat.leonet.site` — веб-клиент (проксирует на `127.0.0.1:8080`)
  - `sfo.leonet.site` — видеосвязь (проксирует на `127.0.0.1:7880`)

## 🚀 Быстрый старт

**Перед началом работы прочитайте [DEPLOYMENT.md](DEPLOYMENT.md) для настройки GitHub Workflow!**

### 1. Клонирование и подготовка

```bash
git clone <repo>
cd Chat
cp .env.example .env
```

### 2. Обновление переменных окружения

Отредактируйте `.env` с вашими параметрами:

```bash
SYNAPSE_SERVER_NAME=matrix.leonet.site
POSTGRES_PASSWORD=your_very_secure_password
LIVEKIT_API_KEY=your_api_key
LIVEKIT_API_SECRET=your_api_secret
```

### 3. Генерация конфигурации Synapse

```bash
chmod +x synapsedeploy.sh
./synapsedeploy.sh
```

Это создаст начальную конфигурацию в директории `/mnt/Share/chat/synapse/homeserver.yaml`.

### 4. Редактирование конфигурации Synapse

Отредактируйте `/mnt/Share/chat/synapse/homeserver.yaml`:
- Установите `server_name`
- Настройте `database` (подключение к PostgreSQL)
- Проверьте портовые настройки

**Минимальные изменения для database:**

```yaml
database:
  name: psycopg2
  args:
    user: synapse
    password: your_very_secure_password
    database: synapse
    host: 127.0.0.1
    port: 5432
    cp_min: 5
    cp_max: 10
```

### 5. Настройка nginx

nginx конфигурация управляется отдельным workflow и хранится в `leoserverteam/DevOpsTemplates`.

Убедитесь, что ваш nginx проксирует:
- `matrix.leonet.site` → `127.0.0.1:8008` (Synapse)
- `chat.leonet.site` → `127.0.0.1:8080` (Element Web)
- `sfo.leonet.site` → `127.0.0.1:7880` (LiveKit)

### 6. Установка SSL сертификатов

Убедитесь, что ваши сертификаты расположены по пути:
```
/etc/letsencrypt/live/leonet.site/
├── fullchain.pem
└── privkey.pem
```

```bash
docker-compose up -d
```

Проверьте статус:
```bash
docker-compose ps
```

### 8. Проверка работоспособности

```bash
# Matrix API
curl https://matrix.leonet.site/_synapse/admin/v1/server_version

# Element Web
curl https://chat.leonet.site/

# LiveKit
curl https://sfo.leonet.site/livekitconfig
```

## 🔧 Управление

### Просмотр логов

```bash
# Все контейнеры
docker-compose logs -f

# Конкретный сервис
docker-compose logs -f synapse
docker-compose logs -f nginx
```

### Остановка/перезагрузка

```bash
# Остановить
docker-compose down

# Перезагрузить
docker-compose restart

# Пересоздать
docker-compose up -d --force-recreate
```

### Резервная копия БД

```bash
docker-compose exec db pg_dump -U synapse synapse > backup_$(date +%Y%m%d_%H%M%S).sql
```

### Восстановление БД

```bash
docker-compose exec -T db psql -U synapse synapse < backup.sql
```

## 🔐 Безопасность

- Весь трафик через HTTPS/TLS 1.2+ (управляется nginx)
- PostgreSQL запускается в изолированной сети Docker
- Данные хранятся в `/mnt/Share/chat/` вне контейнеров

⚠️ **ВАЖНО**: Перед production:
- Измените `POSTGRES_PASSWORD` на сильный пароль
- Обновите `LIVEKIT_API_KEY` и `LIVEKIT_API_SECRET`
- Включите backup базы данных

## 📚 Дополнительные ресурсы

- [Synapse Documentation](https://matrix-org.github.io/synapse/latest/)
- [Element Web Setup](https://github.com/vector-im/element-web)
- [LiveKit Documentation](https://docs.livekit.io/)
- [Matrix Spec](https://spec.matrix.org/)

## 📝 Структура проекта

```
.
├── docker-compose.yml      # Docker Compose конфигурация
├── .env.example            # Пример переменных окружения
├── nginx/                  # Nginx конфигурация
│   ├── Dockerfile
│   └── nginx.conf
├── synapse/                # Данные Synapse (создаётся при генерации)
├── postgresdata/           # Данные PostgreSQL (создаётся автоматически)
├── synapsedeploy.sh        # Скрипт генерации конфигурации
├── element-config.json     # Конфигурация Element Web
├── livekit.yaml            # Конфигурация LiveKit
└── README.md               # Этот файл
```

## 🐛 Решение проблем

### Nginx не стартует
```bash
docker-compose logs nginx
# Проверьте пути к SSL сертификатам в /etc/letsencrypt/live/leonet.site/
```

### Synapse не подключается к БД
```bash
docker-compose logs synapse
# Убедитесь, что пароль в homeserver.yaml совпадает с POSTGRES_PASSWORD в .env
```

### Element не видит Synapse
- Проверьте `element-config.json` (base_url должен быть правильным)
- Проверьте CORS headers в homeserver.yaml

## 📄 Лицензия

Matrix - Apache 2.0
Element - AGPL v3
LiveKit - Apache 2.0
