# tableau.R
# HTML tables written by R: light (no JavaScript library to load in the
# browser), themed by Bootstrap, readable by screen readers.
#
# The table is written column by column, as text: building one htmltools tag
# per cell took 3 s for the 217 rows of the ranking under webR, at every sort.

# colonnes: named list; each element is
#   list(titre =, cellule = function(v, d), num = TRUE/FALSE, tri = "key")
#   cellule receives the whole column (and the data) and returns one piece of
#   HTML per row; without it, the values are shown as they are, escaped.
# tri: list(input =, actif =) makes the headers of the columns that have a
#   `tri` key into buttons: a click sends the key to the Shiny input `input`
#   (www/graphique.js), and the sorted column is announced with aria-sort.
tableau_html <- function(d, colonnes, legende = NULL, tri = NULL) {
  echapper <- htmltools::htmlEscape
  entete <- vapply(colonnes, function(c) {
    triable <- !is.null(tri) && !is.null(c$tri)
    actif <- triable && identical(c$tri, tri$actif)
    sprintf('<th scope="col"%s%s>%s</th>',
      if (isTRUE(c$num)) ' class="num"' else "",
      if (actif) sprintf(' aria-sort="%s"', if (identical(c$tri, "area")) "ascending" else "descending") else "",
      if (triable) sprintf('<button type="button" class="tri-col" data-input="%s" data-valeur="%s">%s</button>',
                           echapper(tri$input, TRUE), echapper(c$tri, TRUE), echapper(c$titre))
      else echapper(c$titre))
  }, "")
  cellules <- lapply(names(colonnes), function(k) {
    c <- colonnes[[k]]
    contenu <- if (is.null(c$cellule)) echapper(as.character(d[[k]])) else c$cellule(d[[k]], d)
    if (identical(k, names(colonnes)[1])) paste0('<th scope="row" class="fw-normal">', contenu, "</th>")
    else paste0(if (isTRUE(c$num)) '<td class="num">' else "<td>", contenu, "</td>")
  })
  lignes <- if (nrow(d)) paste0("<tr>", do.call(paste0, cellules), "</tr>", collapse = "") else ""
  htmltools::HTML(paste0(
    '<div class="tableau-defile"><table class="table table-sm table-hover align-middle mb-0">',
    if (!is.null(legende)) paste0('<caption class="visually-hidden">', echapper(legende), "</caption>"),
    "<thead><tr>", paste(entete, collapse = ""), "</tr></thead><tbody>", lignes, "</tbody></table></div>"))
}

# A share with a small bar in front of it.
cellule_barre <- function(couleur, lang) function(v, d) {
  ifelse(is.na(v), '<span class="note">-</span>',
         sprintf('<span class="barre"><i style="width:%.0fpx;background:%s"></i>%s</span>',
                 v * 0.7, couleur, fmt_pc(v, lang)))
}
