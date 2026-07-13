#
# Helper functions
#

# Get the list of transects
get_transects <- function() {
    return(
        c("A", "B", "C")
    )
}

# Get the habitat description for a given transect
get_habitat <- function(transect) {
    habitats <- c(
        "A" = "buried in soil of a conifer forest area with reindeer access.",
        "B" = "buried in soil of a conifer forest area protected from grazing by reindeers.",
        "C" = "buried in soil of a mixed broadleaf forest accessed by random visitors."
    )

    return(habitats[transect])
}

# Get the latitude for a given transect
get_latitude <- function(transect) {
    latitudes <- c(
        "A" = 66.367,
        "B" = 66.367, # A and B have the same coordinates
        "C" = 66.376
    )

    return(latitudes[transect])
}

# Get the longitude for a given transect
get_longitude <- function(transect) {
    longitudes <- c(
        "A" = 29.533,
        "B" = 29.533, # A and B have the same coordinates
        "C" = 29.313
    )

    return(longitudes[transect])
}

# Get the wood type for a given site
get_wood_type <- function(site) {
    if (site %in% c("A", "B")) {
        return("Pine")
    }
    if (site %in% c("C", "D")) {
        return("Birch")
    }
    # site %in% c("E", "F")
    return("Spruce")
}

# Get the wood texture for a given site
get_wood_texture <- function(site) {
    if (site %in% c("A", "B", "E", "F")) {
        return("Softwood")
    }
    # site %in% c("C", "D")
    return("Hardwood")
}

# Get the match source for a given source
get_match_source <- function(source) {
    if (source == "BLAST") {
        return("BLASTn circa 2024-05-01")
    }
    return("UNITE Fungi 9.0 (2023-07-18) (https://doi.org/10.15156/BIO/2938068)")
}
