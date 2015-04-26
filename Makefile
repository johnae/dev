CUR_DIR                := $(shell pwd)
PROJECT_NAME           := $(shell basename ${CUR_DIR})
GIT_BRANCH             := $(shell git symbolic-ref --short HEAD)
GIT_SHORT_SHA          := $(shell git rev-parse --short ${GIT_BRANCH})
DOCKER_IMAGE_NAME      := johnae/dev
DOCKER_BRANCH          := $(shell echo -n ${GIT_BRANCH} | sed 's/\//_/g' | sed 's/[!?\#]//g')
# just using latest here
#DOCKER_TAG             := ${DOCKER_BRANCH}-${GIT_SHORT_SHA}
#DOCKER_FULL_IMAGE_NAME := ${DOCKER_IMAGE_NAME}:${DOCKER_TAG}
DOCKER_FULL_IMAGE_NAME := ${DOCKER_IMAGE_NAME}
BUCKET_PSEUDO_DIR := $(shell openssl rand -hex 32)
S3_ENCRYPTION_KEY := $(shell openssl rand -hex 32)

.PHONY: clean check-env

all: build

check-env: exists-id_rsa exists-authorized_keys guard-TMP_BUCKET guard-AWS_ACCESS_KEY_ID guard-AWS_SECRET_ACCESS_KEY guard-AWS_REGION guard-SSH_KEY_PASS

guard-%:
	@ if test "${${*}}" = ""; then \
		echo "Required variable $* not set"; \
		exit 1; \
	fi

exists-%:
	@ if ! ls ${CUR_DIR}/$* >/dev/null 2>&1; then \
		echo "File $* does not exist, please create it"; \
		exit 1; \
	fi

print-%:
	@echo $*=$($*)

process-ssh-keys: check-env
	rm -rf plain_rsa_keys* encrypted_rsa_keys*
	mkdir -p plain_rsa_keys
	mkdir -p encrypted_rsa_keys

	## we need the decrypted ssh key to clone repos from github for the build
	## it is removed from the resulting image
	openssl rsa -in id_rsa -passin "pass:${SSH_KEY_PASS}" -out plain_rsa_keys/id_rsa

	## so ssh-keygen doesn't complain
	chmod 0600 plain_rsa_keys/id_rsa
	ssh-keygen -y -f plain_rsa_keys/id_rsa > plain_rsa_keys/id_rsa.pub
	cp plain_rsa_keys/id_rsa.pub encrypted_rsa_keys/id_rsa.pub
	chmod 0644 plain_rsa_keys/id_rsa

	for RSAKEY in $$(ls id_rsa*); do \
		openssl pkcs8 -topk8 -v2 des3 -in $$RSAKEY -passin "pass:${SSH_KEY_PASS}" -out encrypted_rsa_keys/$$(basename $$RSAKEY) -passout "pass:${SSH_KEY_PASS}"; \
	done \

	cp authorized_keys plain_rsa_keys/authorized_keys
	cp authorized_keys encrypted_rsa_keys/authorized_keys

	tar czf - plain_rsa_keys | \
		gpg --symmetric --batch --yes --passphrase ${S3_ENCRYPTION_KEY} --cipher-algo AES256 | \
		./gof3r put --bucket ${TMP_BUCKET} --endpoint s3-${AWS_DEFAULT_REGION}.amazonaws.com -m x-amz-acl:public-read -m x-amz-server-side-encryption:AES256 -k ${BUCKET_PSEUDO_DIR}/plain_rsa_keys.tar.gz.enc

	tar czf - encrypted_rsa_keys | \
		gpg --symmetric --batch --yes --passphrase ${S3_ENCRYPTION_KEY} --cipher-algo AES256 | \
		./gof3r put --bucket ${TMP_BUCKET} --endpoint s3-${AWS_DEFAULT_REGION}.amazonaws.com -m x-amz-acl:public-read -m x-amz-server-side-encryption:AES256 -k ${BUCKET_PSEUDO_DIR}/encrypted_rsa_keys.tar.gz.enc

build: check-env process-ssh-keys

	cat bootstrap.sh.tmpl | \
		sed "s/TMPL_S3_ENCRYPTION_KEY/${S3_ENCRYPTION_KEY}/g" | \
		sed "s/TMPL_DOCKER_TMP_BUCKET/${TMP_BUCKET}/g" | \
		sed "s/TMPL_REGION/s3-${AWS_DEFAULT_REGION}/g" | \
		sed "s/TMPL_PSEUDO_BUCKET_DIR/${BUCKET_PSEUDO_DIR}/g" > bootstrap.sh

	chmod +x bootstrap.sh

	docker build --force-rm -t ${DOCKER_IMAGE_NAME} .

	## remove the files on S3
	./gof3r rm --endpoint s3-${AWS_DEFAULT_REGION}.amazonaws.com s3://${TMP_BUCKET}/${BUCKET_PSEUDO_DIR}/encrypted_rsa_keys.tar.gz.enc

	./gof3r rm --endpoint s3-${AWS_DEFAULT_REGION}.amazonaws.com s3://${TMP_BUCKET}/${BUCKET_PSEUDO_DIR}/plain_rsa_keys.tar.gz.enc

push:
	docker push ${DOCKER_IMAGE_NAME}:latest

build-and-push: build push

clean:
	rm -rf plain_rsa_keys* encrypted_rsa_keys*
	rm -f bootstrap.sh

clean-old-images:
	$(eval LATEST_SHA := $(shell docker images | tail -n +2 | grep "${DOCKER_IMAGE_NAME}" | grep "latest" | awk '{print $$3}'))
	@ docker images | \
		tail -n +2 | \
		grep "${DOCKER_IMAGE_NAME}" | \
		awk '{print $$3}' | \
		grep -v "${LATEST_SHA}" | \
		xargs -r docker rmi 2>/dev/null || true
