#!/usr/bin/env bash

set -e

FAILURE=1
SUCCESS=0

elasticsearch_cluster_ip="$(kubectl get services --namespace test -l service==elasticsearch -o json | jq -r .items[0].spec.clusterIP)"
elasticsearch_cluster_port="9200"

random_index_name="$(cat /dev/urandom | tr -cd 'a-f0-9' | head -c6)"
echo "Creating a temporay index in Elasticsearch : ${random_index_name}"
curl -X PUT http://${elasticsearch_cluster_ip}:${elasticsearch_cluster_port}/${random_index_name}

echo "Push random log data into index : ${random_index_name}"
python elasticstack/test/es_test_data.py --es-url="http://${elasticsearch_cluster_ip}:${elasticsearch_cluster_port}" --index-name="${random_index_name}" --batch-size=100 --count=10

sleep 5

echo "Checking if data is available in ElasticSearch"
index_resp_code="$(curl -s -o /dev/null -w "%{http_code}" -X GET http://${elasticsearch_cluster_ip}:${elasticsearch_cluster_port}/${random_index_name})"
if [[ "${index_resp_code}" == "200" ]]; then
  echo "[SUCCESS] : Found index records in elasticsearch.."
else
  echo "[FAILURE] : Did not find records in elasticsearch index.."
  exit "${FAILURE}"
fi

echo "Deleting the temporary index in elasticsearch"
curl -X DELETE http://${elasticsearch_cluster_ip}:${elasticsearch_cluster_port}/${random_index_name}


