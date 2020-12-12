def svg(display, style, content):
    if len(display) != 2:
        print('display must be a 2-tuple')
        raise ValueError
    
    return '''<?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"
  "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="{0}" height="{1}" viewBox="0 0 {0} {1}">
<style type="text/css" >
    <![CDATA[
        {2}
    ]]>
</style>
    <rect width="{0}" height="{1}" class="background"/>
    {3}
</svg>
    '''.format( * display , style, '\n    '.join(content))

def circle(center, radius = 1, classes = ()):
    if type(classes) is str:
        classes = (classes,)
    return '<circle class="{0}" cx="{1}" cy="{2}" r="{3}"/>'.format(' '.join(classes), * center , radius)

def path(points, classes = ()):
    if type(classes) is str:
        classes = (classes,)
    head, * body = points 
    path = 'M {0},{1} '.format( * head ) + ' '.join('L {0},{1}'.format( * point ) for point in body)
    return '<path class="{0}" d="{1}"/>'.format(' '.join(classes), path)

def text(text, position, classes = ()):
    if type(classes) is str:
        classes = (classes,)
    return '<text x="{0}" y="{1}" class="{2}">{3}</text>'.format(
        * position , ' '.join(classes), text)
