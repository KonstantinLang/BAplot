#' Bland-Altman statistics
#'
#' The function is computing all relevant Bland-Altman statistics, including bias, lower and upper
#' limits of agreement and their confidence limits.
#'
#' @param data A data frame
#' @param var1 1st variable to compare (unquoted)
#' @param var2 2nd variable to compare (unquoted)
#' @param group grouping variable (unquoted)
#' @param alpha alpha level for the intervals
#'
#' @return A [tibble] with three variables n (number of observations), parameter and value is returned.
#'
#' @seealso [ba_plot]
#'
#' @export
#'
#' @examples
#' library(tidyr)
#' tbl <- temperature %>% pivot_wider(names_from = method, values_from = temperature)
#'
#' # simple example
#' ba_stat(data = tbl, var1 = infrared, var2 = rectal)
#'
#' ## example with grouping
#' ba_stat(data = tbl, var1 = infrared, var2 = rectal, group = treatment) %>%
#'   pivot_wider(names_from = parameter, values_from = value)
ba_stat <- function(
  data  = stop("data must be specified"),
  var1  = stop("variable must be specified"),
  var2  = stop("variable must be specified"),
  group = NULL,
  alpha = .05
) {

  tbl_0 <-
    data %>%
    dplyr::mutate(
      dfce = {{var1}} - {{var2}},       # difference
      avg  = ({{var1}} + {{var2}}) / 2  # average
    )

  tbl_stat_0 <-
    tbl_0 %>%
    dplyr::group_by({{group}}) %>%
    dplyr::summarise(
      n    = sum(!is.na(dfce)),         # number of not missing obs
      bias = mean(dfce, na.rm = TRUE),  # arithmetic mean of differences = bias
      stdv = stats::sd(dfce, na.rm = TRUE),    # SD of differences
      .groups = "keep"
    ) %>%
    dplyr::ungroup()

  tbl_stat_1 <-
    tbl_stat_0 %>%
    dplyr::mutate(
      # t-based standard errors for bias and LoA
      conf.int = 1 - alpha / 2,
      bias.add = stats::qt(p = conf.int, df = n - 1) * stdv / sqrt(n),
      loa.add  = stats::qt(p = conf.int, df = n - 1) * stdv * sqrt(1/n + stats::qnorm(conf.int)^2/(2*(n-1))),
      # confidence limits for 'bias'
      bias.lcl = bias - bias.add,
      bias.ucl = bias + bias.add,
      # lower & upper limit of agreement and their approximate (symmetric) confidence limits
      lloa     = bias - stats::qnorm(conf.int) * stdv,
      lloa.lcl = lloa - loa.add,
      lloa.ucl = lloa + loa.add,
      uloa     = bias + stats::qnorm(conf.int) * stdv,
      uloa.lcl = uloa - loa.add,
      uloa.ucl = uloa + loa.add
      # # exact intervals for n = 17
      # loa.in   = 1.3150,
      # loa.out  = 3.1483,
      # lloa.lcl = bias - loa.out * stdv,
      # lloa.ucl = bias - loa.in * stdv,
      # lloa.ucl = bias + loa.out * stdv,
      # lloa.lcl = bias + loa.in * stdv
    ) %>%
    dplyr::select({{group}}, n, bias, lloa, uloa,
                  dplyr::ends_with(match = "lcl"), dplyr::ends_with(match = "ucl")) %>%
    tidyr::pivot_longer(cols = bias:uloa.ucl, names_to = "parameter", values_to = "value")

  return(tbl_stat_1)
}
