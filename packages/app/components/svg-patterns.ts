const svgPatternMaker = ({color, density, opacity = 0.5, radius = 0.75 }: { color: string, density: number, opacity?: number, radius?: number }) => {

  let size = 0;
  let offset = 0;
  let otherOffset = (radius / 2) + radius;

  switch(density) {
    case 1:
      size = 0.02;
      offset = 3;
      break;
    case 2:
      size = 0.025;
      offset = 3.5;
      break;
    case 3:
      size = 0.04;
      offset = 5;
      break;
    case 4:
      size = 0.1;
      offset = 10;
      break;
    case 5:
      size = 0.1675;
      offset = 16;
      break;
    default:
      size = 0.1675;
      offset = 16;
  } 

  return (
  `<svg width="200" height="200" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <pattern id="Pattern" x="0" y="0" width="${size}" height="${size}">
        <circle cx="${offset}" cy="${otherOffset}" r="${radius}" fill="${color}" fill-opacity="${opacity}"/>
        <circle cx="${otherOffset}" cy="${offset}" r="${radius}" fill="${color}" fill-opacity="${opacity}"/>
    
      </pattern>
    </defs>
    
    <rect fill="url(#Pattern)" width="200" height="200"/>
    </svg>`
  )
}
  
  export default svgPatternMaker;
  