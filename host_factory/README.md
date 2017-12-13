# A very basic Host Factory demo
  - 1_set_hf_token.sh - one argument: output file, creats HF token, hostname and variable to retrieve
  - 2_get_secret_restapi.sh - one argument: outfile from above, redeems HF token, retrieves variable w/ REST API
  - 2_get_secret_summon.sh - one argument: outfile from above, redeems HF token, retrieves variable w/ Summon
  - 3_cleanup.sh - deletes old HF tokens
  - EDIT.ME - connection info for Conjur
  - policy.yml - webapp policy to create variable for retrieval
  - setup_summon.sh - installs summon
  - tomcat.xml.erb - example template for secrets injection via Summon
