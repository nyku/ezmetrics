import React from 'react';

export default function RequestsBlock(props: any): JSX.Element {

  return (
    <div className="row requests-block">
      {
        props.state.overviewMetricsList.map((m: any) => m.value).includes('requests_all') &&
        <div className="col-sm alert-secondary rounded">
          <div className="request-metric text-center">
            <div className="metric-name">ALL</div>
            <div className="display-4">
              <strong>
                <span className="">{props.data.all}</span>
              </strong>
            </div>
          </div>
        </div>
      }

      {
        props.state.overviewMetricsList.map((m: any) => m.value).includes('requests_2xx') &&
        <div className="col-sm alert-success rounded">
          <div className="request-metric text-center">
            <div className="metric-name">2XX</div>
            <div className="display-4">
              <strong>
                <span className="">{props.data.grouped['2xx']}</span>
              </strong>
            </div>
          </div>
        </div>
      }

      {
        props.state.overviewMetricsList.map((m: any) => m.value).includes('requests_3xx') &&
        <div className="col-sm alert-info rounded">
          <div className="request-metric text-center">
            <div className="metric-name">3XX</div>
            <div className="display-4">
              <strong>
                <span className="">{props.data.grouped['3xx']}</span>
              </strong>
            </div>
          </div>
        </div>
      }

      {
        props.state.overviewMetricsList.map((m: any) => m.value).includes('requests_4xx') &&
        <div className="col-sm alert-warning rounded">
          <div className="request-metric text-center">
            <div className="metric-name">4XX</div>
            <div className="display-4">
              <strong>
                <span className="">{props.data.grouped['4xx']}</span>
              </strong>
            </div>
          </div>
        </div>
      }

      {
        props.state.overviewMetricsList.map((m: any) => m.value).includes('requests_5xx') &&
        <div className="col-sm alert-danger rounded">
          <div className="request-metric text-center">
            <div className="metric-name">5XX</div>
            <div className="display-4">
              <strong>
                <span className="">{props.data.grouped['5xx']}</span>
              </strong>
            </div>
          </div>
        </div>
      }
    </div>
  );
}
