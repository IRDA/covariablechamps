# Tests pour le classement des series de sol (quota ILR)
# =============================================================================

creer_proba_inputs <- function() {
  p1 <- sf::st_polygon(list(matrix(c(0, 0, 100, 0, 100, 100, 0, 100, 0, 0),
                                   ncol = 2, byrow = TRUE)))
  p2 <- sf::st_polygon(list(matrix(c(100, 0, 200, 0, 200, 100, 100, 100, 100, 0),
                                   ncol = 2, byrow = TRUE)))
  polys <- sf::st_sf(
    Code.polygone = c("A", "B"),
    geometry = sf::st_sfc(p1, p2, crs = 32618)
  )

  mnt <- terra::rast(xmin = 0, xmax = 200, ymin = 0, ymax = 100,
                     resolution = 10, crs = "EPSG:32618")
  set.seed(1)
  terra::values(mnt) <- runif(terra::ncell(mnt), 0, 50)

  ts <- data.frame(
    Code.polygone = c("A", "A", "B", "B"),
    Composante = c("S1", "S2", "S1", "S2"),
    Pourcentage = c(60, 40, 30, 70),
    Sable = c(0.6, 0.2, 0.6, 0.2),
    Limon = c(0.3, 0.4, 0.3, 0.4),
    Argile = c(0.1, 0.4, 0.1, 0.4)
  )

  list(polys = polys, mnt = mnt, ts = ts)
}

test_that("proba_et_classement_serie_quota_ilr retourne la structure attendue", {
  skip_if_not_installed("sf")
  skip_if_not_installed("terra")
  skip_if_not_installed("dplyr")
  skip_if_not_installed("compositions")

  inp <- creer_proba_inputs()

  res <- proba_et_classement_serie_quota_ilr(
    polygones_sf = inp$polys,
    table_series = inp$ts,
    mnt = inp$mnt,
    grid_m = 10,
    sigma_voisin = 10,
    verbose = FALSE,
    progress = FALSE
  )

  expect_type(res, "list")
  expect_true(all(c("prob", "ilr_mean", "dist", "id_r", "closest_index",
                    "closest_label", "series") %in% names(res)))
  expect_setequal(res$series, c("S1", "S2"))
  expect_equal(terra::nlyr(res$dist), 2)
})

test_that("proba_et_classement_serie_quota_ilr valide les colonnes requises", {
  skip_if_not_installed("sf")
  skip_if_not_installed("terra")

  inp <- creer_proba_inputs()
  ts_incomplet <- inp$ts[, c("Code.polygone", "Composante")]

  expect_error(
    proba_et_classement_serie_quota_ilr(inp$polys, ts_incomplet, inp$mnt,
                                        verbose = FALSE, progress = FALSE),
    "Colonnes manquantes"
  )
})

test_that("proba_et_classement_serie_quota_ilr requiert des types valides", {
  inp <- creer_proba_inputs()

  expect_error(
    proba_et_classement_serie_quota_ilr("pas_sf", inp$ts, inp$mnt)
  )
})
