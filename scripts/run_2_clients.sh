#!/bin/sh

function usage {
  echo "Usage: run_experiments.sh <Number-of-clients>"
}

if [ $# -lt 1 ]; then
  echo 1>&2 " missing number of clients"
  usage
  exit 2
fi
EXEC_DIR="/home/danghu/paxosudp/build/sample"

ssh node80 "nohup $EXEC_DIR/acceptor 0 $EXEC_DIR/paxos.conf > Acceptor0.log 2>&1 &"
ssh node82 "nohup $EXEC_DIR/acceptor 1 $EXEC_DIR/paxos.conf > Acceptor1.log 2>&1 &"
ssh node83 "nohup $EXEC_DIR/acceptor 2 $EXEC_DIR/paxos.conf > Acceptor2.log 2>&1 &"
ssh node85 "nohup $EXEC_DIR/proposer 0 $EXEC_DIR/paxos.conf > Proposer0.log 2>&1 &"
sleep 1
for i in {1..3}
do
ssh node80 "nohup bwm-ng /home/danghu/paxosudp/scripts/bwm-ng.conf > /home/danghu/log-bwm/2/acceptor0experiment$i.csv 2>&1 &"
ssh node82 "nohup bwm-ng /home/danghu/paxosudp/scripts/bwm-ng.conf > /home/danghu/log-bwm/2/acceptor1experiment$i.csv 2>&1 &"
ssh node83 "nohup bwm-ng /home/danghu/paxosudp/scripts/bwm-ng.conf > /home/danghu/log-bwm/2/acceptor2experiment$i.csv 2>&1 &"
ssh node85 "nohup bwm-ng /home/danghu/paxosudp/scripts/bwm-ng.conf > /home/danghu/log-bwm/2/proposer0experiment$i.csv 2>&1 &"
ssh node84 "nohup bwm-ng /home/danghu/paxosudp/scripts/bwm-ng.conf > /home/danghu/log-bwm/2/client1experiment$i.csv 2>&1 &"
ssh node86 "nohup bwm-ng /home/danghu/paxosudp/scripts/bwm-ng.conf > /home/danghu/log-bwm/2/client2experiment$i.csv 2>&1 &"
ssh node84 "nohup $EXEC_DIR/client $EXEC_DIR/paxos.conf 0 1 64 1 > Client1.log 2>&1 &"
ssh node86 "$EXEC_DIR/client $EXEC_DIR/paxos.conf 0 1 64 2"
done
echo "Terminate Acceptors and Proposers"
ssh node80 "pkill acceptor"
ssh node82 "pkill acceptor"
ssh node83 "pkill acceptor"
ssh node85 "pkill proposer"
ssh node84 "pkill client"
ssh node86 "pkill client"
echo "Experiment end successfully"
