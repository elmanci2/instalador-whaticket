#!/bin/bash

# Colores para output
WHITE='\033[1;37m'
GRAY_LIGHT='\033[0;37m'
NC='\033[0m' # No Color

#######################################
# Configurar usuario actual para deployment
# Sin preguntas interactivas
#######################################
setup_current_user() {
  printf "${WHITE} 💻 Configurando usuario actual para deployment...${GRAY_LIGHT}"
  printf "\n\n"

  # Obtener usuario actual
  CURRENT_USER=$(whoami)
  echo "Usuario actual: $CURRENT_USER"
  
  # Agregar usuario al grupo docker
  usermod -aG docker $CURRENT_USER
  
  # Crear directorio para la aplicación si no existe
  APP_DIR="/home/$CURRENT_USER"
  if [[ $CURRENT_USER == "root" ]]; then
    APP_DIR="/root"
  fi
  
  echo "Directorio de trabajo: $APP_DIR"
  
  # Asegurar permisos correctos
  if [[ $CURRENT_USER != "root" ]]; then
    chown -R $CURRENT_USER:$CURRENT_USER $APP_DIR
  fi
  
  echo "Usuario $CURRENT_USER configurado exitosamente"
}

#######################################
# Crear Redis y PostgreSQL
# Usa valores por defecto
#######################################
backend_redis_create_current_user() {
  printf "${WHITE} 💻 Criando Redis & Banco Postgres...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2
  
  # Obtener usuario actual
  DEPLOY_USER=$(whoami)
  
  # Valores por defecto
  instancia_add="app01"
  redis_port="6379"
  mysql_root_password="123456"

  # Crear Redis usando el usuario actual
  usermod -aG docker $DEPLOY_USER
  docker run --name redis-${instancia_add} -p ${redis_port}:6379 --restart always --detach redis redis-server --requirepass ${mysql_root_password}
  
  sleep 2
  
  # Crear base de datos PostgreSQL
  sudo su - postgres << EOF
  createdb ${instancia_add};
  psql -c "CREATE USER ${instancia_add} SUPERUSER INHERIT CREATEDB CREATEROLE;"
  psql -c "ALTER USER ${instancia_add} PASSWORD '${mysql_root_password}';"
EOF

  sleep 2
  echo "Redis y PostgreSQL configurados para usuario: $DEPLOY_USER"
}

#######################################
# Configurar variables de ambiente
# Usa valores por defecto
#######################################
backend_set_env_current_user() {
  printf "${WHITE} 💻 Configurando variáveis de ambiente...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2
  
  # Obtener usuario actual
  DEPLOY_USER=$(whoami)
  if [[ $DEPLOY_USER == "root" ]]; then
    DEPLOY_DIR="/root"
  else
    DEPLOY_DIR="/home/$DEPLOY_USER"
  fi

  # Valores por defecto
  backend_url="https://api.example.com"
  frontend_url="https://app.example.com"
  backend_port="3000"
  instancia_add="app01"
  jwt_secret="jwt_secret_123"
  jwt_refresh_secret="jwt_refresh_secret_123"
  redis_port="6379"
  mysql_root_password="123456"
  max_user="10"
  max_whats="5"

  # Crear directorio si no existe
  mkdir -p ${DEPLOY_DIR}/${instancia_add}/backend
  
  # Crear archivo .env
  cat > ${DEPLOY_DIR}/${instancia_add}/backend/.env << EOF
NODE_ENV=
BACKEND_URL=${backend_url}
FRONTEND_URL=${frontend_url}
PROXY_PORT=443
PORT=${backend_port}

DB_HOST=localhost
DB_DIALECT=postgres
DB_USER=${instancia_add}
DB_PASS=${mysql_root_password}
DB_NAME=${instancia_add}
DB_PORT=5432

JWT_SECRET=${jwt_secret}
JWT_REFRESH_SECRET=${jwt_refresh_secret}

REDIS_URI=redis://:${mysql_root_password}@127.0.0.1:${redis_port}
REDIS_OPT_LIMITER_MAX=1
REGIS_OPT_LIMITER_DURATION=3000

USER_LIMIT=${max_user}
CONNECTIONS_LIMIT=${max_whats}
CLOSED_SEND_BY_ME=true

GERENCIANET_SANDBOX=false
GERENCIANET_CLIENT_ID=sua-id
GERENCIANET_CLIENT_SECRET=sua_chave_secreta
GERENCIANET_PIX_CERT=nome_do_certificado
GERENCIANET_PIX_KEY=chave_pix_gerencianet
EOF

  # Ajustar permisos
  chown -R $DEPLOY_USER:$DEPLOY_USER ${DEPLOY_DIR}/${instancia_add}
  
  echo "Variables de ambiente configuradas en: ${DEPLOY_DIR}/${instancia_add}/backend/.env"
  sleep 2
}

