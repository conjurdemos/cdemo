#!/bin/bash -e
set -o pipefail

main() {
	kill_master
	wait_for_new_master
	./0-setup-cluster.sh
}

kill_master() {
        cont_list=$(docker ps -f "label=role=conjur_node" --format {{.Names}})
        for cname in $cont_list; do
		crole=$(docker exec $cname sh -c "evoke role")
		if [[ $crole == master ]]; then
			docker stop $cname && docker rm $cname
		fi	
        done
}

wait_for_new_master() {
        cont_list=$(docker ps -f "label=role=conjur_node" --format {{.Names}})
	MASTER_FOUND=false
	while [[ $MASTER_FOUND == false ]]; do
	        for cname in $cont_list; do
			crole=$(docker exec $cname sh -c "evoke role")
			if [[ $crole == master ]]; then
				MASTER_FOUND=true
			fi
		done
        done
}

main "$@"
