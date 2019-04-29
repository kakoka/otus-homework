### Role Name

Конфигурирование aditd для приема логов.

#### 1. Requirements

- Centos/7

#### 3. Example Playbook

```
---
- name: Do something
  hosts: servers

  roles:
  - { role: conf_auditd_server }
  ```