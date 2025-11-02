FROM python:3.11-slim-bookworm

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       gcc \
       libpq-dev \
       gettext \
       curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app

WORKDIR /app

RUN pip install --upgrade pip --no-cache-dir
COPY requirements.txt .
RUN pip install -r requirements.txt --no-cache-dir

ENV SECRET_KEY='build-time-fake-key'
ENV DEBUG='False'
ENV DB_HOST='build-time-fake-db-host'
ENV DB_NAME='fake'
ENV DB_USER='fake'
ENV DB_PASSWORD='fake'
ENV DB_PORT='1234'
ENV USE_MINIO='False'

COPY . .

EXPOSE 8000