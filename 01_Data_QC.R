#' ---
#' title: "scRNA-seq workflow (1: Load Data & QC)"
#' description: |
#'   "Single-cell RNA-seq workflow (1: Load Data & QC)"
#' author:
#'   - name: "I-Hsuan Lin"
#'     url: https://github.com/ycl6
#'     affiliation: University of Manchester
#'     affiliation_url: https://www.manchester.ac.uk/
#' date: '`r format(Sys.Date(), "%B %d, %Y")`'
#' output:
#'     rmarkdown::html_document:
#'         theme: united
#'         highlight: tango
#'         self_contained: true
#'         toc: true
#'         toc_depth: 2
#'         toc_float:
#'             collapsed: false
#'             smooth_scroll: true
#' ---
#' 

#' 
#' -----
#' 
#' **scRNAseq:** [Bioconductor](https://bioconductor.org/packages/scRNAseq/)
#' 
#' **DropletUtils:** [Bioconductor](https://bioconductor.org/packages/DropletUtils/)
#' 
#' **scater:** [Bioconductor](https://bioconductor.org/packages/scater/), [GitHub](https://github.com/LTLA/scater), [Paper](https://doi.org/10.1093/bioinformatics/btw777)
#' 
#' **ggbeeswarm:** [CRAN](https://cran.r-project.org/package=ggbeeswarm), [GitHub](https://github.com/eclarke/ggbeeswarm)
#' 
#' **Demo Dataset:** `BachMammaryData` from *[Differentiation dynamics of mammary epithelial cells revealed by single-cell RNA sequencing](https://doi.org/10.1038/s41467-017-02001-5) Nat Commun. 2017;8(1):2128.*
#' 
#' **License:** GPL-3.0
#' 
#' 
#' # Start R & prepare environment
#' 
#' ## Start `R`
#' 
#' ```
#' cd /ngs/scRNA-seq-Analysis-Demo
#' 
#' R
#' ```
#' 
#' ## Load R libraries
#' 
## ----load-libraries-----------------------------------------------------------
suppressPackageStartupMessages({
	library(scRNAseq)
	library(scater)
	library(ggbeeswarm) # geom_quasirandom
})

#' 
#' ## Set up colour palettes
#' 
## ----set colour-palettes, fig.width = 5, fig.height = 5, fig.align = "center", dpi = 100----
c30 <- c("#1C86EE",	#1 dodgerblue2
         "#FF0000",	#2 red1
         "#008B00",	#3 green4
         "#FF7F00",	#4 DarkOrange1
         "#00FF00",	#5 green1
         "#A020F0",	#6 purple
         "#0000FF",	#7 blue1
         "#FF1493",	#8 DeepPink1
         "#8B4500",	#9 DarkOrange4
         "#000000",	#10 black
         "#FFD700",	#11 gold1
         "#00CED1",	#12 DarkTurquoise
         "#68228B",	#13 DarkOrchid4
         "#FF83FA",	#14 orchid1
         "#B3B3B3",	#15 gray70
         "#B03060",	#16 maroon
         "#7CCD7C",	#17 PaleGreen3
         "#333333",	#18 gray20
         "#D8BFD8",	#19 thistle
         "#FFC125",	#20 goldenrod1
         "#EEE685",	#21 khaki2
         "#7EC0EE",	#22 SkyBlue2
         "#36648B",	#23 SteelBlue4
         "#54FF9F",	#24 SeaGreen1
         "#8B8B00",	#25 yellow4
         "#CDCD00",	#26 yellow3
         "#F08080",	#27 LightCoral
         "#A52A2A",	#28 brown
         "#00008B",	#29 blue4
         "#CD2626"	#30 firebrick3
)

pie(rep(1,30), col = c30, radius = 1)

#' 
#' ## Choose sample & cluster colours
#' 
## ----define-colours-----------------------------------------------------------
# Choosing colours for samples, n = 8
sample_col <- c30[c(1:8)]

# Choosing colours for clutsers, n = 15
cluster_col <- c30[c(1:15)]

# Choosing colours for Venn diagram, n = 3
circle.col <- c30[c(23,24,27)]

