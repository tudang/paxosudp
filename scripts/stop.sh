#!/bin/sh

function usage {
  echo "Usage: stop.sh"
}


echo "Terminate Acceptors and Proposers"
ssh node80 "pkill acceptor"
ssh node82 "pkill acceptor"
ssh node83 "pkill acceptor"
ssh node85 "pkill proposer"
echo "Experiment end successfully"
