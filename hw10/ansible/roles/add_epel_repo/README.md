### Role Name
### =========

Роль для добавления epel репозитория.

### Requirements
### ------------

Centos/7.

### Role Variables
### --------------

- epel_repo_url - url для доступа к epel репозиторию
- epel_repo_gpg_key_url - url для доступа к ключу epel репозитория
- epel_repofile_path - местоположение описания репозитария на локальной машине `/etc/yum.repos.d/epel.repo`

### Example Playbook
### ----------------

```
    - hosts: servers
      roles:
         - { role: add_epel_repo }
```
