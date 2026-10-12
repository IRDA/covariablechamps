# Tests pour les zones de protection des haies brise-vent
# =============================================================================

creer_haies_test <- function() {
  coords <- matrix(c(0, 0, 100, 0, 100, 10, 0, 10, 0, 0), ncol = 2, byrow = TRUE)
  sf::st_sf(
    cluster = 1,
    n_arbres = 10,
    hauteur_p95 = 15,
    largeur = 10,
    longueur = 100,
    aspect = 10,
    linearite = 20,
    angle_deg = 0,
    x_center = 50,
    y_center = 5,
    classe = "haie_brise_vent",
    geometry = sf::st_sfc(sf::st_polygon(list(coords)), crs = 32618)
  )
}

test_that("fusionner_zones_vent retourne une couche sf par facteur H", {
  skip_if_not_installed("sf")
  skip_if_not_installed("dplyr")

  haies <- creer_haies_test()
  zones <- calculer_zones_vent_spline(haies, direction_vent = 0,
                                      facteur_hauteur = 1:3, n_points = 20)
  fusion <- fusionner_zones_vent(zones)

  expect_s3_class(fusion, "sf")
  expect_true("facteur_h" %in% names(fusion))
  # Une geometrie fusionnee par facteur H (les zones sont disjointes)
  expect_lte(nrow(fusion), 3)
  expect_true(all(fusion$facteur_h %in% 1:3))
})

test_that("rasteriser_zones_gradient produit le facteur H minimum", {
  skip_if_not_installed("sf")
  skip_if_not_installed("terra")
  skip_if_not_installed("dplyr")

  haies <- creer_haies_test()
  zones <- calculer_zones_vent_spline(haies, direction_vent = 0,
                                      facteur_hauteur = 1:5, n_points = 20)

  r <- rasteriser_zones_gradient(zones, resolution = 5)
  expect_s4_class(r, "SpatRaster")
  expect_equal(names(r), "facteur_H_min")

  vals <- terra::values(r)
  vals <- vals[!is.na(vals)]
  expect_true(length(vals) > 0)
  expect_true(all(vals >= 1))
  expect_true(all(vals <= 5))
})

test_that("rasteriser_zones_gradient_v2 est coherente avec la v1", {
  skip_if_not_installed("sf")
  skip_if_not_installed("terra")
  skip_if_not_installed("dplyr")

  haies <- creer_haies_test()
  zones <- calculer_zones_vent_spline(haies, direction_vent = 0,
                                      facteur_hauteur = 1:4, n_points = 20)

  r1 <- rasteriser_zones_gradient(zones, resolution = 5)
  r2 <- rasteriser_zones_gradient_v2(zones, resolution = 5)

  v1 <- terra::values(r1)
  v2 <- terra::values(r2)
  expect_equal(is.na(v1), is.na(v2))
  expect_equal(v1, v2)
})

test_that("extraire_ligne_centrale_haies conserve la longueur", {
  skip_if_not_installed("sf")
  skip_if_not_installed("dplyr")
  skip_if_not_installed("purrr")

  haies <- creer_haies_test()
  lignes <- extraire_ligne_centrale_haies(haies, output_type = "lignes")

  expect_s3_class(lignes, "sf")
  expect_equal(nrow(lignes), 1)
  longueur_ligne <- as.numeric(sf::st_length(lignes))
  expect_equal(longueur_ligne, 100, tolerance = 1)
})
