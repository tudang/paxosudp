#!/usr/bin/env python

import argparse
import subprocess
import sys
import shlex
import os
import time
from threading import Timer
import ConfigParser

def send_term_signal(host, role):
    cmd = "ssh %s pkill %s" % (host, role)
    proc = subprocess.Popen(shlex.split(cmd),
                        shell=False,
                        stdout=subprocess.PIPE,
                        stderr=subprocess.PIPE)
    proc.wait()


def kill_all(**args):
    send_term_signal(args['client'], 'client')
    send_term_signal(args['proposer'], 'proposer')
    send_term_signal(args['learner'], 'learner')
    acceptors = args['acceptor']
    for a in acceptors:
        send_term_signal(a, 'acceptor')
    
def run_client(node, bin_dir, proposer_id, config, outstanding, value_size, client_id):
    cmd = "ssh {host} {bin_dir}/client {config} {proposer_id} {outstanding} {value_size} {client_id}".format(host=node, 
                bin_dir=bin_dir, proposer_id=proposer_id, config=config, outstanding=outstanding, 
                value_size=value_size, client_id=client_id)
    with open("%s.dat" % (node), "w+") as out:
        with open("%s.err" % (node), "w+") as err:
            ssh = subprocess.Popen(shlex.split(cmd),
                        shell=False,
                        stdout=out,
                        stderr=err)
    return ssh

def run_agent(role, node, bin_dir, agent_id, config):
    cmd = "ssh {host} {bin_dir}/{role} {agent_id} {config}".format(host=node, 
            role=role, bin_dir=bin_dir, agent_id=agent_id, config=config)
    ssh = subprocess.Popen(shlex.split(cmd),
                           shell=False,
                           stdout=subprocess.PIPE,
                           stderr=subprocess.PIPE)
    return ssh

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Run NetPaxos experiment.')
    parser.add_argument('--bin-dir', default='build/sample', help='bin directory')
    parser.add_argument('--config', default='udppaxos.conf', help='config file of libpaxos')
    args = parser.parse_args()
    config = ConfigParser.ConfigParser()
    config.read('demo.cfg')

    # get binary directory and config file path
    cur_dir = os.path.dirname(os.path.realpath(__file__))
    bin_dir = '/'.join([cur_dir , args.bin_dir])
    config_file = '/'.join([cur_dir , args.config])

    # processes is a dict to map role -> addr
    processes = {}
    # run acceptors
    acceptors = []
    num_acceptor = config.getint('acceptor', 'total')
    for i in range(num_acceptor):
        acceptors.append( config.get('acceptor', 'addr%d' % (i+1)) )
        run_agent('acceptor', acceptors[i], bin_dir, i, config_file)

    processes['acceptor'] = acceptors

    time.sleep(1)
    # run proposers
    proposer = config.get('proposer', 'addr')
    processes['proposer'] = proposer
    run_agent('proposer', proposer, bin_dir, 0, config_file)

    # run learner
    learner = config.get('learner', 'addr')
    processes['learner']  = learner
    run_agent('learner', learner, bin_dir, 0, config_file)

    time.sleep(1)
    # run client
    client = config.get('client' , 'addr')
    processes['client']  = client
    t = Timer(120, kill_all, kwargs=processes)
    t.start()
    run_client(client, bin_dir, 0, config_file, 3, 1024, 0)
