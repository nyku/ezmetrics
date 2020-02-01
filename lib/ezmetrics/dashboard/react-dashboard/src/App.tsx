import React, { Component } from 'react';

import Nav from './Nav';
import Graph from './Graph';
import RequestsBlock from './RequestsBlock'
import MetricsBlock from './MetricsBlock';
import {allMetricsList, allRefreshIntervals, allTimeframes, defaultOverviewMetrics, defaultGraphMetrics} from './Constants';

interface AppProps {}

export interface AppState {
  fullscreen: Boolean;
  showNav: Boolean;
  metrics: any;
  frequency: number;
  timeframe: number;
  partition: String;
  metricsUrl: String;
  graphMetricsList: any[];
  overviewMetricsList: any[];
  timeoutFunction: any;
}

export function metricValueToLabel(value: String): String | undefined {
  const foundMetric = allMetricsList.find(metricHash => metricHash.value === value)
  if (foundMetric) {
    return foundMetric.label
  }
}

export function metricLabelToValue(label: String): String | undefined {
  const foundMetric = allMetricsList.find(metricHash => metricHash.label === label)
  if (foundMetric) {
    return foundMetric.value
  }
}


var store = require('store');

export default class App extends Component<AppProps, AppState> {

  constructor(props: AppProps) {
    super(props);
    this.state = {
      showNav:             false,
      metrics:             { simple: {}, partitioned: {} },
      timeoutFunction:     setTimeout(() => this.fetchByTimeout(), allRefreshIntervals[0].value),
      fullscreen:          store.get("fullscreen"),
      metricsUrl:          store.get("metricsUrl")          || "/dashboard/metrics/aggregate",
      frequency:           store.get("frequency")           || allRefreshIntervals[0].value,
      timeframe:           store.get("timeframe")           || allTimeframes[3].value,
      partition:           store.get("partition")           || "minute",
      overviewMetricsList: store.get("overviewMetricsList") || defaultOverviewMetrics,
      graphMetricsList:    store.get("graphMetricsList")    || defaultGraphMetrics,
    };

    this.fetchData                 = this.fetchData.bind(this)
    this.changeFrequency           = this.changeFrequency.bind(this)
    this.changeTimeframe           = this.changeTimeframe.bind(this)
    this.changeMetricsUrl          = this.changeMetricsUrl.bind(this)
    this.toggleFullscreen          = this.toggleFullscreen.bind(this)
    this.toggleNav                 = this.toggleNav.bind(this)
    this.changeOverviewMetricsList = this.changeOverviewMetricsList.bind(this)
    this.changeGraphMetricsList    = this.changeGraphMetricsList.bind(this)
  }

  componentWillUnmount(){
    this.clearTimeoutFunction()
  }

  render() {
    let metricsBlockData = Object.assign({}, this.state.metrics.simple);
    delete metricsBlockData.requests;

    const metricsBlocks = Object.entries(metricsBlockData).map(
      ([name, value]) => {
        return <MetricsBlock key={name} name={name} metrics={value}/>
      }
    )

    let graphData = null;

    let partitionedMetricsSize = Object.keys(this.state.metrics.partitioned).length

    if (partitionedMetricsSize > 0) {

      let lines = this.intersection(Object.keys(this.state.metrics.partitioned[0]), this.state.graphMetricsList.map(m => m.value))

      graphData = lines.map((line: any) => {
        return {
          id: metricValueToLabel(line),
          data: this.state.metrics.partitioned.map((hash: any) => {
            return {
              x: this.formatTimestamp(hash.timestamp),
              y: hash[line]
              }
            }
          ).filter((hash: any) => typeof(hash.y) === "number")
        }
      });
    }

    return (
      <div className="App">
        <div className={this.state.fullscreen ? "container-fluid" : "container"}>
          <nav className="navbar navbar-light bg-light rounded">
            <span className="navbar-brand">Ezmetrics | Dashboard</span>
            <div className="col"><button className="btn btn-outline-secondary fullscreen" onClick={this.toggleFullscreen}>↹</button></div>
            <button onClick={this.toggleNav} className="btn btn-outline-secondary" type="submit">Settings</button>
            <Nav
              changeFrequency={this.changeFrequency}
              changeTimeframe={this.changeTimeframe}
              changeMetricsUrl={this.changeMetricsUrl}
              toggleFullscreen={this.toggleFullscreen}
              changeGraphMetricsList={this.changeGraphMetricsList}
              changeOverviewMetricsList={this.changeOverviewMetricsList}
              state={this.state}
             />
          </nav>
          {this.state.metrics.simple.requests && <RequestsBlock data={this.state.metrics.simple.requests} state={this.state}/>}
          <div className="row">{metricsBlocks}</div>
          <div className="row">
            <div className="col">
              {graphData && graphData.length !== 0 && <Graph data={graphData} state={this.state}/> }
            </div>
          </div>
        </div>
      </div>
    );
  }

  formatTimestamp(timestamp: number): string {
    return new Date(timestamp * 1000).toLocaleTimeString("en-GB")
  }

  fetchByTimeout() {
    this.clearTimeoutFunction()
    this.fetchData()
    this.setState({timeoutFunction: setTimeout(() => this.fetchByTimeout(), this.state.frequency)});
  }

  fetchData() {
    const overviewMetrics = this.state.overviewMetricsList.map(m => m.value).join(",")
    const graphMetrics    = this.state.graphMetricsList.map(m => m.value).join(",")

    fetch(`${this.state.metricsUrl}?interval=${this.state.timeframe}&partition=${this.state.partition}&overview_metrics=${overviewMetrics}&graph_metrics=${graphMetrics}`)
    .then(res => res.json())
    .then(
      (data) => {
        this.setState({metrics: data});
      }
    )
  }

  changeFrequency(frequencyValue: number) {
    store.set("frequency", frequencyValue);
    this.setState({frequency: frequencyValue});
    this.fetchByTimeout()
  }

  changeTimeframe(timeframeValue: number) {
    var partition = "minute";

    if (timeframeValue < 121) {
      partition = "second";
    } else if (timeframeValue < 3601) {
      partition = "minute";
    } else {
      partition = "hour";
    }

    store.set("timeframe", timeframeValue);
    store.set("partition", partition);

    this.setState({timeframe: timeframeValue, partition: partition});
    this.fetchByTimeout()
  }

  changeOverviewMetricsList(metricsList: String[]) {
    store.set("overviewMetricsList", metricsList)
    this.setState({overviewMetricsList: metricsList});
  }

  changeGraphMetricsList(metricsList: String[]) {
    store.set("graphMetricsList", metricsList)
    this.setState({graphMetricsList: metricsList});
  }

  changeMetricsUrl(metricsUrl: String) {
    store.set("metricsUrl", metricsUrl);
    this.setState({metricsUrl: metricsUrl});
  }

  toggleFullscreen() {
    store.set("fullscreen", !this.state.fullscreen)

    this.setState(prevState => ({
      fullscreen: !prevState.fullscreen
    }));
  }

  toggleNav() {
    this.setState(prevState => ({
      showNav: !prevState.showNav
    }));
  }

  clearTimeoutFunction(){
    window.clearTimeout(this.state.timeoutFunction);
  }

  intersection(a1: String[], a2: String[]) {
    return a1.filter(x => a2.indexOf(x) > -1)
  }
}
