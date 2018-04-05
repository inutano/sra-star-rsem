library(FNN)

version = "v1"

totalcount_data_path <- "./table/mouse_summary_test_3950_header_totalcount.tsv"
totalcount_data<-file(totalcount_data_path,"r")

a <- readLines(con=totalcount_data,1)
a <- readLines(con=totalcount_data,1)
v <- as.vector(strsplit(a,"\t")[[1]])
total_counts <- as.numeric(v[2:length(v)])

use_samples <- total_counts>=1E+6

all_data_path <- "./table/mouse_summary_test_3950_header.tsv"
all_data<-file(all_data_path,"r")

a <- readLines(con=all_data,1)

dens <- list()
genes <- c()

dens_mat <- c()

repeat{
	a <- readLines(con=all_data,1)
	if(length(a)==0){break}
	v <- as.vector(strsplit(a,"\t")[[1]])
	print(v[1])
	values <- as.numeric(v[2:length(v)])
	values2 <- values[use_samples]
	total_counts2 <- total_counts[use_samples]
	nonzero_genes <- values2!=0
	values3 <- values2[nonzero_genes]
	total_counts3 <- total_counts2[nonzero_genes]
	if (length(total_counts3)!=0){
		genes <- c(genes,v[1])
		values4 <- log10(values3/total_counts3*1E+6+1)
		values5 <- values4/max(values4)
		pdf_file <- paste("./gene_histogram/",v[1],"_histogram_",version,".pdf",sep="")
		pdf(pdf_file,width=5,height=4)
		h <- hist(values5,breaks=seq(0,1,0.02))
		dev.off()

		d <- h$density

		dens_mat <- rbind(dens_mat,d)

		dens[[v[1]]] <- d
	}
}

rownames(dens_mat) <- genes

dist_mat <- c()

for (g1 in genes){
	tmp_dist <- c()
	for (g2 in genes){
		if (g1 == g2){
			tmp_dist <- c(tmp_dist,0.0)
		} else if (is.na(dens[[g2]][1])){
		} else {
			kl_res <- KL.dist(dens[[g1]],dens[[g2]],k=1)
			tmp_dist <- c(tmp_dist,kl_res)
		}
	}
	dist_mat <- rbind(dist_mat,tmp_dist)
}

rownames(dist_mat) <- genes
colnames(dist_mat) <- genes

h <- hclust(as.dist(dist_mat),method="ward.D2")
pdf("hclust_genes.pdf",width=30,height=10)
plot(h)
dev.off()
