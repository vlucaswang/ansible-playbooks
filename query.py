#!/usr/bin/env python2

import pysphere 
import re
import sys
try:
    import json
except ImportError:
    import simplejson as json

server_fqdn = "vcenter1"
server_username = "root"
server_password = "vmware"

def vcenter_connect(server_fqdn, server_username, server_password):
    vserver = pysphere.VIServer()
    try:
        vserver.connect(server_fqdn, server_username, server_password)
    except Exception as error:
        print(('Could not connect to vCenter: %s') % (error))

    return vserver


def hostinfo(name):
    vserver = vcenter_connect(server_fqdn,server_username,server_password)
    try:
        vm = vserver.get_vm_by_name(name)
    except Exception as e:
        print("[Error]: %s" % e)
        sys.exit(1)

    # Inject some variables for all hosts
    vars = {
        'admin'              : 'root',
        'source_database'    : 'VMWare'
    }

    if 'ldap' in name.lower():
        vars['baseDN'] = 'dc=example,dc=org'


    print json.dumps(vars, indent=4)

def grouplist():
    inventory ={}
    inventory['local'] = [ '127.0.0.1' ]
    vserver = vcenter_connect(server_fqdn,server_username,server_password)
    vms_in_vserver = vserver.get_registered_vms(status='poweredOn')
    inventory["no_group"] = {
        'hosts' : []
    }

    for vsphere_vm in vms_in_vserver:
        virtual_machine = vserver.get_vm_by_path(vsphere_vm)
        virtual_machine_name = virtual_machine.get_property('name')
        inventory['no_group']['hosts'].append(virtual_machine_name)

    print json.dumps(inventory, indent=4)

if __name__ == '__main__':
    if len(sys.argv) == 2 and (sys.argv[1] == '--list'):
        grouplist()
    elif len(sys.argv) == 3 and (sys.argv[1] == '--host'):
        hostinfo(sys.argv[2])
    else:
        print "Usage: %s --list or --host <hostname>" % sys.argv[0]
        sys.exit(1)
