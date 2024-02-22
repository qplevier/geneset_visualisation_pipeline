library(tidyverse)
library(phyloseq)
library(ggplot2)
library(RColorBrewer)

#create color package
mycolors <- c(brewer.pal(name="Set1", n = 8),
              brewer.pal(name="Dark2", n = 8),
              brewer.pal(name="Set2", n = 8),
              brewer.pal(name="Set3", n = 8),
              brewer.pal(name="Accent", n = 8),
              brewer.pal(name="Set3", n = 10),
              brewer.pal(name="Set1", n = 8),
              brewer.pal(name="Dark2", n = 8),
              brewer.pal(name="Set2", n = 8),
              brewer.pal(name="Set3", n = 8),
              brewer.pal(name="Accent", n = 8),
              brewer.pal(name="Set3", n = 10),
              brewer.pal(name="Set1", n = 8),
              brewer.pal(name="Dark2", n = 8),
              brewer.pal(name="Set2", n = 8),
              brewer.pal(name="Set3", n = 8),
              brewer.pal(name="Accent", n = 8),
              brewer.pal(name="Set3", n = 5))

# read phyloseq object
table <- read_rds(snakemake@input[["physeq"]]) %>%
  subset_samples(micro == snakemake@params[["micro"]] &
                   time == snakemake@params[["timepoint"]]) %>%
  psmelt() %>%
  mutate(id_sample = as.factor(id_sample)) %>%
  filter(Abundance > "0") %>%
  separate(OTU, c("OTU", "Species"), "\\|") %>%
  na.omit() %>%
  mutate(Species = str_remove(Species, ".*s__")) %>%
  group_by(Species, id_sample, micro, time) %>%
  summarise(Abundance = sum(Abundance)) %>%
  ungroup() %>%
  group_by(id_sample, .drop = FALSE) %>%
  mutate(Relative_abundance = Abundance/sum(Abundance)*100) %>%
  ungroup() %>%
  group_by(Species, .drop = FALSE) %>%
  mutate(Sum_abundance = sum(Abundance)) %>%
  ungroup() %>%
  filter(Sum_abundance %in% c(rev(sort(unique(.$Sum_abundance)))[0:snakemake@params[["top"]]]))

# create bubbleplot
ggplot(table, aes(x = id_sample, y = reorder(Species, desc(Species)), size = Relative_abundance, fill = Species)) +
  geom_point(alpha = 0.75,
             shape = 21) +
  facet_grid( ~ micro + time, scales = "free", space = "free", labeller = labeller(.multi_line = FALSE)) +
  labs(x = "",
       y = "",
       size = "Relative\nabundance(%)",
       fill = "")  +
  theme(
    legend.key = element_blank(),
    axis.text.x = element_text(
      colour = "black",
      size = 8,
      face = "plain",
      angle = 45,
      hjust = 1
    ),
    axis.text.y = element_text(
      colour = "black",
      face = "plain",
      size = 8
    ),
    legend.text = element_text(
      size = 10,
      face = "plain",
      colour = "black"
    ),
    legend.title = element_text(size = 12, face = "plain"),
    panel.background = element_blank(),
    panel.border = element_rect(
      colour = "grey",
      fill = NA,
      linewidth = 1.2
    ),
    legend.position = "right"
  ) +
  scale_fill_manual(values = mycolors, guide = "none") +
  labs(x = "Individual",
       y = "Species",
       title = glue::glue("{snakemake@params[['top']]} most abundant species")) +
  theme(strip.text.x = element_text(size = 12))

ggsave(snakemake@output[["png"]], height = (snakemake@params[["top"]] * 40 + 450), units = "px")