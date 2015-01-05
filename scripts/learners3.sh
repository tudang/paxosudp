#!/bin/sh

EXEC_DIR="/home/danghu/paxosudp/build/sample"
n=4

ssh node70 "nohup $EXEC_DIR/acceptor 0 $EXEC_DIR/paxos.conf > Acceptor0.log 2>&1 &"
ssh node71 "nohup $EXEC_DIR/acceptor 1 $EXEC_DIR/paxos.conf > Acceptor1.log 2>&1 &"
ssh node72 "nohup $EXEC_DIR/acceptor 2 $EXEC_DIR/paxos.conf > Acceptor2.log 2>&1 &"
ssh node74 "nohup $EXEC_DIR/proposer 0 $EXEC_DIR/paxos.conf > Proposer0.log 2>&1 &"
for i in {1..3}
  do

  ssh node70 "nohup bwm-ng /home/danghu/paxosudp/scripts/bwm-ng.conf > /home/danghu/log-bwm/$n/acceptor0exp$i.csv 2>&1 &"
  ssh node71 "nohup bwm-ng /home/danghu/paxosudp/scripts/bwm-ng.conf > /home/danghu/log-bwm/$n/acceptor1exp$i.csv 2>&1 &"
  ssh node72 "nohup bwm-ng /home/danghu/paxosudp/scripts/bwm-ng.conf > /home/danghu/log-bwm/$n/acceptor2exp$i.csv 2>&1 &"
  ssh node74 "nohup bwm-ng /home/danghu/paxosudp/scripts/bwm-ng.conf > /home/danghu/log-bwm/$n/proposer0exp$i.csv 2>&1 &"
  ssh node75 "nohup bwm-ng /home/danghu/paxosudp/scripts/bwm-ng.conf > /home/danghu/log-bwm/$n/learner1exp$i.csv 2>&1 &"
  ssh node76 "nohup bwm-ng /home/danghu/paxosudp/scripts/bwm-ng.conf > /home/danghu/log-bwm/$n/learner2exp$i.csv 2>&1 &"
  ssh node77 "nohup bwm-ng /home/danghu/paxosudp/scripts/bwm-ng.conf > /home/danghu/log-bwm/$n/learner3exp$i.csv 2>&1 &"
              nohup bwm-ng /home/danghu/paxosudp/scripts/bwm-ng.conf > /home/danghu/log-bwm/$n/client1exp$i.csv 2>&1 &

  ssh node75 "nohup $EXEC_DIR/learner $EXEC_DIR/paxos.conf > learner1.log 2>&1 &"
  ssh node76 "nohup $EXEC_DIR/learner $EXEC_DIR/paxos.conf > learner2.log 2>&1 &"
  ssh node77 "nohup $EXEC_DIR/learner $EXEC_DIR/paxos.conf > learner3.log 2>&1 &"
                    $EXEC_DIR/client $EXEC_DIR/paxos.conf 0 1 8192 1 
  mv client1-1-8192B.csv latency$i.csv
  done

echo "Terminate Acceptors and Proposers"

ssh node70 "pkill acceptor"
ssh node71 "pkill acceptor"
ssh node72 "pkill acceptor"
ssh node74 "pkill proposer"
ssh node75 "pkill learner"
ssh node76 "pkill learner"
ssh node77 "pkill learner"

echo "Experiment end successfully"
