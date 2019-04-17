## Курсовой проект 

- Terraform - развертывание инфрастуктуры
- Ansible - приведение инфрастуктуры к желаемому состоянию

Сначала создаем bastion host, забрасываем в него все установочные скрипты, настраиваем прокси, устанавливаем vault, прописываем cridentials, запускаем создание инфрастуктуры

### 1. Облачная инфрастуктура

- Yandex cloud
- Object storage
- Описание приложения

### 2. Развертывание инфрастуктуры

#### 2.1 Доступ к Яндекс.Облаку

На локальной машине необходимо установить Yandex.Cloud CLI и выполнить начальные настройки:

```bash
$ curl https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash && source "/home/otus-user/.bashrc"
$ yc init
```

В процессе инициализации cli инструмента будут запрошены доступы Яндекс.Облака. Будет создан файл `~/.config/yandex-cloud/config.yaml`, с данными для доступа к облаку.

#### 2.2 Создание AWS S3 совместимого бакета и сервисного аккаунта

В веб консоли аккаунта Яндекс.Облака создаем объектное хранилище с именем `otus-infra`, внутри хранилища создаем папку `state`. К сожалению, cli инструментов для этих операции на сегодняшний момент нет.

#### 2.3 Пользователь otus-user, ssh-ключ

На облачную виртуальную машину будем заходить под пользователем `otus-user`. Сгенерируем для него ssh-ключи:

```bash
$ ssh-keygen -t rsa -b 4096 -f /home/otus-user/.ssh/otus-user-key -q -N ""
```

#### 2.4 Использование стартового скрипта

