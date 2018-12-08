### Role Name

Добавление параметров ядра в sysctl.conf.
Sysctl как служба в systemd.

#### 1. Requirements

- Centos/7

#### 2. Role Variables

Параметризованный sysctl.conf находится в templates/sysctl.conf.j2, можно добавлять в шаблон нужные опции и генерировать новый конфиг. 
Переменные в defaults/main.yml.

Пример:

- net_ipv6_conf_all_disable_ipv6: 1

в шаблоне:

- net.ipv6.conf.all.disable_ipv6={{ net_ipv6_conf_all_disable_ipv6 }}


#### 3. Example Playbook

```
---
- name: Do something
  hosts: servers

  roles:
  - { role: tune_kernel }
  ```