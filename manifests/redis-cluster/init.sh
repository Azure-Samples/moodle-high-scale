#!/bin/bash
# Usage: ./roles.sh

urls=$(kubectl -n moodle get pods -l app=redis -o jsonpath='{range.items[*]}{.status.podIP} ')
command="kubectl -n moodle exec -it redis-0 -- redis-cli --cluster create --cluster-replicas 1 "

for url in $urls
do
    command+=$url":6379 "
done

echo "Executing command: " $command
$command

cache_urls=$(kubectl -n moodle get pods -l app=redis-cache -o jsonpath='{range.items[*]}{.status.podIP} ')
cache_command="kubectl -n moodle exec -it redis-cache-0 -- redis-cli --cluster create --cluster-replicas 1 "

for cache_url in $cache_urls
do
    cache_command+=$cache_url":6379 "
done

echo "Executing command: " $caches_command
$cache_command