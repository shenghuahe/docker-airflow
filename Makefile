build:
	docker build --no-cache -t hshhbd/docker-airflow .
push:
	docker push hshhbd/docker-airflow

.PHONY: build push
