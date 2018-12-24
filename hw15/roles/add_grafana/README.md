### Role Name

Развертывание Grafana.

#### 1. Requirements

- Centos/7

#### 2. Role Variables

- domain_name: `domain.name`

#### 3. Example Playbook

```
---
- name: Do something
  hosts: servers

  roles:
  - { role: add_grafana }
```