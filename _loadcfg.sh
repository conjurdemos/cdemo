# Internal script used to check and load config files

echo -n "Checking for config.cfg... "
if [ ! -f ./config.cfg ]; then
  echo " Not Found!"
  echo "  Please copy config.template.cfg to config.cfg and edit as needed."
  exit 1
else
  echo "Found!"
  echo "  Loading config.cfg"
  . ./config.cfg
fi 

