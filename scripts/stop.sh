#!/bin/sh


echo "Terminate Acceptors and Proposers"
ssh node70 "pkill acceptor"
ssh node71 "pkill acceptor"
ssh node72 "pkill acceptor"
ssh node74 "pkill proposer"
ssh node2 "pkill learner"
ssh node3 "pkill learner"
ssh node4 "pkill learner"
ssh node5 "pkill learner"
ssh node6 "pkill learner"
echo "Experiment end successfully"
