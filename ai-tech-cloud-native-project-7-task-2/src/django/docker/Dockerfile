FROM python:3.10

ENV PYTHONUNBUFFERED=1

# Allows docker to cache installed dependencies between builds
COPY requirements.txt requirements.txt
RUN  apt-get update && apt-get install -y python3-dev default-libmysqlclient-dev build-essential pkg-config && pip install --no-cache-dir -r requirements.txt

# Mounts the application code to the image
# Includes the sqlite file (Will update in P5)
COPY . code
WORKDIR /code


# runs the production server
CMD ["opentelemetry-instrument", "--service_name", "login", "--metrics_exporter", "otlp,console", "--exporter_otlp_endpoint", "http://simplest-collector:4317", "python", "manage.py", "runserver", "0.0.0.0:8080", "--noreload"]
