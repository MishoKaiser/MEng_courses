#ACHTUNG: From the RStudio menu, click on "Session" and then "Set Working Directory" to "To Source File Location"
#Script for proportional representation of N most abundant species

library(phyloseq)
library(vegan)
library(plyr)
library(ape)
library(grid)

#PARAMETERS ###########################
which_level<-"Genus" #Phylum Class Order Family Genus Otus
library(biomformat);b_<-read_biom("../../Data/collated_feature_w_tax.biom");physeq<-merge_phyloseq(otu_table(as(biom_data(b_),"matrix"),taxa_are_rows=TRUE),tax_table(as(observation_metadata(b_),"matrix")))
meta_table<-read.csv("../../Data/meta_data_rev2.csv",header=T,row.names=1)
reveal_sample_names=FALSE
legend_text_size=50
axis_title_size=60
text_size=50
axis_text_size=50
strip_text_size=50
height_image=80
width_image=120
how_many_columns_for_legend=3
#By default, the labels are displayed on the top and right of the plot. 
#If "x", the top labels will be displayed to the bottom. 
#If "y", the right-hand side labels will be displayed 
#to the left. Can also be set to "both".
switch_strip="x" 
N=25 #Extract list of top N Taxa
#/PARAMETERS ###########################

abund_table<-otu_table(physeq)
abund_table<-t(abund_table)
#Uncomment if you'd like to get rid of samples below a certain library size
abund_table<-abund_table[rowSums(abund_table)>=5000,]


OTU_taxonomy<-data.frame(as(tax_table(physeq),"matrix"))
colnames(OTU_taxonomy)<-c("Kingdom","Phylum","Class","Order","Family","Genus","Otus")

#Ensure that all columns of OTU_taxonomy are character and not factors
OTU_taxonomy[] <- lapply(OTU_taxonomy, function(x) as.character(x))
OTU_taxonomy[is.na(OTU_taxonomy)]<-""
OTU_taxonomy$Otus<-gsub("D_6__|s__","",OTU_taxonomy$Otus)
OTU_taxonomy$Genus<-gsub("D_5__|g__","",OTU_taxonomy$Genus)
OTU_taxonomy$Family<-gsub("D_4__|f__","",OTU_taxonomy$Family)
OTU_taxonomy$Order<-gsub("D_3__|o__","",OTU_taxonomy$Order)
OTU_taxonomy$Class<-gsub("D_2__|c__","",OTU_taxonomy$Class)
OTU_taxonomy$Phylum<-gsub("D_1__|p__","",OTU_taxonomy$Phylum)
OTU_taxonomy$Kingdom<-gsub("D_0__|d__","",OTU_taxonomy$Kingdom)

#Remove singletons and adjust OTU_taxonomy
abund_table<-abund_table[,colSums(abund_table)>1]
OTU_taxonomy<-OTU_taxonomy[colnames(abund_table),]

#get rid of contaminants with "Unassigned", "Chloroplast" and "Mitochondria" assignment", and "non classified" at Phylum level
abund_table<-abund_table[,!(OTU_taxonomy$Kingdom %in% c("Unassigned") | OTU_taxonomy$Phylum=="" | OTU_taxonomy$Order %in% c("Chloroplast") | OTU_taxonomy$Family %in% c("Mitochondria"))]


#extract subset of abund_table for which samples also exists in meta_table
abund_table<-abund_table[rownames(abund_table) %in% rownames(meta_table),]
#when reducing the abund_table, there is a high likelihood that an OTU was only present in a sample that is removed, so we shrink
#the abund_table to get rid of empty columns
abund_table<-abund_table[,colSums(abund_table)>0]
#make your meta_table smaller by only considering samples that appear in abund_table
meta_table<-meta_table[rownames(abund_table),]
#make OTU_taxonomy smaller by only considering OTUs that appear in abund_table
OTU_taxonomy<-OTU_taxonomy[colnames(abund_table),]
#At this point we have abund_table, meta_table, and OTU_taxonomy are ready and their dimensions should match
#/DATA IMPORT############################################################


