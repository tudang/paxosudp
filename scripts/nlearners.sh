#!/bin/sh

if [ $# -lt 1 ] ; then
  echo "Missing number of learners"
  exit 1
fi

N="$1"

BWM_DIR="/home/danghu/log-bwm"
EXEC_DIR="/home/danghu/paxosudp/build/sample"
#start acceptors & proposer
ssh node70 "nohup $EXEC_DIR/acceptor 0 $EXEC_DIR/paxos.conf > experiment_log/Acceptor0.log 2>&1 &"
ssh node71 "nohup $EXEC_DIR/acceptor 1 $EXEC_DIR/paxos.conf > experiment_log/Acceptor1.log 2>&1 &"
ssh node72 "nohup $EXEC_DIR/acceptor 2 $EXEC_DIR/paxos.conf > experiment_log/Acceptor2.log 2>&1 &"
ssh node74 "nohup $EXEC_DIR/proposer 0 $EXEC_DIR/paxos.conf > experiment_log/Proposer0.log 2>&1 &"

#start bwm-ng on acceptors & proposer
ssh node70 "nohup bwm-ng $EXEC_DIR/bwm-ng.conf > $BWM_DIR/$N/acceptor0.csv 2>&1 &"
ssh node71 "nohup bwm-ng $EXEC_DIR/bwm-ng.conf > $BWM_DIR/$N/acceptor1.csv 2>&1 &"
ssh node72 "nohup bwm-ng $EXEC_DIR/bwm-ng.conf > $BWM_DIR/$N/acceptor2.csv 2>&1 &"
ssh node74 "nohup bwm-ng $EXEC_DIR/bwm-ng.conf > $BWM_DIR/$N/proposer0.csv 2>&1 &"
            nohup bwm-ng $EXEC_DIR/bwm-ng.conf > $BWM_DIR/$N/client0.csv 2>&1 &

for ((i=1; i<=N; i++ ))
do
  if [ $i -eq 42 ]; then c=62; else c=$[$i+1]; fi
  ssh node$c "nohup $EXEC_DIR/learner $EXEC_DIR/paxos.conf > experiment_log/learner$i.log 2>&1 &"
  ssh node$c "nohup bwm-ng $EXEC_DIR/bwm-ng.conf > $BWM_DIR/$N/learner$i.csv 2>&1 &"
done

#run the client
$EXEC_DIR/client $EXEC_DIR/paxos.conf 0 1 8192 1 
mv client1-1-8192B.csv n$N-learners.csv

echo "Terminate Acceptors and Proposers"

ssh node70 "pkill acceptor"
ssh node71 "pkill acceptor"
ssh node72 "pkill acceptor"
ssh node74 "pkill proposer"
for ((i=1; i<=N; i++ ))
  do
  if [ $i -eq 42 ]; then c=62; else c=$[$i+1]; fi
  ssh node$c "pkill learner"
  done
echo "Experiment end successfully"
