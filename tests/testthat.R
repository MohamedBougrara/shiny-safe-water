# Run from the app folder:  Rscript tests/testthat.R
library(testthat)
for (f in list.files("R", full.names = TRUE)) source(f, encoding = "UTF-8")
test_dir("tests/testthat", reporter = "summary", stop_on_failure = TRUE)
