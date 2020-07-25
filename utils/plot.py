#!/usr/bin/python3
import sys 
import math
from collections import defaultdict

try:
    input   = sys.argv[1] 
    output  = sys.argv[2] 
except IndexError:
    print('missing input/output file arguments')
    sys.exit(-1)

with open(input, 'r') as file:
    data = file.read()

def parse_datapoint(string):
    i, time, size, key = string.split(' ')
    return (time, size, key)

svg = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"
  "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 800 800">
<style type="text/css" >
    <![CDATA[
        rect.background 
        {
            fill:   #ffffffff;
        }
        path.curve 
        {
            stroke: #3333ffff;
            stroke-width: 2px;
            fill:   none;
        }
        
        path.curve.v8-monochrome-photographic,
        path.curve.v8-monochrome-nonphotographic 
        {
            stroke: #aaaaaaff;
        }
        circle.curve-point.v8-monochrome-photographic,
        circle.curve-point.v8-monochrome-nonphotographic 
        {
            fill: #aaaaaaff;
        }
        
        path.curve.v16-monochrome-photographic,
        path.curve.v16-monochrome-nonphotographic 
        {
            stroke: #666666ff;
        }
        circle.curve-point.v16-monochrome-photographic,
        circle.curve-point.v16-monochrome-nonphotographic 
        {
            fill: #666666ff;
        }
        
        path.curve.va8-monochrome-photographic,
        path.curve.va8-monochrome-nonphotographic 
        {
            stroke: #aa88ffff;
        }
        circle.curve-point.va8-monochrome-photographic,
        circle.curve-point.va8-monochrome-nonphotographic 
        {
            fill: #aa88ffff;
        }
        path.curve.va16-monochrome-photographic,
        path.curve.va16-monochrome-nonphotographic 
        {
            stroke: #9920ffff;
        }
        circle.curve-point.va16-monochrome-photographic,
        circle.curve-point.va16-monochrome-nonphotographic 
        {
            fill: #9920ffff;
        }
        
        path.curve.indexed8-monochrome-photographic,
        path.curve.indexed8-monochrome-nonphotographic, 
        path.curve.indexed8-color-photographic,
        path.curve.indexed8-color-nonphotographic 
        {
            stroke: #6688ffff;
        }
        circle.curve-point.indexed8-monochrome-photographic,
        circle.curve-point.indexed8-monochrome-nonphotographic, 
        circle.curve-point.indexed8-color-photographic,
        circle.curve-point.indexed8-color-nonphotographic 
        {
            fill: #6688ffff;
        }
        
        path.curve.rgb8-monochrome-photographic,
        path.curve.rgb8-monochrome-nonphotographic, 
        path.curve.rgb8-color-photographic,
        path.curve.rgb8-color-nonphotographic 
        {
            stroke: #ffaa90ff;
        }
        circle.curve-point.rgb8-monochrome-photographic,
        circle.curve-point.rgb8-monochrome-nonphotographic, 
        circle.curve-point.rgb8-color-photographic,
        circle.curve-point.rgb8-color-nonphotographic 
        {
            fill: #ffaa90ff;
        }
        
        path.curve.rgb16-monochrome-photographic,
        path.curve.rgb16-monochrome-nonphotographic,
        path.curve.rgb16-color-photographic,
        path.curve.rgb16-color-nonphotographic 
        {
            stroke: #ff6040ff;
        }
        circle.curve-point.rgb16-monochrome-photographic,
        circle.curve-point.rgb16-monochrome-nonphotographic,
        circle.curve-point.rgb16-color-photographic,
        circle.curve-point.rgb16-color-nonphotographic 
        {
            fill: #ff6040ff;
        }
        
        path.curve.rgba8-monochrome-photographic,
        path.curve.rgba8-monochrome-nonphotographic, 
        path.curve.rgba8-color-photographic,
        path.curve.rgba8-color-nonphotographic 
        {
            stroke: #ff90aaff;
        }
        circle.curve-point.rgba8-monochrome-photographic,
        circle.curve-point.rgba8-monochrome-nonphotographic, 
        circle.curve-point.rgba8-color-photographic,
        circle.curve-point.rgba8-color-nonphotographic 
        {
            fill: #ff90aaff;
        }
        path.curve.rgba16-monochrome-photographic,
        path.curve.rgba16-monochrome-nonphotographic, 
        path.curve.rgba16-color-photographic,
        path.curve.rgba16-color-nonphotographic 
        {
            stroke: #ff4060ff;
        }
        circle.curve-point.rgba16-monochrome-photographic,
        circle.curve-point.rgba16-monochrome-nonphotographic, 
        circle.curve-point.rgba16-color-photographic,
        circle.curve-point.rgba16-color-nonphotographic 
        {
            fill: #ff4060ff;
        }
                
                
        path.curve.indexed8-monochrome-photographic,
        path.curve.indexed8-monochrome-nonphotographic, 
        path.curve.rgb8-monochrome-photographic,
        path.curve.rgb8-monochrome-nonphotographic, 
        path.curve.rgb16-monochrome-photographic,
        path.curve.rgb16-monochrome-nonphotographic,
        path.curve.rgba8-monochrome-photographic,
        path.curve.rgba8-monochrome-nonphotographic, 
        path.curve.rgba16-monochrome-photographic,
        path.curve.rgba16-monochrome-nonphotographic
        {
            stroke-dasharray: 5;
        }
    ]]>
</style>
<rect width="800" height="800" class="background"/>
'''

for group in (group for group in data.split('\n\n') if group):
    curves  = defaultdict(list)
    name    = None 
    for line in group.split('\n'):
        if line[-1] == ':':
            name = line[:-1]
        else:
            curves[name].append(parse_datapoint(line))
    
    svg += '<g>\n'
    for name, vector in curves.items():
        key     = vector[0][2]
        points  = list((120.0 + 50.0 * math.log2(float(time)), 3050.0 - 150 * math.log2(float(size))) for time, size, key in vector)
        path    = 'M {0},{1} '.format( * points[0] ) + ' '.join('L {0},{1}'.format( * point ) for point in points[1:])
        svg += '<path class="curve {0}" d="{1}"/>\n'.format(key, path)
        for x, y in points:
            svg += '<circle class="curve-point {0}" cx="{x}" cy="{y}" r="2"/>\n'.format(key, x = x, y = y)
    svg += '</g>\n'

svg += '</svg>'

with open(output, 'w') as file:
    file.write(svg)
