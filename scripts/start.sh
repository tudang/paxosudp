#!/bin/sh

function usage {
  echo "Usage: start.sh"
}

EXEC_DIR="/home/danghu/paxosudp/build/sample"

ssh node80 "nohup $EXEC_DIR/acceptor 0 $EXEC_DIR/paxos.conf > Acceptor0.log 2>&1 &"
ssh node82 "nohup $EXEC_DIR/acceptor 1 $EXEC_DIR/paxos.conf > Acceptor1.log 2>&1 &"
ssh node83 "nohup $EXEC_DIR/acceptor 2 $EXEC_DIR/paxos.conf > Acceptor2.log 2>&1 &"
ssh node85 "nohup $EXEC_DIR/proposer 0 $EXEC_DIR/paxos.conf > Proposer0.log 2>&1 &"
#ssh node84 "nohup $EXEC_DIR/client $EXEC_DIR/paxos.conf 0 1 1500 0 > Client0.log 2>&1 &"
