# Доска объявлений(Kubernetes)

[![hexlet-check](https://github.com/Mrac044/devops-engineer-from-scratch-project-319/actions/workflows/hexlet-check.yml/badge.svg)](https://github.com/Mrac044/devops-engineer-from-scratch-project-319/actions)

Разверните приложение в Managed Kubernetes в облаке. Кластер описывается в Terraform, приложение выкатывается Helm-чартом, а метрики, логи и секреты подключаются к кластеру.

Учебный проект Хекслета: https://ru.hexlet.io/programs/devops-engineer-from-scratch
Как это должно работать: https://asciinema.org/a/v4evn7XjCdou7Yh71IG0ljb0W

## Стек

- Инструменты

## Установка

<!-- Опишите установку: клонирование, зависимости, переменные окружения -->
- Инициализация бекенда terraform. acces_key/secret_key должны быть описаны в `secret.backend.tfvars`:
`terraform init -backend-config=secret.backend.tfvars`


```bash
git clone https://github.com/Mrac044/devops-engineer-from-scratch-project-319.git
cd devops-engineer-from-scratch-project-319
```

## Использование

<!-- Добавьте примеры запуска и запись asciinema — именно это смотрит работодатель -->
Для создания инфраструктуры необходимы:

- Terraform >= 1.11
- Yandex Cloud CLI (`yc`)
- настроенный аккаунт Yandex Cloud
- доступ к нужному Cloud и Folder
- SSH-клиент
- Kubernetes CLI (`kubectl`) для проверки созданного кластера

Terraform-код находится в директории `terraform/`.

### Настройка Yandex Cloud

Необходимо выполнить аутентификацию в Yandex Cloud CLI:

```bash
yc init

---

<details>
<summary>Автоматические тесты Хекслета</summary>

Тесты запускаются на каждый коммит. За запуск отвечает файл `.github/workflows/hexlet-check.yml` — не удаляйте и не переименовывайте ни его, ни репозиторий.

</details>

## О Хекслете

[Хекслет](https://ru.hexlet.io/) — школа программирования: авторские программы обучения с практикой, поддержкой наставников и реальными проектами, которые остаются в резюме. Этот репозиторий — один из таких проектов.

##
