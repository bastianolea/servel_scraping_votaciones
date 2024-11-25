library(dplyr)
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

mapa <- readr::read_rds("datos/mapas/mapa_comunas.rds")
mapa_urbano <- readr::read_rds("datos/mapas/mapa_rm_urbano.rds")
region <- readr::read_rds("datos/mapas/mapa_region.rds")

source("servel_limpiar.R") # obtiene datos_todos
source("datos/comunas.R")
# comunas_rm

# eleccion <- "alcaldes"
eleccion <- "gobernadores"

# eleccion_titulo <- "Elecciones Municipales 2024"
eleccion_titulo <- "Elecciones de Gobernadores 2024"

# eleccion_url <- "elecciones.servel.cl"
eleccion_url <- "eleccionesgore.servel.cl"


# filtrar comuna
datos_resultados_rm <- datos_todos |>
  # acortar nombres
  mutate(candidato = str_extract(candidato, "\\w+ \\w+")) |> 
  filter(!is.na(candidato)) |> 
  filter(comuna %in% comunas_rm) |>
  # datos aleatorios
  # mutate(votos = sample(100:999, n())) |>
  # mutate(porcentaje = votos/sum(votos), .by = comuna) |> 
  # seleccionar ganadores
  # group_by(comuna) |> 
  # slice_max(votos, with_ties = FALSE) |> 
  # ungroup() |> 
  # arreglar etiquetas
  mutate(porcentaje_t = scales::percent(porcentaje, accuracy = 0.1, trim = TRUE)) |> 
  group_by(comuna) |> 
  mutate(partido = replace_na(partido, ""),
         candidato = fct_reorder(candidato, porcentaje),
         candidato = fct_relevel(candidato, "Nulo/Blanco",after = 0)) |> 
  ungroup() |> 
  relocate(sector, .after = partido)


mesas_rm <- datos_resultados_rm |> 
  summarize(mesas_escrutadas = sum(mesas_escrutadas), 
            mesas_totales = sum(mesas_totales)) |> 
  mutate(mesas_porcentaje = mesas_escrutadas/mesas_totales) |> 
  mutate(mesas_porcentaje = replace_na(mesas_porcentaje, 0))


datos_resultados_rm_2 <- datos_resultados_rm |> 
  select(comuna, candidato, porcentaje) |> 
  pivot_wider(names_from = candidato, 
              values_from = porcentaje) |> 
  janitor::clean_names() |> 
  mutate(ganando = case_when(claudio_orrego >= francisco_orrego ~ "Claudio Orrego",
                            francisco_orrego > claudio_orrego ~ "Francisco Orrego")) |> 
  # mutate(diferencia = case_when(ganando == "Claudio Orrego" & claudio_orrego - francisco_orrego > .5 ~ .5,
  #                               ganando == "Claudio Orrego" & claudio_orrego - francisco_orrego > .1 ~ .1,
  #                               ganando == "Claudio Orrego" & claudio_orrego - francisco_orrego > .05 ~ .05,
  #                               ganando == "Francisco Orrego" & francisco_orrego - claudio_orrego > .5 ~ .5,
  #                               ganando == "Francisco Orrego" & francisco_orrego - claudio_orrego > .1 ~ .1,
  #                               ganando == "Francisco Orrego" & francisco_orrego - claudio_orrego > .05 ~ .05,
  #                               ))
  mutate(diferencia = case_when(ganando == "Claudio Orrego" ~ claudio_orrego - francisco_orrego,
                                ganando == "Francisco Orrego" ~ francisco_orrego - claudio_orrego
  ))

datos_resultados_rm_2 |> 
  filter(comuna == "PUENTE ALTO")


# mapas ----
mapa_filtrado <- mapa |> 
  # left_join(poblacion_censo) |> 
  # filter(poblacion > 100000) |> 
  # filter(!nombre_comuna %in% c("Lampa", "Colina", "Melipilla")) |> 
  filter(nombre_comuna %in% c("Pudahuel", "Cerro Navia", "Conchali", "La Pintana", "El Bosque", 
                              "Estacion Central", "Pedro Aguirre Cerda", "Recoleta", "Independencia", 
                              "La Florida", "Penalolen", "Las Condes", "Lo Barnechea", "Quinta Normal", 
                              "Maipu", "Macul", "Nunoa", "Puente Alto", "Quilicura", "Renca", 
                              "San Bernardo", "San Miguel", "La Granja", "Providencia", "Santiago",
                              "San Joaquin", "Lo Espejo", "La Reina", "San Ramon", "La Cisterna", "Lo Prado", "Cerrillos", "Vitacura", "Huechuraba"
  ))

# transformar mapas
mapa_urbano_2 <- mapa_urbano |> 
  st_as_sf() |> 
  st_union() |> 
  st_transform(crs = 4326)


sf_use_s2(FALSE)

