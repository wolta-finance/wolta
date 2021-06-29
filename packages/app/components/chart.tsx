import { LineChart, Line } from 'recharts';
const data = [{month: 'Jan', amt: 10},{month: 'Feb', amt: 30, },{month: 'Mar', amt: 100, }];

const Chart = () => (
  <LineChart width={200} height={50} data={data}>
    <Line type="monotone" dataKey="amt" stroke="#000000" />
  </LineChart>
);

export default Chart;