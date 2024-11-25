library(dplyr)
library(forcats)
library(stringr)
library(glue)
library(scales)
library(ggplot2)
library(sysfonts)
library(showtext)
library(ragg)
library(ggtext)

# tipografía
tipografia = "Open Sans"
font_add_google(tipografia, tipografia, db_cache = TRUE)
showtext_auto()
showtext_opts(dpi = 290)

source("funciones.R")
source("datos/colores.R")

eleccion <- "gobernadores"

# eleccion_titulo <- "Elecciones Municipales 2024"
eleccion_titulo <- "Elecciones de Gobernadores 2024"

# eleccion_url <- "elecciones.servel.cl"
eleccion_url <- "eleccionesgore.servel.cl"

# datos ----
source("servel_limpiar.R")

datos_barras <- datos_todos |> 
  mutate(candidato = str_extract(candidato, "\\w+ \\w+")) |> 
  # filter(!is.na(candidato)) |> 
  mutate(candidato = replace_na(candidato, "Nulos/blancos")) |> 
  filter(comuna %in% comunas_rm) |> 
  select(comuna, candidato, votos, porcentaje, mesas_porcentaje) |> 
  mutate(porcentaje_t = percent(porcentaje, accuracy = 1)) |> 
  mutate(total = sum(votos), .by = comuna) |> 
  mutate(comuna = str_to_title(comuna))

p_mesas <- datos_todos |> 
  group_by(comuna) |> 
  slice(1) |> 
  ungroup() |> 
  summarize(mean(mesas_porcentaje)) |> 
  pull() |> 
  percent(accuracy = 0.01, decimal.mark = ",")

# gráfico base ----
barras_base <- datos_barras |> 
  arrange(desc(total)) |>
  # ranking
  mutate(rank = dense_rank(desc(total))) |> 
  filter(rank <= 35) |> 
  # ordenar factores
  mutate(comuna = fct_reorder(comuna, total)) |> 
  ggplot() +
  aes(x = porcentaje, y = comuna, fill = candidato) +
  geom_col(width = .7, position = position_stack()) +
  geom_point(data = ~group_by(.x, comuna) |> 
               slice_max(votos),
             aes(x = 1.035, color = candidato), 
             size = 2.8, alpha = .9,
             show.legend = FALSE) +
  geom_text(aes(label = ifelse(porcentaje > .2, porcentaje_t, "")),
            position = position_stack(vjust = 0.5),
            size = 2.6, family = tipografia, fontface = "bold", color = "white") +
  theme_classic()

barras_base

# temas ----
barras <- barras_base +
  scale_y_discrete(expand = expansion(c(0.028, 0.028))) +
  scale_x_continuous(expand = expansion(c(0.028, 0.036)),
                     labels = scales::label_percent(accuracy = 1)) +
  scale_fill_manual(values = c("Claudio Orrego" = color$centro,
                               "Francisco Orrego" = color$derecha,
                               "Nulos/blancos" = "grey60"), 
                    aesthetics = c("color", "fill")) +
  guides(fill = guide_legend(position = "bottom"),
         color = guide_legend(position = "bottom")) +
  # títulos
  theme(text = element_text(family = tipografia, color = color_texto), 
        plot.subtitle = element_text(margin = margin(t = -3)), 
        plot.title.position = "plot") +
  # fondos
  theme(panel.background = element_rect(fill = color_fondo),
        panel.grid.major.x = element_blank(),
        panel.grid.major.y = element_blank(),
        plot.margin = unit(c(4, 8, 2, 4), "mm")) +
  # ejes
  theme(axis.title = element_text(face = "italic"),
        axis.title.y = element_text(margin = margin(l = -2, r = 2)),
        axis.title.x = element_text(margin = margin(t = 8)),
        axis.text.y = element_text(face = "bold", size = 10,
                                   color = color_texto, margin = margin(l = 7, r = 2)),
        axis.line = element_line(color = color_texto, linewidth = .7),
        axis.ticks = element_line(color = color_texto, lineend = "round", linewidth = .7),
        axis.ticks.y = element_blank()) +
  # leyenda
  theme(#legend.title = element_text(face = "italic", size = 9),
    legend.text = element_text(size = 9, margin = margin(l = 4)),
    legend.title = element_blank(),
    legend.justification = c(1, 0),
    legend.background = element_rect(fill = color_fondo),
    legend.key.size = unit(4, "mm"),
    legend.key.spacing.y = unit(1.5, "mm")) +
  theme(plot.title = element_markdown(),
        plot.subtitle = element_markdown(margin = margin(t = -3, b = 5)),
        plot.caption = element_text(margin = margin(t = 10), lineheight = 1, colour = color_texto)) +
  labs(title = glue("**Resultados parciales:** {eleccion_titulo}"),
       subtitle = glue("_Región Metropolitana_ (35 comunas con más votos)"),
       fill = "Candidatos",
       y = NULL,
       x = glue("Porcentaje de votos ({p_mesas} de mesas escrutadas)"),
       # caption = glue("Fuente: Servel ({eleccion_url}), obtenido el {fecha_scraping |> format('%d de %B')} a las {fecha_scraping |> format('%H:%M')}\nElaboración: Bastián Olea Herrera")
       caption = glue("Fuente: Servel ({eleccion_url}), obtenido el {fecha_scraping |> format('%d de %B')}\nElaboración: Bastián Olea Herrera")
  )


barras

# guardar ----
ggsave(filename = glue("graficos/resultados/{eleccion}/servel_grafico_barras_{now()}.jpg"),
       width = 3.6, height = 5, scale = 1.5
)
