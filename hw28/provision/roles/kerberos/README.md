Role Name
=========

Setup Kerberos KDC.

Requirements
------------

DNS and NTP services required.

Role Variables
--------------

db_pass: pass
realm: OTUS.TEST
kadmin_user: root/admin
kadmin_pass: pass
kuser_user: vagrant
kuser_pass: vagrant

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: servers
      roles:
         - { role: kerberos }