#' 
#' # Load scRNA-seq data
#' 
#' ## Import public scRNA-seq data
#' 
#' In this example, we will use the example data set from the [scRNAseq](https://bioconductor.org/packages/scRNAseq/) Bioconductor package. It contains expression matrices for several public scRNA-seq datasets in the form of `SingleCellExperiment` objects. The `BachMammaryData` function will download and import the mouse mammary gland single-cell RNA-seq data obtained with the 10x Genomics Chromium platform from [Bach et al. (2017)](https://doi.org/10.1038/s41467-017-02001-5). The object contains 25,806 barcodes, cell annotations that includes the sample ID and condition, and the gene annotations that includes the Ensembl gene ID and gene symbol.
#' 
## ----import-data, message = FALSE---------------------------------------------
sce <- BachMammaryData()
sce

# Print the number of genes and cells in the object
paste0("Number of genes: ", nrow(sce))
paste0("Number of cells: ", ncol(sce))

# Cell info
str(colData(sce))

# Gene info
str(rowData(sce))

#' 
#' ## Import Cell Ranger data
#' 
#' > **Note:** Skip if using the `BachMammaryData` dataset.
#' 
## -----------------------------------------------------------------------------
# Define sample ID
sample_id <- c("Sample1", "Sample2", "Sample3", "Sample4")

#' 
#' To import scRNA-seq data generated by Cell Ranger, we can using the `read10xCounts` function from the `DropletUtils` package, which will produce a `SingleCellExperiment` object containing count data for each gene (row) and cell (column) across all samples.
#' 
#' ### Import 10X data 
#' 
#' #### A. From matrix files
#' 
#' Edit the script below to point `cr_mat_path` to the directory containing CellRanger output files: `barcodes.tsv.gz`, `features.tsv.gz`, and `matrix.mtx.gz`.
#' 
## ----import-cell-ranger-matrix, eval = FALSE----------------------------------
## # Define data location
## cr_mat_path <- "path-to-cellranger-output-folder" # a folder
## 
## # Check if these files exist: barcodes.tsv.gz, features.tsv.gz, matrix.mtx.gz
## check_matrix_input <- function(cr_mat_path) {
## 	error <- FALSE
## 	if(! file.exists(paste0(cr_mat_path,"/barcodes.tsv.gz"))) {
##         	error <- TRUE
## 	        print("'barcodes.tsv.gz' not found")
## 	}
## 
## 	if(! file.exists(paste0(cr_mat_path,"/features.tsv.gz"))) {
##         	error <- TRUE
## 	        print("'features.tsv.gz' not found")
## 	}
## 
## 	if(! file.exists(paste0(cr_mat_path,"/matrix.mtx.gz"))) {
##         	error <- TRUE
## 	        print("'matrix.mtx.gz' not found")
## 	}
## 
## 	if(isTRUE(error)) {
## 	        stop("Stopped!")
## 	} else {
##         	print("All files found.")
## 	}
## }
## 
## check_matrix_input(cr_mat_path)
## 
## # Import data
## sce <- DropletUtils::read10xCounts(cr_mat_path, sample.names = sample_id)
## sce
## 
## # Print the number of genes and cells in the object
## paste0("Number of genes: ", nrow(sce))
## paste0("Number of cells: ", ncol(sce))

#' 
#' #### B. From HDF5 files
#' 
#' Edit the script below to point `cr_h5_path` to the path of the `filtered_feature_bc_matrix.h5` file.
#' 
## ----import-cell-ranger-h5, eval = FALSE--------------------------------------
## # Define data location
## cr_h5_file <- "path-to-cellranger-output-folder/filtered_feature_bc_matrix.h5" # a h5 file
## 
## # Check if this files exist
## file.exists(cr_h5_file)
## 
## # Import data
## sce <- DropletUtils::read10xCounts(cr_h5_file, sample.names = sample_id)
## sce
## 
## # Print the number of genes and cells in the object
## paste0("Number of genes: ", nrow(sce))
## paste0("Number of cells: ", ncol(sce))

#' 
#' ### Add cell and gene annotations
#' 
#' > **Note:** Skip if using the `BachMammaryData` dataset.
#' 
## ----annotate-sce-obj, eval = FALSE-------------------------------------------
## colnames(sce) <- colData(sce)$Barcode
## rownames(sce) <- rowData(sce)$Symbol
## 
## # Cell info
## str(colData(sce))
## 
## # Gene info
## str(rowData(sce))

