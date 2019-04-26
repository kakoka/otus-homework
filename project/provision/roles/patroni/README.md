### Role Name

Установка patroni.

#### 1. Requirements

- Centos/7

#### 3. Example Playbook

```
---
- name: Do something
  hosts: servers

  roles:
  - { role: patroni }
  ```