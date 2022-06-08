PROJECT_ID=l-gs-gsrd-general
VM_PREFIX=python-devops-vm-
USER_ID=terraform-sa
ENV=staging
ZONE=us-central1-a

#deployment variables
GITHUB_SHA?=latest
LOCAL_TAG=hello-python:$(GITHUB_SHA)
REMOTE_TAG=gcr.io/$(PROJECT_ID)/$(LOCAL_TAG)
CONTAINER_NAME=hello-python


#Secret helper
define get-secret
$(shell gcloud secrets versions access latest --secret=$(1) --project=$(PROJECT_ID))
endef

build-start:
	docker-compose up


create-tf-backend-bucket:
	gsutil mb -p ${PROJECT_ID} gs://${PROJECT_ID}-terraform


terraform-init:
	cd terraform && \
		terraform init


terraform-create-workspace:
	cd terraform && \
		terraform workspace new $(ENV) && \ 
			terraform init 

TF_ACTION?=plan
terraform-action:
	@cd terraform && \
		terraform workspace select $(ENV) && \
		terraform $(TF_ACTION) \
		-var-file="./environments/common.tfvars" \
		-var-file="./environments/$(ENV)/config.tfvars" \
		-var="test-key=$(call get-secret,python-test-secret_$(ENV))"

SSH_STRING=$(USER_ID)@$(VM_PREFIX)$(ENV)

ssh:
	gcloud compute ssh $(SSH_STRING) \
		--project=$(PROJECT_ID) \
		--zone=$(ZONE)

ssh-cmd:
	@gcloud compute ssh $(SSH_STRING) \
		--project=$(PROJECT_ID) \
		--zone=$(ZONE) \
		--command="$(CMD)"

build:
	docker build -t $(LOCAL_TAG) .

push:
	docker tag $(LOCAL_TAG) $(REMOTE_TAG)
	docker push $(REMOTE_TAG)

deploy:
	$(MAKE) ssh-cmd CMD='docker-credential-gcr configure-docker'
	@echo "pulling new container image..."
	$(MAKE) ssh-cmd CMD='docker pull $(REMOTE_TAG)'
	@echo "resolving old container"
	-$(MAKE) ssh-cmd CMD='docker container stop $(CONTAINER_NAME)'
	-$(MAKE) ssh-cmd CMD='docker container rm $(CONTAINER_NAME)'
	@echo "starting new container..."
	@$(MAKE) ssh-cmd CMD='\
	  docker run -d --name=$(CONTAINER_NAME) \
	    --restart=unless-stopped \
		-p 5001:5001 \
		$(REMOTE_TAG) \
		'