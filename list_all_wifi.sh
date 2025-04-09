#!/bin/sh
system_profiler SPAirPortDataType | awk '
# Function to compute quality from a "Signal / Noise:" line.
function getQuality(s,    sig, nos, snr, a, qual) {
  sub(/Signal \/ Noise:[[:space:]]*/, "", s)
  split(s, a, " / ")
  gsub(/ dBm/, "", a[1])
  gsub(/ dBm/, "", a[2])
  sig = a[1] + 0
  nos = a[2] + 0
  snr = sig - nos
  if (snr >= 40)
     qual = "Excellent"
  else if (snr >= 20)
     qual = "Good"
  else
     qual = "Weak"
  return qual
}

BEGIN {
  block_count = 0
}

/Other Local Wi-Fi Networks:/ { flag = 1; next }

flag {
  # Detect a new network block header (line with 12 spaces followed by a non-space)
  if ($0 ~ /^ {12}[^ ]/) {
    if (section != "" && security != "" && signal != "") {
      quality = getQuality(signal)
      if (quality == "Weak")
         quality_line = "\033[90mQuality: " quality "\033[0m"
      else if (quality == "Excellent")
         quality_line = "\033[92mQuality: " quality "\033[0m"
      else
         quality_line = "Quality: " quality

      # Build the full block string (each block ends with one newline)
      block = section "\n"
      if (security ~ /[[:space:]]*Security:[[:space:]]*None/)
         block = block "\033[31m" security "\033[0m" "\n"
      else
         block = block security "\n"
      block = block signal "\n" quality_line "\n"

      block_count++
      blocks[block_count] = block
      # Assign numeric order for sorting: Excellent=1, Good=2, Weak=3
      if (quality == "Excellent")
         order[block_count] = 1
      else if (quality == "Good")
         order[block_count] = 2
      else
         order[block_count] = 3
    }
    sub(/^[[:space:]]+/, "", $0)
    section = $0
    security = ""
    signal = ""
    next
  }
  # Capture the Security line.
  if ($0 ~ /Security:/) {
    sub(/^[[:space:]]+/, "", $0)
    security = $0
  }
  # Capture the Signal / Noise line.
  if ($0 ~ /Signal \/ Noise:/) {
    sub(/^[[:space:]]+/, "", $0)
    signal = $0
  }
}

END {
  # Process the final block if present.
  if (section != "" && security != "" && signal != "") {
      quality = getQuality(signal)
      if (quality == "Weak")
         quality_line = "\033[90mQuality: " quality "\033[0m"
      else if (quality == "Excellent")
         quality_line = "\033[92mQuality: " quality "\033[0m"
      else
         quality_line = "Quality: " quality

      block = section "\n"
      if (security ~ /[[:space:]]*Security:[[:space:]]*None/)
         block = block "\033[31m" security "\033[0m" "\n"
      else
         block = block security "\n"
      block = block signal "\n" quality_line "\n"

      block_count++
      blocks[block_count] = block
      if (quality == "Excellent")
         order[block_count] = 1
      else if (quality == "Good")
         order[block_count] = 2
      else
         order[block_count] = 3
  }
  # Sort the collected blocks using a simple bubble sort.
  for (i = 1; i <= block_count; i++) {
    for (j = i + 1; j <= block_count; j++) {
      if (order[i] > order[j]) {
        temp = order[i]; order[i] = order[j]; order[j] = temp
        temp_block = blocks[i]; blocks[i] = blocks[j]; blocks[j] = temp_block
      }
    }
  }
  # Print the sorted network blocks.
  for (i = 1; i <= block_count; i++) {
    print blocks[i]
  }
}
'

