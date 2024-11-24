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

source("funciones.R")
source("datos/colores.R")
source("datos/comunas.R")

source("servel_limpiar.R")

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


# mapas ----
library(chilemapas)

# obtener mapa comunal
mapa_pais <- chilemapas::mapa_comunas %>%
  left_join(chilemapas::codigos_territoriales %>%
              select(matches("comuna"), matches("region"))) |> 
  mutate(geometry = rmapshaper::ms_simplify(geometry, keep = 0.2, keep_shapes = TRUE))

# obtener mapa regional
mapa_region <- mapa_pais |> 
  group_by(codigo_region) |> 
  summarize(geometry = st_union(geometry)) |> 
  mutate(geometry = rmapshaper::ms_simplify(geometry, keep = 0.5, keep_shapes = TRUE))



# unión datos con mapas ----

# preparar columna de comunas en datos
datos_resultados_join <- datos_resultados |> 
  mutate(comuna_match = tolower(comuna)) |> 
  mutate(comuna_match = case_match(comuna_match, 
                                   "aysen" ~ "aisen",
                                   "coyhaique" ~ "coihaique",
                                   "llay-llay" ~ "llaillay",
                                   "o'higgins" ~ "ohiggins",
                                   "paihuano" ~ "paiguano",
                                   "trehuaco" ~ "treguaco",
                                   tolower("CABO DE HORNOS(EX-NAVARINO)") ~ "cabo de hornos",
                                   "marchigue" ~ "marchihue",
                                   .default = comuna_match)) |> 
  mutate(comuna_match = stringi::stri_trans_general(comuna_match, "latin-ascii"))

# preparar columna de comunas en mapa
mapa_pais_join <- mapa_pais |>
  mutate(comuna_match = tolower(nombre_comuna))

# unir datos con mapa
mapa_resultados <- left_join(datos_resultados_join |> select(1:7, comuna_match),
          mapa_pais_join,
          by = "comuna_match") |> 
  filter(!is.na(codigo_comuna))
  # mutate(punto = geometry |> st_simplify() |> st_centroid(of_largest_polygon = TRUE))



mapa_base <- mapa_resultados |> 
  ggplot(aes(geometry = geometry)) +
  geom_sf(aes(fill = sector), color = color_fondo, linewidth = .1) +
  coord_sf(xlim = c(-77.1, -65), 
           ylim = c(-16.8, -56.5), expand = FALSE) +
  scale_fill_manual(values = c("Centro" = color$centro,
                               "Izquierda" = color$izquierda,
                               "Derecha" = color$derecha,
                               "Independiente" = color$independiente,
                               "Otros" = color$otros), aesthetics = c("color", "fill")) +
  theme_classic()

mapa_base + guides(fill = guide_none())

mapa_chile <- mapa_base +  
# títulos
  theme(text = element_text(family = tipografia, color = color_texto), 
        plot.subtitle = element_text(margin = margin(t = 4, b = 8, l = 4)), 
        plot.title.position = "plot", plot.caption.position = "plot",
        plot.title = element_markdown(margin = margin(l = 4))) +
  # fondos
  theme(panel.background = element_rect(fill = color_fondo),
        panel.grid.major.x = element_line(color = color_detalle, lineend = "round"),
        plot.margin = unit(c(4, 4, 2, 4), "mm")) +
  # leyenda
  theme(legend.title = element_text(face = "italic", size = 9),
        legend.text = element_text(size = 9, margin = margin(l = 4)),
        legend.position.inside = c(0.98, 0.02),
        legend.justification = c(1, 0),
        legend.background = element_rect(fill = alpha(color_fondo, 0.6)),
        legend.key.size = unit(4, "mm"),
        legend.key.spacing.y = unit(1.5, "mm")) +
  # ejes
  theme(axis.line = element_blank(), axis.text = element_blank(), axis.ticks = element_blank()) +
  # textos
  labs(title = "**Resultados:** Elecciones Municipales 2024",
       subtitle = "Alcaldías electas según sector político",
       fill = "Sector político",
       caption = glue("Fuente: Servel (elecciones.servel.cl), obtenido el {fecha_scraping |> format('%d de %B')}\nElaboración: Bastián Olea Herrera"))

mapa_chile

# guardar ----
ggsave(plot = mapa_chile,
       filename = glue("graficos/resultados/servel_mapa_resultados_{formatear_fecha(fecha_scraping)}_b.jpg"),
       width = 4.6, height = 10, scale = 0.9
)  
