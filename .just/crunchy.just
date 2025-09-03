set shell := ['bash', '-Eeu', '-o', 'pipefail', '-c']

set quiet := true

_default:
	@just --list crunchy

CRUNCHY_DEFAULT_NS := "databases"
CRUNCHY_DEFAULT_DB_CLUSTER := "postgres"
OUTPUT_DIR := justfile_dir()
CLI_ARGS := "--verbose --format=c --no-comments --clean --if-exists --no-owner"


# Dump a database
[no-cd]
dump DB_NAME OUTPUT_DIR="." NS=(CRUNCHY_DEFAULT_NS) DB_CLUSTER=(CRUNCHY_DEFAULT_DB_CLUSTER) CLI_ARGS=(CLI_ARGS):
  #!/usr/bin/env bash
  set -euo pipefail
  POD=$(kubectl get pods -n {{NS}} -l postgres-operator.crunchydata.com/role=master,postgres-operator.crunchydata.com/cluster={{DB_CLUSTER}} -o jsonpath='{.items[0].metadata.name}')
  kubectl exec -it -c database -n {{NS}} ${POD} -- /bin/bash -c 'pg_dump --dbname {{DB_NAME}} {{CLI_ARGS}} --file /pgdata/{{DB_NAME}}.psql'
  kubectl cp -c database "{{NS}}/${POD}:/pgdata/{{DB_NAME}}.psql" "{{OUTPUT_DIR}}/{{DB_NAME}}.psql"
  kubectl exec -it -c database -n {{NS}} ${POD} -- /bin/bash -c 'rm -rf /pgdata/{{DB_NAME}}.psql'


# Restore the database
[no-cd]
restore DB_NAME FILE DB_USER=(DB_NAME) NS=(CRUNCHY_DEFAULT_NS) DB_CLUSTER=(CRUNCHY_DEFAULT_DB_CLUSTER) CLI_ARGS=(CLI_ARGS):
  #!/usr/bin/env bash
  set -euo pipefail
  CLI_ARGS="{{ CLI_ARGS }} --role {{DB_USER}}"
  POD=$(kubectl get pods -n {{NS}} -l postgres-operator.crunchydata.com/role=master,postgres-operator.crunchydata.com/cluster={{DB_CLUSTER}} -o jsonpath='{.items[0].metadata.name}')
  test -f "{{FILE}}" || echo "File {{FILE}} not found" && exit 1
  kubectl cp -c database "{{FILE}}" "{{NS}}/${POD}:/pgdata/restore-{{DB_NAME}}.psql"
  kubectl exec -it -c database -n {{NS}} ${POD} -- /bin/bash -c 'echo "ALTER DATABASE \"{{DB_NAME}}\" OWNER TO \"{{DB_USER}}\";" | psql'
  kubectl exec -it -c database -n {{NS}} ${POD} -- /bin/bash -c 'pg_restore --dbname {{DB_NAME}} {{CLI_ARGS}} /pgdata/restore-{{DB_NAME}}.psql'
  kubectl exec -it -c database -n {{NS}} ${POD} -- /bin/bash -c 'rm -rf /pgdata/restore-{{DB_NAME}}.psql'

# Exec into the master instance
exec NS=(CRUNCHY_DEFAULT_NS) DB_CLUSTER=(CRUNCHY_DEFAULT_DB_CLUSTER):
  #!/usr/bin/env bash
  set -euo pipefail
  POD=$(kubectl get pods -n {{NS}} --selector='postgres-operator.crunchydata.com/cluster={{DB_CLUSTER}},postgres-operator.crunchydata.com/role=master' -o name)
  kubectl exec -it --container database --namespace {{NS}} ${POD} -- /bin/bash

# Backup the cluster
trigger-backup NS=(CRUNCHY_DEFAULT_NS) DB_CLUSTER=(CRUNCHY_DEFAULT_DB_CLUSTER):
  kubectl annotate --namespace {{NS}} postgrescluster {{DB_CLUSTER}} postgres-operator.crunchydata.com/pgbackrest-backup="$(date)" --overwrite

# Retrieve the password
password NS=(CRUNCHY_DEFAULT_NS) DB_CLUSTER=(CRUNCHY_DEFAULT_DB_CLUSTER):
  kubectl get secret --namespace {{NS}} {{DB_CLUSTER}}-pguser-postgres -o jsonpath="{['data']['password']}" | base64 --decode && echo

# Create a new stanza
create-stanza NS=(CRUNCHY_DEFAULT_NS) DB_CLUSTER=(CRUNCHY_DEFAULT_DB_CLUSTER):
  #!/usr/bin/env bash
  set -euo pipefail
  POD=$(kubectl get pods -n {{NS}} --selector='postgres-operator.crunchydata.com/cluster={{DB_CLUSTER}},postgres-operator.crunchydata.com/role=master' -o name)
  echo ${POD}
  kubectl exec ${POD} -it -n {{NS}} -c database -- pgbackrest stanza-create --stanza=db