#######################################
# Instalar dependencias del backend
#######################################
backend_node_dependencies_current_user() {
  printf "${WHITE} 💻 Instalando dependências do backend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2
  
  DEPLOY_USER=$(whoami)
  if [[ $DEPLOY_USER == "root" ]]; then
    DEPLOY_DIR="/root"
  else
    DEPLOY_DIR="/home/$DEPLOY_USER"
  fi
  
  instancia_add="app01"

  cd ${DEPLOY_DIR}/${instancia_add}/backend
  npm install

  sleep 2
}

#######################################
# Compilar código del backend
#######################################
backend_node_build_current_user() {
  printf "${WHITE} 💻 Compilando o código do backend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2
  
  DEPLOY_USER=$(whoami)
  if [[ $DEPLOY_USER == "root" ]]; then
    DEPLOY_DIR="/root"
  else
    DEPLOY_DIR="/home/$DEPLOY_USER"
  fi
  
  instancia_add="app01"

  cd ${DEPLOY_DIR}/${instancia_add}/backend
  npm run build

  sleep 2
}

#######################################
# Instalar dependencias del frontend
#######################################
frontend_node_dependencies_current_user() {
  printf "${WHITE} 💻 Instalando dependências do frontend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2
  
  DEPLOY_USER=$(whoami)
  if [[ $DEPLOY_USER == "root" ]]; then
    DEPLOY_DIR="/root"
  else
    DEPLOY_DIR="/home/$DEPLOY_USER"
  fi
  
  instancia_add="app01"

  cd ${DEPLOY_DIR}/${instancia_add}/frontend
  npm install

  sleep 2
}

#######################################
# Compilar código del frontend
#######################################
frontend_node_build_current_user() {
  printf "${WHITE} 💻 Compilando o código do frontend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2
  
  DEPLOY_USER=$(whoami)
  if [[ $DEPLOY_USER == "root" ]]; then
    DEPLOY_DIR="/root"
  else
    DEPLOY_DIR="/home/$DEPLOY_USER"
  fi
  
  instancia_add="app01"

  cd ${DEPLOY_DIR}/${instancia_add}/frontend
  npm run build

  sleep 2
}

#######################################
# Configurar variables de ambiente del frontend
#######################################
frontend_set_env_current_user() {
  printf "${WHITE} 💻 Configurando variáveis de ambiente (frontend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2
  
  DEPLOY_USER=$(whoami)
  if [[ $DEPLOY_USER == "root" ]]; then
    DEPLOY_DIR="/root"
  else
    DEPLOY_DIR="/home/$DEPLOY_USER"
  fi

  # Valores por defecto
  backend_url="https://api.example.com"
  frontend_port="3001"
  instancia_add="app01"

  # Crear directorio si no existe
  mkdir -p ${DEPLOY_DIR}/${instancia_add}/frontend
  
  # Crear archivo .env para frontend
  cat > ${DEPLOY_DIR}/${instancia_add}/frontend/.env << EOF
REACT_APP_BACKEND_URL=${backend_url}
REACT_APP_HOURS_CLOSE_TICKETS_AUTO = 24
EOF

  # Crear server.js para production
  cat > ${DEPLOY_DIR}/${instancia_add}/frontend/server.js << EOF
//simple express server to run frontend production build;
const express = require("express");
const path = require("path");
const app = express();
app.use(express.static(path.join(__dirname, "build")));
app.get("/*", function (req, res) {
	res.sendFile(path.join(__dirname, "build", "index.html"));
});
app.listen(${frontend_port});
EOF

  # Ajustar permisos
  chown -R $DEPLOY_USER:$DEPLOY_USER ${DEPLOY_DIR}/${instancia_add}
  
  echo "Variables de ambiente del frontend configuradas"
  sleep 2
}

#######################################
# Iniciar PM2 para frontend
#######################################
frontend_start_pm2_current_user() {
  printf "${WHITE} 💻 Iniciando pm2 (frontend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2
  
  DEPLOY_USER=$(whoami)
  if [[ $DEPLOY_USER == "root" ]]; then
    DEPLOY_DIR="/root"
  else
    DEPLOY_DIR="/home/$DEPLOY_USER"
  fi
  
  instancia_add="app01"

  cd ${DEPLOY_DIR}/${instancia_add}/frontend
  pm2 start server.js --name ${instancia_add}-frontend
  pm2 save

  # Configurar PM2 startup
  pm2 startup
  env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u $DEPLOY_USER --hp ${DEPLOY_DIR}

  sleep 2
}

#######################################
# Configurar nginx para frontend
#######################################
frontend_nginx_setup_current_user() {
  printf "${WHITE} 💻 Configurando nginx (frontend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2
  
  # Valores por defecto
  frontend_url="https://app.example.com"
  frontend_port="3001"
  instancia_add="app01"
  
  frontend_hostname=$(echo "${frontend_url/https:\/\/}")

  cat > /etc/nginx/sites-available/${instancia_add}-frontend << EOF
server {
  server_name $frontend_hostname;
  location / {
    proxy_pass http://127.0.0.1:${frontend_port};
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_cache_bypass \$http_upgrade;
  }
}
EOF

  ln -s /etc/nginx/sites-available/${instancia_add}-frontend /etc/nginx/sites-enabled
  
  echo "Nginx configurado para frontend"
  sleep 2
}

