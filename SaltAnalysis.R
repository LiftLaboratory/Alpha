
  require(boot)
  require(drc)
  require(ggplot2)
  require(scales)
  
  SlidingRGR = function(grMat,winSize=5,fitCut=0.95,numToFit=4)
  {
    require(stringr)
    
    date<-NULL
    rgrs<-NULL
    dens<-NULL
    fit<-NULL
    area<-NULL
    
    #grMat[grMat[,2]==0,2]<-1
    keeprows<-which(grMat[,"area"]>100) # keeping all rows in column two (area)
    if(length(keeprows)>=winSize)
    {
      grMat<-grMat[keeprows,]
      grMat[,"Dens"]<-log(grMat[,"area"])
      
      tdate<-grMat[,"timestamp"]
      tdate<-str_extract(string = tdate, pattern = "^[[:digit:]]{4}\\-[[:digit:]]{2}\\-[[:digit:]]{2}")
      tdate<-as.Date(x = tdate, format = "%Y-%m-%d")
      #return(tdate)
      grMat[,"Date"]<-tdate
      
      winStarts<-1:(nrow(grMat)-winSize+1)
      for(st in winStarts)
      {
        curMat<-grMat[st:(st+winSize-1),] # the rows within the window
        curRow<-(ceiling(winSize/2))
        date<-c(date,curMat[curRow,"Date"])
        area<-c(area,curMat[curRow,"area"])
        dens<-c(dens,curMat[curRow,"Dens"]) # ceiling of 5/2 = 3
        
        
        # calculate RGR and fit from log values
        tmpLm<-lm(formula = Dens~Date, data = curMat) # calculating the slope of the log value
        tmpSlp<-coef(tmpLm)["Date"]
        rgrs<-c(rgrs,tmpSlp)
        fit<-c(fit,summary(tmpLm)$adj.r.squared)
      } 
      
      
      tMat<-cbind(date,area,dens,rgrs,fit)
      return(tMat)
    }
    return(NULL)
  }
  
  # c is a vector of the coefficients of the model
  log5AsY = function(x,c)
  {
    y = c[2] + (c[3]-c[2])/(1+exp(c[1]*(log(x)-log(c[4]))))^c[5]
    return(y)
  }
  # c is a vector of the coefficients of the model
  log5AsX = function(y,c)
  {
    x = exp((log(((c[2]+((c[3]-c[2])/y))^(1/c[5]))-1)/c[1])+log(c[4]))
  }
  # this function is used to calculte the EC50 values
  getEC50 = function(inData,tIndex)
  {
    require(drc)
    tryCatch(
      expr = {
        mod = drm(formula = Inhib ~ SaltConc, data = inData[tIndex,], fct = LL.5())
        ec50 = log5AsX(0.5,mod$coefficients)
        return(as.numeric(ec50))
      },
      error = function(e){ 
        print(e)
        return(NA)
      }
    )
    
  }
  
  # this is a function used for plotting a square root transformed axis with ggplot2
  mysqrt_trans <- function()
  {
    trans_new("mysqrt", 
              transform = base::sqrt,
              inverse = function(x) ifelse(x<0, 0, x^2),
              domain = c(0, Inf))
  }
  
  
  # Starting from growth curves
  # Take out anything that does not have at least 15 consecutive days above 1000 area
  Salt_GC_filtered<-lapply(Salt_GC,function(x) x[x[,"area"]>1000,])
  keeps<-sapply(Salt_GC_filtered,nrow)
  keeps<-which(keeps>=15)
  Salt_GC_filtered<-Salt_GC_filtered[keeps]
  
  # Look at a sliding window of 10 days, calculate the relative growth rate in each window
  Salt_filtered_RGR<-lapply(Salt_GC_filtered, function(x) SlidingRGR(grMat = x, winSize = 10))
  
  # take the highest RGR with model fit>=0.8
  maxRGR<-sapply(Salt_filtered_RGR,function(x) max(x[(x[,"fit"]>0.8),"rgrs"]))
  
  # Group each sample variety
  nmSplit = strsplit(names(maxRGR),split = "_",fixed = T)
  var = sapply(nmSplit,function(x) x[1])
  dose = sapply(nmSplit,function(x) x[2])
  varLst = tapply(X = 1:length(maxRGR),INDEX = var,function(x) data.frame(maxRGR[x],dose[x]))
  # Sub-group by dose
  varLst = lapply(varLst,function(x) tapply(x[,1], INDEX = x[,2],function(x) x))
  
  # Remove all -Inf (samples that were not quantifiable)
  # And change all 200mM samples to zero (did not grow)
  grList = varLst
  for(v in names(grList))
  {
    for(d in names(grList[[v]]))
    {
      # remove any -Inf
      keep = which(!is.infinite(grList[[v]][[d]]))
      grList[[v]][[d]]=grList[[v]][[d]][keep]
    }
    grList[[v]][["200mM"]] = c(0,0,0)
  }
  
  # combine everything into data frames
  dfList = list()
  for(v in names(grList))
  {
    nms = names(grList[[v]])
    tdose = as.numeric(gsub("mM","",nms))
    nums = sapply(grList[[v]],length)
    tdf = data.frame("SaltConc"=rep(tdose,times=nums),"gr"=unlist(grList[[v]]))
    maxGR = mean(tdf$gr[tdf$SaltConc==0])
    tdf["Inhib"] = ((maxGR - tdf["gr"])/maxGR)
    dfList[[v]] = tdf
  }
  
  # The getEC50 function (defined below) uses the R drc package to fit a dose-response model using a 5-factor model
  # Using the fitted model coefficients, the function solves the equation to find the concentration that results in 50% of the max growth rate 
  ec50s = sapply(dfList, function(x) getEC50(inData = x, tIndex = 1:nrow(x)))
  
  # The R boot package is used to generate 500 bootstrapped values for the ec50
  bootList = lapply(dfList,function(x) boot(data = x, statistic = getEC50, R = 500))
  # the standard deviation is calculated from these bootstrapped values
  ec50Err = sapply(bootList,function(x) sd(x$t[,1],na.rm=T))
  ec50df = data.frame(var=names(ec50s),EC50=round(ec50s,0),stdErr = ec50Err)
  
  # get some colors
  colVec=c("blue","orange","grey70","red","skyblue","darkgreen")
  
  # plot the EC50
  tbars = ggplot(data=ec50df, aes(x=var, y=EC50)) +
    geom_bar(stat="identity", fill=colVec) +
    coord_cartesian(ylim=c(50,150)) +
    labs(title="Salinity Tolerance", y=expression("EC"[50]*" (mM NaCl)"), x="Plant Variety") +
    geom_text(aes(label=EC50,y=75), color="white", size=5)+
    geom_errorbar(aes(ymin=EC50-stdErr, ymax=EC50+stdErr), width=.2, position=position_dodge(.9))+
    theme(legend.position="none", panel.background = element_rect(fill = 'white', color = 'white'),
          panel.grid.major = element_line(color = 'lightblue', linetype = 'solid'),
          axis.text=element_text(size=10))
  pdf(file = "/Path/To/Plots/EC50s.pdf",width = 5,height = 12)
  plot(tbars)
  dev.off()
  
  # organize data for plotting
  plotDF = lapply(names(grList),function(x) data.frame(Variety=rep(x,4),SaltConc=as.numeric(gsub("mM","",names(grList[[x]])[1:4])),mean=sapply(grList[[x]][1:4],mean),sd=sapply(grList[[x]][1:4],sd)))
  names(plotDF)=names(grList)
 
  # plot it
  names(colVec)=names(plotDF)
  for(curVar in names(plotDF))
  {
    
    tplot = ggplot(plotDF[[curVar]], aes(x=SaltConc, y=mean))+
      labs(title=curVar, y=expression("Relative Growth Rate (day"^ -1*")"), x="Salinity (mM NaCl)") +
      theme(legend.position="none", panel.background = element_rect(fill = 'white', color = 'white'),
            panel.grid.major = element_line(color = 'lightblue', linetype = 'solid'))+
      #panel.grid.minor = element_line(color = 'lightblue', linetype = 'solid')) +
      ylim(0,0.31) + geom_line(size=2, color=colVec[curVar]) +
      scale_x_continuous(trans="mysqrt", limits=c(0, NA)) +
      #scale_x_sqrt(breaks=c(0,50,100,150,200), expand=c(0,0.1)) + 
      geom_linerange(aes(ymin=mean-sd, ymax=mean+sd), size = 1.5, color="black") +
      geom_point(shape=21, size=2, fill=colVec[curVar], stroke = 2)
    pdf(file = paste("/Path/To/Plots/",curVar,"_SaltCurve.pdf",sep=""),width = 3,height = 6)
    plot(tplot)
    dev.off()
  } 

