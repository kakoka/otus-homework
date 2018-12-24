### Role Name

Развертывание node_exporter.

#### 1. Requirements

- Centos/7

#### 2. Role Variables

- node_exp_ver: 0.17.0
- node_listen_address: "127.0.0.1:9100"
- node_collector_dir: /var/lib/node-exporter/textfile_collector

#### 3. Example Playbook

```
---
- name: Do something
  hosts: servers

  roles:
  - { role: add_node_exporter }
```