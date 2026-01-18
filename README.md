# How to build native multi-platform images using Google Cloud Build

## The problem and the solution

When the docker image needs to run on a different platform, there are two options:
1. Use the emulation provided by docker
2. Use native image

Option 1 is the easiest solution, but it's error-prone and slow. This is not good especially if you need to use it in a production environment or as a part of your workflow to achieve your goals. This leaves option 2 as the only solution.

## GCP Cloud Build limitations

At this point, Cloud Build doesn't support native multi-platform builds. Cloud Build uses amd64 machines to execute the build. This means that if a multi-platform build is required by default, Cloud Build will use the emulation provided by docker. As before, this is error-prone and slow. Compiling the PHP swoole extension in a multi-platform image was almost 10 times slower than just compiling it in an amd64 image.

## What is required to build native multi-platform images

A node for each platform that will be supported by the docker image is required. The docker client must be configured to use a builder that can use all these nodes. This means that the builder must have SSH access to all nodes, and the client (if not on the same machine as the builder) must have access to the builder.

In general, the configuration is as follows:

1. Create docker context for each node using a command like this `docker context create ${CONTEXT} --docker "host=ssh://${USER}@${HOST}:${PORT}"`
2. Configure the builder to use all these nodes with something similar to
```bash
docker buildx create --name ${BUILDER}
docker buildx create --append --name ${BUILDER} ${CONTEXT}
```
All contexts must be added to the builder. If your docker client is on the docker server, then there is already context (most probably named `default`) that you can directy add to the builder. Use `docker contextls ls` to list all contexts and `docker buildx ls` to list all builders.

## GCP setup

This example uses arm64 VM on GCP and builds docker images for amd64 and arm64 platforms. To extend it, you need to add more nodes (even as bare metal machines or VMs hosted somewhere else) and configure them so Cloud Build can access them using SSH.

Cloud Build already supports the amd64 platform natively, so only a node for the arm64 platform is required. The node will not be opened to be accessed from the Internet for security reasons. For this reason the Identity-Aware Proxy (IAP) is used without any private IP address knowledge.

You can find the GCP configuration in the `terraform` directory. In general, it requires the following:

1. The VM must have access to the Internet to download all required packages
2. The VM must have docker installed
3. The SSH user must have permission to use `docker` and to be authenticated to any docker registry that is required. In this example the service account used by the VM has access to the Artifact Registry.
4. The SSH user must be configured to use SSH keys

### Node configuration (VM)

The Internet access is provided by using a router.
The machine itself is configured using a startup script that will:

1. Install docker
2. Create the `builder` user
3. Authenticate the `builder` user to the Artifact Registry
4. Configure the SSH keys for the `builder` user - this is done by using a secret. If Terraform is not used to manage the configuration `gcloud secrets` can be used to get the public SSH key (the VM service account must have `roles/secretmanager.secretAccessor`).

### Cloud Build configuration

If Cloud Build can access the node using IP address then the normal `docker` container provided by the Cloud Build team can be used and configuration related to `gcloud compute start-iap-tunnel` can be omitted.

#### Docker image with gcloud, docker and SSH

Cloud Build doesn't provide an image with `gcloud`, `docker` and `SSH`. They provided images for docker and gcloud separately but not together. Because IAP is used to access the node, an image with gcloud, docker and SSH is required. The `docker/Dockerfile` is used to build an image that has gcloud, docker and SSH.

Because IAP is used to access the node the SSH is configured to use `gcloud compute start-iap-tunnel` as a proxy in `docker/ssh.config`. If IAP is not used remove the `ProxyCommand` line from the SSH config and the image can be based on any docker image that works with Cloud Build.

The `docker/docker-wrapper.sh` script must be modified to configure docker with all required nodes. The script configures docker only once for each build, because this is enough, however, the SSH private key must be configured in every step. This means that the private key secret must be provided to each step.

For the example the image built custom docker image will be called `{DOCKER-REGISTRY}/gcloud-docker-ssh:latest`

#### Cloud Build step

Converting the build steps to use the multi-platform image build is straightforward. The following is a simple trigger to build a single platform image:

```yaml
steps:

  - id: "Build image"
    name: 'gcr.io/cloud-builders/docker'
    args:
      - 'build'
      - '-f'
      - 'my-image.Dockerfile'
      - '-t'
      - '$_DOCKER_IMAGE_REPO/my-image:latest'
      - '.'

images:
  - '$_DOCKER_IMAGE_REPO/my-image:latest'
```

To build a multi-platform image use the emulation provided by docker the step changes to use `buildx`:

```yaml
steps:
  - id: "Create docker buildx builder"
    name: 'gcr.io/cloud-builders/docker'
    args:
      - 'buildx'
      - 'create'
      - '--driver'
      - 'docker-container'
      - '--use'
      - '--name'
      - 'multi-platform'

  - id: "Build image"
    name: 'gcr.io/cloud-builders/docker'
    args:
      - 'buildx'
      - 'build'
      - '-f'
      - 'my-image.Dockerfile'
      - '-t'
      - '$_DOCKER_IMAGE_REPO/my-image:latest'
      - '--platform'
      - 'linux/amd64,linux/arm64'
      - '--push'
      - '.'
```

The changes here are to use `buildx`, to specfy the platforms the image must be built for and directly push the image to the registry. Multi-platform images can't be stored in the local Docker daemon's image store, These images are in the BuildKit container's internal cache, so `docker push` and `images:` will not work.

And now the easy part – switch to native multi-platform builds we just need to use the custom docker image

```yaml
steps:

  - id: "Build image"
    name: '{DOCKER-REGISTRY}/gcloud-docker-ssh:latest'
    secretEnv: ['SSH_PRIVATE_KEY']
    args:
      - 'buildx'
      - 'build'
      - '-f'
      - 'my-image.Dockerfile'
      - '-t'
      - '$_DOCKER_IMAGE_REPO/my-image:latest'
      - '--platform'
      - 'linux/amd64,linux/arm64'
      - '--push'
      - '.'

availableSecrets:
  secretManager:
    - versionName: 'projects/{SECRET_PROJECT_ID}/secrets/VM_SSH_PRIVATE_KEY/versions/1'
      env: 'SSH_PRIVATE_KEY'
```