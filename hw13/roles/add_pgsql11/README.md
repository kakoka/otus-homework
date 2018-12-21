### Role Name

Установка PostgreSQL 11.

#### 1. Requirements

- Centos/7

#### 3. Example Playbook

```
---
- name: Do something
  hosts: servers

  roles:
  - { role: add_pgsql11 }
  ```