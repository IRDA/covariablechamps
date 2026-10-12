# Tests pour les utilitaires geo internes et exportes
# =============================================================================

test_that("detecter_utm_epsg calcule la bonne zone UTM", {
  skip_if_not_installed("sf")

  # Point au Quebec (lon ~ -71.2, lat ~ 46.8) => zone 19 Nord
  poly <- sf::st_sf(geometry = sf::st_sfc(
    sf::st_polygon(list(matrix(c(
      -71.2, 46.8,
      -71.1, 46.8,
      -71.1, 46.9,
      -71.2, 46.9,
      -71.2, 46.8
    ), ncol = 2, byrow = TRUE))),
    crs = 4326
  ))

  expect_equal(detecter_utm_epsg(poly), 32619)
})

test_that("detecter_utm_epsg gere l'hemisphere sud", {
  skip_if_not_installed("sf")

  # Point dans l'hemisphere sud (lat < 0) => EPSG 327xx
  poly <- sf::st_sf(geometry = sf::st_sfc(
    sf::st_polygon(list(matrix(c(
      -70, -33,
      -69, -33,
      -69, -32,
      -70, -32,
      -70, -33
    ), ncol = 2, byrow = TRUE))),
    crs = 4326
  ))

  expect_true(detecter_utm_epsg(poly) >= 32700)
  expect_true(detecter_utm_epsg(poly) < 32800)
})

test_that("direction_cardinale convertit les angles en points cardinaux", {
  expect_equal(covariablechamps:::direction_cardinale(0), "N")
  expect_equal(covariablechamps:::direction_cardinale(90), "E")
  expect_equal(covariablechamps:::direction_cardinale(180), "S")
  expect_equal(covariablechamps:::direction_cardinale(270), "O")
  expect_equal(covariablechamps:::direction_cardinale(45), "NE")
})

test_that("calculer_mbr trouve le rectangle d'aire minimale d'un carre", {
  skip_if_not_installed("sf")

  coords <- matrix(c(0, 0, 100, 0, 100, 100, 0, 100, 0, 0), ncol = 2, byrow = TRUE)
  poly <- sf::st_sfc(sf::st_polygon(list(coords)), crs = 32618)

  mbr <- covariablechamps:::calculer_mbr(poly)

  expect_equal(mbr$longueur, 100, tolerance = 1)
  expect_equal(mbr$largeur, 100, tolerance = 1)
  expect_equal(mbr$aire, 10000, tolerance = 500)
})