#' 
#' # Generate QC metrics
#' 
#' ## Define mitochondrial genes
#' 
#' We use `grep` to perform pattern matching to look for genes that are from the mitochondrial genome (chrM). The regular expression `"^mt-|^MT-"` will work for both human (`MT-`) and mouse (`mt-`) mitochondrial genomes. The `^` anchor is to ensure the pattern is matched to the beginning of the gene symbol.
#' 
## ----define-mito--------------------------------------------------------------
# The subset feature can be supplied as character vector of feature names, a logical vector,
# or a numeric vector of indices
#is.mito <- grepl("^mt-|^MT-", rowData(sce)$Symbol) # a logical vector
is.mito <- grep("^mt-|^MT-", rowData(sce)$Symbol)   # numeric vector of indices

# Print matched genes
rowData(sce)$Symbol[is.mito]

#' 
#' ## Add QC metrics
#' 
#' With an older version of `scater`, we would use the `calculateQCMetrics` function to add QC metrics, but it is now deprecated. We will instead use `addPerCellQC` and `addPerFeatureQC` and add additional metrics to `colData` and `rowData` instead.
#' 
#' ### Add per-cell QC
#' 
#' > **Note:** A pseudocount of **1** is added to avoid undefined values after the log-transformation.
#' 
## ----add-per-cell-qc-to-sce---------------------------------------------------
# "sum" - sum of counts for the cell (library size)
# "detected" - number of genes for the cell that have counts above the detection limit (default 0)
sce <- addPerCellQC(sce, list(MT = is.mito))

# Add additional stats to per-cell QC
pseudocount = 1
colData(sce)$log10_sum <- log10(colData(sce)$sum + pseudocount)
colData(sce)$log10_detected <- log10(colData(sce)$detected + pseudocount)
colData(sce)$log10_genes_per_umi <- colData(sce)$log10_detected / colData(sce)$log10_sum

#' 
#' ### Add per-feature QC
#' 
## ----add-per-feature-qc-to-sce------------------------------------------------
# "mean" - mean counts for each gene across all cells
# "detected" - percentage of expressing cells, i.e.cells with non-zero counts for each gene
sce <- addPerFeatureQC(sce)

#' 
## ----print-sce----------------------------------------------------------------
sce

# Cell data
names(colData(sce))
colData(sce)

# Gene data
names(rowData(sce))
rowData(sce)

#' 
#' # Identify low-quality cells
#' 
#' In most cases, We can assume most of the cells are  _high quality_ and use the median absolute deviation (MAD) from the median approach to identify cells that are outliers, presumably representing low-quality cells. The threshold used here to determined if a cell is an outlier is if it is __more than 3 MADs from the median__, under a normal distribution this cutoff will retain 99% of cells. The log-transformed values will be applied to the input values (with `log = TRUE`) as this improves resolution at small values for distribution exhibit a heavy right tail, and avoid inflation of the MAD that might compromise outlier detection on the left tail.
#' 
#' **Note:** One should be aware of factors that could affect the distribution, for example certain cells can have a high metabolic rate and thus higher mitochondrial gene expression, or certain cells can express very few genes. In such cases, one might need to use fixed thresholds to filter low-quality cells.
#' 
## ----run-isOutlier------------------------------------------------------------
qc.lib <- isOutlier(colData(sce)$sum, nmads = 3, log = TRUE, type = "lower")
qc.expr <- isOutlier(colData(sce)$detected, nmads = 3, log = TRUE, type = "lower")
qc.mito <- isOutlier(colData(sce)$subsets_MT_percent, nmads = 3, type = "higher")

#' 
#' View the filter thresholds and determine if they are appropriate.
#' 
## ----show-thresholds----------------------------------------------------------
attr(qc.lib, "thresholds")  # values lower than the "lower" threshold would be filtered
attr(qc.expr, "thresholds") # values lower than the "lower" threshold would be filtered
attr(qc.mito, "thresholds") # values higher than the "higher" threshold would be filtered

#' 
#' **Note:** The `qc.mito` threshold is very low, i.e. it will remove cells with mitochondrial proportions greater than ~1.63%. Usually cells with less than 10% are considered good quality and more than 20% are of poor quality. In this case, we will manually set a fixed threshold of 10%.
#' 
## ----set-fixed-mito-threshold-------------------------------------------------
qc.mito.threshold = 10 # set at 10%
qc.mito <- colData(sce)$subsets_MT_percent > qc.mito.threshold
attr(qc.mito, "thresholds")["lower"] <- -Inf
attr(qc.mito, "thresholds")["higher"] <- qc.mito.threshold

