### Role Name

Установка atop как сервис в systemd.

#### 1. Requirements

- Centos/7
- Перед установкой nginx необходимо добавить пакет atop.

#### 2. Role Variables

- atop_log_path: /var/log/atop
- atop_bin_path: /usr/bin
- atop_pid_file: /var/run/atop.pid
- atop_polling_interval: 15

#### 3. Example Playbook

```
---
- name: Do something
  hosts: servers

  roles:
  - { role: setup_atop_service }
  ```