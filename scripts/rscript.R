# run command
# Rscript paxosthroughput.r client1-45-1500B.csv client1-50-1500B.csv client1-55-1500B.csv
# load libraries
library("ggplot2")
library("plyr")

# set working directory
setwd("/Users/hdang/paxos_throughput")
pdf("stat.pdf")
args<-commandArgs(TRUE)
client_id = 1
df <- data.frame(outstanding=numeric(), pktsize=numeric(), time=numeric(), latency=numeric(),count=numeric(), mean_lat=numeric(), client=numeric(), Mbps=numeric())
for (i in args) {
  c1 = read.csv(i, col.names=c('outstanding','pktsize','time', 'latency'))
  c1stat <- ddply(c1, c("outstanding", "pktsize", "time"), summarise, count=length(latency), mean_lat=mean(latency))
  c1stat$client <- client_id
  client_id <- client_id + 1
  c1stat$Mbps <- c1stat$pktsize * 8 * c1stat$count / 10^6
  df <- rbind(df, c1stat)
}

ggplot(data=df, aes(x=time, y=Mbps, group=outstanding, colour=factor(outstanding))) + geom_line() + geom_point()
dev.off()
