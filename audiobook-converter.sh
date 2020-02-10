#!/bin/bash

# Set Defaults
bitrate="64k"
khz="44100"
genre="Audiobook"
track=1
overwrite=y # Set to n not overwrite existing output mp3 file

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
script_dir="$(cd $(dirname "$0") && echo $(pwd))"
ffmpeg_cmd="$script_dir/ffmpeg/$os/$ffmpeg_bin"
ffmpeg_args="-hide_banner -loglevel error"
list=list.txt

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
  output+="file '$(echo "$f" | sed -e 's/'\''/'\''\\'\'''\''/g')'"$'\n'
done
echo "$output" > $list

# Get metadata
directory="${PWD##*/}"
possible_author="$(echo "$directory" | awk -F' - ' '{print $1}' 2>/dev/null)"
possible_title="$(echo "$directory" | awk -F' - ' '{print $2}' 2>/dev/null)"
possible_subtitle="$(echo "$directory" | awk -F' - ' '{print $3}' 2>/dev/null)"

# Get Author
printf "${prompt}Who is the Author? [$possible_author]$n\n"
read author
test "$author" == "" && author="$possible_author" && tput cuu1 && printf "$author\n\n" || echo

# Get Title
printf "${prompt}What is the Title? [$possible_title]$n\n"
read title
test "$title" == "" && title="$possible_title" && tput cuu1 && printf "$title\n\n" || echo

# Get Subtitle
output_file="$author - $title.mp3"
printf "${prompt}What is the Subtitle"
test "$possible_subtitle" != "" && printf "? [$possible_subtitle]" || printf " (if any)?"
printf "$n\n"
read subtitle
if [[ "$subtitle" == "" ]]; then
  if [[ "$possible_subtitle" != "" ]]; then
    subtitle="$possible_subtitle"
    output_file="$author - $title - $subtitle.mp3"
    title="$title: $subtitle"
    tput cuu1
    printf "$subtitle\n"
  fi
else
  output_file="$author - $title - $subtitle.mp3"
  title="$title: $subtitle"
fi

# Get Year
printf "\n${prompt}What year was this audiobook released?$n\n"
read year

# Encode
printf "\n${message}Encoding...$n\n"
if [[ $use_cover -eq 0 ]]; then
  # Encode without cover art
  "$ffmpeg_cmd" $ffmpeg_args -$overwrite -f concat -safe 0 -i "$list" \
    -ac 1 -ab $bitrate -ar $khz -id3v2_version 3 -c:a copy \
    -metadata artist="$author" -metadata title="$title" -metadata album="$title" \
    -metadata genre="$genre" -metadata track="$track" -metadata date="$year" \
    "$output_file"
  test $? -eq 0 && printf "Done\n\n" || printf "${error}ERROR: Failed to create MP3 file\n\n"
else
  # Encode with cover art
  "$ffmpeg_cmd" $ffmpeg_args -$overwrite -f concat -safe 0 -i "$list" \
    -i "$cover" -c:v copy -map 0:0 -map 1:0 \
    -ac 1 -ab $bitrate -ar $khz -id3v2_version 3 -c:a copy \
    -metadata artist="$author" -metadata title="$title" -metadata album="$title" \
    -metadata genre="$genre" -metadata track="$track" -metadata date="$year" \
    "$output_file"
  test $? -eq 0 && printf "Done\n\n" || printf "${error}ERROR: Failed to create MP3 file\n\n"
fi

# Done
printf "${message}Created Audiobook file:$n\n$selected$output_file$n\n\n"
test -f "$list" && rm "$list"
