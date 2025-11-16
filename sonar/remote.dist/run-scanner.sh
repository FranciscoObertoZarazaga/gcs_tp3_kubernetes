#!/bin/sh

echo "📢 Iniciando análisis del proyecto en $(pwd)"

# Esperar a que SonarQube esté listo
echo "⏳ Esperando a que SonarQube esté listo..."
until curl -s -u "${SONAR_TOKEN}:" "${SONAR_HOST}/api/system/status" | grep -q "\"status\":\"UP\""; do
  echo "⌛ SonarQube no está listo aún..."
  sleep 5
done

echo "🚀 Iniciando SonarScanner..."
sonar-scanner \
  -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
  -Dsonar.sources=. \
  -Dsonar.host.url=${SONAR_HOST} \
  -Dsonar.token=${SONAR_TOKEN} \
  -Dproject.settings=/sonar-project.properties \
  -Dsonar.working.directory=/tmp/sonarwork \
  -Dsonar.projectBaseDir=. \
  || exit 1

# Verificar Quality Gate
echo "⏳ Verificando Quality Gate..."
sleep 10  # Ajustar si SonarQube está muy cargado

RESPONSE=$(curl -s -u "${SONAR_TOKEN}:" "${SONAR_HOST}/api/qualitygates/project_status?projectKey=${SONAR_PROJECT_KEY}&branch=${BRANCH_NAME}")

echo "📜 Respuesta completa del Quality Gate:"
echo "$RESPONSE"

STATUS=$(echo "$RESPONSE" | grep -o '"status":"[^"]*"' | head -1 | cut -d':' -f2 | tr -d '"')

echo "Quality Gate Status: $STATUS"
if [ "$STATUS" != "OK" ]; then
  echo "❌ Quality Gate fallido."
  exit 1
fi

echo "✅ Análisis finalizado con éxito y Quality Gate aprobado."
