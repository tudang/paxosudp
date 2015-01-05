#!/bin/sh


echo "Terminate Acceptors and Proposers"
ssh node70 "pkill acceptor"
ssh node71 "pkill acceptor"
ssh node72 "pkill acceptor"
ssh node74 "pkill proposer"
echo "Experiment end successfully"
