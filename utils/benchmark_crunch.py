from differentialplot   import plot as differentialplot
from toolchain          import toolchain, compression_benchmark

def percent(x):
    return '{0} percent'.format(round(x * 100, 2))

def save_data(series):
    return ''.join('{0}:{1}:{2}\n'.format(level, image, ratio)
        for level, series in zip(range(10, 14), series) 
        for image, ratio  in series.items())

def load_data(string, images):
    entries = {(int(level), image): float(ratio)
        for level, image, ratio in (tuple(line.split(':')) 
        for line in string.split('\n') if line)}
    return tuple({image: entries[level, image] for image in images} 
        for level in range(10, 14))

def benchmark(images, save, load, prefix):
    paths   = tuple('tests/compression/baseline/{0}.png'.format(image) for image in images)
    cache   = '{0}/crunch.data'.format(prefix)
    
    if load:
        with open(cache, 'r') as file:
            series = load_data(file.read(), images)
    else:
        libpng      = compression_benchmark('c', '.build-historical/clang')
        baseline    =       {image:   libpng.collect_data(path, level = 9,     trials = 1)['size'] 
            for image, path in zip(images, paths)}
        with toolchain() as swiftpng:
            swift   = tuple({image: swiftpng.collect_data(path, level = level, trials = 1)['size']
                for image, path in zip(images, paths)}
                for level in range(10, 14))
        
        series = tuple({image: size / baseline[image] for image, size in swift.items()} for swift in swift)
        if save:
            with open(cache, 'w') as file:
                file.write(save_data(series))
    
    fields = {}
    for level, series in zip(range(10, 14), series):
        plot = differentialplot(series, 
            range_x     = (0, 1.8),
            major       = 0.2, 
            minor       = 4,
            title       = 'relative file size (level {0})'.format(level),
            subtitle    = 'swift png size / best libpng size ',
            colors      = {
                'color_fill_worse':     '#888888ff',
                'color_fill_better':    '#ff694eff',
                'color_worse':          '#666666ff',
                'color_better':         '#ff694eff',
            })
        
        output = '{0}/compression-size@{1}.svg'.format(prefix, level)
        with open(output, 'w') as file:
            file.write(plot)
        
        fields['plot_compression_ratio@{0}'.format(level)] = output 
        fields['rgb8_compression_ratio@{0}'.format(level)] = percent(series['rgb8-color-photographic'])

    return fields