# filtrar el mapa de comunas urbanas para dejar solo sectores urbanos de esas comunas
mapa_filtrado_urbano <- st_intersection(st_as_sf(mapa_filtrado), 
                                        mapa_urbano |> 
                                          st_as_sf() |> 
                                          st_union())

# coindir comunas ----
datos_resultados_rm_2_join <- datos_resultados_rm_2 |> 
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


mapa_filtrado_urbano_join <- mapa_filtrado_urbano |>
  mutate(comuna_match = tolower(nombre_comuna))


# unir mapa con datos ----
mapa_resultados_rm_p <- left_join(datos_resultados_rm_2_join,
                                mapa_filtrado_urbano_join,
                                by = "comuna_match") |> 
  filter(!is.na(codigo_comuna)) |> 
  # crear nombres cortos de comunas
  mutate(comuna_palabras = str_count(comuna, "\\w+")) |> 
  rowwise() |> 
  mutate(comuna_t = case_when(comuna == "SANTIAGO" ~ "STGO",
                              comuna_palabras == 1 ~ str_extract(comuna, "^..."),
                              comuna_palabras >= 2 ~ str_split(comuna, pattern = " ") |> unlist() |> 
                                str_extract("^.") |> 
                                paste(collapse = ""))) |>
  ungroup() |> 
  select(-comuna_palabras)
# centroide
# mutate(punto = geometry |> st_simplify() |> st_centroid(of_largest_polygon = TRUE))



# graficar mapa ganador ----
mapa_rm_p <- mapa_resultados_rm_p |> 
  ggplot(aes(geometry = geometry)) +
  # fondos
  geom_sf(aes(fill = ganando, alpha = diferencia),
          col = color_fondo,
          linewidth = 0.4) +
  # nombres de comunas
  geom_sf_text(aes(label = comuna_t), 
               size = 1.8, alpha = .6, color = "white", 
               family = tipografia, fontface = "bold") +
  # 
  coord_sf(xlim = c(-70.798, -70.45), 
           ylim = c(-33.32, -33.645),
           expand = TRUE) +
  scale_alpha_binned(range = c(0.35, 1), 
                     limits = c(0.001, 0.301),
                     # breaks = c(0.1, 0.2, 0.3, 0.4),
                     # breaks = c(.02, .05, .1, .2, 1)
                     labels = scales::label_percent()
                     ) +
  scale_fill_manual(values = c("Claudio Orrego" = color$centro,
                               "Francisco Orrego" = color$derecha), 
                    aesthetics = c("color", "fill")) +
  theme_classic(base_family = tipografia) +
  guides(fill = guide_legend(title = "Candidato mayoritario"),
         alpha = guide_legend(title = "Porcentaje de ventaja\nde candidato mayoritario",
                              override.aes = list(fill = "black"))
  )

mapa_rm_p


# temas ----
mapa_rm_p_2 <- mapa_rm_p +  
  # títulos
  theme(text = element_text(family = tipografia, color = color_texto), 
        plot.subtitle = element_text(margin = margin(t = -2, b = 6)), 
        plot.title.position = "plot", plot.caption.position = "plot",
        plot.title = element_markdown(),
        plot.caption = element_text(lineheight = 1.1)) +
  # fondos
  theme(panel.background = element_rect(fill = color_fondo),
        panel.grid.major.x = element_line(color = color_detalle, lineend = "round"),
        plot.margin = unit(c(4, 4, 4, 4), "mm")) +
  # leyenda
  theme(legend.title = element_text(face = "italic", size = 9),
        legend.text = element_text(size = 9, margin = margin(l = 4)),
        legend.position.inside = c(0.98, 0.02),
        legend.justification = c(1, 0),
        legend.background = element_rect(fill = color_fondo),
        legend.key.size = unit(4, "mm"),
        legend.key.spacing.y = unit(1.5, "mm")) +
  # ejes
  theme(axis.line = element_blank(), axis.text = element_blank(), axis.ticks = element_blank()) +
  # guides(fill = guide_none()) +
  # textos
  labs(title = glue("**Resultados parciales:** {eleccion_titulo}"),
       subtitle = glue("Candidatura mayoritaria por comuna, al {percent(mesas_rm$mesas_porcentaje, accuracy = 0.01)} de mesas escrutadas"),
       fill = "Candidato a Gobernador", x = NULL, y = NULL,
       caption = glue("Fuente: Servel ({eleccion_url}), obtenido a las {fecha_scraping |> format('%H:%M')}\nElaboración: Bastián Olea Herrera"))


mapa_rm_p_2


# guardar ----
ggsave(plot = mapa_rm_p_2,
       filename = glue("mapas/resultados/{eleccion}/servel_mapa_rm_p_resultados_{now()}.jpg"),
       width = 6, height = 4.9, scale = 0.9
)
