# Tests pour les fonctions de distance aux arbres
# =============================================================================

test_that("calculer_distance_arbres requiert les packages", {
  skip_if_not_installed("terra")
  skip_if_not_installed("sf")
  
  expect_true(exists("calculer_distance_arbres"))
})


test_that("calculer_distance_arbres fonctionne avec des points simples", {
  skip_if_not_installed("terra")
  skip_if_not_installed("sf")
  
  # Creer des arbres
  arbres <- sf::st_sf(
    id = 1:5,
    geometry = sf::st_sfc(
      sf::st_point(c(10, 50)),
      sf::st_point(c(20, 50)),
      sf::st_point(c(30, 50)),
      sf::st_point(c(40, 50)),
      sf::st_point(c(50, 50)),
      crs = 32618
    )
  )
  
  # Creer un champ
  coords <- matrix(c(0, 0, 100, 0, 100, 100, 0, 100, 0, 0), ncol = 2, byrow = TRUE)
  poly <- sf::st_polygon(list(coords))
  champ <- sf::st_sf(geometry = sf::st_sfc(poly, crs = 32618))
  
  # Calculer
  result <- calculer_distance_arbres(
    arbres_sf = arbres,
    champ_bbox = champ,
    resolution = 10,
    buffer_arbre = 2,
    max_distance = 50,
    taille_lissage = 1
  )
  
  expect_type(result, "list")
  expect_true("distance_buffer" %in% names(result))
  expect_true("distance_points" %in% names(result))
  expect_true("buffer" %in% names(result))
  expect_s4_class(result$distance_buffer, "SpatRaster")
  expect_s4_class(result$distance_points, "SpatRaster")
})


test_that("visualiser_distance_arbres genere des ggplots", {
  skip_if_not_installed("terra")
  skip_if_not_installed("sf")
  skip_if_not_installed("ggplot2")
  
  # Creer des arbres
  arbres <- sf::st_sf(
    id = 1:3,
    geometry = sf::st_sfc(
      sf::st_point(c(25, 50)),
      sf::st_point(c(50, 50)),
      sf::st_point(c(75, 50)),
      crs = 32618
    )
  )
  
  # Creer un champ
  coords <- matrix(c(0, 0, 100, 0, 100, 100, 0, 100, 0, 0), ncol = 2, byrow = TRUE)
  poly <- sf::st_polygon(list(coords))
  champ <- sf::st_sf(geometry = sf::st_sfc(poly, crs = 32618))
  
  # Calculer
  result <- calculer_distance_arbres(
    arbres_sf = arbres,
    champ_bbox = champ,
    resolution = 10,
    buffer_arbre = 2,
    max_distance = 50,
    taille_lissage = 1
  )
  
  # Tester visualisation
  p <- visualiser_distance_arbres(result, type = "buffer")
  expect_s3_class(p, "ggplot")
  
  p <- visualiser_distance_arbres(result, type = "points")
  expect_s3_class(p, "ggplot")
  
  plots <- visualiser_distance_arbres(result, type = "comparaison")
  expect_type(plots, "list")
  expect_true("points" %in% names(plots))
  expect_true("buffer" %in% names(plots))
})


test_that("simuler_vitesse_vent_simple fonctionne", {
  skip_if_not_installed("terra")
  skip_if_not_installed("sf")
  
  # Creer des arbres et calculer distances
  arbres <- sf::st_sf(
    id = 1:3,
    geometry = sf::st_sfc(
      sf::st_point(c(25, 50)),
      sf::st_point(c(50, 50)),
      sf::st_point(c(75, 50)),
      crs = 32618
    )
  )
  
  coords <- matrix(c(0, 0, 100, 0, 100, 100, 0, 100, 0, 0), ncol = 2, byrow = TRUE)
  poly <- sf::st_polygon(list(coords))
  champ <- sf::st_sf(geometry = sf::st_sfc(poly, crs = 32618))
  
  dist_result <- calculer_distance_arbres(
    arbres_sf = arbres,
    champ_bbox = champ,
    resolution = 10,
    buffer_arbre = 2,
    max_distance = 50,
    taille_lissage = 1
  )
  
  # Simuler vitesse avec la fonction simple
  vitesse <- simuler_vitesse_vent_simple(dist_result, vitesse_ref = 5, coef_protection = 0.5)
  
  expect_type(vitesse, "list")
  expect_true("vitesse" %in% names(vitesse))
  expect_s4_class(vitesse$vitesse, "SpatRaster")
  
  # Verifier que les vitesses sont dans les limites
  vals <- terra::values(vitesse$vitesse)
  vals <- vals[!is.na(vals)]
  expect_true(all(vals >= 5 * 0.3))  # vitesse_ref * 0.3
  expect_true(all(vals <= 5))        # vitesse_ref
})


