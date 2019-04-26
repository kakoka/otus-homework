### Role Name

Развертывание prometheus.

#### 1. Requirements

- Centos/7

#### 2. Role Variables

- prom_ver: 2.6.0
- prom_user: prometheus
- prom_group: prometheus
- prom_conf_dir: /etc/prom
- prom_db_dir: /var/lib/prom
- prom_listen_address: "127.0.0.1:9090"
- prom_ext_url: "{{ ansible_fqdn }}"
- prom_retention: "14d"

#### 3. Example Playbook

```
---
- name: Do something
  hosts: servers

  roles:
  - { role: add_prometheus }
```