#!/bin/bash
# Startup script cho VM income-api: chay bang root moi lan VM khoi dong.
set -e
U=deploy
MD=http://metadata.google.internal/computeMetadata/v1/instance/attributes
id "$U" >/dev/null 2>&1 || useradd -m -s /bin/bash "$U"
mkdir -p /home/$U/src /home/$U/models
curl -sf -H Metadata-Flavor:Google $MD/serve-py > /home/$U/src/serve.py
BUCKET=$(curl -sf -H Metadata-Flavor:Google $MD/artifact-bucket)

if [ ! -f /opt/income-venv/.ok ]; then
  apt-get update -y
  apt-get install -y python3-pip python3-venv curl
  python3 -m venv /opt/income-venv
  /opt/income-venv/bin/pip install --no-cache-dir \
    fastapi==0.111.0 uvicorn==0.29.0 scikit-learn==1.4.2 pandas==2.2.2 \
    joblib==1.4.2 google-cloud-storage==2.16.0
  touch /opt/income-venv/.ok
fi
chown -R $U:$U /home/$U

# GitHub Actions (user deploy) chi duoc phep restart dung service nay
echo "$U ALL=(root) NOPASSWD: /usr/bin/systemctl restart income-api" > /etc/sudoers.d/income-deploy
chmod 440 /etc/sudoers.d/income-deploy

# Xac thuc GCS bang service account gan vao VM (khong can file sa-key.json tren VM)
cat > /etc/systemd/system/income-api.service <<EOF
[Unit]
Description=Income Model Inference Server
After=network-online.target

[Service]
User=$U
WorkingDirectory=/home/$U
Environment="ARTIFACT_BUCKET=$BUCKET"
ExecStart=/opt/income-venv/bin/python /home/$U/src/serve.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable income-api
echo "income-api setup done"
