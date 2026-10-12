# Détecter le code EPSG UTM approprié pour un objet sf

Calcule la zone UTM (nord ou sud) correspondant au centroïde d'un objet
\`sf\`.

## Usage

``` r
detecter_utm_epsg(sf_obj)
```

## Arguments

- sf_obj:

  Un objet \`sf\` représentant la zone d'intérêt.

## Value

Le code EPSG (entier) de la zone UTM correspondante.

## Examples

``` r
if (FALSE) { # \dontrun{
champ <- sf::st_read("champ.shp")
epsg <- detecter_utm_epsg(champ)
} # }
```
