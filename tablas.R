library(gt)
library(forcats)
library(glue)
library(lubridate)

# tipografía
tipografia = "Open Sans"

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

# filtrar comuna
datos_tabla <- datos_todos |>
  mutate(sector = as.factor(sector)) |> 
  filter(comuna == comuna_elegida) |>
  # arreglar etiquetas
  mutate(porcentaje_t = scales::percent(porcentaje, accuracy = 0.1, trim = TRUE)) |> 
  mutate(partido = replace_na(partido, ""),
         candidato = fct_reorder(candidato, porcentaje),
         candidato = fct_relevel(candidato, "Nulo/Blanco",after = 0))

n_mesas = datos_grafico$mesas_escrutadas[1]
total_mesas = datos_grafico$mesas_totales[1]
p_mesas = datos_grafico$mesas_porcentaje[1] |> percent(accuracy = 1, trim = TRUE)

tabla <- datos_tabla |> 
  arrange(desc(candidato)) |>
  select(candidato, partido, votos, porcentaje, sector) |> 
  gt() |> 
  tab_header(title = md("_Resultados parciales:_ Elecciones Municipales 2024"),
             subtitle = md(glue("**{comuna_t}** ({p_mesas} de mesas escrutadas)"))) |> 
  # formato de números
  fmt_percent(porcentaje, decimals = 1) |> 
  fmt_number(votos, 
             decimals = 0, sep_mark = ".", dec_mark = ",") |> 
  # color texto partidos
  data_color(columns = sector, #rows = candidato != "Nulo/Blanco", 
             target_columns = partido,
             method = "factor", levels = levels(datos_tabla$sector), # la paleta va en el orden que tiene el vector
             palette = c(color$centro, color$derecha, color$independiente, color$izquierda, color_detalle3),
             apply_to = "text") |>
  # color fondo partidos
  data_color(columns = sector,  rows = candidato != "Nulo/Blanco", 
             target_columns = partido,
             method = "factor", levels = levels(datos_tabla$sector), # la paleta va en el orden que tiene el vector
             palette = c(color$centro, color$derecha, color$independiente, color$izquierda, color_detalle2),
             alpha = .2, apply_to = "fill", autocolor_text = FALSE) |> 
  cols_label(candidato = "Candidato/a",
             partido = "Partido",
             votos = "Votos",
             porcentaje = "%") |>
  # tipografía
  opt_table_font(font = google_font(tipografia)) |>
  # alineación de textos
  cols_align(columns = c(candidato, partido, porcentaje), align = "left") |> 
  cols_align(columns = c(partido), align = "center") |> 
  cols_hide(sector) |>
  opt_table_lines("none") |>
  opt_align_table_header(align = "left") |> 
  # estilo de textos
  tab_style(locations = cells_body(column = c(partido, porcentaje)), style = cell_text(weight = "bold")) |> 
  tab_style(locations = cells_column_labels(), style = cell_text(style = "italic")) |> 
  tab_style(locations = cells_body(rows = candidato == "Nulo/Blanco"), 
            style = cell_text(weight = "normal")) |> 
  tab_options(heading.subtitle.font.size = 19, heading.padding = 1, 
              heading.border.bottom.style = "solid", heading.border.bottom.width = 16, heading.border.bottom.color = "white") |> 
  tab_style(locations = cells_body(column = candidato), style = cell_text(weight = "bold")) |> 
  # estilo fondos
  tab_style(locations = cells_body(column = c(candidato, votos, porcentaje)), style = cell_fill(color = color_fondo)) |> 
  # estilo fila nulos
  tab_style(locations = cells_body(rows = candidato == "Nulo/Blanco"), 
            style = cell_text(color = color_detalle2)) |> 
  # notas al pie
  tab_options(table_body.hlines.style = "solid", table_body.hlines.width = 8, table_body.hlines.color = "white",
              table_body.vlines.style = "solid", table_body.vlines.width = 8, table_body.vlines.color = "white") |> 
  tab_footnote(footnote = glue("Fuente: Servel (provisorios.servel.cl), obtenido el {fecha_scraping |> format('%d de %B')} a las {fecha_scraping |> format('%H:%M')}")) |> 
  tab_footnote(footnote = glue("Elaboración: Bastián Olea Herrera")) |>
  tab_style(locations = cells_footnotes(), 
            style = cell_text(align = "right", size = px(12))) |> 
  tab_options(table_body.border.bottom.style = "solid", table_body.border.bottom.width = 5, table_body.border.bottom.color = "white",
              footnotes.padding = 1)

tabla


# guardar ----
gtsave(tabla, 
       filename = glue("tablas/servel_tabla_{comuna_t}_{formatear_fecha(fecha_scraping)}.png"),
       quiet = TRUE) |> 
  suppressWarnings()
