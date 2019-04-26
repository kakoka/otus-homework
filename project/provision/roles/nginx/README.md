### Role Name

Установка nginx в качестве reverse proxe.

#### 1. Requirements

- Centos/7
- Перед установкой nginx необходимо добавить локальный репозиторий.

#### 2. Role Variables

- nginx_port - порт сервера, `80`
- nginx_web_root - `/var/www/html` 
- nginx_conf_folder - `/etc/nginx`
- nginx_conf_def_folder - `/etc/nginx/conf.d`

#### 3. Example Playbook

```
---
- name: Nginx server deploy
  hosts: servers

  roles:
  - { role: add_nginx_server }
  ```