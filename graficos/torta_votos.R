source("servel_limpiar.R")
source("funciones.R")
source("datos/colores.R")

library(ggplot2)
library(scales)
library(glue)
library(sysfonts)
library(showtext)
library(ragg)

# tipografía
tipografia = "Open Sans"
font_add_google(tipografia, tipografia, db_cache = TRUE)
showtext_auto()
showtext_opts(dpi = 290)


# votos por sector ----
datos_todos |> 
  group_by(sector) |> 
  summarize(votos = sum(votos)) |> 
  arrange(desc(votos)) |> 
  mutate(p = votos/sum(votos)) |> 
  mutate(sector = recode(sector, "Independiente" = "Indep.")) |> 
  ggplot(aes(x = p, y = factor(1), fill = sector)) +
  geom_col(width = 1, linewidth = 0.6, color = "white") +
  geom_text(aes(label = sector), position = position_stack(vjust = 0.5), family = tipografia,
            angle = 90, hjust = 0.5, fontface = "bold", color = "white") + 
  geom_text(aes(label = percent(p, accuracy = 1), y = 0.25, color = sector), position = position_stack(vjust = 0.5),
            angle = 90, hjust = 0.5, fontface = "bold", family = tipografia,) + 
  geom_text(aes(label = comma(votos, big.mark = ".", decimal.mark = ","), y = 1.7, color = sector), 
            position = position_stack(vjust = 0.5),
            # angle = 90, 
            hjust = 0.5, fontface = "bold", family = tipografia,) + 
  scale_y_discrete(guide = "none", name = NULL) +
  guides(fill = "none", color = "none") +
  coord_radial(expand = FALSE, rotate.angle = TRUE, theta = "x", start = 0, inner.radius = 0.4) +
  theme_void(base_family = tipografia) +
  scale_fill_manual(values = c("Centro" = color$centro,
                               "Izquierda" = color$izquierda,
                               "Derecha" = color$derecha,
                               "Indep." = color$independiente,
                               "Otros" = color$otros), aesthetics = c("color", "fill")) +
  labs(title = "Votos totales por sector político", 
     subtitle = "Votación de alcaldes a nivel nacional, Elecciones Municipales 2024",
     caption = glue("Fuente: Servel (elecciones.servel.cl), obtenido el {fecha_scraping |> format('%d de %B')} a las {fecha_scraping |> format('%H:%M')}\nElaboración: Bastián Olea Herrera")) +
  theme(plot.title = element_text(face = "bold", margin = margin(t = 6, l = 10, b = 6)),
        plot.subtitle = element_text(margin = margin(l = 10, t = 0, b =-20)),
        plot.caption = element_text(lineheight = 1.2, margin = margin(t = -10, r = 6, b = 6)))

## guardar ----
ggsave(filename = glue("graficos/resultados/servel_votos_sector_{formatear_fecha(fecha_scraping)}.jpg"),
       width = 5, height = 5.5, scale = 1.1
)


# votos por partido ----
datos_todos |> 
  mutate(partido = ifelse(partido == "", "Ninguno", partido)) |> 
  # mutate(sector = case_match(sector, 
  #                            "Derecha" ~ "Derecha", 
  #                            "Izquierda" ~ "Izquierda",
  #                            .default = "Otros")) |> 
  group_by(sector, partido) |> 
  summarize(votos = sum(votos)) |> 
  arrange(sector, desc(votos)) |> 
  mutate(color = "") |> 
  gt() |> 
  fmt_number(votos, sep_mark = ".", drop_trailing_zeros = TRUE) |> 
  data_color(votos, 
             # target_columns = color, 
             method = "numeric", palette = "viridis") |> 
  cols_label(color = "")


