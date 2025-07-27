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

# Verificar que se ejecute como root
if [[ $EUID -ne 0 ]]; then
   echo "Este script debe ejecutarse como root (sudo)" 
   exit 1
fi

# Ejecutar todo automáticamente
setup_current_user
backend_redis_create_current_user
backend_set_env_current_user
backend_node_dependencies_current_user
backend_node_build_current_user

echo "=== Configuración completada ==="
echo "Usuario configurado: $(whoami)"
echo "Directorio de aplicación: $(if [[ $(whoami) == "root" ]]; then echo "/root/app01"; else echo "/home/$(whoami)/app01"; fi)"
