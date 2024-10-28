library(ggplot2)
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

source("funciones.R")
source("colores.R")


# comuna ----
# especificar la comuna para obtenerla desde los datos limpiados en limpiar.R

# comuna_elegida = "ANTOFAGASTA"
# comuna_elegida = "AYSEN"

# comuna al azar
# comuna_elegida = sample(unique(datos_todos$comuna), 1)

# nombre correcto de la comuna
comuna_t <- corregir_comunas(comuna_elegida)

# comuna_elegida = "PUENTE ALTO"
# filtrar comuna ----
datos_grafico <- datos_todos |>
  filter(comuna == comuna_elegida) |>
  # arreglar etiquetas
  mutate(porcentaje_t = percent(porcentaje, accuracy = 0.1, trim = TRUE)) |> 
  mutate(partido = replace_na(partido, ""),
         candidato = ifelse(partido == "", candidato, 
                            glue("{candidato} ({partido})")),
         candidato = candidato |> str_wrap(22),
         candidato = fct_reorder(candidato, porcentaje),
         candidato = fct_relevel(candidato, "Nulo/Blanco",after = 0)) |> 
  arrange(desc(candidato))

n_candidatos = length(datos_grafico$candidato)
n_mesas = datos_grafico$mesas_escrutadas[1]
total_mesas = datos_grafico$mesas_totales[1]
p_mesas = datos_grafico$mesas_porcentaje[1] |> percent(accuracy = 0.01, trim = TRUE)

# usar esto o alto variable de la imagen final
# opt_ancho_col = case_when(n_candidatos >= 8 ~ .55,
#                           n_candidatos >= 6 ~ .4,
#                           n_candidatos >= 4 ~ .3,
#                           n_candidatos < 4 ~ .2)



# gráfico ----

opt_nudge = 0.006
opts_corte = 0.045 * n_candidatos
opts_size_texto = 4
opt_ancho_col = .4
opt_expand_x = 0.1


## base ----
grafico_1 <- datos_grafico |> 
  ggplot(aes(porcentaje, candidato, fill = sector)) +
  # geom_vline(xintercept = .5, color = color_detalle2) +
  geom_col(width = opt_ancho_col, alpha = .9) +
  geom_text(data = ~filter(.x, porcentaje > opts_corte),
            aes(label = porcentaje_t), hjust = 1,
            color = color_fondo, fontface = "bold", size = opts_size_texto, family = tipografia,
            nudge_x = -opt_nudge, alpha = .95, show.legend = F) +
  geom_text(data = ~filter(.x, porcentaje <= opts_corte),
            aes(label = porcentaje_t, color = sector), 
            hjust = 0, size = opts_size_texto, family = tipografia,
            nudge_x = opt_nudge, show.legend = F)

## escalas ---- 
grafico_2 <- grafico_1 +
  scale_x_continuous(labels = scales::percent, expand = expansion(c(0, opt_expand_x))) +
  scale_fill_manual(values = c("Centro" = color$centro,
                               "Izquierda" = color$izquierda,
                               "Derecha" = color$derecha,
                               "Independiente" = color$independiente,
                               "Otros" = color$otros), aesthetics = c("color", "fill")) +
  guides(fill = guide_legend(position = "inside", ncol = 1))

## temas ----
grafico_3 <- grafico_2 +
  theme_classic() +
  # títulos
  theme(text = element_text(family = tipografia, color = color_texto), 
        plot.subtitle = element_text(margin = margin(t = -3)), 
        plot.title.position = "plot") +
  # fondos
  theme(panel.background = element_rect(fill = color_fondo),
        panel.grid.major.x = element_line(color = color_detalle, lineend = "round"),
        plot.margin = unit(c(4, 4, 2, 4), "mm")) +
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
  theme(legend.title = element_text(face = "italic", size = 9),
        legend.text = element_text(size = 9, margin = margin(l = 4)),
        legend.position.inside = c(0.98, 0.02),
        legend.justification = c(1, 0),
        legend.background = element_rect(fill = alpha(color_fondo, 0.6)),
        legend.key.size = unit(4, "mm"),
        legend.key.spacing.y = unit(1.5, "mm"),
        plot.caption = element_text(margin = margin(t = 10), lineheight = 1, colour = color_texto))

## textos ----
grafico_4 <- grafico_3 +
  labs(title = "_Resultados parciales:_ Elecciones Municipales 2024",
       subtitle = glue("**{comuna_t}**"),
       fill = "Sector político",
       y = "Candidaturas", #glue("Candidaturas en {comuna_t}"),
       x = glue("Porcentaje de votos ({p_mesas} de mesas escrutadas)"),
       caption = glue("Fuente: Servel (elecciones.servel.cl), obtenido el {fecha_scraping |> format('%d de %B')} a las {fecha_scraping |> format('%H:%M')}\nElaboración: Bastián Olea Herrera")) +
  theme(plot.title = element_markdown(),
        plot.subtitle = element_markdown())

grafico_4

# guardar ----
ggsave(filename = glue("graficos/servel_grafico_{comuna_t}_{formatear_fecha(fecha_scraping)}.jpg"),
       width = 5, height = (1.4 + (n_candidatos * 0.3)), scale = 1.5
)
