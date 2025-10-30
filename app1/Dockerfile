FROM python:3.11-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    APP_HOME=/app

RUN useradd --create-home --shell /bin/bash appuser

WORKDIR $APP_HOME
COPY requirements.txt .

RUN pip install -r requirements.txt

COPY ./src .

RUN chown -R appuser:appuser $APP_HOME

USER appuser

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]