attr(qc.mito, "thresholds")

#' 
#' Summarize the number of cells removed for each reason. In this example, all cells passed the thresholds and none are considered an outlier.
#' 
## ----discard-summary----------------------------------------------------------
discard <- qc.lib | qc.expr | qc.mito
colData(sce)$discard <- discard	# Add a column in colData to store QC filter result
DataFrame(LibSize = sum(qc.lib), ExprGene = sum(qc.expr), MitoProp = sum(qc.mito), 
	  Total = sum(discard))

# Show as Venn diagram
limma::vennDiagram(data.frame(LibSize = qc.lib, ExprGene = qc.expr, MitoProp = qc.mito),
		   circle.col = circle.col)

#' 
#' # Assess QC metrics on cells
#' 
#' Now we are ready to inspect the distributions of various metrics and the thresholds chosen earlier. In an ideal case, we will see these metrics follow normal distributions and thus would justify the 3 MAD thresholds used in outlier detection. Afer assessing the plots, we can decide if the thresholds need adjustment to account for specific biological states or subset of cells, etc.
#' 
#' ## Cell counts
#' 
#' The cell counts are determined by the number of unique cellular barcodes detected. Ideally, the number of unique cellular barcodes will correpsond to the number of cells loaded. However the *capture rates or capture efficiency* of cells will affect the eventual cell counts. Accurate measure the input cell concentration is also important in determining the cell capture efficiency. Lastly, it is also possible to detect cell numbers that are much higher than what we loaded due to the experimental procedure. For example, there is a chance of obtaining only a barcoded bead in the emulsion droplet (GEM) and no actual cell with the 10X protocol.
#' 
#' > **Note:** What were the expected cell counts in samples?
#' 
## ----plot-cell-counts, message = FALSE, fig.width = 8, fig.height = 6, fig.align = "center", dpi = 100----
table(colData(sce)$Sample)

ggplot(as.data.frame(colData(sce)), aes(Sample, fill = Sample)) + geom_bar(color = "black") + 
	geom_text(stat = "count", aes(label = ..count..), vjust = -0.5, size = 5) +
	scale_fill_manual(values = sample_col) + theme_classic(base_size = 12) + 
	theme(legend.position = "none") + ylab("Counts") + ggtitle("Cell counts")

#' 
#' ## Library size
#' 
#' Next, we will consider the total number of RNA molecules detected per cell. The unique molecular identifier (UMI) counts should generally be above 500 ([ref](https://hbctraining.github.io/scRNA-seq/lessons/04_SC_quality_control.html#umi-counts-transcripts-per-cell)). Wells with few transcripts are likely to have been broken or failed to capture a cell, and should thus be removed. If UMI counts are between 500-1000 counts, it is usable but the cells probably should have been sequenced more deeply ([ref](https://hbctraining.github.io/scRNA-seq/lessons/04_SC_quality_control.html#umi-counts-transcripts-per-cell)).
#' 
#' View library size distributions with `quantile`.
#' 
#' > **Note:** Are there any cells with low total UMI counts?
#' 
## ----library-sizes------------------------------------------------------------
quantile(colData(sce)$sum, seq(0, 1, 0.1))	# 0% - 100% percentile
quantile(colData(sce)$sum, seq(0.9, 1, 0.1))	# 90% - 100% percentile (high read-depth)

#' 
#' Visualise library size distributions with `ggplot`.
#' 
## ----plot-umi, message = FALSE, fig.width = 8, fig.height = 10, fig.align = "center", dpi = 100----
logbreak = scales::trans_breaks("log10", function(x) 10^x)
loglab = scales::trans_format("log10", scales::math_format(10^.x))

# histogram
p1 <- ggplot(as.data.frame(colData(sce)), aes(sum, color = Sample, fill = Sample)) +
	geom_histogram(position = "identity", alpha = 0.4, bins = 50) +
	scale_x_log10(breaks = logbreak, labels = loglab) +
	geom_vline(xintercept = attr(qc.lib, "thresholds")[1], linetype = 2) + # show cutoff
	scale_fill_manual(values = sample_col) + scale_color_manual(values = sample_col) +
	theme_classic(base_size = 12) + xlab("Total UMI counts") + 
	ylab("Frequency") + ggtitle("Histogram of Library Size per Cell")

