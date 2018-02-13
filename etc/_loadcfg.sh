# Internal script used to check and load config files

cfg_loc="${BASH_SOURCE%%etc/_loadcfg.sh}config.cfg"
if [ ! -f "$cfg_loc" ]; then
  echo "  Please copy config.template.cfg to config.cfg and edit as needed."
  exit 1
else
  . $cfg_loc
fi 

announce_section() {
  printf "\n========================\n$1\n========================\n"
}


