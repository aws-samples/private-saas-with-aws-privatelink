.PHONY: setup build test deploy clean

setup:
	python3 -m venv .venv
	.venv/bin/python3 -m pip install -U pip
	.venv/bin/python3 -m pip install -r requirements-test.txt

build:
	sam build --use-container --parallel --cached

deploy:
	sam deploy

test:
	.venv/bin/cfn-lint
	.venv/bin/checkov -d privatelink_nlb_alb/terraform
	.venv/bin/checkov -d privatelink_nlb_apigw/terraform

clean:
	sam delete