# violin plot
p2 <- ggplot(as.data.frame(colData(sce)), aes(Sample, sum, colour = discard)) +
	geom_violin(width = 1) + scale_y_log10(breaks = logbreak, labels = loglab) +
	geom_quasirandom(size = 0.2, alpha = 0.2, width = 0.5) +
	geom_hline(yintercept = attr(qc.lib, "thresholds")[1], linetype = 2) + # show cutoff
	scale_color_manual(values = c("blue", "red")) + theme_classic(base_size = 12) +
	guides(color = guide_legend("Discard", override.aes = list(size = 1, alpha = 1))) +
	theme(legend.position = "right") + ylab("Total UMI counts") + 
	ggtitle("Violin plot of Library Size perl Cell")

multiplot(p1, p2)

#' 
#' ## Expressed features
#' 
#' Aside from having sufficient sequencing depth for each sample, we also expected to see reads distributed across the transcriptome. When visualised the expressed features (i.e. genes) in all the cells as a histogram or density plot, the plot should contain a single large peak for high quality data.
#' 
#' View expressed features distributions with `quantile`.
#' 
## ----expressed-gene-----------------------------------------------------------
quantile(colData(sce)$detected, seq(0, 1, 0.1))

#' 
#' Visualise expressed features distributions with `ggplot`.
#' 
## ----plot-expressed-gene, message = FALSE, fig.width = 8, fig.height = 10, fig.align = "center", dpi = 100----
# histogram
p1 <- ggplot(as.data.frame(colData(sce)), aes(detected, color = Sample, fill = Sample)) +
	geom_histogram(position = "identity", alpha = 0.4, bins = 50) + 
	scale_x_log10(breaks = logbreak, labels = loglab) +
	geom_vline(xintercept = attr(qc.expr, "thresholds")[1], linetype = 2) + # show cutoff
	scale_fill_manual(values = sample_col) + scale_color_manual(values = sample_col) +
	theme_classic(base_size = 12) + xlab("Total expressed genes") + 
	ylab("Frequency") + ggtitle("Histogram of Expressed Features per Cell")

# violin
p2 <- ggplot(as.data.frame(colData(sce)), aes(Sample, detected, colour = discard)) +
	geom_violin(width = 1) + scale_y_log10(breaks = logbreak, labels = loglab) +
	geom_quasirandom(size = 0.2, alpha = 0.2, width = 0.5) +
	geom_hline(yintercept = attr(qc.expr, "thresholds")[1], linetype = 2) + # show cutoff
	scale_colour_manual(values = c("blue", "red")) + theme_classic(base_size = 12) +
	guides(color = guide_legend("Discard", override.aes = list(size = 1, alpha = 1))) +
	theme(legend.position = "right") + ylab("Total expressed genes") + 
	ggtitle("Violin plot of Expressed Features per Cell")

multiplot(p1, p2)

#' 
#' ## Complexity of RNA species
#' 
#' The UMI count per cell and the number of genes detected per cell are often evaluated together. These two indices are usually strongly related, i.e. the higher UMI count for a cell, the more genes are detected as well. Cells that have a less complex RNA species (low number of genes detected per UMI), such as red blood cells, can often be detected by this metric. Generally, we expect the complexity score to be above 0.80 [ref](https://hbctraining.github.io/scRNA-seq/lessons/04_SC_quality_control.html#complexity).
#' 
#' View complexity distributions with `quantile`.
#' 
## -----------------------------------------------------------------------------
quantile(colData(sce)$log10_genes_per_umi, seq(0, 1, 0.1))

#' 
#' Visualise complexity distributions with `ggplot`.
#' 
## ----plot-complexity, message = FALSE, fig.width = 8, fig.height = 10, fig.align = "center", dpi = 100----
# histogram
p1 <- ggplot(as.data.frame(colData(sce)), aes(log10_genes_per_umi, color = Sample,
                                              fill = Sample)) +
        geom_histogram(position = "identity", alpha = 0.4, bins = 50) + 
	geom_vline(xintercept = 0.8, linetype = 2) +
        scale_fill_manual(values = sample_col) + scale_color_manual(values = sample_col) +
        theme_classic(base_size = 12) + xlab("log10 Gene per UMI") + ylab("Frequency") +
        ggtitle("Histogram of Complexity of Gene Expression")

