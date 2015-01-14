#!/bin/sh

if [ $# -lt 2 ] ; then
  echo "usage: udptest.sh [#learners] [#outstanding]"
  exit 1
fi

N="$1"
OST="$2"

BWM_DIR="/home/danghu/log-bwm"
EXEC_DIR="/home/danghu/paxosudp/build/sample"
#start acceptors & proposer
ssh node70 "nohup $EXEC_DIR/acceptor 0 $EXEC_DIR/paxos.conf > experiment_log/acceptor0.log 2>&1 &"
ssh node71 "nohup $EXEC_DIR/acceptor 1 $EXEC_DIR/paxos.conf > experiment_log/acceptor1.log 2>&1 &"
ssh node72 "nohup $EXEC_DIR/acceptor 2 $EXEC_DIR/paxos.conf > experiment_log/acceptor2.log 2>&1 &"
ssh node74 "nohup $EXEC_DIR/proposer 0 $EXEC_DIR/paxos.conf > experiment_log/proposer0.log 2>&1 &"

#start bwm-ng on acceptors & proposer
ssh node70 "nohup bwm-ng $EXEC_DIR/bwm-ng.conf > $BWM_DIR/$N/acceptor0.csv 2>&1 &"
ssh node71 "nohup bwm-ng $EXEC_DIR/bwm-ng.conf > $BWM_DIR/$N/acceptor1.csv 2>&1 &"
ssh node72 "nohup bwm-ng $EXEC_DIR/bwm-ng.conf > $BWM_DIR/$N/acceptor2.csv 2>&1 &"
ssh node74 "nohup bwm-ng $EXEC_DIR/bwm-ng.conf > $BWM_DIR/$N/proposer0.csv 2>&1 &"
            nohup bwm-ng $EXEC_DIR/bwm-ng.conf > $BWM_DIR/$N/client0.csv 2>&1 &

for ((i=1; i<=N; i++ ))
do
  c=$[$i+1]
  ssh node$c "nohup $EXEC_DIR/learner $i $EXEC_DIR/paxos.conf > experiment_log/learner$i.log 2>&1 &"
  ssh node$c "nohup bwm-ng $EXEC_DIR/bwm-ng.conf > $BWM_DIR/$N/learner$i.csv 2>&1 &"
done

#run the client
$EXEC_DIR/client $EXEC_DIR/paxos.conf 0 $OST 8192 0 
mv client0-$OST-8192B.csv udp-$N-$OST.csv

echo "Terminate Acceptors and Proposers"

ssh node70 "pkill acceptor"
ssh node71 "pkill acceptor"
ssh node72 "pkill acceptor"
ssh node74 "pkill proposer"
for ((i=1; i<=N; i++ ))
  do
  c=$[$i+1]
  ssh node$c "pkill learner"
  done
echo "Experiment end successfully"
