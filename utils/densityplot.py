import math

def svg(display, style, content):
    if len(display) != 2:
        print('display must be a 2-tuple')
        raise ValueError
    
    return '''<?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"
      "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
    <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 {0} {1}">
    <style type="text/css" >
        <![CDATA[
            {2}
        ]]>
    </style>
    <rect width="{0}" height="{1}" class="background"/>
    {3}
    </svg>
    '''.format( * display , style, '\n'.join(content))

def svg_path(points, classes = None):
    head, * body = points 
    path = 'M {0},{1} '.format( * head ) + ' '.join('L {0},{1}'.format( * point ) for point in body)
    return '<path class="{0}" d="{1}"/>'.format(' '.join(classes), path)

def kernel(x, center, width):
    return 1 / (width * math.sqrt(2 * math.pi)) * math.exp(-0.5 * ((x - center) / width) ** 2)

def plot(series, smoothing = 1, bins = 40, colors = {}):
    resolution   = 10 * bins
    kernel_width = smoothing / bins
    display = 800, 400
    margin  = 100, 100
    start   = 0 
    end     = max(x for series in series.values() for x in series) * ((bins + 1) / (bins))
    
    paths   = []
    for name, series in series.items():
        scale   = 1 / (bins * len(series))
        curve   = tuple(
            (
                           x / resolution, 
                sum(kernel(x / resolution, (point - start) / (end - start), kernel_width)
                    for point in series) * scale
            ) 
            for x in range(resolution + 1))
        
        area    = display[0] - margin[0], margin[1] - display[1]
        offset  =        0.5 * margin[0], display[1] - 0.5 * margin[1]
        
        paths.append(svg_path(
            (tuple(u * area + offset for u, area, offset in zip(node, area, offset)) for node in curve), 
            classes = (name, 'density-curve')))
    
    style = '''
    rect.background 
    {{
        fill:   white;
    }}
    path.density-curve 
    {{
        stroke-width: 2px;
        fill:   none;
    }}
    {0}
    '''.format(''.join('''
    path.{0} 
    {{
        stroke: {1};
    }}
    '''.format(name, color) for name, color in colors.items()))
    
    return svg(display, style, paths)
