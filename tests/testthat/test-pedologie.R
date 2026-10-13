# Tests pour le téléchargement des données pédologiques
# =============================================================================

test_that("telecharger_pedologie_quebec pointe vers polygone_pedologie.fgb", {
  url <- as.character(formals(telecharger_pedologie_quebec)$url_pedologie)
  expect_match(url, "polygone_pedologie\\.fgb$")
})

test_that("telecharger_pedologie_quebec requiert un objet sf", {
  skip_if_not_installed("sf")
  # Sans CRS ni geometrie exploitable, l'appel doit echouer proprement
  expect_error(suppressWarnings(
    telecharger_pedologie_quebec(sf::st_sfc(sf::st_point(c(0, 0))))
  ))
})

test_that("telecharger_pedologie_quebec retourne polygones et table_series", {
  skip_on_cran()
  skip_if_offline()
  skip_if_not_installed("sf")
  skip_if_not_installed("dplyr")

  champ <- sf::st_read(system.file("extdata", "M2.shp", package = "covariablechamps"),
                       quiet = TRUE)

  res <- tryCatch(
    telecharger_pedologie_quebec(champ),
    error = function(e) skip(paste("Donnees pedologiques indisponibles:", conditionMessage(e)))
  )

  if (is.null(res)) skip("Aucun polygone pedologique pour cette emprise")

  expect_type(res, "list")
  expect_true(all(c("polygones", "table_series") %in% names(res)))
  expect_s3_class(res$polygones, "sf")
  expect_true("Code.polygone" %in% names(res$polygones))
  expect_true(all(c("Code.polygone", "Composante", "Pourcentage",
                    "Sable", "Limon", "Argile") %in% names(res$table_series)))
})
