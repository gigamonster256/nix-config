{
  writeShellApplication,
  gnutar,
  unzip,
}:
writeShellApplication {
  name = "extract";

  runtimeInputs = [
    gnutar
    unzip
  ];

  text =
    /*
    bash
    */
    ''
      if [ -f "$1" ] ; then
        case $1 in
          *.tar.bz2) tar xjf "$1";;
          *.tar.gz)  tar xzf "$1";;
          *.tar)     tar xf "$1";;
          *.tbz2)    tar xjf "$1";;
          *.tgz)     tar xzf "$1";;
          *.zip)     unzip "$1";;
          *)         echo "'$1' cannot be extracted via extract()";;
        esac
      else
          echo "'$1' is not a valid file"
      fi
    '';
}
