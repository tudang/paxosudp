#!/bin/sh

EXEC_DIR="/home/danghu/paxosudp/build/sample"
CONF_FILE="/home/danghu/paxosudp/multicast.conf"
LOG_DIR="/home/danghu/paxosudp/scripts/log"
#start acceptors & proposer
ssh node70 "nohup $EXEC_DIR/acceptor 0 $CONF_FILE > $LOG_DIR/acceptor0.log 2>&1 &"
ssh node71 "nohup $EXEC_DIR/acceptor 1 $CONF_FILE > $LOG_DIR/acceptor1.log 2>&1 &"
ssh node72 "nohup $EXEC_DIR/acceptor 2 $CONF_FILE > $LOG_DIR/acceptor2.log 2>&1 &"
ssh node74 "nohup $EXEC_DIR/proposer 0 $CONF_FILE > $LOG_DIR/proposer0.log 2>&1 &"
ssh node75 "nohup $EXEC_DIR/learner 0 $CONF_FILE > $LOG_DIR/learner0.log 2>&1 &"
