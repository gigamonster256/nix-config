{
  lib,
  writeShellApplication,
  gnutar,
  unzip,
  unrar,
  bzip2,
  gzip,
  p7zip,
  withUnfree ? true,
}:
writeShellApplication {
  name = "extract";

  runtimeInputs = [
    gnutar
    unzip
    bzip2
    gzip
    p7zip
  ]
  ++ lib.optional withUnfree unrar;

  text =
    let
      extractRar =
        if withUnfree then
          "unrar x \"$1\""
        else
          "echo 'unrar is not available, please install extract with unfree'";
    in
    # bash
    ''
      if [ -f "$1" ] ; then
        case $1 in
          *.tar.bz2) tar xjf "$1";;
          *.tar.gz)  tar xzf "$1";;
          *.tar)     tar xf "$1";;
          *.bz2)     bunzip2 "$1";;
          *.gz)      gunzip "$1";;
          *.rar)     ${extractRar};;
          *.tbz2)    tar xjf "$1";;
          *.tgz)     tar xzf "$1";;
          *.zip)     unzip "$1";;
          *.Z)       uncompress "$1";;
          *.7z)      7z x "$1";;
          *)         echo "'$1' cannot be extracted via extract()";;
        esac
      else
          echo "'$1' is not a valid file"
      fi
    '';
}
