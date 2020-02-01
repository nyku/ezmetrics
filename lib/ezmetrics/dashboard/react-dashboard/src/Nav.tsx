import React from 'react';
import { allMetricsList, allRefreshIntervals, allTimeframes } from './Constants';

import Autocomplete from '@material-ui/lab/Autocomplete';
import TextField from '@material-ui/core/TextField';

export default function Nav(props: any): JSX.Element {

  return (
    <div className={props.state.showNav ? "topbar" : "topbar closed"}>
      <div className="row">
        <div className="col col-md-12">
          <Autocomplete
            multiple
            id="overview_metrics"
            options={allMetricsList}
            getOptionLabel={option => option.label}
            defaultValue={props.state.overviewMetricsList}
            filterSelectedOptions
            onChange={(event, value) => value && props.changeOverviewMetricsList(value)}
            renderInput={params => (
              <TextField
                {...params}
                variant="outlined"
                label="Overview metrics"
                fullWidth
                value={props.state.overviewMetricsList}
              />
            )}
          />

          <br></br>

          <Autocomplete
            multiple
            id="graph_metrics"
            options={allMetricsList}
            getOptionLabel={option => option.label}
            defaultValue={props.state.graphMetricsList}
            filterSelectedOptions
            onChange={(event, value) => value && props.changeGraphMetricsList(value)}
            renderInput={params => (
              <TextField
                {...params}
                variant="outlined"
                label="Graph metrics"
                fullWidth
                value={props.state.graphMetricsList}
              />
            )}
          />

          <br></br>

        </div>

        <div className="col">
          <Autocomplete
            id="refresh"
            options={allRefreshIntervals}
            getOptionLabel={option => option.label}
            onChange={(event: any, value: any) => value && props.changeFrequency(value.value)}
            defaultValue={allRefreshIntervals.find(element => element.value === props.state.frequency)}
            filterSelectedOptions
            renderInput={params => (
              <TextField
                {...params}
                variant="outlined"
                label="Refresh interval"
                fullWidth
              />
            )}
          />
        </div>

        <div className="col">
          <Autocomplete
            id="timeframe"
            options={allTimeframes}
            getOptionLabel={option => option.label}
            onChange={(event: any, value: any) => value && props.changeTimeframe(value.value)}
            defaultValue={allTimeframes.find(element => element.value === props.state.timeframe)}
            filterSelectedOptions
            renderInput={params => (
              <TextField
                {...params}
                variant="outlined"
                label="Timeframe"
                fullWidth
              />
            )}
          />
        </div>

        <div className="col col-md-6">
          <div className="form-group metrics-url">
            <label>Metrics url</label>
            <input type="url" className="form-control" placeholder="Metrics url" value={props.state.metricsUrl} onChange={e => props.changeMetricsUrl(e.target.value)}/>
          </div>
        </div>
      </div>

    </div>
  );
}
