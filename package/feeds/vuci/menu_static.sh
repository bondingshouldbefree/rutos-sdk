#!/bin/bash

declare -A menus

table_filter() {
	local condition="$1"
	local -a input=("${!2}")
	local -n result=$3
	result=()
	for item in "${input[@]}"; do
		if eval "$condition"; then
			result+=("$item")
		fi
	done
}

check_menu() {
	local menu="$1"
	for key in $(jq -r 'keys[]' <<< "$menu"); do
		local item=$(jq -c --arg k "$key" '.[$k]' <<< "$menu")

		local index=$(jq -r '.index // empty' <<< "$item")
		if [ -n "$index" ]; then
			local tmp="{}"

			for k in $(jq -r 'keys[]' <<< "$item"); do
				local value=$(jq -c --arg k "$k" '.[$k] // empty' <<< "$item")

				if [ "$k" == "acls" ]; then
					local acls_array=$(jq -c '.' <<< "$value")
					tmp=$(jq --argjson acls "$acls_array" '. + {"acls": $acls}' <<< "$tmp")
				elif [ "$k" == "depends" ]; then
					local depends=$(jq -c '.' <<< "$value")
					tmp=$(jq --argjson depends "$depends" '. + {"depends": $depends}' <<< "$tmp")
				else
					tmp=$(jq --arg key "$k" --argjson value "$value" '. + {($key): $value}' <<< "$tmp")
				fi
			done

			tmp=$(jq '. + {"read_access": true, "write_access": true}' <<< "$tmp")
			menus["$key"]="$tmp"
		fi
	done
}

generate_static() {
	local output_file="$1"
	local menu_files_path="$2"

	for file in "$menu_files_path"/*.json; do
		local menu_json=$(jq '.' "$file" 2>/dev/null)
		[ -z "$menu_json" ] && continue

		check_menu "$menu_json"
	done

	local json_object="{"

	for key in "${!menus[@]}"; do
		json_object+="\"$key\": ${menus[$key]},"
	done

	json_object="${json_object%,}}"
	echo "$json_object" > "$output_file"
}

main() {
	local output_path="$1"
	local menu_files_path="$2"

	if [ -z "$output_path" ] || [ -z "$menu_files_path" ]; then
		echo "Usage: $0 <output_path> <menu_files_path>"
		exit 1
	fi

	generate_static "$output_path" "$menu_files_path"
}

main "$@"
