Role Name
=========

Setup chronyd as ntp-client.

Requirements
------------

DNS, NTP services required.

Role Variables
--------------

ntp_timezone: Europe/Moscow

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: servers
      roles:
         - { role: ntp-client }
