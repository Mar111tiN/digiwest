### this is a little statistics helper to be able to use different boxplot settings
# this is controlled by the type and probs argument that are passed to quantile()

# this is a function factory that returns a callable bp_vals function containing
# ...the type and probs arguments as a closure (they are saved at initiation)
# the callable takes the vector of values and returns a named vector that is used by the boxplot stat
bp_vals <- function(...) {
  # 

  bp_vals_func <- function(x) {
    r <- quantile(x, na.rm=TRUE, ...)
    r <- c(r[1:2], exp(mean(log(x))), r[3:4])
    names(r) <- c("ymin", "lower", "middle", "upper", "ymax")
    return(r)
  }
  return(bp_vals_func)
}
