import math
import svg 

def transform(x, w, b):
    return tuple(x * w + b for x, w, b in zip(x, w, b))

def plot(ratios, 
    range_x     = (0, 2),
    major       = 1.0, 
    minor       = 5,
    title       = None,
    subtitle    = None, 
    colors      = {}):    
    
    display     = 800, 680
    margin_x    = 60, 60
    margin_y    =  20,  80 + 10 * (subtitle is not None) + 20 * (title is not None)
    
    area        = display[0] - sum(margin_x), sum(margin_y) - display[1]
    offset      = margin_x[0], display[1] - margin_y[0]
    
    # draw grid lines
    start, end  = range_x
    # epsilon to deal with rounding errors
    cells       = int((end - start) / major * minor + 1e-5)
    
    grid_minor  = []
    grid_major  = []
    ticks       = []
    labels      = []
    for i in range(cells + 1):
        x      = i * major / (minor * (end - start))
        v      = i * major /  minor
        m      = i % minor == 0
        
        screen = tuple(tuple(map(round, transform(x, area, offset))) for x in ((x, 0), (x, 1)))
        length = 12 if m else 6
        (grid_major if m else grid_minor).append(  
            svg.path(  (transform(screen[0], (1, 1), (0.5,  0)), 
                        transform(screen[1], (1, 1), (0.5, -1))), 
            classes = ('grid', 'grid-major' if m else 'grid-minor')))
        ticks.append( 
            svg.path(  (transform(screen[1], (1, 1), (0.5, -8)), 
                        transform(screen[1], (1, 1), (0.5, -8 - length))), 
            classes = ('tick',)))
        
        if m:
            labels.append(svg.text(str(round(v, 3)), 
                position    = transform(screen[1], (1, 1), (0, -16 - length)), 
                classes     = ('label-numeric', 'label-x') + (('unity',) if v == 1 else ())))
    # title and subtitle
    if type(title) is str:
        screen = tuple(map(round, transform((0.5, 1), area, offset)))
        labels.append(svg.text(title, 
            position    = transform(screen, (1, 1), (0, -70)), 
            classes     = ('title',)))
    if type(subtitle) is str:
        screen = tuple(map(round, transform((0.5, 1), area, offset)))
        labels.append(svg.text(subtitle, 
            position    = transform(screen, (1, 1), (0, -50)), 
            classes     = ('subtitle',)))
    
    # plot data 
    rows    = tuple((name, ratio, (
            margin_x[0] + area[0] * (ratio - range_x[0]) / (range_x[1] - range_x[0]),
            margin_y[1] + (i + 0.5) * 20))
        for i, (name, ratio) in enumerate(sorted(ratios.items(), key = lambda k: k[1])))
    # pixel coordinate of the y axis
    zero    = margin_x[0] + area[0] * (1.0 - range_x[0]) / (range_x[1] - range_x[0])
    
    legend      = tuple(svg.text(name, 
        (zero + 16 * (1 if ratio <= 1 else -1), screen[1]), 
        classes = ('label-legend', 'better' if ratio <= 1 else 'worse'))
        for name, ratio, screen in rows)
    percents    = tuple(svg.text('{:+.2f} %'.format((ratio - 1) * 100), 
        (screen[0] - 16 * (1 if ratio <= 1 else -1), screen[1]), 
        classes = ('label-percent', 'better' if ratio <= 1 else 'worse'))
        for name, ratio, screen in rows)
    
    stems       = tuple(svg.path((
            (zero,                                      screen[1]), 
            (screen[0] + 4 * (1 if ratio <= 1 else -1), screen[1])), 
        classes = ('stem', 'better' if ratio <= 1 else 'worse'))
        for name, ratio, screen in rows 
        if abs(screen[0] - zero) > 4)
    dots        = tuple(svg.circle(screen, radius = 4, 
        classes = ('dot', 'better' if ratio <= 1 else 'worse'))
        for name, ratio, screen in rows)
    
    style = '''
    rect.background 
    {
        fill:   white;
    }
    
    path.grid 
    {
        stroke-width: 1px;
        fill:   none;
    }
    path.grid-major 
    {
        stroke: #eeeeeeff;
    }
    path.grid-minor 
    {
        stroke: #f5f5f5ff;
    }
    
    path.tick 
    {
        stroke-width: 1px;
        stroke: #333333ff;
        fill:   none;
    }
    
    path.stem 
    {
        stroke-width: 1px;
        stroke-dasharray: 3 3;
    }
    circle.dot 
    {
        stroke-width: 2px;
        stroke: #666;
        fill:   none;
    }
    
    text
    {
        fill: #333333ff;
        font-family: 'SF Mono';
    }
    text.label-numeric 
    {
        font-size: 12px;
    }
    text.label-numeric.unity 
    {
        font-weight: 700;
    }
    text.label-x 
    {
        text-anchor: middle; 
        dominant-baseline: text-top;
    }
    
    text.label-legend, text.label-percent
    {
        font-size: 12px;
        dominant-baseline: middle;
    }
    text.label-percent 
    {
        font-weight: 700;
    }
    text.label-legend.better, text.label-percent.worse 
    {
        text-anchor: begin; 
    }
    text.label-legend.worse, text.label-percent.better 
    {
        text-anchor: end; 
    }
    
    text.title, text.subtitle 
    {
        text-anchor: middle; 
    }
    text.title 
    {
        font-size: 20px;
    }
    text.subtitle 
    {
        font-size: 12px;
    }
    ''' + '''
    circle.better, path.stem.better
    {{
        stroke: {color_fill_better}
    }}
    circle.worse, path.stem.worse
    {{
        stroke: {color_fill_worse}
    }}
    text.label-percent.better 
    {{
        fill: {color_better}
    }}
    text.label-percent.worse 
    {{
        fill: {color_worse}
    }}
    '''.format( ** colors )
    
    return svg.svg(display, style, 
        tuple(grid_minor + grid_major + ticks + labels) + legend + percents + stems + dots)