test_that("calculer_distances_vent fonctionne", {
  skip_if_not_installed("terra")
  skip_if_not_installed("sf")
  
  # Creer des arbres
  arbres <- sf::st_sf(
    id = 1:5,
    geometry = sf::st_sfc(
      sf::st_point(c(0, 50)),
      sf::st_point(c(10, 50)),
      sf::st_point(c(20, 50)),
      sf::st_point(c(30, 50)),
      sf::st_point(c(40, 50)),
      crs = 32618
    )
  )
  
  # Creer un champ
  coords <- matrix(c(0, 0, 100, 0, 100, 100, 0, 100, 0, 0), ncol = 2, byrow = TRUE)
  poly <- sf::st_polygon(list(coords))
  champ <- sf::st_sf(geometry = sf::st_sfc(poly, crs = 32618))
  
  # Calculer distances vent (direction ouest = 270)
  result <- calculer_distances_vent(
    arbres_sf = arbres,
    angle_vent = 270,
    champ_bbox = champ,
    resolution = 10,
    max_distance = 50,
    angle_focal = 45
  )
  
  expect_type(result, "list")
  expect_true("totale" %in% names(result))
  expect_true("amont" %in% names(result))
  expect_true("aval" %in% names(result))
  expect_true("angle_vent" %in% names(result))
  expect_equal(result$angle_vent, 270)
})


test_that("calculer_distances_vent: totale = min(amont, aval) sans lissage", {
  skip_if_not_installed("terra")
  skip_if_not_installed("sf")

  arbres <- sf::st_sf(
    id = 1:5,
    geometry = sf::st_sfc(
      sf::st_point(c(20, 50)),
      sf::st_point(c(40, 50)),
      sf::st_point(c(60, 50)),
      sf::st_point(c(80, 50)),
      sf::st_point(c(90, 50)),
      crs = 32618
    )
  )
  coords <- matrix(c(0, 0, 100, 0, 100, 100, 0, 100, 0, 0), ncol = 2, byrow = TRUE)
  champ <- sf::st_sf(geometry = sf::st_sfc(sf::st_polygon(list(coords)), crs = 32618))

  # taille_lissage = 1 ne doit pas produire d'erreur (fenetre 1x1)
  res <- calculer_distances_vent(
    arbres_sf = arbres, angle_vent = 270, champ_bbox = champ,
    resolution = 10, max_distance = 50, angle_focal = 45, taille_lissage = 1
  )

  a <- terra::values(res$amont)
  v <- terra::values(res$aval)
  t <- terra::values(res$totale)
  expect_equal(t, pmin(a, v))
})


test_that("calculer_distances_vent place les arbres dans le bon secteur", {
  skip_if_not_installed("terra")
  skip_if_not_installed("sf")

  # Un seul arbre au sud du point (50, 50) => angle mathematique 270 degres
  arbre <- sf::st_sf(
    id = 1,
    geometry = sf::st_sfc(sf::st_point(c(50, 20)), crs = 32618)
  )
  coords <- matrix(c(0, 0, 100, 0, 100, 100, 0, 100, 0, 0), ncol = 2, byrow = TRUE)
  champ <- sf::st_sf(geometry = sf::st_sfc(sf::st_polygon(list(coords)), crs = 32618))

  # Vent a 270 deg (vers le sud) : l'arbre est en "amont"
  res <- calculer_distances_vent(
    arbres_sf = arbre, angle_vent = 270, champ_bbox = champ,
    resolution = 10, max_distance = 50, angle_focal = 20, taille_lissage = 1
  )

  amont_centre <- terra::extract(res$amont, matrix(c(50, 50), ncol = 2))[1, 1]
  aval_centre <- terra::extract(res$aval, matrix(c(50, 50), ncol = 2))[1, 1]

  # L'arbre est en amont (distance ~30m), pas en aval (max_distance)
  expect_equal(amont_centre, 30, tolerance = 5)
  expect_equal(aval_centre, 50, tolerance = 1)
})
