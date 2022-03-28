# pa_ts_tbl.initialize <- function(.id, 
#                                  .time,
#                                  .HR,
#                                  .steps){
#   self <- tibble(.id, 
#                  .time, 
#                  .HR, 
#                  .steps)
#   
#   #add tsibble checks
#   
#   class(self) = "pa_ts_tbl"
#   return(self)
# }
# 
# .no_missing.pa_ts_tbl <- function(self) {
#   self %>% 
#     mutate(.no_missing = !(is.na(HR) | is.na(steps)))
# }
# .no_missing = function(self, ...) UseMethod(".no_missing", self)

pabble.initialize <- function(.id, 
                              .time,
                              .HR,
                              .steps){
  self <- tibble(.id, 
                 .time, 
                 .HR, 
                 .steps)
  
  #add tsibble checks

  return(self)
}

.no_missing <- function(pabble) {
  pabble %<>% 
    mutate(.no_missing = !(is.na(.HR) | is.na(.steps)))
  
  return(pabble)
}

.wear <- function(pabble, 
                  method = c("no_missing")) {
  
  if(method[1] == "no_missing") {
    pabble %<>% 
      mutate(.no_missing = !(is.na(.HR) | is.na(.steps)))
      rename(.wear = .no_missing)
  }
  
  return(pabble)
}

.adherence <- function(pabble, 
                      adherent_time = c("daytime")) {
  if(adherent_time[1] == "daytime") {
    minute_data %<>% 
      mutate(adherence = eight_to_eight, 
             adherent_wear = wear & adherence)
  } 
    
}


