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
tipografia = "Helvetica"
# tipografia = "Open Sans"
# font_add_google(tipografia, tipografia, db_cache = TRUE)
# showtext_auto()
# showtext_opts(dpi = 290)

source("funciones.R")
source("datos/colores.R")

mapa <- readr::read_rds("datos/mapas/mapa_comunas.rds")
mapa_urbano <- readr::read_rds("datos/mapas/mapa_rm_urbano.rds")
region <- readr::read_rds("datos/mapas/mapa_region.rds")

source("servel_limpiar.R")
source("datos/comunas.R")
# comunas_rm

# filtrar comuna
datos_resultados_rm <- datos_todos |>
  filter(comuna %in% comunas_rm) |>
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

datos_resultados_rm |> 
  count(partido)

datos_resultados_rm |> 
  count(sector)

datos_resultados_rm |> 
  count(partido, sector) |> 
  arrange(sector)


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

mapa_filtrado_urbano


mapa_filtrado_urbano

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


mapa_resultados_rm <- left_join(datos_resultados_rm_join |> select(1:7, comuna_match),
          mapa_filtrado_urbano_join,
          by = "comuna_match") |> 
  filter(!is.na(codigo_comuna))
  # mutate(punto = geometry |> st_simplify() |> st_centroid(of_largest_polygon = TRUE))



# graficar mapa
mapa_base_rm <- mapa_resultados_rm |> 
  ggplot(aes(geometry = geometry)) +
  geom_sf(aes(fill = sector),
          col = color_fondo,
          alpha = 1, linewidth = 0.2) +
  coord_sf(xlim = c(-70.805, -70.45), 
           ylim = c(-33.32, -33.65),
           expand = TRUE) +
  scale_fill_manual(values = c("Centro" = color$centro,
                               "Izquierda" = color$izquierda,
                               "Derecha" = color$derecha,
                               "Independiente" = color$independiente,
                               "Otros" = color$otros), aesthetics = c("color", "fill")) +
  theme_classic()

mapa_base_rm

mapa_rm <- mapa_base_rm +  
  # títulos
  theme(text = element_text(family = tipografia, color = color_texto), 
        plot.subtitle = element_text(margin = margin(t = -2, b = 6)), 
        plot.title.position = "plot", plot.caption.position = "plot",
        plot.title = element_markdown()) +
  # fondos
  theme(panel.background = element_rect(fill = color_fondo),
        panel.grid.major.x = element_line(color = color_detalle, lineend = "round"),
        plot.margin = unit(c(0,0,0,0), "mm")) +
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
  guides(fill = guide_none())
  # # textos
  # labs(title = "**Resultados:** Elecciones Municipales 2024",
  #      subtitle = "Comunas según sector político",
  #      fill = "Sector político",
  #      caption = glue("Fuente: Servel (elecciones.servel.cl), obtenido el {fecha_scraping |> format('%d de %B')}\nElaboración: Bastián Olea Herrera"))

mapa_rm

# guardar ----
# ggsave(plot = mapa,
#        filename = glue("graficos/servel_mapa_rm_resultados_{formatear_fecha(fecha_scraping)}.jpg"),
#        width = 4.6, height = 10, scale = 0.9
# )  
