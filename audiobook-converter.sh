#!/bin/bash

# This setting determines the final filename format you prefer. You can set this
# to whatever you'd like as long as you keep the formatting in tact. Options are:
# [author]      - will be replaced by the author
# [title]       - will be replaced by the title
# [subtitle]    - will be replaced by the subtitle
# [year]        - will be replaced by the year
# [series-name] - will be replaced by the name of the book series
# [book-number] - will be replaced by the book number within the series
filename_format='[author] - [title] - [subtitle] ([year])'

# Set Defaults
debug=0
bitrate=64k
sample_rate=44100
channels=1  # 1 for mono 2 for stereo (mono is recommended for smaller file sizes)
genre=Audiobook
track=1
overwrite=y  # Set to 'n' to prevent overwriting the existing output mp3 file

## Detect environment
if [[ "$(cat /proc/version 2>/dev/null)" =~ CYGWIN|MINGW|Microsoft ]]; then
  # Windows
  ffmpeg_bin=win/ffmpeg.exe
elif [[ $(uname) == Darwin ]]; then
  # Mac
  ffmpeg_bin=mac/ffmpeg
else
  # Linux
  if [[ "$(cat /proc/version 2>/dev/null)" =~ amd64 ]]; then
    # 64-bit
    ffmpeg_bin=linux/ffmpeg-x64
  else
    # 32-bit
    ffmpeg_bin=linux/ffmpeg-x32
  fi
fi

# Define vars
list=list.txt
script_dir="$(cd $(dirname "$0") && echo $(pwd))"
ffmpeg_cmd="$script_dir/ffmpeg/$ffmpeg_bin"
if [[ "$debug" -eq 1 ]]; then
  # Turn up debug output
  ffmpeg_args="-hide_banner -loglevel level+info"
else
  # Show only errors
  ffmpeg_args="-hide_banner -loglevel level+fatal"
fi

# Define colors
green="\e[32m"
yellow="\e[33m"
cyan="\e[36m"
white="\e[37m"
redbg="\e[41m"
bluebg="\e[44m"
bold="\e[1m"
n="\e[m" # Reset to normal

# Define styles
error=$bold$white$redbg
menu=$white$bluebg
prompt=$yellow
selected=$green
message=$cyan

printf "\n"
printf "$menu ╔═════════════════════════╗ $n\n"
printf "$menu ║                         ║ $n\n"
printf "$menu ║   Audiobook Converter   ║ $n\n"
printf "$menu ║                         ║ $n\n"
printf "$menu ╚═════════════════════════╝ $n\n"
printf "\n"

# Turn single quote (') into escaped single quote ('\'')
escape_single_quotes() {
  echo "$1" | sed -e 's/'\''/'\''\\'\'''\''/g'
}

# Take the first image file as the cover art
cover="$(ls *.jpg *.jpeg *.png 2>/dev/null | head -n1)"
if [[ "$cover" == "" ]]; then
  printf "${error}WARNING: Could not find cover art file.$n\n\n"
  printf "${message}If you wish to add cover art, press Enter to cancel.\n"
  printf "Find and save a jpg or png file to this directory and re-run script.$n\n\n"
  printf "${prompt}Do you wish to proceed? [N/y]$n\n"
  read proceed
  if [[ ! "$proceed" =~ [Yy] ]]; then
    exit
  fi
  use_cover=0
  echo
else
  printf "${message}Found cover art:$n ${selected}$cover$n\n\n"
  use_cover=1
fi

# Create list of mp3 files with proper escaping:
printf "${message}Creating list of mp3 files...$n\n\n"
test -f $list && rm $list
for f in *.mp3; do
  # Detect any single quotes and convert to: '\''
  output+="file '$(escape_single_quotes "$f")'"$'\n'
done
echo "$output" > $list

# Get metadata
directory="${PWD##*/}"
possible_author="$(echo "$directory" | awk -F ' - ' '{print $1}' 2>/dev/null)"
possible_title="$(echo "$directory" | awk -F ' - ' '{print $2}' 2>/dev/null)"
possible_subtitle="$(echo "$directory" | awk -F ' - ' '{print $3}' 2>/dev/null)"

# Get Author
printf "${prompt}Who is the Author? [$possible_author]$n\n"
read author
test "$author" == "" && author="$possible_author" && tput cuu1 && printf "$author\n\n" || echo

# Get Title
printf "${prompt}What is the Title? [$possible_title]$n\n"
read title
test "$title" == "" && title="$possible_title" && tput cuu1 && printf "$title\n\n" || echo

# Get Subtitle
printf "${prompt}What is the Subtitle"
test "$possible_subtitle" != "" && printf "? [$possible_subtitle]" || printf " (if any)?"
printf "$n\n"
read subtitle
if [[ "$subtitle" == "" ]]; then
  if [[ "$possible_subtitle" != "" ]]; then
    subtitle="$possible_subtitle"
    new_title="$title: $subtitle"
    tput cuu1
    printf "$subtitle\n"
  fi
else
  new_title="$title: $subtitle"
fi

# Get Year
printf "\n${prompt}What year was this audiobook released?$n\n"
read year

# Determine output format
output_file="$(echo "$filename_format.mp3" | sed -e 's/\[author\]/'"$author"'/g' -e 's/\[title\]/'"$title"'/g' \
  -e 's/\[subtitle\]/'"$subtitle"'/g' -e 's/\[year\]/'"$year"'/g')"

# Check if overwrite is set to 'n' and the output file already exists
if [[ "$overwrite" =~ n|N ]] && [[ -f "$output_file" ]]; then
  printf "\nOutput MP3 file already exists.\n\nSkipping.$n\n\n"
  test -f "$list" && rm "$list"
  exit 0
fi

# Make sure output file is not listed in temporary list of files to process (for repeated runs)
escaped_output_file="$(escape_single_quotes "$output_file")"
grep_output="$(grep -Fn "$escaped_output_file" "$list")"
if [[ "$grep_output" != "" ]]; then
  line_to_delete="$(echo "$grep_output" | cut -d':' -f1)"
  sed -i "${line_to_delete}d" "$list"
fi

# Encode
printf "\n${message}Encoding...$n\n"

if [[ $use_cover -eq 0 ]]; then
  # Encode without cover art
  "$ffmpeg_cmd" $ffmpeg_args -y -f concat -safe 0 -i "$list" \
    -ab $bitrate -ar $sample_rate -ac $channels -id3v2_version 3 -c:a copy \
    -metadata artist="$author" -metadata title="$new_title" -metadata album="$title" \
    -metadata genre="$genre" -metadata track="$track" -metadata date="$year" \
    "$output_file"
  result=$?
else
  # Encode with cover art
  "$ffmpeg_cmd" $ffmpeg_args -y -f concat -safe 0 -i "$list" \
    -i "$cover" -c:v copy -map 0:0 -map 1:0 \
    -ab $bitrate -ar $sample_rate -ac $channels -id3v2_version 3 -c:a copy \
    -metadata artist="$author" -metadata title="$new_title" -metadata album="$title" \
    -metadata genre="$genre" -metadata track="$track" -metadata date="$year" \
    "$output_file"
  result=$?
fi

# Done
test -f "$list" && rm "$list"
if [[ "$result" -eq 0 ]]; then
  printf "Done\n\n"
  printf "${message}Created Audiobook file:$n\n$selected$output_file$n\n\n"
else
  printf "${error}ERROR: Failed to create MP3 file$n\n\n"
  printf "You can enable debugging mode and re-run it to see what the problem is.\n\n"
  printf "See the readme.md file for more details.\n\n"
fi
