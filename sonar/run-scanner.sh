#!/bin/sh

echo "📢 Iniciando análisis de todos los proyectos en /projects"

# Crear directorio seguro para logs
LOG_DIR="/tmp/logs"
mkdir -p "$LOG_DIR"

PIDS=()

for project_dir in /projects/*; do
  if [ -d "$project_dir" ]; then
    echo "📁 Procesando proyecto: $project_dir"

    # Cargar .env del proyecto línea por línea
    if [ -f "$project_dir/.env" ]; then
      while IFS='=' read -r key value; do
        if [ -n "$key" ] && [ -n "$value" ]; then
          export "$key"="$value"
        fi
      done < "$project_dir/.env"
    else
      echo "⚠️ No se encontró $project_dir/.env"
    fi

    echo "⏳ Esperando a que SonarQube esté listo..."
    until curl -s -u "${SONAR_TOKEN}:" "http://sonarqube:${SONAR_PORT}/api/system/status" | grep -q "\"status\":\"UP\""; do
      echo "⌛ SonarQube no está listo aún..."
      sleep 5
    done

    SRC_DIR="$project_dir/src"
    if [ ! -d "$SRC_DIR" ]; then
      echo "❌ ERROR: No se encontró $SRC_DIR"
      continue
    fi

    # Log seguro en /tmp/logs
    LOG_FILE="$LOG_DIR/$(basename $project_dir)_scan.log"
    echo "🚀 Iniciando SonarScanner para $(basename $project_dir). Log: $LOG_FILE"

    (
      sonar-scanner \
        -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
        -Dsonar.sources=. \
        -Dsonar.host.url=http://sonarqube:${SONAR_PORT} \
        -Dsonar.token=${SONAR_TOKEN} \
        -Dproject.settings=$project_dir/sonar-project.properties \
        -Dsonar.working.directory=/tmp/sonarwork_$(basename $project_dir) \
        -Dsonar.projectBaseDir=$SRC_DIR \
        > "$LOG_FILE" 2>&1
      echo "✅ SonarScanner para $(basename $project_dir) finalizado."
    ) &
    PIDS+=($!)
  fi
done

for pid in "${PIDS[@]}"; do
  wait "$pid"
done

echo "🎉 Todos los proyectos han sido analizados"
