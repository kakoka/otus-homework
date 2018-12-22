### Role Name

Пересылка логов аудита (auditd) на центральный сервер, без сохранения на локальном, кроме случая переполнения очереди. [audit clinet -> audit server]

#### 1. Requirements

- Centos/7

#### 3. Example Playbook

```
---
- name: Do something
  hosts: servers

  roles:
  - { role: conf_audit_client }
```