# scatter plot
p2 <- ggplot(as.data.frame(colData(sce)), aes(sum, detected, color = Sample)) + 
	scale_x_log10(breaks = logbreak, labels = loglab) +
	scale_y_log10(breaks = logbreak, labels = loglab) +
	geom_point(size = 0.6, alpha = 0.3) + facet_wrap(~ as.data.frame(colData(sce))$Sample) + 
	scale_color_manual(values = sample_col) + theme_classic(base_size = 12) +
	guides(color = guide_legend("Sample", override.aes = list(size = 3, alpha = 1))) +
	xlab("Total UMI counts") + ylab("Total expressed genes") + 
	ggtitle("UMIs vs. Expressed Genes")

multiplot(p1, p2)

#' 
#' ## Mitochondrial contamination
#' 
#' The mitochondrial proportions in cells is an useful indicator of cell quality. High proportion of counts assigned to mitochondrial genes is an indication of damaged, dying and dead cells, whereby cytoplasmic mRNA has leaked out through a broken membrane, hence only the mRNA located in the mitochondria is preserved and being sequenced.
#' 
#' View distributions with `quantile`.
#' 
#' > **Note:** Are there any cells with high expression of mitochondrial genes (>20% of total counts in a cell)?
#' 
## ----pct-mito-----------------------------------------------------------------
quantile(colData(sce)$subsets_MT_percent, seq(0, 1, 0.1))

#' 
#' Visualise distributions with `ggplot`.
#' 
## ----plot-pct-mito, message = FALSE, fig.width = 8, fig.height = 10, fig.align = "center", dpi = 100----
# histogram
p1 <- ggplot(as.data.frame(colData(sce)), aes(x = subsets_MT_percent, color = Sample, 
					       fill = Sample)) +
	geom_histogram(position = "identity", alpha = 0.4, bins = 50) +
	geom_vline(xintercept = attr(qc.mito, "thresholds")[2], linetype = 2) + # show cutoff
	scale_fill_manual(values = sample_col) + scale_color_manual(values = sample_col) +
	theme_classic(base_size = 12) + xlab("% counts from mitochondrial genes") + 
	ylab("Frequency") + ggtitle("Histogram of Mitochondrial Proportions per Cell")

# violin
p2 <- ggplot(as.data.frame(colData(sce)), aes(Sample, subsets_MT_percent, colour = discard)) +
        geom_violin(width = 1) + geom_quasirandom(size = 0.2, alpha = 0.2, width = 0.5) +
        geom_hline(yintercept = attr(qc.mito, "thresholds")[2], linetype = 2) + # show cutoff
        scale_colour_manual(values = c("blue", "red")) + theme_classic(base_size = 12) +
	guides(color = guide_legend("Discard", override.aes = list(size = 1, alpha = 1))) +
        theme(legend.position = "right") + ylab("% counts from mitochondrial genes") +
        ggtitle("Violin plot of Mitochondrial Proportions per Cell")

multiplot(p1, p2)

#' 
#' # Cell filtering
#' 
#' After reviewing the diagnostic plots, we will proceed with removing low-quality cells from `sce` with the thresholds that were selected in [Identify low-quality cells]. You can also change the thresholds that is suitable for your study to prevent removing biologically relevant cells.
#' 
#' ## Remove outlier cells
#' 
#' In this example, none of the cells are outliers, and hence none were removed.
#' 
## ----cell-filtering-----------------------------------------------------------
sce.filt <- sce[, !discard]
sce.filt

#' 
#' ## Update per-feature QC
#' 
#' Because poor-quality cells were removed, we will update the per-feature QC metrics whereby some calculations uses cell data.
#' 
## ----update-per-feature-qc-to-sce.filt----------------------------------------
rowData(sce.filt) <- cbind(rowData(sce.filt)[,c("Ensembl", "Symbol")], 
			   perFeatureQCMetrics(sce.filt))

# Add additional stats to per-feature QC
rowData(sce.filt)$n_cells <- rowData(sce.filt)$detected/100 * ncol(sce.filt) # number of expressing cells
rowData(sce.filt)$pct_dropout <- 100 - rowData(sce.filt)$detected # percentage of cells with zero counts
rowData(sce.filt)$total_counts <- rowData(sce.filt)$mean * ncol(sce.filt)

