# mapa que compara los 3 mayores candidatos presidenciales por comuna en la RM

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

source("servel_limpiar_presidenciales.R") # obtiene datos_todos
source("datos/comunas.R")
# comunas_rm

eleccion <- "presidenciales"
eleccion_titulo <- "Elecciones presidenciales 2025"
eleccion_url <- "elecciones.servel.cl"


# datos ----

# filtrar comuna
datos_resultados_rm <- datos_todos |>
  # acortar nombres
  mutate(candidato = case_match(candidato, 
                                "Jeannette Jara Román" ~ "Jeannette Jara",
                                "Franco Parisi Fernández" ~ "Franco Parisi",
                                "José Antonio Kast Rist" ~ "José Antonio Kast",
                                "Evelyn Matthei Fornet" ~ "Evelyn Matthei",
                                "Nulo/Blanco" ~ "Nulo/Blanco",
                                .default = "Otros")) |> 
  # filter(comuna %in% comunas_rm) |>
  # arreglar etiquetas
  mutate(porcentaje_t = scales::percent(porcentaje, accuracy = 0.1, trim = TRUE)) |> 
  group_by(comuna) |> 
  mutate(candidato = fct_reorder(candidato, porcentaje),
         candidato = fct_relevel(candidato, "Nulo/Blanco",after = 0)) |> 
  ungroup() |> 
  filter(candidato %in% c("Jeannette Jara",
                          "Franco Parisi",
                          "José Antonio Kast"))

## mesas ----
mesas_rm <- datos_resultados_rm |> 
  summarize(mesas_escrutadas = sum(mesas_escrutadas), 
            mesas_totales = sum(mesas_totales)) |> 
  mutate(mesas_porcentaje = mesas_escrutadas/mesas_totales) |> 
  mutate(mesas_porcentaje = replace_na(mesas_porcentaje, 0))

p_mesas <- percent(mesas_rm$mesas_porcentaje, accuracy = 0.01, decimal.mark = ",")




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
datos_resultados_rm_join <- datos_resultados_rm |> 
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
mapa_resultados_rm_p <- left_join(datos_resultados_rm_join,
                                  mapa_filtrado_urbano_join,
                                  by = "comuna_match") |> 
  filter(!is.na(codigo_comuna)) |> 
  # crear nombres cortos de comunas
  mutate(comuna_palabras = str_count(comuna, "\\w+")) |> 
  rowwise() |> 
  mutate(comuna_t = case_when(comuna == "SANTIAGO" ~ "STGO",
                              comuna == "PROVIDENCIA" ~ "PRV",
                              comuna_palabras == 1 ~ str_extract(comuna, "^..."),
                              comuna_palabras >= 2 ~ str_split(comuna, pattern = " ") |> unlist() |> 
                                str_extract("^.") |> 
                                paste(collapse = ""))) |>
  ungroup() |> 
  select(-comuna_palabras)
# centroide
# mutate(punto = geometry |> st_simplify() |> st_centroid(of_largest_polygon = TRUE))



# mapa base ----
mapa_rm_p <- mapa_resultados_rm_p |> 
  mutate(candidato = fct_rev(candidato)) |> 
  ggplot(aes(geometry = geometry)) +
  # fondos
  geom_sf(aes(fill = candidato, alpha = porcentaje),
          col = color_fondo,
          linewidth = 0.4) +
  facet_wrap(~candidato, ncol = 1) +
  # nombres de comunas
  geom_sf_text(aes(label = comuna_t), 
               size = 1.8, alpha = .6, color = "white", 
               family = tipografia, fontface = "bold") +
  coord_sf(xlim = c(-70.798, -70.45), 
           ylim = c(-33.32, -33.645),
           expand = TRUE) +
  # scale_alpha_binned(range = c(0.3, 1), 
  #                    limits = c(0.001, 0.301),
  #                    breaks = c(0.1, 0.15, 0.2, 0.25, 0.3),
  #                    labels = scales::label_percent()
  # ) +
  scale_alpha_continuous(range = c(0.3, 1),
                         limits = c(0.001, 0.3),
                         breaks = c(0.1, 0.15, 0.2, 0.25, 0.3),
                         labels = scales::label_percent()) +
  scale_fill_manual(values = c("Jeannette Jara" = "#B16AD2",
                               "Franco Parisi" = "#E27726",
                               "José Antonio Kast" = "#1D76DB"), 
                    aesthetics = c("color", "fill")) +
  theme_classic(base_family = tipografia) +
  guides(fill = guide_none(),
         alpha = guide_legend(position = "top",
                              title = NULL,
                              title.hjust = 0.5,
                              nrow = 1,
                              override.aes = list(fill = "#666666")
         ))

mapa_rm_p


# temas ----
mapa_rm_p_2 <- mapa_rm_p +  
  # títulos
  theme(text = element_text(family = tipografia, color = color_texto), 
        plot.title.position = "panel", plot.caption.position = "panel",
        plot.title = element_text(face = "bold", size = 12),
        plot.subtitle = element_text(size = 10, margin = margin(t = 0, b = 8)), 
        plot.caption = element_text(lineheight = .9, size = 7)) +
  # fondos
  theme(panel.background = element_rect(fill = color_fondo),
        panel.grid.major.x = element_line(color = color_detalle, lineend = "round"),
        panel.spacing.y = unit(4, "mm"),
        plot.margin = unit(c(4, 0, 2, 0), "mm")
  ) +
  # leyenda
  theme(legend.title = element_text(face = "italic", size = 9),
        legend.text = element_text(size = 9, margin = margin(l = 2, r = 2)),
        legend.background = element_rect(fill = color_fondo),
        legend.key.size = unit(3.5, "mm"),
        legend.key.spacing.y = unit(1.5, "mm")) +
  theme(strip.background = element_rect(linewidth = 0),
        strip.text = element_text(face = "bold", size = 10, color = color_texto)) +
  # ejes
  theme(axis.line = element_blank(), axis.text = element_blank(), axis.ticks = element_blank()) +
  # textos
  labs(title = glue("{eleccion_titulo}"),
       subtitle = glue("Porcentaje de voto por comuna,\nal {p_mesas} de mesas escrutadas"),
       fill = "Candidato a Gobernador", x = NULL, y = NULL,
       caption = glue("Fuente: Servel ({eleccion_url})\nElaboración: Bastián Olea Herrera")
  )


mapa_rm_p_2 +
  canvas(3, 10)


# guardar ----
save_ggplot(plot = last_plot(),
            file = glue("mapas/resultados/{eleccion}/servel_mapa_rm_p_resultados_{now()}.jpg")
)
