Role Name
=========

Setup chronyd as NTP server.

Requirements
------------

DNS service required.

Role Variables
--------------

ntp_timezone: Europe/Moscow
ntp_server: 0.rhel.pool.ntp.org

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: servers
      roles:
         - { role: ntp }
