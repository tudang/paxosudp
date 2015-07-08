#!/bin/sh

if [ $# -lt 4 ] ; then
  echo "usage: $0 [#learners] [#outstanding] [#value-size] [#experiment-id]"
  exit 1
fi

N="$1"
OST="$2"
SIZE=$3
ID=$4

EXEC_DIR="/home/danghu/paxosudp/build/sample"
CONF_FILE="/home/danghu/paxosudp/multicast.conf"
LOG_DIR="/home/danghu/paxosudp/scripts/log"
#start acceptors & proposer
ssh node70 "nohup $EXEC_DIR/acceptor 0 $CONF_FILE > $LOG_DIR/acceptor0.log 2>&1 &"
ssh node71 "nohup $EXEC_DIR/acceptor 1 $CONF_FILE > $LOG_DIR/acceptor1.log 2>&1 &"
ssh node72 "nohup $EXEC_DIR/acceptor 2 $CONF_FILE > $LOG_DIR/acceptor2.log 2>&1 &"
ssh node74 "nohup $EXEC_DIR/proposer 0 $CONF_FILE > $LOG_DIR/proposer0.log 2>&1 &"
ssh node75 "nohup $EXEC_DIR/learner 0 $CONF_FILE > $LOG_DIR/learner0.log 2>&1 &"

#run the client
$EXEC_DIR/client $CONF_FILE 0 $OST $SIZE 0
#mv client0-$OST-${SIZE}B.csv UDP-$ID-$OST-$SIZE-$N.csv

echo "Terminate Acceptors and Proposers"

ssh node70 "pkill acceptor"
ssh node71 "pkill acceptor"
ssh node72 "pkill acceptor"
ssh node74 "pkill proposer"
ssh node75 "pkill learner"
echo "Experiment end successfully"