#PARAMETERS CHANGE THE GROUPING COLUMN AS YOU DESIRE############################
#In the hypothesis space, all you need is to select the rows in meta_table you are interested in
#and then allocate a column to meta_table$Groups that you want to use

label="Hypothesis1"
meta_table<-meta_table[meta_table$Material %in% c(
  "PE",                                              
  "PP",                                              
  "Pellets",                                         
  "PS",                                              
  "water",                                           
  "wood",                                            
  "sediment",                                        
  "LDPE",                                            
  "PVC",                                             
  "metal",                                           
  "HDPE",                                            
  "stone"
),]
#First provide grouping column
meta_table$Groups<-as.character(meta_table$Material)
#The colours in the the next instruction match the factors for meta_table$Groups
meta_table$Groups<-factor(meta_table$Groups,c(
  "PE",                                              
  "PP",                                              
  "Pellets",                                         
  "PS",                                              
  "water",                                           
  "wood",                                            
  "sediment",                                        
  "LDPE",                                            
  "PVC",                                             
  "metal",                                           
  "HDPE",                                            
  "stone"
))


#PARAMETERS CHANGE THE GROUPING COLUMN AS YOU DESIRE############################

#Adjust abund_table to contain only those rows that got selected in the Hypothesis space
abund_table<-abund_table[rownames(meta_table),]
#After adjustment, get rid of OTUs that are all empty
abund_table<-abund_table[,colSums(abund_table)>0]
#Adjust OTU taxonomy
OTU_taxonomy<-OTU_taxonomy[colnames(abund_table),]

#COLLATE OTUS AT A PARTICULAR LEVEL#######################################
new_abund_table<-NULL
if(which_level=="Otus"){
  new_abund_table<-abund_table
} else {
  list<-unique(OTU_taxonomy[,which_level])
  new_abund_table<-NULL
  for(i in list){
    tmp<-data.frame(rowSums(abund_table[,rownames(OTU_taxonomy)[OTU_taxonomy[,which_level]==i],drop=FALSE]))
    if(i==""){colnames(tmp)<-c("__Unknowns__")} else {
      #colnames(tmp)<-paste("",i,sep="")
      colnames(tmp)<-gsub(";+$","",paste(sapply(OTU_taxonomy[OTU_taxonomy[,which_level]==i,][1,1:which(colnames(OTU_taxonomy)==which_level)],as.character),collapse=";"))
    }
    if(is.null(new_abund_table)){new_abund_table<-tmp} else {new_abund_table<-cbind(tmp,new_abund_table)}
  }
}

new_abund_table<-as.data.frame(as(new_abund_table,"matrix"))
abund_table<-new_abund_table
#/COLLATE OTUS AT A PARTICULAR LEVEL#######################################


#Apply proportion normalisation
x<-abund_table/rowSums(abund_table)
x<-x[,order(colSums(x),decreasing=TRUE)]


taxa_list<-colnames(x)[1:min(dim(x)[2],N)]
if (c("__Unknowns__") %in% taxa_list){
  taxa_list<-colnames(x)[1:min(dim(x)[2],N+1)]
  taxa_list<-taxa_list[!grepl("__Unknowns__",taxa_list)]
}
N<-length(taxa_list)

#Generate a new table with everything added to Others
new_x<-NULL
if(N==dim(x)[2]){
  new_x<-data.frame(x[,colnames(x) %in% taxa_list],check.names=FALSE)
} else {
  new_x<-data.frame(x[,colnames(x) %in% taxa_list],Others=rowSums(x[,!colnames(x) %in% taxa_list]),check.names=FALSE)
}
if(which_level=="Otus"){
  if(N==dim(x)[2]){
    colnames(new_x)<-c(paste(colnames(new_x),sapply(colnames(new_x),function(x) gsub(";+$","",paste(sapply(OTU_taxonomy[x,],as.character),collapse=";")))))  
  } else {
    colnames(new_x)<-c(paste(colnames(new_x)[-(N+1)],sapply(colnames(new_x)[-(N+1)],function(x) gsub(";+$","",paste(sapply(OTU_taxonomy[x,],as.character),collapse=";")))),"Others")
  }
}

