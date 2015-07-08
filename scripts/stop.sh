#!/bin/sh


echo "Terminate Acceptors and Proposers"
ssh node70 "pkill acceptor"
ssh node71 "pkill acceptor"
ssh node72 "pkill acceptor"
ssh node74 "pkill proposer"
ssh node75 "pkill learner"
echo "Experiment end successfully"
