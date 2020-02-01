import React from 'react';
import Metric from './Metric';

export default function MetricsBlock(props: any): JSX.Element {

  const metricsList = Object.entries(props.metrics).map(
    ([name, value]) => {
      return <Metric key={name} name={props.name} aggregateFunction={name} metrics={value}/>
    }
  )

  return (
    <div className="col-sm metrics-block rounded text-center alert-light">
      <h2>
        <span className="metric-block-name badge badge-info">
          {props.name.toUpperCase()}&nbsp;
          <span className="small">({props.name === 'queries' ? 'count' : 'ms'})</span>
        </span></h2>
      {metricsList}
    </div>
  );
}
