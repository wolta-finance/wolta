import { LineChart, Line, Area, AreaChart, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
const data = [{name: 'Jan', amt: 10},{name: 'Feb', amt: 30 },{name: 'Mar', amt: 100}];

const Chart = () => (
<ResponsiveContainer width="100%" height={80}>
  <AreaChart width={300} height={80} data={data}>
     <CartesianGrid strokeDasharray="3 3" />
     <Tooltip labelFormatter={(value) => data[value].name} />
    <Area type="monotone" dataKey="amt" stroke="#000000" fill="#efefef" />
  </AreaChart>
  </ResponsiveContainer>
);

export default Chart;