Скрипт `start.sh` создает первую машину в облаке, с которой будет разворачиваться инфрастукртура проекта. При создании ВМ устанавливаются необходимые инструменты для дальнейшей работы, генерируется файл metadata.yml. Так же внутрь новой ВМ в домашний каталог `otus-user` клонируется [репозиторий инфрастурктуры проекта](https://github.com/kakoka/otus-infra.git). Публичная часть ключа `otus-user` должна быть включена в метаданные создаваемой ВМ.

Metadata - данные, которые будут применены скриптами cloud-init при старте ВМ в Яндекс.Облаке.

После старта ВМ необходимо зайти в нее по SSH и выполнить дальнейшую настройку:

```bash
$ ssh -i ~/.ssh/otus-user-key otus-user@$(yc compute instance get bastion --format json | jq -r '.network_interfaces[].primary_v4_address.one_to_one_nat.address')
```

### 3. Настройка первой виртуальной машины в облаке

#### 3.1 Доступ к Яндекс.Облаку

Установим Yandex Cloud CLI:

```bash
$ curl https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash && source "/home/otus-user/.bashrc"
```

С локальной машины из `~/.config/yandex-cloud/config.yaml` возьмем конфигурацию cli и перенесем на виртуальную в такой же файл и по такому же пути. Как альтернатива - можно выполнить команду `yc init`, получить токен и тд.

#### 3.2 Настройка и инициализация Terraform, импорт ранее созданных ресурсов

Убедимся, что в бакете отсутствует старый стейт Terraform. Если он есть, то его необходимо удалить для дальнейшей корректной работы при создании новой инфрастуктуры.

В директории с кодом инфрастуктуры проекта `~/otus-infra` необходимо выполнить инициализацию Terraform.

Для работы Terraform с Яндекс.Облаком необходим провайдер. Провайдер устанавливается автоматически при инициализации в директории с проектом, но для этого необходимы учетные данные из `~/.config/yandex-cloud/config.yaml`.

На этапе создания первой ВМ был сгенерирован новый ssh-ключ для доступа к новосоздаваемым ресурсам `~/.ssh/otus-user.pub`, этот ключ необходимо добавить в файл, содержащий метаданные виртуальных машин.

Инициализация Terraform выполняестя с параметрами, так как мы создаем бэкенд, лежащий в объектном хранилище. Команда инициализации выглядит так:

```bash
$ terraform init -backend-config="access_key=key_id" -backend-config="secret_key=secret" -backend-config="bucket=state"
```

Необходимо создать сервисного пользователя, назначить ему права на каталог, в котором должна быть развернута инфрастуктура и находится уже созданный бакет, а так же получить для него ключи доступа.

```bash
$ yc iam service-account create --name otus-user
$ yc iam access-key create --service-account-name otus-user
$ yc resource-manager folder add-access-binding **ИМЯ_КАТАЛОГА** --role editor --subject serviceAccount:**service_account_id**
```

Вывод команд будет следующим, здесь нам интересны два ключа `key_id`, `secret` и `service_account_id`, которые необходимо зафиксировать в безопасном месте:

<pre>
access_key:
 ...
 **key_id:** xxx...xxx
 **secret:** xxx....xxxxxx
</pre>

Из-за особенностей реализации Яндекс.Облака, между назначением прав пользователю на каталог и работой с ним должно пройти примерно 60 секунд.

В терминологии Terraform мы создаем backend, для хранения Terraform state, который необходим, если предполагается совместное использование этого инструмента.

На этапе создания стартовой ВМ, мы создали виртуальную сеть (my-network) и в ней подсеть (my-subnet). Эти же ресурсы мы описали с помощью терраформ. Заметим, что терраформ ничего не знает о том, что эти ресурсы уже созданы. Поэтому перед развертыванием полной инфрастуктуры проекта необходимо выполнить импорт описанных и уже созданных ресурсов:

```bash
$ terraform import yandex_vpc_network.my-network network_id
$ terraform import yandex_vpc_subnet.my-subnet subnet_id
```

После этого шага все готово к развертыванию полной инфрастуктуры проекта.

Для выполнения всех вышеперчисленных операций написан скрипт `init.sh`, его необходмо выполнить в директории с проектом `~/otus-infra`. Скрипт генирирует файлы `~/otus-infra/providers.tf` и `~/otus-infra/boostrap/metadata.yml` с нужными значениями, содает сервисного пользователя и инициализирует Terraform с нужными бэкендом, импортирует уже созданные ресурсы.

В скрипте в переменную `CATALOG` необходимо подставить имя каталога в облаке в котором будет происходить развертывание инфрастуктуры (в новосозданном аккаунте обычно это каталог `default`).

#### 3.6 Развертывание инфрастуктуры проекта

$ terraform plan

$ terraform apply

Проверяем

$ terraform state list

$ terraform destroy -target target.name

#### 3.7 Ссылки

- [Terraform. Разные AWS профили для S3 бэкенда и окружения](https://notessysadmin.com/terraform-different-aws-profiles-for-s3-backend-and-environment)
- [s3 bucket + terraform backend](https://medium.com/@jmarhee/digitalocean-spaces-as-a-terraform-backend-b761ae426086)
- [Importing Infrastructure in Terraform – Networking](https://ascisolutions.com/blog/2018/07/05/importing-infrastructure-in-terraform-networking/)

#### 3.2 x2go рабочие станции

- Terraform

#### 3.3 Kerberos, NTP, DNS, NFS, Gitlab, Jenkins, Bugzilla, Postgres, RPM репозиторий

#### 3.4

ВМ для быстрой сборки пакетов
- rmp build

#### 3.5 Мониторинг

- Netdata
- PostgesSQL + TimescaleDB
- Prometheus
- Grafana
- Alertd, alertmanager (slack notify)
- postfix

#### 3.6 Коллектор логов

- ELK
- rsyslog
- graylog

#### 3.7 Вычислительные ноды

- terraform
- rmp install, configure
 
Описание билда:
- собирается rpm пакет
- поднимается ВМ, устанавливаются необходимые пакеты
- делается снепшот
- из снепшота поднимаются вычислительные ноды

#### 3.8 Кластер СУБД

- Patroni
- pg_backrest

#### 3.9 Кластерная ФС

- LizardFS

### 4. Ссылки

- http://www.micronarrativ.org/2016/2016-lizardfs.html