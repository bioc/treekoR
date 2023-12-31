suppressPackageStartupMessages({
  library(treekoR)
  library(SingleCellExperiment)
  library(data.table)
})

data(COVIDSampleData)
sce <- DeBiasi_COVID_CD8_samp

exprs <- t(assay(sce, "exprs"))
clusters <- colData(sce)$cluster_id
classes <- colData(sce)$condition
samples <- colData(sce)$sample_id

clust_tree <- getClusterTree(exprs,
                             clusters,
                             hierarchy_method="hopach")

tested_tree <- testTree(phylo=clust_tree$clust_tree,
                        clusters=clusters,
                        samples=samples,
                        classes=classes,
                        pos_class_name=NULL)


## Randomise clusters to be in string
cluster_names <- paste0("cluster_name", 1:50)
clusters_str <- sample(cluster_names, 5000, replace=TRUE)

## Test framework using character as cluster names
clust_tree_str <- getClusterTree(exprs,
                             clusters_str,
                             hierarchy_method="hopach")

tested_tree_str <- testTree(phylo=clust_tree_str$clust_tree,
                        clusters=clusters_str,
                        samples=samples,
                        classes=classes,
                        pos_class_name=NULL)

prop_df <- getCellProp(clust_tree$clust_tree,
                       clusters=clusters,
                       samples=samples,
                       classes=classes)

gmean_df <- getCellGMeans(clust_tree$clust_tree,
                          exprs=exprs,
                          clusters=clusters,
                          samples=samples,
                          classes=classes)

###################################################
# hopachToPhylo
###################################################
# Run hopach to phylo for factor clusters
clust_med_dt <- as.data.table(exprs)
clust_med_dt[, cluster_id := clusters]
res <- clust_med_dt[, lapply(.SD, median, na.rm=TRUE), by=cluster_id]
res2 <- res[,.SD, .SDcols = !c('cluster_id')]
rownames(res2) <- res[["cluster_id"]]

hopach_res <- runHOPACH(as.data.frame(scale(res2)))
hc_phylo <- hopachToPhylo(hopach_res)
hc_phylo$tip.label <- rownames(res2)[as.numeric(hc_phylo$tip.label)]

# Run hopach to phylo for string clusters
clust_med_dt <- as.data.table(exprs)
clust_med_dt[, cluster_id := clusters_str]
res <- clust_med_dt[, lapply(.SD, median, na.rm=TRUE), by=cluster_id]
res2 <- res[,.SD, .SDcols = !c('cluster_id')]
rownames(res2) <- res[["cluster_id"]]

hopach_res_str <- runHOPACH(as.data.frame(scale(res2)))
hc_phylo_str <- hopachToPhylo(hopach_res_str)
hc_phylo_str$tip.label <- rownames(res2)[as.numeric(hc_phylo_str$tip.label)]

test_that(
  "Case hopachToPhylo_1: returns a phylogenetic tree",
  {
    expect_equal(class(hc_phylo), "phylo")
  }
)

test_that(
  "Case hopachToPhylo_2a: returns a phylogenetic tree
  with same number of leafs as number of clusters",
  {
    expect_equal(length(hc_phylo$tip.label),
                 length(as.character(unique(clusters))))
    expect_equal(length(hc_phylo_str$tip.label),
                 length(as.character(unique(clusters_str))))
  }
)

test_that(
  "Case hopachToPhylo_2b: returns a phylogenetic tree
  with same leafs labels as clusters",
  {
    expect_equal(sort(hc_phylo$tip.label),
                 sort(as.character(unique(clusters))))
    expect_equal(sort(hc_phylo_str$tip.label),
                 sort(as.character(unique(clusters_str))))
  }
)

###################################################
# getClusterTree
###################################################
test_that(
  "Case getClusterTree_1: Dataframe of median cluster expression has correct dimensions",
  {
    expect_equal(nrow(clust_tree$median_freq), length(unique(clusters)))
    expect_equal(ncol(clust_tree$median_freq), ncol(exprs))
  }
)

test_that(
  "Case getClusterTree_2: getClusterTree is a list with two values",
  {
    expect_output(str(clust_tree), "List of 2")
  }
)


test_that(
  "Case getClusterTree_3: Cluster names are carried through pipeline",
  {
    expect_true(all(rownames(clust_tree_str$median_freq) %in% unique(clusters_str)))
    expect_true(all(clust_tree_str$clust_tree$tip.label %in% unique(clusters_str)))

    expect_true(all(unique(clusters_str) %in% rownames(clust_tree_str$median_freq)))
    expect_true(all(unique(clusters_str) %in% clust_tree_str$clust_tree$tip.label))
  }
)

