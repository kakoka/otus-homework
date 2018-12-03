### Role Name

Установка локального репозитория.

#### 1. Requirements

- Centos/7

#### 2. Role Variables

- local_repo - имя файла локального репозитория, `vts.repo`
- dest_folder - папка, куда добавляем локальный репозиторий, `/etc/yum.repos.d/`

#### 3. Example Playbook

```
---
- name: Add local repo
  hosts: servers

  roles:
  - { role: add_local_repo }
  ```