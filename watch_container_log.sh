#!/bin/bash
# docker-compose exec -T webapp tail -f cc.log
docker-compose logs -tf webapp
