### Role Name

Установка пакетов для мониторинга.

#### 1. Requirements

- Centos/7

#### 2. Role Variables

Список добавляемых пакетов:

- monitoring_packages_list:
  - procps-ng
  - ...
  - tuned

#### 3. Example Playbook

```
---
- name: Do something
  hosts: servers

  roles:
  - { role: deploy_monitoring_tools }
  ```