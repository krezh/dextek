set shell := ['bash', '-Eeu', '-o', 'pipefail', '-c']

_default:
	@just --list rook

# Get the Rook Ceph dashboard password
dashboard-password:
	@kubectl -n rook-ceph get secret rook-ceph-dashboard-password -o jsonpath="{['data']['password']}" | base64 --decode && echo

toolbox:
	@kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- bash
