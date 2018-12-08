### Role Name

Обновление ядра до текущей версии из репозитория ELRepo.

#### 1. Requirements

- Centos/7

#### 2. Role Variables

- grub_build_command: grub2-mkconfig -o

#### 3. Example Playbook

```
---
- name: Do something
  hosts: servers

  roles:
  - { role: upgrade_kernel }
  ```