import React from 'react';

import { ResponsiveLine } from '@nivo/line';

export default function Graph(props: any): JSX.Element {
  return (
    <div className="nivo">
      <ResponsiveLine
        data={props.data}
        margin={{ top: 20, right: 120, bottom: 64, left: 70 }}
        xScale={{ type: 'point' }}
        yScale={{ type: 'linear', min: 'auto', max: 'auto', stacked: true, reverse: false }}
        axisTop={null}
        axisRight={null}
        axisBottom={{
          orient: 'bottom',
          tickSize: 5,
          tickPadding: 5,
          tickRotation: -60,
          legend: 'time',
          legendOffset: 58,
          legendPosition: 'middle'
        }}
        axisLeft={{
          orient: 'left',
          tickSize: 2,
          tickPadding: 5,
          tickRotation: 0,
          legend: 'value',
          legendOffset: -50,
          legendPosition: 'middle',
        }}
        colors={{ scheme: 'nivo' }}
        pointSize={5}
        pointColor={{ theme: 'background' }}
        pointBorderWidth={1}
        pointBorderColor={{ from: 'serieColor' }}
        pointLabel="y"
        pointLabelYOffset={-12}
        animate={props.state.timeframe === 60}
        useMesh={true}
        legends={[
          {
            anchor: 'bottom-right',
            direction: 'column',
            justify: false,
            translateX: 100,
            translateY: 0,
            itemsSpacing: 0,
            itemDirection: 'left-to-right',
            itemWidth: 80,
            itemHeight: 20,
            itemOpacity: 0.75,
            symbolSize: 10,
            symbolShape: 'circle',
            symbolBorderColor: 'rgba(0, 0, 0, .5)',
            effects: [
              {
                on: 'hover',
                style: {
                  itemBackground: 'rgba(0, 0, 0, .03)',
                  itemOpacity: 1
                }
              }
            ]
          }
        ]}
    />
    </div>
  );
}
