package main

import (
	//"github.com/micro/go-micro/v2/server"
	"github.com/micro/micro/v3/service/server"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"goTempM/globalMonitoring"
	"net/http"
)

const (
	// serviceId numeric service identifier
	serviceId = "3"
	// serviceMetricsPrefix prefix for all metrics related to this service
	serviceMetricsPrefix = "goTemp_"
	// metricsEndPoint is the address where we can scrape metrics
	metricsEndPoint = "/metrics"
	//httpPort is the port where the http server for metrics is listening
	httpPort = ":2113"
)

// runHttp runs a secondary server to handle metrics scraping
func runHttp() {
	http.Handle(metricsEndPoint, promhttp.Handler())
	http.ListenAndServe(httpPort, nil)
}

//newMetricsWrapper Create a new metrics wrapper to configure the data to be scraped for monitoring
func newMetricsWrapper() server.HandlerWrapper {
	// TODO: get version number from external source
	return globalMonitoring.NewMetricsWrapper(
		globalMonitoring.ServiceName(serviceName),
		globalMonitoring.ServiceID(serviceId),
		globalMonitoring.ServiceVersion("latest"),
		globalMonitoring.ServiceMetricsPrefix(serviceMetricsPrefix),
		globalMonitoring.ServiceMetricsLabelPrefix(serviceMetricsPrefix),
	)
}