#' 
#' # Assess QC metrics on features
#' 
#' Show number of genes that are not expressed in any cell.
#' 
## ----show-dropout-------------------------------------------------------------
not.expressed <- rowData(sce.filt)$n_cells == 0
table(not.expressed)

#' 
#' We remove genes that are not expressed in any cell
#' 
## ----remove-dropout-----------------------------------------------------------
sce.filt <- sce.filt[!not.expressed,]
sce.filt

#' 
#' Aside from the 6858 genes that are not expressed in any cell, there are also genes that have extremely low average expression across all cells. We can also observe a positive relationship between the number of of expressing cells versus mean counts of all the genes in the expression matrix.
#' 
## ----plot-pct_dropout, message = FALSE, fig.width = 8, fig.height = 10, fig.align = "center", dpi = 100----
# histogram
p1 <- ggplot(as.data.frame(rowData(sce.filt)), aes(x = mean)) +
	geom_histogram(position = "identity", bins = 100, fill = "white", color = "black") +
	scale_x_log10(breaks = logbreak, labels = loglab) +
	geom_vline(xintercept = 0.005, linetype = 2, color = "cyan") +	# mean count = 0.005
	geom_vline(xintercept = 0.010, linetype = 2, color = "blue") +	# mean count = 0.010
	geom_vline(xintercept = 0.020, linetype = 2, color = "red") +	# mean count = 0.020
	theme_classic(base_size = 12) + xlab("Mean counts") +
	ylab("Frequency") + ggtitle("Histogram of Mean Counts")

# scatter plot
p2 <- ggplot(as.data.frame(rowData(sce.filt)), aes(n_cells, mean, color = pct_dropout)) + 
	geom_point(size = 0.6, alpha = 0.3) + theme_classic(base_size = 12) + 
	scale_x_log10(breaks = logbreak, labels = loglab) + 
	scale_y_log10(breaks = logbreak, labels = loglab) +
	geom_hline(yintercept = 0.005, linetype = 2, color = "cyan") +
	geom_hline(yintercept = 0.010, linetype = 2, color = "blue") +
	geom_hline(yintercept = 0.020, linetype = 2, color = "red") +
	guides(color = guide_legend("Pct Dropouts", override.aes = list(size = 3, alpha = 1))) + 
	xlab("Number of expressing cells") + ylab("Mean counts") + 
	ggtitle("Expressing Cells vs. Mean Counts")

multiplot(p1, p2)

#' 
#' # Feature filtering
#' 
#' ## Compare filtering methods
#' 
#' After assessing the QC metrics on features, we can proceeed to remove genes that is considered "undetectable". This can be done by define a gene as detectable if the average expression is above a certain threshold, or a `N` number of cells expressing `X` number of the transcript.
#' 
## ----comparison-feature-filtering-methods-------------------------------------
# Average expression more than 0.02
qc.gene1 <- rowData(sce.filt)$mean > 0.02

# 2 transcript detected in at least 0.1% of total cells
ncell <- ncol(sce.filt) * 0.001
ncell
qc.gene2 <- nexprs(sce.filt, byrow = TRUE, detection_limit = 2) >= ncell

x = data.frame(n_cells = rowData(sce.filt)$n_cells, mean = rowData(sce.filt)$mean, 
	       qc1 = qc.gene1, qc2 = qc.gene2)
x$cond = paste0(x$qc1, x$qc2)
x$cond = as.factor(x$cond)
levels(x$cond) = c("Failed (Both)", "Failed (mean)", "Failed (nexprs)", "Pass")

table(x$cond)

# Show as Venn diagram
limma::vennDiagram(data.frame(MeanExpr = qc.gene1, kOverA = qc.gene2),
                   circle.col = c("blue", "red"), main = "Detectable Genes")

#' 
## ----plot-feature-filtering, message = FALSE, fig.width = 8, fig.height = 10, fig.align = "center", dpi = 100----
# scatter plots
p3 <- ggplot(x, aes(n_cells, mean, color = cond)) + 
	geom_point(size = 0.6, alpha = 0.3) + theme_classic(base_size = 12) +
        scale_x_log10(breaks = logbreak, labels = loglab) +
        scale_y_log10(breaks = logbreak, labels = loglab) +
	geom_hline(yintercept = 0.02, linetype = 2, color = "blue") + # mean count = 0.005
        guides(color = guide_legend("Feature Status", override.aes = list(size = 3, alpha = 1))) +
        xlab("Number of expressing cells") + ylab("Mean counts") +
        ggtitle("Expressing Cells vs. Mean Counts")

