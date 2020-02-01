import React from 'react';

export default function Metric(props: any): JSX.Element {

  var aggFunc = props.aggregateFunction;

  aggFunc = aggFunc.startsWith("percent") ? aggFunc.split("_")[1] + "%" : aggFunc.toUpperCase()

  return (
    <div className="metric text-center">
      <div className="metric-name">
        {aggFunc}
      </div>
      <div className={typeof(props.metrics) === "number" ? "display-4" : "display-5"}>
        <strong>
          <div className="">{props.metrics}</div>
        </strong>
      </div>
    </div>
  );
}
