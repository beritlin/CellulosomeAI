library(data.table)
library(ggplot2)
library(reticulate)
library(bigstatsr)

# Load Python UMAP module
umap <- import("umap")

# Read input count matrix and metadata
counts <- fread(".../txipv3.csv.gz")
sp <- fread(".../species.txt")


# Filter  species
sp <- sp[SUPERREGNUM != "viruses"] # no virus
# sp <- sp[SUPERREGNUM == "bacteria"] # bacteria only


# Merge species metadata with counts matrix using Tax_ID
merged <- merge(sp[, .(Tax_ID, SUPERREGNUM)], counts, by.x = "Tax_ID", by.y = "V1")

# Extract metadata
meta_info <- merged[, .(Tax_ID, SUPERREGNUM)]

# Remove metadata columns and keep numerical matrix
expr_matrix <- as.data.frame(merged[, -c("Tax_ID", "SUPERREGNUM")])
rownames(expr_matrix) <- meta_info$Tax_ID

# Log-transform the expression matrix after adding pseudo-count
expr_log <- log1p(expr_matrix + 1)

# Identify columns (features) with zero variance
var_zero <- apply(expr_log, 2, sd) == 0

# Remove zero-variance columns
expr_filtered <- expr_log[, !var_zero]

### species umap ###
# Convert to Filebacked Big Matrix (FBM) format
fbm <- as_FBM(as.matrix(t(expr_filtered)))

# Compute Pearson correlation matrix
cor_matrix <- big_cor(fbm)[]
rownames(cor_matrix) <- rownames(expr_filtered)
colnames(cor_matrix) <- rownames(expr_filtered)

### domain umap ###
# fbm <- as_FBM(as.matrix(expr_filtered))
# cor_matrix <- big_cor(fbm)[]

# rownames(cor_matrix) <- colnames(expr_filtered)
# colnames(cor_matrix) <- colnames(expr_filtered)

# Apply UMAP using GPU-accelerated Python implementation
reducer <- umap$UMAP(n_neighbors = 15L, min_dist = 0.1, metric = 'euclidean') 
embedding <- reducer$fit_transform(cor_matrix)

# Construct UMAP dataframe with metadata
df_umap <- as.data.frame(embedding)
colnames(df_umap) <- c("UMAP1", "UMAP2")
df_umap$Tax_ID <- rownames(cor_matrix)
df_umap <- merge(df_umap, meta_info, by = "Tax_ID")

# Plot UMAP result
p <- ggplot(df_umap, aes(x = UMAP1, y = UMAP2, color = SUPERREGNUM)) +
  geom_point(alpha = 0.6) +
  labs(title = "UMAP projection", color = "Superregnum") +
  theme_classic()

# Save UMAP plot
ggsave(".../umap_txipv3.jpg",
       plot = p, width = 8, height = 6, dpi = 300)