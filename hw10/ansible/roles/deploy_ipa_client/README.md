### Role Name

Роль для установки IPA-клиента.

#### 1. Requirements

Centos/7, необходимо наличине локального IPA-сервера.

#### 2. Role Variables

- ipa_server_address - адрес IPA-сервера `192.168.11.150`
- ipa_fqdn - fqdn-имя `master.homework.local`
- ipa_domain - имя домена `homework.local`
- ipa_realm - имя домена, но заглавными буквами `HOMEWORK.LOCAL`
- ipa_pkg:
  - ipa-client - список устанавливаемых пакетов 
- ipa_install_command - команда для установки клиента `ipa-client-install -U`

#### 3. Example Playbook

    - hosts: servers
      roles:
         - { role: deploy_ipa_client }