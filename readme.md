# Audiobook Converter

Audiobook converter is a bash script that will join all the MP3 files within a directory into a single MP3 file and prompt you to add the Author, Title, Subtitle, Year as well as search for the cover art.

<a href="https://i.imgur.com/Raz3Vey.png"><img src="https://i.imgur.com/Raz3Vey.png" title="Audiobook Converter" /></a>

## Metadata

By default, the script will parse the name of the starting directory using a *space dash space* separator in the format of:

`[author] - [title] - [subtitle]`

If any of these are found, the script will auto-suggest these in the prompts.



## Cover Art

An image in one of the following formats will be selected as cover art: *.png, *.jpg, *.jpeg

The first image file found (alphabetically), will be automatically selected as the cover art, so before running, you can search for the cover art and save it into the directory and it will automatically find it.



## Running

To run, simply clone the repo (or download and unzip) the project into a directory of your choosing.

Then in a terminal running the bash shell, cd into the directory containing the audiobook MP3 files you wish to join, and execute the script.

For example, if I was on a Mac and I had extracted the Audiobook Converter project into my `/Users/dean/bin/audio-converter/` directory, and I had my audio book MP3 files located in `/Users/dean/audiobooks/Simon Sinek - Leaders Eat Last - Why Some Teams Pull Together and Others Don't/`, I would:

1. Search the web for the _Leaders Eat Last_ audiobook and download the cover art into the audiobook directory.
2. `cd ~/audiobooks/Simon Sinek - Leaders Eat Last - Why Some Teams Pull Together and Others Don't/`
3. `~/bin/audio-converter/audiobook-converter.sh`
4. Follow the prompts and the script will save the final MP3 file into the directory with the existing audio book files.



## Compatibility

This project will work on Mac OS, Windows and Linux. Included in this project are the ffmpeg binaries for each of them.

If you are running Windows you just need any Bash environment, such as: [Cygwin](https://www.cygwin.com/), [Git Bash](https://git-scm.com/download/win) or [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10).



## Configuration

By default the output file will be encoded with the following settings:

1. Bit Rate: **64kbps** (constant bit rate)
2. Sample Rate: **44.1 kHz** (CD quality sound)
3. Channels: **1** (1 for Mono, 2 for Stereo. Mono is recommended for audiobooks and will cut the file size in half)

I find that these settings sound great for audio books. If you prefer different settings, you can adjust them at the top of the main script, `audiobook-converter.sh`. 



## Enabling Debug Mode

If you encounter any errors with ffmpeg encoding, you won't see them by default. In order to see the error, you can turn on debugging at the top of the main script, `audiobook-converter.sh`.  Just change `debug=0` to `debug=1`.



## Known Issues

While it is safe to re-run the script multiple times on the same audiobook, if you run a conversion, then edit the `filename_format` in the `audiobook-converter.sh` script and re-run it on the same directory, the script will not know that the previously generated file is separate and will create new audiobook mp3 with it, which will basically have a double-book in a single file.