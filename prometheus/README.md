# Prometheus integration


The application is integrated with Prometheus and Grafana to provide metrics observability.
Currently, it is set up to collect metrics from all services, databases and NATS.

### Folder Organization

The `./prometheus` folder is organized as follows:

- `postgresExporter`: Settings related to the PostgresSQL metrics exporter that allow Prometheus to scrape the database metrics
- `redisExporter`: Settings related to the PostgresSQL metrics exporter that allow Prometheus to scrape the database metrics
- `timescaledbExporter`: Settings related to the PostgresSQL metrics exporter that allow Prometheus to scrape the database metrics
- `prometheus.yml`: Prometheus scrape targets configuration

Notes:
- The microservices, ArangoDB and NATS provide endpoints for Prometheus to scrape metrics directly and thus they do not need exporters.
- Since Micro automatically manages the K8s objects for the microservices,
exposing the metrics ports to Prometheus is done by patching the Micro created K8s services via service patches. 
The patches can be found under `cicd/K8s/microservicesPatch`
- The microservices integration with Prometheus was made in two parts: 
    - `globalMonitoring/prometheus` provides wrapper definitions common to all services
    - `<serviceName>/server/monitoring` integrates the wrappers as middleware in the microservice