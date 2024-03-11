#!/usr/bin/env bash

locations=(
	"/downloads/complete"
)

find "${locations[@]}" -type f \( -iname "*op[0-9]*" -o -iname "*nced*" -o -iname "*ncop*" -o -iname "*music video*" \) -exec rm -rf {} \;
