#
# KL4genes.R
#  original code histogram_genes.R by eiryo-kawakami
# usage
#  Rscript --vanilla KL4genes.R <path to data.tsv>
#

#
# Configuration
#

# FNN
# if (!require("FNN")) {
#   install.packages("FNN", repos="https://cran.ism.ac.jp/")
# }
# library("FNN")

# pforeach
if (!require("pforeach")) {
  install.packages("devtools", repos="https://cran.ism.ac.jp/")
  devtools::install_github("hoxo-m/pforeach")
}
library("pforeach")

# Script version info
script.version = "v1.1"

# Create output directory
data.dir <- file.path(".", "data")
rds.dir <- file.path(data.dir, "rds")
pergene.rds.dir <- file.path(rds.dir, "pergene")
plot.dir <- file.path(".", "plot")
hist.dir <- file.path(plot.dir, "densityHistogram")
hclust.dir <- file.path(plot.dir, "hclust")

dir.create(rds.dir, showWarnings=FALSE, recursive=TRUE)
dir.create(pergene.rds.dir, showWarnings=FALSE, recursive=TRUE)
dir.create(hist.dir, showWarnings=FALSE, recursive=TRUE)
dir.create(hclust.dir, showWarnings=FALSE, recursive=TRUE)

#
# Load input data
#

# Get input table file from the first argument
argv <- commandArgs(trailingOnly=TRUE)
data.path <- file.path(argv[1])

#
# Calculate density of read counts among the samples
#
genesDensity <- function(data.path, genes.rds.path, dens.rds.path){
  # Select samples with more than 1,000,000 read counts
  # Get total mapped read count from the last line of the file
  lastLine.str <- system(paste("tail -n 1", data.path), intern=TRUE)
  # Split to convert to vector
  lastLine.vec <- strsplit(lastLine.str, "\t")[[1]]
  # Remove the first element (column name) and make elements numeric
  total.counts <- as.numeric(lastLine.vec[2:length(lastLine.vec)])
  # Counts greater than 100M?
  samples.gt100m <- total.counts >= 1E+6
  # Total counts for gt100m samples
  total.counts.gt100m <- total.counts[samples.gt100m]

  # Create file connection object and remove the first line
  fcon <- file(data.path, "r")
  expids <- readLines(fcon, 1)

  # Create empty objects
  genes <- c()
  dens <- list()
  # dens.mat <- c()

  # Loop for each gene: skip the last line
  repeat {
    # Read another line
    line.str <- readLines(fcon, 1)
    # Convert the line to vecrot
    line.vec <- strsplit(line.str, "\t")[[1]]
    # Put the first element in the vector as gene name
    geneName <- line.vec[1]
    # break if it is the last line starts with "TotalMappedReads"
    if (geneName == "TotalMappedReads") { break }
    # Print gene name
    print(geneName)
    # Create vector of readcount values
    values.vec <- as.numeric(line.vec[2:length(line.vec)])
    # Extract values of samples > 100M mapped reads
    values.gt100m <- values.vec[samples.gt100m]
    # Vector to remove zero count samples
    values.nonzero <- values.gt100m != 0

    # Values for density calculation
    v <- values.gt100m[values.nonzero]
    # Vector of total counts for calculation of this gene
    tc <- total.counts.gt100m[values.nonzero]

    # Do nothing if no values remained
    if (length(tc) != 0) {
      # Register gene name
      genes <- c(genes, geneName)
      # log10 value of the ratio of reads mapped to this gene
      v.ratio <- log10(v / tc * 1E+6 + 1)
      # Normalize each value by deviding with the max value
      normalized.values <- v.ratio / max(v.ratio)
      # Output histogram
      out.pdf.path <- file.path(hist.dir, paste(gsub("/","__",geneName), "histogram", script.version, "pdf", sep="."))
      pdf(out.pdf.path, width=5, height=4)
      h <- hist(normalized.values, breaks=seq(0,1,0.01))
      dev.off()
      # Save density
      d <- h$density
      dens[[geneName]] <- d
      # dens.mat <- rbind(dens.mat, d)
    }
  }
  # Set rownames
  # rownames(dens.mat) <- genes

  # Save objects as RDS
  saveRDS(genes, genes.rds.path)
  saveRDS(dens, dens.rds.path)
}

# Exec if no data is stored
genes.rds.path <- file.path(rds.dir, "genes.rds")
dens.rds.path <- file.path(rds.dir, "dens.rds")
if (!file.exists(dens.rds.path)) {
  genesDensity(data.path, genes.rds.path, dens.rds.path)
}
genes <- readRDS(genes.rds.path)
dens <- readRDS(dens.rds.path)

#
# Calculate Kullback–Leibler divergence for each pair of density
#

calcKLdist <- function(genes, dens){
  # Loop over genes to create matrix of KL distance
  pforeach(i = 1:NROW(genes), .combine=cbind) ({
    dkl.vec <- foreach(j = 1:NROW(genes)) %do% {
      if(i==j){
        0.0
      # } else if(is.na(dens[[genes[j]]][1])) { #TODO
      #
      } else if(i>j) {
        p <- dens[[genes[i]]] + 0.000001
        q <- dens[[genes[j]]] + 0.000001
        # KL distance
        (sum(p * log( p / q )) + sum(q * log( q / p ))) / 2
      }
    }
    # Save object
    pergene.dkl10.rds.path <- file.path(pergene.rds.dir, paste(gsub("/","__",genes[i]), "dkl10.rds", sep="."))
    # pergene.dkl.dist.rds.path <- file.path(pergene.rds.dir, paste(gsub("/","__",genes[i]), "dkl.dist.rds", sep="."))
    saveRDS(dkl.vec, pergene.dkl10.rds.path)
    rm(dkl.vec)
  })

  # Read the RDS files for each gene
  dist.mat <- pforeach(i = 1:NROW(genes), .combine=cbind) ({
    pergene.dkl10.rds.path <- file.path(pergene.rds.dir, paste(gsub("/","__",genes[i]), "dkl10.rds", sep="."))
    readRDS(pergene.dkl10.rds.path)
  })

  # Configure matrix: convert elements to numeric
  dist.mat <- matrix(sapply(dist.mat, as.numeric), nrow=NROW(dist.mat), ncol=NROW(dist.mat))
  storage.mode(dist.mat) <- "numeric"

  # Fill lower triangle
  mat[lower.tri(mat)] <- t(mat)[lower.tri(mat)]

  # Set row/col names
  rownames(dist.mat) <- colnames(dist.mat) <- genes

  # return dist.mat
  dist.mat
}

drawHclust <- function(dist.mat){
  # Hierarchical clustering and output to pdf
  h <- hclust(as.dist(dist.mat), method="ward.D2")
  out.pdf.file <- paste("hclust.genes",script.version,"pdf", sep=".")
  out.pdf.path <- file.path(hclust.dir, out.pdf.file)
  pdf(out.pdf.path, width=30, height=10)
  plot(h)
  dev.off()
}

# Exec
print("Start calculating KL.dist")
dist.mat <- calcKLdist(genes, dens)
print("Done.")
print("Start drawing hclust..")
drawHclust(dist.mat)
print("Done.")
