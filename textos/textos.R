
datos_comuna <- datos_todos |>
  filter(comuna == comuna_elegida)

comuna_t <- corregir_comunas(comuna_elegida)


intro <- glue("Elecciones presidenciales 2025: comuna de {toupper(comuna_t)}, con un {p_mesas} de las mesas escrutadas.")

mayor <- datos_comuna |> slice_max(votos, with_ties = F)
segundo <- datos_comuna |> 
  slice_max(votos, n = 2, with_ties = F) |> 
  slice_min(votos, with_ties = F)

mayor$candidato
p_mayor <- percent(mayor$porcentaje, accuracy = 0.1)

segundo$candidato
p_segundo <- percent(segundo$porcentaje, accuracy = 0.1)


interpretación <- glue("{mayor$candidato} lidera con un {p_mayor} de los votos, seguido por {segundo$candidato}, con {p_segundo}.")


outro <- "Datos preliminares, obtenidos desde Servel (elecciones.servel.cl)"

cat(intro, 
    interpretación, 
    outro, 
    sep = "\n\n")

writeLines(c(intro, 
             interpretación, 
             outro), 
           # con = glue("textos/resultados/{eleccion}/texto_{comuna_t}.txt"))
           con = glue("textos/resultados/{eleccion}/{comuna_t}_texto.txt"))
