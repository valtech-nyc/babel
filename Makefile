MAKEFLAGS = -j1
FLOW_COMMIT = 622bbc4f07acb77eb1109830c70815f827401d90
TEST262_COMMIT = 52f70e2f637731aae92a9c9a2d831310c3ab2e1e

export BABEL_ENV = test

# Fix color output until TravisCI fixes https://github.com/travis-ci/travis-ci/issues/7967
export FORCE_COLOR = true

SOURCES = packages codemods

.PHONY: build build-dist watch lint fix clean test-clean test-only test test-ci publish bootstrap

build: clean
	make clean-lib
	./node_modules/.bin/gulp build
	node ./packages/babel-types/scripts/generateTypeHelpers.js
	# call build again as the generated files might need to be compiled again.
	./node_modules/.bin/gulp build
	# generate flow and typescript typings
	node scripts/generators/flow.js > ./packages/babel-types/lib/index.js.flow
	node scripts/generators/typescript.js > ./packages/babel-types/lib/index.d.ts
	# generate docs
	node scripts/generators/docs.js > ./packages/babel-types/README.md
ifneq ("$(BABEL_COVERAGE)", "true")
	make build-standalone
	make build-preset-env-standalone
endif

build-standalone:
	./node_modules/.bin/gulp build-babel-standalone

build-preset-env-standalone:
	./node_modules/.bin/gulp build-babel-preset-env-standalone

build-dist: build
	cd packages/babel-polyfill; \
	scripts/build-dist.sh
	cd packages/babel-runtime; \
	node scripts/build-dist.js

watch: clean
	make clean-lib

	# Ensure that build artifacts for types are created during local
	# development too.
	BABEL_ENV=development ./node_modules/.bin/gulp build-no-bundle
	node ./packages/babel-types/scripts/generateTypeHelpers.js
	node scripts/generators/flow.js > ./packages/babel-types/lib/index.js.flow
	BABEL_ENV=development ./node_modules/.bin/gulp watch

flow:
	./node_modules/.bin/flow check --strip-root

lint:
	./node_modules/.bin/eslint scripts $(SOURCES) '*.js' '**/.*.js' --format=codeframe --rulesdir="./scripts/eslint_rules"

fix:
	# The config is hardcoded because otherwise prettier searches for it and also picks up some broken package.json files from tests
	./node_modules/.bin/prettier --config .prettierrc --write --ignore-path .eslintignore '**/*.json'
	./node_modules/.bin/eslint scripts $(SOURCES) '*.js' '**/.*.js' --format=codeframe --fix --rulesdir="./scripts/eslint_rules"

clean: test-clean
	rm -rf packages/babel-polyfill/browser*
	rm -rf packages/babel-polyfill/dist
	rm -rf coverage
	rm -rf packages/*/npm-debug*

test-clean:
	$(foreach source, $(SOURCES), \
		$(call clean-source-test, $(source)))

test-only:
	./scripts/test.sh
	make test-clean

test: lint test-only

test-ci:
	make bootstrap
	make test-only

test-ci-coverage: SHELL:=/bin/bash
test-ci-coverage:
	BABEL_COVERAGE=true BABEL_ENV=test make bootstrap
	TEST_TYPE=cov ./scripts/test-cov.sh
	bash <(curl -s https://codecov.io/bash) -f coverage/coverage-final.json

bootstrap-flow:
	rm -rf ./build/flow
	mkdir -p ./build
	git clone --branch=master --single-branch --shallow-since=2017-01-01 https://github.com/facebook/flow.git ./build/flow
	cd build/flow && git checkout $(FLOW_COMMIT)

test-flow:
	node scripts/tests/flow/run_babylon_flow_tests.js

test-flow-ci:
	make bootstrap
	make test-flow

test-flow-update-whitelist:
	node scripts/tests/flow/run_babylon_flow_tests.js --update-whitelist

bootstrap-test262:
	rm -rf ./build/test262
	mkdir -p ./build
	git clone --branch=master --single-branch --shallow-since=2017-01-01 https://github.com/tc39/test262.git ./build/test262
	cd build/test262 && git checkout $(TEST262_COMMIT)

test-test262:
	node scripts/tests/test262/run_babylon_test262.js

test-test262-ci:
	make bootstrap
	make test-test262

test-test262-update-whitelist:
	node scripts/tests/test262/run_babylon_test262.js --update-whitelist

publish:
	git pull --rebase
	make clean-lib
	rm -rf packages/babel-runtime/helpers
	rm -rf packages/babel-runtime/core-js
	BABEL_ENV=production make build-dist
	make test
	# not using lerna independent mode atm, so only update packages that have changed since we use ^
	# --only-explicit-updates
	./node_modules/.bin/lerna publish --force-publish=* --exact --skip-temp-tag
	make clean

bootstrap:
	make clean-all
	yarn --ignore-engines
	./node_modules/.bin/lerna bootstrap -- --ignore-engines
	make build
	cd packages/babel-runtime; \
	node scripts/build-dist.js

clean-lib:
	$(foreach source, $(SOURCES), \
		$(call clean-source-lib, $(source)))

clean-all:
	rm -rf node_modules
	rm -rf package-lock.json

	$(foreach source, $(SOURCES), \
		$(call clean-source-all, $(source)))

	make clean

define clean-source-lib
	rm -rf $(1)/*/lib

endef

define clean-source-test
	rm -rf $(1)/*/test/tmp
	rm -rf $(1)/*/test-fixtures.json

endef

define clean-source-all
	rm -rf $(1)/*/lib
	rm -rf $(1)/*/node_modules
	rm -rf $(1)/*/package-lock.json

endef
