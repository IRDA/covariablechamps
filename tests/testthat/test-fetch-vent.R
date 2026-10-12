# Tests pour le calcul du fetch de vent (elliptique)
# =============================================================================

creer_fetch_test <- function() {
  arbres <- sf::st_sf(
    id = 1:5,
    geometry = sf::st_sfc(
      sf::st_point(c(50, 50)),
      sf::st_point(c(60, 50)),
      sf::st_point(c(70, 50)),
      sf::st_point(c(80, 50)),
      sf::st_point(c(90, 50)),
      crs = 32618
    )
  )
  coords <- matrix(c(0, 0, 200, 0, 200, 100, 0, 100, 0, 0), ncol = 2, byrow = TRUE)
  champ <- sf::st_sf(geometry = sf::st_sfc(sf::st_polygon(list(coords)), crs = 32618))

  calculer_fetch_vent(
    arbres_sf = arbres,
    angle_vent = 270,
    champ_bbox = champ,
    resolution = 10,
    max_fetch = 50,
    coef_ellipse = 3
  )
}

test_that("calculer_fetch_vent retourne les rasters attendus", {
  skip_if_not_installed("terra")
  skip_if_not_installed("sf")

  res <- creer_fetch_test()

  expect_type(res, "list")
  expect_true(all(c("distance_simple", "distance_elliptique", "buffer_arbres",
                    "angle_vent", "coef_ellipse", "max_fetch") %in% names(res)))
  expect_s4_class(res$distance_simple, "SpatRaster")
  expect_s4_class(res$distance_elliptique, "SpatRaster")
  expect_equal(res$angle_vent, 270)
  expect_equal(res$max_fetch, 50)

  vals <- terra::values(res$distance_elliptique)
  vals <- vals[!is.na(vals)]
  expect_true(all(vals >= 0))
  expect_true(all(vals <= 50 + 1e-6))
})

test_that("calculer_fetch_vent donne une distance nulle pres des arbres", {
  skip_if_not_installed("terra")
  skip_if_not_installed("sf")

  res <- creer_fetch_test()

  # Au moins une cellule proche d'un arbre doit avoir une distance faible
  # (la resolution est de 10 m)
  vals <- terra::values(res$distance_elliptique)
  vals <- vals[!is.na(vals)]
  expect_true(min(vals) < 10)
})

test_that("visualiser_fetch genere des ggplots", {
  skip_if_not_installed("terra")
  skip_if_not_installed("sf")
  skip_if_not_installed("ggplot2")

  res <- creer_fetch_test()

  expect_s3_class(visualiser_fetch(res, type = "elliptique"), "ggplot")
  expect_s3_class(visualiser_fetch(res, type = "simple"), "ggplot")

  lst <- visualiser_fetch(res, type = "comparaison")
  expect_type(lst, "list")
  expect_true(all(c("simple", "elliptique") %in% names(lst)))
})

test_that("simuler_vitesse_vent_fetch respecte les bornes", {
  skip_if_not_installed("terra")
  skip_if_not_installed("sf")

  res <- creer_fetch_test()
  v <- simuler_vitesse_vent_fetch(res, vitesse_ref = 5, coef_acceleration = 0.3)

  expect_type(v, "list")
  expect_s4_class(v$vitesse, "SpatRaster")

  vals <- terra::values(v$vitesse)
  vals <- vals[!is.na(vals)]
  expect_true(all(vals >= 5))
  expect_true(all(vals <= 10 + 1e-6))
})