df<-NULL
for (i in 1:dim(new_x)[2]){
  tmp<-data.frame(row.names=NULL,Sample=rownames(new_x),Taxa=rep(colnames(new_x)[i],dim(new_x)[1]),Value=new_x[,i],Groups=meta_table$Groups)
  if(i==1){df<-tmp} else {df<-rbind(df,tmp)}
}

#Uncomment if you want to use Anna's colors
#colours <- c("#DC143C", "#FFAEB9", "#FF82AB","#EE1289","#FF83FA","#9400D3","#AB82FF","#836FFF","#0000FF","#000080","#4876FF","#CAE1FF","#9FB6CD","#1E90FF","#00F5FF","#03A89E","#00C78C","#00C957","#008000","#ADFF2F","#FFFF00","#FFD700","#FFC125","#FFA500","#8B4513","#FF7256",rainbow(300)[seq(1,300,6)]);
#Uncomment, if you want to use Jasmine's Rainbow
colours <- c("#920606", "#f40a0a", "#f86c6c", "#fccece", "#994b00", "#cc6500", "#ff7f00", "#ffb266", "#ccaf00", "#ffdb00", "#ffe966", "#fef7cc", "#00660b", "#009a17", "#00cc17", "#ccfed1", "#002766", "#004ecc", "#3380ff", "#ccdffe", "#570099", "#9200ff", "#bd66ff", "#e9ccfe", "#686666", "#c0bfbf");
#Uncomment, if you want to use "BETTER" colour scheme based on umer's AESTHETIC taste informed by the latest in psychology, sociology whatever. We are going to use our favorite 21 orthogonal colours palette followed by greyscale values should we run out of assignments
#colours <- c("#F0A3FF", "#0075DC", "#993F00","#4C005C","#2BCE48","#FFCC99","#808080","#94FFB5","#8F7C00","#9DCC00","#C20088","#003380","#FFA405","#FFA8BB","#426600","#FF0010","#5EF1F2","#00998F","#740AFF","#990000","#FFFF00",grey.colors(1000));

#The first step to get levels is to find all the possible values in a given column in df$sample by outputing the following command on terminal:
# cat(paste("levels=c(",paste(paste("\"",unique(as.character(df$Sample)),"\"",sep=""),collapse=","),")",sep=""))
# then use df$Sample<-factor(as.character(df$Sample),levels=c()) list

#For the newerversion of R, to fix the ordering problem, use this line
df$Taxa<-factor(as.character(df$Taxa),levels=colnames(new_x))

library(ggplot2)
p<-ggplot(df,aes(Sample,Value,fill=Taxa))+geom_bar(stat="identity")+facet_grid(. ~ Groups, drop=TRUE,scale="free",space="free_x",switch=switch_strip)
p<-p+scale_fill_manual(values=colours[1:(N+1)],guide=guide_legend(ncol = how_many_columns_for_legend))
p<-p+theme_bw()+ylab("Proportions")
p<-p+ scale_y_continuous(expand = c(0.02,0))+theme(strip.background = element_rect(fill="gray85"),
                                                   panel.spacing = unit(0.3, "lines"),
                                                   legend.position = "bottom",
                                                   strip.text = element_text(size=strip_text_size,angle=90),
                                                   legend.text=element_text(size=legend_text_size),
                                                   text = element_text(size=text_size),
                                                   axis.text=element_text(size=axis_text_size),
                                                   axis.title=element_text(size=axis_title_size))

if(reveal_sample_names){
  p<-p+theme(axis.text.x=element_text(angle=90,hjust=1,vjust=0.5))
} else {
  p<-p+theme(axis.text.x=element_blank(),axis.ticks=element_blank())
}



pdf(paste("TAXAplot_",which_level,"_",label,".pdf",sep=""),height=height_image,width=width_image)
print(p)
dev.off()