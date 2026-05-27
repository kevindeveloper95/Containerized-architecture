#!/bin/bash
set -euo pipefail
exec > /var/log/user-data-docker.log 2>&1

APP_BASE="${app_base_dir}"
AWS_REGION="${aws_region}"
IMAGE_TAG="${docker_image_tag}"

echo "=== Ritual Roast EC2 bootstrap (Docker + ECR) ==="

# La VPC suele ser solo IPv4; curl intenta IPv6 primero y puede retrasar/fallar al arranque.
wait_for_network() {
  local attempt=1
  while [ "$attempt" -le 30 ]; do
    if curl -4 -fsSL --connect-timeout 5 --max-time 15 https://github.com -o /dev/null 2>/dev/null; then
      echo "Network ready (attempt $${attempt})"
      return 0
    fi
    echo "Waiting for outbound network (attempt $${attempt}/30)..."
    sleep 10
    attempt=$((attempt + 1))
  done
  echo "ERROR: outbound network not available after 5 minutes"
  exit 1
}
wait_for_network

echo "Installing packages (Docker, unzip)..."
# AL2023 ya trae curl-minimal; instalar el paquete "curl" completo provoca conflicto con dnf.
dnf install -y docker unzip

systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user
docker --version

install_aws_cli() {
  if command -v aws >/dev/null 2>&1; then
    aws --version
    return 0
  fi
  echo "Installing AWS CLI v2..."
  curl -4 -fsSL --connect-timeout 30 --max-time 600 "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
  unzip -qo /tmp/awscliv2.zip -d /tmp
  /tmp/aws/install
  aws --version
}

ecr_login() {
  local registry="$1"
  echo "Connecting to ECR registry: $${registry}"
  aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$registry"
}

patch_flask_app_py() {
  local build_dir="${app_base_dir}/${backend_dir_name}"
  local app_py="$${build_dir}/app.py"

  if [ ! -f "$app_py" ]; then
    echo "ERROR: app.py not found in $build_dir"
    exit 1
  fi

  echo "Patching app.py: region=${aws_region}, SecretId=${mysql_secret_id}"
  sed -i "s/INSERT-REGION-HERE/${aws_region}/g" "$app_py"
  sed -i "s/YOUR-SECRET-ID/${mysql_secret_id}/g" "$app_py"
  grep -E 'region_name|SecretId' "$app_py" || true
}

build_and_push_to_ecr() {
  local project_dir="$1"
  local ecr_image_uri="$2"

  local build_dir="$${APP_BASE}/$${project_dir}"
  if [ ! -d "$build_dir" ]; then
    echo "ERROR: Directory not found: $build_dir"
    exit 1
  fi
  if [ ! -f "$${build_dir}/Dockerfile" ]; then
    echo "ERROR: Dockerfile not found in $${build_dir}"
    exit 1
  fi

  echo "--- docker build -t $${ecr_image_uri} ($${build_dir}) ---"
  cd "$build_dir"
  docker build -t "$${ecr_image_uri}" .

  echo "--- docker push $${ecr_image_uri} ---"
  docker push "$${ecr_image_uri}"
  echo "OK: image published to ECR: $${ecr_image_uri}"
}

download_and_extract_zip() {
  local zip_url="$1"
  local target_dir="$2"
  local tmp_zip="/tmp/$${target_dir}.zip"

  echo "Downloading $${target_dir} from $${zip_url} ..."
  if ! curl -4 -fsSL --connect-timeout 30 --max-time 600 -o "$tmp_zip" "$zip_url"; then
    echo "ERROR: curl failed downloading $${target_dir} (exit $?)"
    exit 1
  fi
  if [ ! -s "$tmp_zip" ]; then
    echo "ERROR: downloaded ZIP is empty for $${target_dir}"
    exit 1
  fi
  echo "Downloaded $${target_dir} ($(wc -c < "$tmp_zip") bytes)"

  local top_dir
  top_dir=$(unzip -Z -1 "$tmp_zip" | head -1 | cut -d/ -f1)

  rm -rf "$${APP_BASE}/$${target_dir}"
  unzip -qo "$tmp_zip" -d "$${APP_BASE}"

  if [ -d "$${APP_BASE}/$${top_dir}" ] && [ "$top_dir" != "$target_dir" ]; then
    mv "$${APP_BASE}/$${top_dir}" "$${APP_BASE}/$${target_dir}"
  elif [ ! -d "$${APP_BASE}/$${target_dir}" ]; then
    mkdir -p "$${APP_BASE}/$${target_dir}"
    unzip -qo "$tmp_zip" -d "$${APP_BASE}/$${target_dir}"
  fi

  rm -f "$tmp_zip"
  chown -R ec2-user:ec2-user "$${APP_BASE}/$${target_dir}"
  echo "Extracted: $${APP_BASE}/$${target_dir}"
}

mkdir -p "$APP_BASE"
chown ec2-user:ec2-user "$APP_BASE"

# 1) Download and extract project ZIPs (each folder must contain a Dockerfile)
%{ if frontend_zip_url != "" }
download_and_extract_zip "${frontend_zip_url}" "${frontend_dir_name}"
%{ endif }

%{ if backend_zip_url != "" }
download_and_extract_zip "${backend_zip_url}" "${backend_dir_name}"
%{ endif }

# 2) ECR login, docker build, docker push (frontend + backend repositories)
%{ if build_and_push_ecr_images }
echo "=== ECR: build and push images (tag: ${docker_image_tag}) ==="
install_aws_cli
export AWS_DEFAULT_REGION="$AWS_REGION"

ecr_login "${ecr_registry}"

%{ if backend_ecr_image_uri != "" && backend_zip_url != "" }
echo "Backend ECR repository: ${backend_ecr_image_uri}"
%{ if mysql_secret_id != "" }
patch_flask_app_py
%{ endif }
build_and_push_to_ecr "${backend_dir_name}" "${backend_ecr_image_uri}"
%{ endif }

%{ if frontend_ecr_image_uri != "" && frontend_zip_url != "" }
echo "Frontend ECR repository: ${frontend_ecr_image_uri}"
build_and_push_to_ecr "${frontend_dir_name}" "${frontend_ecr_image_uri}"
%{ endif }
%{ endif }

%{ if install_ecs_agent }
echo "Installing ECS agent (ecs-init)..."
dnf install -y ecs-init
systemctl enable ecs
%{ if ecs_cluster_name != "" }
mkdir -p /etc/ecs
echo "ECS_CLUSTER=${ecs_cluster_name}" > /etc/ecs/ecs.config
%{ endif }
systemctl start ecs
%{ endif }

echo "=== User-data completed successfully ==="
