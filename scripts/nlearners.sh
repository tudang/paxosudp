#!/bin/sh

EXEC_DIR="/home/danghu/paxosudp/centos6/sample"
EXEC_DIR2="/home/danghu/paxosudp/centos7/sample"
CONFIG_FILE="/home/danghu/paxosudp/scripts/paxos.conf"
#start acceptors & proposer
ssh node70 "nohup $EXEC_DIR/acceptor 0 $CONFIG_FILE > experiment_log/Acceptor0.log 2>&1 &"
ssh node71 "nohup $EXEC_DIR/acceptor 1 $CONFIG_FILE > experiment_log/Acceptor1.log 2>&1 &"
ssh node72 "nohup $EXEC_DIR/acceptor 2 $CONFIG_FILE > experiment_log/Acceptor2.log 2>&1 &"
ssh node74 "nohup $EXEC_DIR/proposer 0 $CONFIG_FILE > experiment_log/Proposer0.log 2>&1 &"


ssh node91 "nohup $EXEC_DIR2/learner 1 $CONFIG_FILE > experiment_log/learner.log 2>&1 &"

#run the client
$EXEC_DIR2/client $CONFIG_FILE 0 $1 1470 1 

echo "Terminate Acceptors and Proposers"

ssh node70 "pkill acceptor"
ssh node71 "pkill acceptor"
ssh node72 "pkill acceptor"
ssh node74 "pkill proposer"
ssh node91 "pkill learner"
echo "Experiment end successfully"