test_that(
  "Case getClusterTree_4: getClusterTree returns a phylo with non-null tips",
  {
    expect_true(!is.null(clust_tree$clust_tree$tip.label))
  }
)

###################################################
# testTree
###################################################
# Error handling
test_that(
  "Case testTree_1: missing parameters",
  {
    expect_error(testTree())
    expect_error(testTree(clusters=clusters,
                          samples=samples,
                          classes=classes))
    expect_error(testTree(phylo=clust_tree$clust_tree,
                          samples=samples,
                          classes=classes))
    expect_error(testTree(phylo=clust_tree$clust_tree,
                          samples=samples,
                          classes=classes))
    expect_error(testTree(phylo=clust_tree$clust_tree,
                          clusters=clusters,
                          samples=samples))
  }
)

test_that(
  "Case testTree_2: More than 3 classes",
  {
    set.seed(12)
    three_class_vec <- sample(c("c1","c2", "c3"), length(samples), replace=TRUE)
    expect_error(testTree(phylo=clust_tree$clust_tree,
                          clusters=clusters,
                          samples=samples,
                          classes=three_class_vec,
                          pos_class_name=NULL),
                 "treekoR can currently only test between two classes.")
  }
)

test_that(
  "Case testTree_2b: Less than 2 classes",
  {
    one_class_vec <- rep(c("c1"), length(samples))
    expect_error(testTree(phylo=clust_tree$clust_tree,
                          clusters=clusters,
                          samples=samples,
                          classes=one_class_vec,
                          pos_class_name=NULL),
                 "grouping factor must have exactly 2 levels")
  }
)



test_that(
  "Case testTree_3: Correct and erroneous positive class name",
  {
    expect_silent(testTree(phylo=clust_tree$clust_tree,
                          clusters=clusters,
                          samples=samples,
                          classes=classes,
                          pos_class_name="COV"))
    expect_error(testTree(phylo=clust_tree$clust_tree,
                          clusters=clusters,
                          samples=samples,
                          classes=classes,
                          pos_class_name="sadjn"))
  }
)

test_that(
  "Case testTree_4: Cluster names are carried through pipeline",
  {
    expect_true(all(unique(unlist(tested_tree_str$data$clusters)) %in% unique(clusters_str)))
    expect_true(all(unique(clusters_str) %in% unique(unlist(tested_tree_str$data$clusters))))
  }
)

###################################################
# getTreeResults
###################################################
# Error handling
test_that(
  "Case getTreeResults.1: missing parameters",
  {
    expect_error(getTreeResults())
  }
)

test_that(
  "Case getTreeResults.2: Wrong parameter",
  {
    expect_error(getTreeResults(testedTree = tested_tree,
                                sort_by = ""))
    expect_error(getTreeResults(testedTree = tested_tree,
                                sort_by = "oifne"))
  }
)

###################################################
# getCellProp
###################################################
# Error handling
test_that(
  "Case getCellProp.1: missing parameters",
  {
    expect_error(getCellProp(clusters=clusters,
                             samples=samples,
                             classes=classes))
    expect_error(getCellProp(phylo=clust_tree$clust_tree,
                             samples=samples,
                             classes=classes))
    expect_error(getCellProp(phylo=clust_tree$clust_tree,
                             clusters=clusters,
                             classes=classes))
    expect_error(getCellProp(phylo=clust_tree$clust_tree,
                             clusters=clusters,
                             samples=samples))
  }
)

test_that(
  "Case getCellProp.2: Samples are carried through function",
  {
    expect_true(all(prop_df$sample_id %in% unique(samples)))
    expect_true(all(unique(samples) %in% prop_df$sample_id))
  }
)

test_that(
  "Case getCellProp.3: Cluster proportions are calculated",
  {
    expect_true(all(paste0("perc_total_", unique(clusters)) %in% colnames(prop_df)))
  }
)

###################################################
# getCellGMeans
###################################################
# Error handling
test_that(
  "Case getCellGMeans.1: missing parameters",
  {
    expect_error(getCellGMeans(clusters=clusters,
                               samples=samples,
                             classes=classes))
    expect_error(getCellGMeans(phylo=clust_tree$clust_tree,
                               samples=samples,
                               classes=classes))
    expect_error(getCellGMeans(phylo=clust_tree$clust_tree,
                               clusters=clusters,
                               classes=classes))
    expect_error(getCellGMeans(phylo=clust_tree$clust_tree,
                               clusters=clusters,
                               samples=samples))
  }
)

test_that(
  "Case getCellGMeans.2: Samples are carried through function",
  {
    expect_true(all(gmean_df$sample_id %in% unique(samples)))
    expect_true(all(unique(samples) %in% gmean_df$sample_id))
  }
)
