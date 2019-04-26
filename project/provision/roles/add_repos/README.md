### Role Name

Установка дополнительных репозиториев.

#### 1. Requirements

- Centos/7

#### 2. Role Variables

Переменная `repo` вида 

```
repo:
  - { name, key, url, file}
```
Пример:

```
  - { name: 'epel', key: 'https://download.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7', url: 'https://download.fedoraproject.org/pub/epel/$releasever/$basearch/', file: '/etc/yum.repos.d/epel.repo'}
```

#### 3. Example Playbook

```
---
- name: Do something
  hosts: servers

  roles:
  - { role: add_repos }
  ```