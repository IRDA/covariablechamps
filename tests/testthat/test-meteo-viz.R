# Tests pour les visualisations et analyses de la rose des vents
# =============================================================================

creer_rose_test <- function() {
  set.seed(1)
  pct <- c(2, 3, 5, 8, 12, 9, 6, 4, 7, 11, 13, 10, 5, 3, 1, 1)
  pct <- pct / sum(pct) * 100
  avg <- seq(2, 8, length.out = 16)
  classes <- matrix(round(runif(16 * 10, 0, 5), 2), nrow = 16,
                    dimnames = list(NULL, paste0("CLASS_", 1:10)))

  list(
    directions = seq(0, 337.5, by = 22.5),
    wd_pct = pct,
    wd_avg = avg,
    classes = classes,
    all_classes = NULL,
    coordonnees = c(longitude = -71.2, latitude = 46.8),
    hauteur = "10m",
    periode = c(debut = "20230101", fin = "20231231"),
    data = list(messages = list(list(CLASSES = NULL)))
  )
}

test_that("obtenir_vent_dominant retourne la bonne direction", {
  rose <- creer_rose_test()
  idx <- which.max(rose$wd_pct)

  res <- obtenir_vent_dominant(rose)
  expect_type(res, "list")
  expect_equal(res$angle, rose$directions[idx])
  expect_equal(res$frequence_pct, rose$wd_pct[idx])

  expect_equal(obtenir_vent_dominant(rose, format = "angle"), rose$directions[idx])
  expect_type(obtenir_vent_dominant(rose, format = "label"), "character")
})

test_that("tracer_rose_vents genere des ggplots (pct et avg)", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("dplyr")
  skip_if_not_installed("scales")

  rose <- creer_rose_test()

  expect_s3_class(tracer_rose_vents(rose, type = "pct"), "ggplot")
  expect_s3_class(tracer_rose_vents(rose, type = "avg"), "ggplot")
  expect_s3_class(tracer_rose_vents(rose, type = "pct", afficher_legende = FALSE), "ggplot")
})

test_that("tracer_rose_vents_stacked genere un ggplot", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("dplyr")
  skip_if_not_installed("tidyr")
  skip_if_not_installed("scales")

  rose <- creer_rose_test()
  expect_s3_class(tracer_rose_vents_stacked(rose), "ggplot")
})