p4 <- ggplot(x, aes(n_cells, mean, color = cond)) + geom_point(size = 0.6, alpha = 0.3) + 
	facet_wrap(~ cond) + theme_classic(base_size = 12) + 
	scale_x_log10(breaks = logbreak, labels = loglab) +
	scale_y_log10(breaks = logbreak, labels = loglab) +
	geom_hline(yintercept = 0.02, linetype = 2, color = "blue") + # mean count = 0.005
	guides(color = guide_legend("Feature Status", override.aes = list(size = 3, alpha = 1))) +
	xlab("Number of expressing cells") + ylab("Mean counts") +
	ggtitle("Expressing Cells vs. Mean Counts")

multiplot(p3, p4)

#' 
#' ## Remove lowly-expressed genes
#' 
#' Here we will use the classical `kOverA` approach to select genes that can be detected (2 transcripts) in at least 0.1% of total cells.
#' 
## ----feature-filtering--------------------------------------------------------
sce.filt <- sce.filt[qc.gene2,]
sce.filt

#' 
#' ## Update per-cell QC
#' 
#' Because lowly-expressed genes were removed, we will update the per-cell QC metrics whereby some calculations uses gene data.
#' 
## ----add-per-cell-qc-to-sce.filt----------------------------------------------
colData(sce.filt) <- cbind(colData(sce.filt)[,c("Barcode","Sample","Condition")], 
			   perCellQCMetrics(sce.filt, list(MT = grep("^mt-|^MT-", rowData(sce.filt)$Symbol))))

#' 
#' ## Add average expression
#' 
#' Use the `calculateAverage` function to average counts per feature after normalizing with size factors.
#' 
## ----plot-average-counts, message = FALSE, fig.width = 6, fig.height = 6, fig.align = "center", dpi = 100----
rowData(sce.filt)$ave_counts <- calculateAverage(sce.filt)

r.squared = summary(lm(mean ~ ave_counts, rowData(sce.filt)))$r.squared
r.squared = as.expression(bquote(R^2 == .(round(r.squared, 4))))

ggplot(as.data.frame(rowData(sce.filt)), aes(mean, ave_counts)) + 
	geom_point(size = 0.6, alpha = 0.3) + theme_classic(base_size = 12) + 
	scale_x_log10(breaks = logbreak, labels = loglab) + 
	scale_y_log10(breaks = logbreak, labels = loglab) + 
	geom_smooth(method = "lm", se = FALSE) + 
	annotate("text", label = r.squared, x = 0.1, y = 100, size = 4) +
	xlab("Mean counts") + ylab("Size-adjusted average count") + 
	ggtitle("Mean Counts vs. Size-adjusted Average Count")

#' 
#' # Add log2 counts to `sce.filt`
#' 
#' In addition to the count data in `assays`, we will also add the log2-transformed counts to `assays`.
#' 
## ----show-assay-counts--------------------------------------------------------
# Accessing the assay data
dim(assay(sce.filt, "counts"))

#' 
#' ## log2 raw counts
#' 
## ----add-log2-raw-counts------------------------------------------------------
assay(sce.filt, "logcounts") <- log2(counts(sce.filt) + pseudocount)

#' 
#' ## log2 count-per-million (CPM)
#' 
#' The effective library sizes are used as the denominator of the CPM calculation.
#' 
#' ```
#' # More about lib.sizes calculation in calculateCPM()
#' # x is a numeric matrix of counts
#' x <- assay(sce, "counts")
#' size.factors <- colSums(x)/mean(colSums(x))     # same as scater::librarySizeFactors(x)
#' lib.sizes <- colSums(x) / 1e6                   # count-per-million
#' lib.sizes <- size.factors / mean(size.factors) * mean(lib.sizes) # normalisation
#' ```
#' 
## ----add-log2-cpm-------------------------------------------------------------
assay(sce.filt, "logcpm") <- log2(calculateCPM(sce.filt) + pseudocount)

#' 
## ----show-assays--------------------------------------------------------------
# Assay info
str(assays(sce.filt))

#' 
#' # Save data
#' 
## ----save-image---------------------------------------------------------------
save.image("BachMammary.RData")

#' 
#' # Session information
#' 
## ----session-info-------------------------------------------------------------
sessionInfo()

