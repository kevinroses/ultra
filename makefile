ifneq ("$(wildcard .env)","")
  include .env
  export $(shell sed 's/=.*//' .env)
endif

export VERSION=$(shell git rev-parse --short HEAD)
export IMAGE_NAME_NUXT=ultradex-nuxt
export IMAGE_NAME_PROXY=ultradex-proxy

K8S_BUILD_DIR ?= ./.build_k8s
K8S_FILES := $(shell find ./kubernetes -name '*.yaml' | sed 's:./kubernetes/::g')

run:
	@docker-compose up -d --build mongo
	@yarn install
	@NETWORK=proton PROTOCOL=http DB_STRING_CONNECTION="" yarn run dev

start:
	@docker-compose stop
	@docker-compose up -d --build mongo
	@NETWORK=jungle PROTOCOL=http DB_STRING_CONNECTION=mongodb://host.docker.internal:27017/alcor docker-compose up -d --build nuxt
	@PROXY_HOST=host.docker.internal docker-compose up -d --build proxy

stop:
	@docker-compose stop

build-docker-images:
	@docker pull $(DOCKER_HUB_USER)/$(IMAGE_NAME_NUXT):latest || true
	@docker build -f Dockerfile.Nuxt . \
		-t $(DOCKER_HUB_USER)/$(IMAGE_NAME_NUXT):$(VERSION) \
		-t $(DOCKER_HUB_USER)/$(IMAGE_NAME_NUXT):latest \
		--cache-from $(DOCKER_HUB_USER)/$(IMAGE_NAME_NUXT):latest \
		--build-arg network="$(NETWORK)" \
		--build-arg protocol="$(PROTOCOL)"
	@docker pull $(DOCKER_HUB_USER)/$(IMAGE_NAME_PROXY):latest || true
	@docker build -f Dockerfile.Proxy . \
		-t $(DOCKER_HUB_USER)/$(IMAGE_NAME_PROXY):$(VERSION) \
		-t $(DOCKER_HUB_USER)/$(IMAGE_NAME_PROXY):latest \
		--cache-from $(DOCKER_HUB_USER)/$(IMAGE_NAME_PROXY):latest \
		--build-arg proxy_host="$(PROXY_HOST)"

push-docker-images:
	@echo $(DOCKER_HUB_PASSWORD) | docker login \
		--username $(DOCKER_HUB_USER) \
		--password-stdin
	@docker push $(DOCKER_HUB_USER)/$(IMAGE_NAME_NUXT):$(VERSION)
	@docker push $(DOCKER_HUB_USER)/$(IMAGE_NAME_NUXT):latest
	@docker push $(DOCKER_HUB_USER)/$(IMAGE_NAME_PROXY):$(VERSION)
	@docker push $(DOCKER_HUB_USER)/$(IMAGE_NAME_PROXY):latest

build-kubernetes-namespace:
	@rm -Rf $(K8S_BUILD_DIR) && mkdir -p $(K8S_BUILD_DIR)
	@for file in $(K8S_FILES); do \
		mkdir -p `dirname "$(K8S_BUILD_DIR)/$$file"`; \
		$(SHELL_EXPORT) envsubst <./kubernetes/$$file >$(K8S_BUILD_DIR)/$$file; \
	done

push-kubernetes-namespace:
	@kubectl create ns $(NAMESPACE) || echo "namespace '$(NAMESPACE)' already exists.";
	@echo "Creating SSL certificates..."
	@kubectl create secret tls \
		tls-secret \
		--key ./ssl/eosio.cr.priv.key \
		--cert ./ssl/eosio.cr.crt \
		-n $(NAMESPACE)  || echo "SSL cert already configured.";
	@echo "Creating configmaps..."
	@kubectl create configmap -n $(NAMESPACE) \
	wallet-config \
	--from-file wallet/config/ || echo "Wallet configuration already created.";
	@echo "Applying kubernetes files..."
	@for file in $(shell find $(K8S_BUILD_DIR) -name '*.yaml' | sed 's:$(K8S_BUILD_DIR)/::g'); do \
		kubectl apply -f $(K8S_BUILD_DIR)/$$file -n $(NAMESPACE) || echo "${file} Cannot be updated."; \
	done

deploy:
	@echo "started at: $$(date +%Y-%m-%d:%H:%M:%S)"
	make build-docker-images
	make push-docker-images
	make build-kubernetes-namespace
	make push-kubernetes-namespace
	@echo "completed at: $$(date +%Y-%m-%d:%H:%M:%S)"