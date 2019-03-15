Role Name
=========

Setup Kerberos KDC.

Requirements
------------

DNS, NTP and KDC services required.

Role Variables
--------------

kadmin_user: root/admin
kadmin_pass: pass
kerb_user: vagrant
kerb_user_pass: vagrant

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: servers
      roles:
         - { role: kerberos-client }
