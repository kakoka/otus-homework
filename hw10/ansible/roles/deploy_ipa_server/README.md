### Role Name

Роль для установки IPA-сервера.

#### 1. Requirements

Centos/7.

#### 2. Role Variables

- ipa_domain - имя домена `homework.local`
- ipa_realm - имя домена, но заглавными буквами `HOMEWORK.LOCAL`
- ipa_pkg:
  - ipa-server
  - ipa-server-dns
  - bind-dyndb-ldap  - список устанавливаемых пакетов 
- ipa_install_command - команда для установки сервера `ipa-server-install -U`
- ipa_add_rule_command - команда для создания правила `ipa sudorule-add `
- ipa_grant_admin_command - команда для добавления пользователя в правило `ipa sudorule-add-user`
- ipa_user_add - команда для добавления пользователя  `ipa user-add`
- ipa_add_to_group - - команда для добавления пользователя в группу `ipa group-add-member`

#### 3. Example Playbook

    - hosts: servers
      roles:
         - { role: deploy_ipa_server }
