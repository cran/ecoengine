#' ee_photos
#'
#' Search the photos methods in the ecoengine API.
#' @template pages
#' @param  state_province Need to describe these parameters
#' @param  county California counties. Package include a full list of counties. To load dataset \code{data(california_counties)}
#' @param  genus genus name
#' @param  scientific_name scientific name
#' @param  authors author name
#' @param  remote_id remote id
#' @param  collection_code Type of collection. Can be \code{CalAcademy}, \code{Private}, \code{VTM}, \code{CDFA}. \code{CalFlora} Others TBA
#' @param  source data source. See \code{\link{ee_sources}}
#' @template dates
#' @param  related_type Need to describe these parameters
#' @param  related  Need to describe these parameters
#' @param  other_catalog_numbers Need to describe these parameters
#' @param  quiet Default is \code{FALSE}. Set to \code{TRUE} to suppress messages.
#' @param  georeferenced  Default is \code{FALSE}. Set to \code{TRUE} to filter by photos that have geo data.
#' @template foptions
#' @template progress
#' @export
#' @importFrom httr warn_for_status content GET
#' @importFrom plyr compact
#' @importFrom dplyr bind_rows
#' @importFrom lubridate ymd
#' @importFrom utils txtProgressBar setTxtProgressBar
#' @seealso related: \code{\link{ee_photos}} \code{\link{california_counties}}
#' @examples
#' # Request all photos. This request will paginate.
#' # merced <- ee_photos(county = "Merced County")
#'  ee_photos(page_size = 10)
#' # Search by collection code. See notes above on options
#' # ee_photos(collection_code = "CalAcademy")
#' # ee_photos(collection_code = "VTM")
#' # ee_photos(collection_code = "CalFlora")
#' # ee_photos(collection_code = "CDFA")
#' # Search by county.
#' # sc_county <- ee_photos(county = "Santa Clara County")
#' # merced <- ee_photos(county = "Merced County")
#' # merced <- ee_photos(county = "Merced County", page = "all")
#' # The package also contains a full list of counties
#' data(california_counties)
#' # alameda <- ee_photos(county = california_counties[1, 1])
#' # alameda$data
#' # You can also get all the data for Alameda county with one request
#' # alameda <- ee_photos(county = "Alameda county", page = "all")
#' # Spidering through the rest of the counties can easily be automated.
#' # Or by author
#' # charles_results <- ee_photos(author = "Charles Webber", page = 1:2)
#' # You can also request all pages in a single call by using ee_photos()
#' # In this example below, there are 6 pages of results (52 result items).
#' # Function will return all at once.
#' # racoons <- ee_photos(scientific_name = "Procyon lotor", page = "all")
ee_photos <- function(page = NULL,
						 state_province = NULL,
						 county = NULL,
						 genus = NULL,
						 scientific_name = NULL,
						 authors = NULL,
						 remote_id = NULL,
						 collection_code = NULL,
						 source  = NULL,
						 min_date = NULL,
						 max_date = NULL,
						 related_type = NULL,
						 related  = NULL,
						 page_size = 1000,
						 quiet = FALSE,
						 georeferenced = FALSE,
						 progress = FALSE,
						 other_catalog_numbers = NULL,
						 foptions = list()) {
	# photos_url <- "http://ecoengine.berkeley.edu/api/photos/?format=json"
	photos_url <- paste0(ee_base_url(), "photos/?format=json")

	if(georeferenced) georeferenced = "True"

	args <- as.list(ee_compact(c(page_size = page_size,
							state_province = state_province,
						 	county = county,
						 	genus = genus,
						 	scientific_name = scientific_name,
						 	authors = authors,
						 	remote_id = remote_id,
						 	collection_code = collection_code,
						 	source  = source ,
						 	min_date = min_date,
						 	max_date = max_date,
						 	related_type = related_type,
						 	related  = related ,
						 	georeferenced = georeferenced,
						 	other_catalog_numbers = other_catalog_numbers)))
	main_args <- args
	if(is.null(page)) { page <- 1 }
	main_args$page <- as.character(page)

	data_sources <- GET(photos_url, query = args, foptions)
    warn_for_status(data_sources, "Web resource is currently unavailable. Please try again later")
    photos <- content(data_sources, type = "application/json")
	required_pages <- ee_paginator(page = page, total_obs = photos$count, page_size)


     if(!quiet) {
    message(sprintf("Search contains %s photos (downloading %s of %s pages \n)", photos$count, length(required_pages), max(required_pages)))
	}
	if(progress) pb <- txtProgressBar(min = 0, max = length(required_pages), style = 3)
	    results <- list()

	  # This fetches multiple pages worth of results and rbinds them
    for(i in required_pages) {
    	args$page <- i
    	data_sources <- GET(photos_url, query = args, foptions)
    	photos <- content(data_sources, type = "application/json")
    	# browser()
      # issue is here
    	# photos_data <- do.call(rbind.fill, lapply(photos$results, rbindfillnull))
    	z <- lapply(photos$results, function(x) data.frame(t(unlist(x, use.names = TRUE)), stringsAsFactors = FALSE))
    	z2 <- data.table::rbindlist(z, fill = TRUE)
    	photos_data <- dplyr::as_data_frame(z2)


    	results[[i]] <- photos_data
    	if(progress) setTxtProgressBar(pb, i)
    }

  # This binds all paginated results together into a tibble
  res <- dplyr::bind_rows(results)
  # removes the "observations" prefix
  names(res) <-  gsub("observations.", "", names(res))
  # Formats date to ymd since there is no recorded time
  res$begin_date <- lubridate::ymd_hms(gsub("T", " ", res$begin_date))
  res$end_date <- lubridate::ymd_hms(gsub("T", " ", res$end_date))
  # Rename latitude and longitude
  names(res)[which(names(res) == "geometry.coordinates1")] = "longitude"
  names(res)[which(names(res) == "geometry.coordinates2")] = "latitude"
  # Goes into a obj that can now become part of a list with metadata.
  photos_data <- res

  photos_results <- list(results = photos$count, call = main_args, type = "photos", data = photos_data)
  class(photos_results) <- "ecoengine"

    if(progress) close(pb)
    photos_results
}







