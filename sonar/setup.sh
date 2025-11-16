#!/bin/sh

# Definir variables con valores por defecto o de entorno
SONAR_HOST="${SONAR_HOST_URL}:${SONAR_PORT}"
DEFAULT_ADMIN="admin"
DEFAULT_PASS="admin"
NEW_PASS="${SONARQUBE_ADMIN_PASSWORD}"

# Esperar a que SonarQube esté listo
echo "⏳ Esperando a que SonarQube esté listo en $SONAR_HOST..."
until curl -s -u "${DEFAULT_ADMIN}:${DEFAULT_PASS}" "$SONAR_HOST/api/system/status" | grep -q "\"status\":\"UP\""; do
  echo "⌛ SonarQube no está listo aún..."
  sleep 5
done

# Cambiar contraseña
echo "🔒 Cambiando contraseña..."
curl -u "${DEFAULT_ADMIN}:${DEFAULT_PASS}" \
  -X POST "$SONAR_HOST/api/users/change_password" \
  -d "login=${DEFAULT_ADMIN}" \
  -d "previousPassword=${DEFAULT_PASS}" \
  -d "password=${NEW_PASS}" \
  > /dev/null 2>&1

echo "✅ Contraseña de admin cambiada"
