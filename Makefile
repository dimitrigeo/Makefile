SHELL := /bin/bash
all: fmt lint

## TODO add terraform-docs

.SILENT:
fmt:
	set -e

	tf_fmt () {
		set -e
		echo fmt: $${1}
		terraform fmt -recursive $${1}
		terraform fmt -recursive $${1/modules/}
	}

	export -f tf_fmt

	TF_MODULES=$$(find modules -maxdepth 2 -mindepth 2 -type d)

	PARALLEL_JOBS=10
	printf '%s\n' $${TF_MODULES[@]} | parallel --halt now,fail=1 -j$${PARALLEL_JOBS} "tf_fmt {}"

.SILENT:
lint:
	set -e
	echo lint: Start
	MODULE_GROUPS=$$(find modules -mindepth 1 -maxdepth 1 -type d)
	for MODULE_GROUP in $${MODULE_GROUPS}; do
		tflint --init -c $${MODULE_GROUP}/.tflint.hcl
		MODULES=$$(find $${MODULE_GROUP} -mindepth 1 -maxdepth 1 -type d)
		for MODULE in $$MODULES; do
			echo lint: $${MODULE}
			tflint -c $${MODULE_GROUP}/.tflint.hcl $${MODULE}
		done
	done
	echo lint: Success