#######################################
# Actualizar sistema
#######################################
system_update_current_user() {
  printf "${WHITE} 💻 Actualizando sistema...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  apt -y update
  apt-get install -y libxshmfence-dev libgbm-dev wget unzip fontconfig locales gconf-service libasound2 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 ca-certificates fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils

  sleep 2
}

#######################################
# Clonar repositorio
#######################################
system_git_clone_current_user() {
  printf "${WHITE} 💻 Clonando repositorio...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2
  
  DEPLOY_USER=$(whoami)
  if [[ $DEPLOY_USER == "root" ]]; then
    DEPLOY_DIR="/root"
  else
    DEPLOY_DIR="/home/$DEPLOY_USER"
  fi
  
  # Valores por defecto
  link_git="https://github.com/equipechat/equipechat.git"
  instancia_add="app01"

  git clone ${link_git} ${DEPLOY_DIR}/${instancia_add}/

  sleep 2
}

#######################################
# Instalar Node.js
#######################################
system_node_install_current_user() {
  printf "${WHITE} 💻 Instalando nodejs...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
  apt-get install -y nodejs
  sleep 2
  npm install -g npm@latest
  sleep 2
  sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
  apt-get update -y && apt-get -y install postgresql
  sleep 2
  timedatectl set-timezone America/Sao_Paulo

  sleep 2
}

#######################################
# Instalar Docker
#######################################
system_docker_install_current_user() {
  printf "${WHITE} 💻 Instalando docker...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  apt install -y apt-transport-https ca-certificates curl software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
  apt install -y docker-ce

  sleep 2
}

#######################################
# Instalar PM2
#######################################
system_pm2_install_current_user() {
  printf "${WHITE} 💻 Instalando pm2...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  npm install -g pm2

  sleep 2
}

#######################################
# Instalar Nginx
#######################################
system_nginx_install_current_user() {
  printf "${WHITE} 💻 Instalando nginx...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  apt install -y nginx
  rm -f /etc/nginx/sites-enabled/default

  sleep 2
}

#######################################
# Instalar Certbot
#######################################
system_certbot_install_current_user() {
  printf "${WHITE} 💻 Instalando certbot...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  apt install -y snapd
  snap install core
  snap refresh core
  apt-get remove -y certbot
  snap install --classic certbot
  ln -sf /snap/bin/certbot /usr/bin/certbot

  sleep 2
}

#######################################
# Configurar Nginx
#######################################
system_nginx_conf_current_user() {
  printf "${WHITE} 💻 Configurando nginx...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  cat > /etc/nginx/conf.d/deploy.conf << 'EOF'
client_max_body_size 100M;
EOF

  sleep 2
}

#######################################
# Reiniciar Nginx
#######################################
system_nginx_restart_current_user() {
  printf "${WHITE} 💻 Reiniciando nginx...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  systemctl restart nginx

  sleep 2
}

#######################################
# Configurar Certbot
#######################################
system_certbot_setup_current_user() {
  printf "${WHITE} 💻 Configurando certbot...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  # Valores por defecto
  backend_url="https://api.example.com"
  frontend_url="https://app.example.com"
  deploy_email="admin@example.com"

  backend_domain=$(echo "${backend_url/https:\/\/}")
  frontend_domain=$(echo "${frontend_url/https:\/\/}")

  certbot -m $deploy_email \
          --nginx \
          --agree-tos \
          --non-interactive \
          --domains $backend_domain,$frontend_domain

  sleep 2
}

# Verificar que se ejecute como root
if [[ $EUID -ne 0 ]]; then
   echo "Este script debe ejecutarse como root (sudo)" 
   exit 1
fi

# Ejecutar todo automáticamente
echo "=== Iniciando instalación completa ==="
system_update_current_user
system_node_install_current_user
system_pm2_install_current_user
system_docker_install_current_user
system_nginx_install_current_user
system_certbot_install_current_user
setup_current_user
system_git_clone_current_user
backend_redis_create_current_user
backend_set_env_current_user
backend_node_dependencies_current_user
backend_node_build_current_user
frontend_set_env_current_user
frontend_node_dependencies_current_user
frontend_node_build_current_user
frontend_start_pm2_current_user
frontend_nginx_setup_current_user
system_nginx_conf_current_user
system_nginx_restart_current_user
system_certbot_setup_current_user

echo "=== Configuración completada ==="
echo "Usuario configurado: $(whoami)"
echo "Directorio de aplicación: $(if [[ $(whoami) == "root" ]]; then echo "/root/app01"; else echo "/home/$(whoami)/app01"; fi)"
echo "Backend configurado en puerto 3000"
echo "Frontend configurado en puerto 3001"
echo "URLs configuradas:"
echo "  - Backend: https://api.example.com"
echo "  - Frontend: https://app.example.com"
