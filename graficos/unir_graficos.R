library(ggplot2)
library(sf)
library(scales)
library(forcats)
library(glue)
library(lubridate)
library(sysfonts)
library(showtext)
library(ragg)
library(ggtext)

# tipografía
tipografia = "Open Sans"
font_add_google(tipografia, tipografia, db_cache = TRUE)
showtext_auto()
showtext_opts(dpi = 290)

library(ragg)
library(cowplot)

ggdraw() +
  draw_plot(mapa_chile +
              theme(#plot.title = element_markdown(margin = margin(t = -10)),
                    plot.subtitle = element_text(margin = margin(l = 4, t = 6, b = 8)),
                    plot.caption = element_text(margin = margin(t = 6, r = -95))),
            hjust = 0, x = -0.12) +
  draw_plot(mapa_rm,
            height = 0.32,
            x = 0.22,
            y = 0.595
  ) +
  draw_plot(torta_sector,
            height = 0.27,
            x = 0.225,
            y = 0.27) +
  theme_cowplot(font_family = tipografia)

ggsave(filename = glue("graficos/resultados/servel_resultados_multi_{formatear_fecha(fecha_scraping)}_c.jpg"),
       width = 3.4, height = 5, scale = 1.5
)  
