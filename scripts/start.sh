#!/bin/sh

EXEC_DIR="/home/danghu/paxosudp/build/sample"

ssh node70 "nohup $EXEC_DIR/acceptor 0 $EXEC_DIR/paxos.conf > Acceptor0.log &"
ssh node71 "nohup $EXEC_DIR/acceptor 1 $EXEC_DIR/paxos.conf > Acceptor1.log &"
ssh node72 "nohup $EXEC_DIR/acceptor 2 $EXEC_DIR/paxos.conf > Acceptor2.log &"
ssh node74 "nohup $EXEC_DIR/proposer 0 $EXEC_DIR/paxos.conf > Proposer0.log &"
ssh node2 "nohup $EXEC_DIR/learner 1 $EXEC_DIR/paxos.conf > Learner1.log &"
ssh node3 "nohup $EXEC_DIR/learner 2 $EXEC_DIR/paxos.conf > Learner2.log &"
ssh node4 "nohup $EXEC_DIR/learner 3 $EXEC_DIR/paxos.conf > Learner3.log &"
ssh node5 "nohup $EXEC_DIR/learner 4 $EXEC_DIR/paxos.conf > Learner4.log &"
ssh node6 "nohup $EXEC_DIR/learner 5 $EXEC_DIR/paxos.conf > Learner5.log &"
