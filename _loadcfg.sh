# Internal script used to check and load config files

if [ ! -f ./config.cfg ]; then
  echo "  Please copy config.template.cfg to config.cfg and edit as needed."
  exit 1
else
  . ./config.cfg
fi 

