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