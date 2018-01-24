#!/usr/bin/env Rscript
# We test the statistical difference between Reichler-Kim indices computed for different experiments.

args = commandArgs(trailingOnly=TRUE)

# test if there are the correct number of arguments: if not, return an error
if (length(args)!=7) {
  stop("KS_index.R: You should use 7 arguments: the two paths data, plots dir, exp1, exp2, year1, year2", call.=FALSE)
}

path=args[1]
rkdir=args[2]
plotdir=args[3]
exp1=args[4]
exp2=args[5]
year1=args[6]
year2=args[7]

# Initial plot:
var_name=c('t2m','msl','qnet','tp','ewss','nsss','SST','SSS','SICE','T','U','V','Q')

nb_var=length(var_name)
ylimites=c(0.8,1.2)

postscript(paste(plotdir,'/reichler_kim_scores_stat_',exp1,'_',exp2,'.eps',sep=''), width = 550, height = 300)
plot(NULL,main='Reichler-Kim normalized index\n Symbols appear in red when ensemble distribution statistically differ according to a KS test, otherwise in blue',xaxt = "n",xlab='var',ylab='Normalized RK index',xlim=c(1,nb_var),ylim=ylimites)
axis(1,at=1:nb_var,labels=var_name)
abline(v=seq(0.5,nb_var-0.5,1),lty=3)
abline(h=1)
shift=0.2

# Adding indices for all variables and experiments

for (ji in 1:nb_var) {

var=var_name[ji]
print(paste("KS: working for",var))

file_exp1=paste(rkdir,'/',exp1,'/',exp1,'_',year1,'_',year2,'_',var,'.txt',sep='')
index_exp1 <- unlist(read.table(file_exp1),use.names=FALSE)
mean_index_exp1 <- mean(index_exp1)

file_exp2=paste(rkdir,'/',exp2,'/',exp2,'_',year1,'_',year2,'_',var,'.txt',sep='')
index_exp2 <- unlist(read.table(file_exp2),use.names=FALSE)
mean_index_exp2 <- mean(index_exp2)

# Mean all exp on all machines:
mean_all_index <- mean(c(mean_index_exp1,mean_index_exp2))

# KS Test:
test_exp1_exp2 <- ks.test(index_exp1,index_exp2)

# Plot:

# Change colors according to the differences of distributions:
if (test_exp1_exp2$p.value < 0.05) {color_exp1='blue'; color_exp2='red'} else
     {color_exp1='blue'; color_exp2='blue'}

# First experiment:
x=array(ji-shift,dim=length(index_exp1))
# Plot indexed for members:
par(new=TRUE)
plot(x,index_exp1/mean_all_index,cex=1,pch=1,xlab="",ylab="",axes=FALSE,xlim=c(1,nb_var),ylim=ylimites,col=color_exp1)
# Plot mean:
par(new=TRUE)
plot(ji-shift,mean_index_exp1/mean_all_index,cex=5,pch=1,xlab="",ylab="",axes=FALSE,xlim=c(1,nb_var),ylim=ylimites,col=color_exp1)

# Second experiment
x=array(ji+shift,dim=length(index_exp2))
# Plot indexed for members:
par(new=TRUE)
plot(x,index_exp2/mean_all_index,cex=1,pch=5,xlab="",ylab="",axes=FALSE,xlim=c(1,nb_var),ylim=ylimites,col=color_exp2)
# Plot mean:
par(new=TRUE)
plot(ji+shift,mean_index_exp2/mean_all_index,cex=5,pch=5,xlab="",ylab="",axes=FALSE,xlim=c(1,nb_var),ylim=ylimites,col=color_exp2)

}

legend(x=1.5,y=1.21,legend=c(exp1,exp2),pch=c(1,5))

dev.off()

