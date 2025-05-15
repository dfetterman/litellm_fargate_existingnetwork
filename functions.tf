locals {
  # Function to URL encode a string, replacing special characters with percent-encoded values
  urlencode = {
    for c in setproduct(range(256), [""]) :
    format("%c", c[0]) => (
      can(regex("^[A-Za-z0-9_.~-]$", format("%c", c[0]))) 
      ? format("%c", c[0]) 
      : format("%%%02X", c[0])
    )
  }
}

# URL encode function that takes a string and returns the URL-encoded version
# This replaces special characters with their percent-encoded equivalents
locals {
  urlencode_string = function(str) {
    join("", [
      for c in split("", str) :
      lookup(local.urlencode, c, format("%%%02X", tonumber(format("%d", coalesce(index("${c}", 0), 0))))
    ])
  }
}

# URL encode mapping for special characters
locals {
  url_encode_chars = {
    "!" = "%21"
    "#" = "%23"
    "$" = "%24"
    "&" = "%26"
    "'" = "%27"
    "(" = "%28"
    ")" = "%29"
    "*" = "%2A"
    "+" = "%2B"
    "," = "%2C"
    "/" = "%2F"
    ":" = "%3A"
    ";" = "%3B"
    "=" = "%3D"
    "?" = "%3F"
    "@" = "%40"
    "[" = "%5B"
    "]" = "%5D"
    " " = "%20"
    '"' = "%22"
    "%" = "%25"
    "<" = "%3C"
    ">" = "%3E"
    "\\" = "%5C"
    "^" = "%5E"
    "_" = "%5F"
    "`" = "%60"
    "{" = "%7B"
    "|" = "%7C"
    "}" = "%7D"
    "~" = "%7E"
  }
} 