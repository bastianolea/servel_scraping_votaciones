library(ggplot2)
library(scales)
library(forcats)
library(glue)
library(lubridate)

source("funciones.R")
source("datos/colores.R")


source("servel_limpiar.R")
source("datos/comunas.R")
# comunas_rm

# filtrar comuna
datos_resultados <- datos_todos |>
  # filter(comuna %in% comunas_rm) |> 
  group_by(comuna) |> 
  slice_max(votos) |> 
  ungroup() |> 
  # arreglar etiquetas
  mutate(porcentaje_t = scales::percent(porcentaje, accuracy = 0.1, trim = TRUE)) |> 
  group_by(comuna) |> 
  mutate(partido = replace_na(partido, ""),
         candidato = fct_reorder(candidato, porcentaje),
         candidato = fct_relevel(candidato, "Nulo/Blanco",after = 0)) |> 
  ungroup() |> 
  relocate(sector, .after = partido)

datos_resultados |> 
  count(partido)

datos_resultados |> 
  count(sector)

datos_resultados |> 
  count(partido, sector) |> 
  arrange(sector)

# solo partido ----
datos_resultados_partido <- datos_resultados |> 
  group_by(partido) |> 
  summarize(n = n()) |>
  arrange(desc(n)) |> 
  mutate(p = n/sum(n)) |> 
  rowwise() |> 
  # mutate(partido_reduc = if_else(p <= 0.055, "Otros", partido),
  mutate(partido_reduc = if_else(p <= 0.01, "Otros", partido),
         partido_reduc = if_else(partido_reduc == "Independiente", "Ind.", partido_reduc)) |> 
  group_by(partido_reduc) |>
  summarize(n = sum(n),
            p = sum(p)) |> 
  rename(partido = partido_reduc)

datos_resultados_partido |> 
  ggplot(aes(x = p, y = factor(1), fill = partido)) +
  geom_col(width = 1, linewidth = 0.6, color = "white") +
  geom_text(aes(label = partido), position = position_stack(vjust = 0.5),
            angle = 90, hjust = 0.5, fontface = "bold", color = "white") + 
  geom_text(aes(label = percent(p, accuracy = 1), y = 0.25, color = partido), position = position_stack(vjust = 0.5),
            angle = 90, hjust = 0.5, fontface = "bold") + 
  scale_y_discrete(guide = "none", name = NULL) +
  guides(fill = "none", color = "none") +
  coord_radial(expand = FALSE, rotate.angle = TRUE, theta = "x",
               start = 0.7, 
               inner.radius = 0.4) +
  theme_void()


# partido sector (para infografía) ----
datos_resultados_sector <- datos_resultados |> 
  group_by(partido, sector) |> 
  summarize(n = n()) |>
  arrange(desc(n)) |> 
  ungroup() |> 
  mutate(p = n/sum(n)) |> 
  rowwise() |> 
  mutate(partido_reduc = if_else(p <= 0.01, "Otros", partido),
         partido_reduc = if_else(partido_reduc == "Independiente", "Ind.", partido_reduc)) |> 
  group_by(partido_reduc, sector) |>
  summarize(n = sum(n),
            p = sum(p)) |> 
  rename(partido = partido_reduc)


opts_texto_size = 2.4 # para collage/infografia
opts_margen_interno = 0.1 # para collage/infografia

torta_sector <- datos_resultados_sector |> 
  ggplot(aes(x = p, y = factor(1), fill = sector)) +
  geom_col(width = 1, linewidth = 0.1,
           color = "white") +
  geom_text(aes(label = partido), position = position_stack(vjust = 0.5),
            angle = 90, hjust = 0.5, fontface = "bold", color = "white", size = opts_texto_size) + 
  geom_text(aes(label = percent(p, accuracy = 1), 
                y = opts_margen_interno), 
            position = position_stack(vjust = 0.5),
            color = color_detalle3,
            fontface = "bold",
            size = opts_texto_size,
            angle = 90, hjust = 0.5) + 
  scale_y_discrete(guide = "none", name = NULL) +
  scale_fill_manual(values = c("Centro" = color$centro,
                               "Izquierda" = color$izquierda,
                               "Derecha" = color$derecha,
                               "Independiente" = color$independiente,
                               "Otros" = color$otros), aesthetics = c("color", "fill")) +
  guides(fill = "none", color = "none") +
  coord_radial(expand = FALSE, rotate.angle = TRUE, theta = "x",
               start = 0.74, 
               inner.radius = 0.5) +
  theme_void() +
  # fondos
  theme(plot.margin = unit(rep(-10, 4), "mm"))


# partido sector ----


opts_texto_size = 2.9 # para individual
opts_margen_interno = 0.35 # para collage/infografia

torta_sector <- datos_resultados_sector |> 
  ggplot(aes(x = p, y = factor(1), fill = sector)) +
  geom_col(width = 1, linewidth = 0.4, # linewidth = 0.1,
           color = "white") +
  geom_text(aes(label = partido), position = position_stack(vjust = 0.5),
            angle = 90, hjust = 0.5, 
            fontface = "bold", family = tipografia, color = "white", size = opts_texto_size) + 
  geom_text(aes(label = n, 
                y = 1.65, color = sector), 
            position = position_stack(vjust = 0.5),
            # color = color_detalle3, 
            fontface = "bold", family = tipografia,
            size = opts_texto_size*1.2,
            # angle = 90, 
            hjust = 0.5) + 
  scale_y_discrete(guide = "none", name = NULL) +
  scale_fill_manual(values = c("Centro" = color$centro,
                               "Izquierda" = color$izquierda,
                               "Derecha" = color$derecha,
                               "Independiente" = color$independiente,
                               "Otros" = color$otros), aesthetics = c("color", "fill")) +
  guides(fill = "none", color = "none") +
  coord_radial(expand = FALSE, rotate.angle = TRUE, theta = "x",
               start = 0.74, 
               inner.radius = 0.5) +
  theme_void(base_family = tipografia) +
  labs(title = "Alcaldes electos, por partido y sector político", 
       subtitle = "Votación de alcaldes a nivel nacional, Elecciones Municipales 2024",
       caption = glue("Fuente: Servel (elecciones.servel.cl), obtenido el {fecha_scraping |> format('%d de %B')} a las {fecha_scraping |> format('%H:%M')}\nElaboración: Bastián Olea Herrera")) +
  theme(plot.title = element_text(face = "bold", margin = margin(t = 6, l = 10, b = 6)),
        plot.subtitle = element_text(margin = margin(l = 10, t = 0, b =-20)),
        plot.caption = element_text(lineheight = 1.2, margin = margin(t = -10, r = 6, b = 6)))

torta_sector

## guardar ----
ggsave(filename = glue("graficos/resultados/servel_alcaldes_sector_{formatear_fecha(fecha_scraping)}.jpg"),
       width = 5, height = 5.5, scale = 1.1
)
