Role Name
=========

Setup NFS client with automount service.

Requirements
------------

DNS, NTP, KDC and NFS services required.

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: servers
      roles:
         - { role: nfs4-client }
