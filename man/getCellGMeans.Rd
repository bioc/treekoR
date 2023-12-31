% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/analyseTree.R
\name{getCellGMeans}
\alias{getCellGMeans}
\title{getCellGMeans}
\usage{
getCellGMeans(phylo, exprs, clusters, samples, classes)
}
\arguments{
\item{phylo}{a phylogram with tip.labels corresponding to cell types/cluster
contained in 'clusters' vector}

\item{exprs}{a dataframe containing single cell expression data}

\item{clusters}{a vector representing the cell type or cluster of each
cell (can be character or numeric). If numeric, cluster names need to be
consecutive starting from 1.}

\item{samples}{a vector identifying the patient each cell belongs to}

\item{classes}{a vector containing the patient outcome/class each cell belongs to}
}
\value{
a dataframe containing proportions calculated for each sample
}
\description{
getCellGMeans
}
\examples{
library(SingleCellExperiment)
data(COVIDSampleData)

sce <- DeBiasi_COVID_CD8_samp
exprs <- t(assay(sce, "exprs"))
clusters <- colData(sce)$cluster_id
classes <- colData(sce)$condition
samples <- colData(sce)$sample_id

clust_tree <- getClusterTree(exprs,
                             clusters,
                             hierarchy_method="hopach")

means_df <- getCellGMeans(clust_tree$clust_tree,
                        exprs=exprs,
                        clusters=clusters,
                        samples=samples,
                        classes=classes)
}
