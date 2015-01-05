#!/bin/sh

EXEC_DIR="/home/danghu/paxosudp/build/sample"

ssh node70 "nohup $EXEC_DIR/acceptor 0 $EXEC_DIR/paxos.conf > Acceptor0.log 2>&1 &"
ssh node71 "nohup $EXEC_DIR/acceptor 1 $EXEC_DIR/paxos.conf > Acceptor1.log 2>&1 &"
ssh node72 "nohup $EXEC_DIR/acceptor 2 $EXEC_DIR/paxos.conf > Acceptor2.log 2>&1 &"
ssh node74 "nohup $EXEC_DIR/proposer 0 $EXEC_DIR/paxos.conf > Proposer0.log 2>&1 &"
