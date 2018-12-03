### Role Name

Установка ранее собранного nginx с модулем статистики из локального репозитория.

#### 1. Requirements

- Centos/7
- Перед установкой nginx необходимо добавить локальный репозиторий.

#### 2. Role Variables

- nginx_port - порт сервера, `8080`
- nginx_web_root - каталог, где лежит контент сайта, `/var/www/html` 
- nginx_conf_folder - каталог, где лежит конфиг nginx, `/etc/nginx`
- nginx_conf_def_folder - каталог где лежат конфиги сайтов, `/etc/nginx/conf.d`

#### 3. Example Playbook

```
---
- name: Nginx server deploy
  hosts: servers

  roles:
  - { role: deploy_nginx_server }
  ```