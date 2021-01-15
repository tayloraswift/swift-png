from densityplot    import plot as densityplot
from toolchain      import toolchain, compression_benchmark

def median(series):
    return sorted(series)[len(series) // 2]

def percent(x):
    return '{0} percent'.format(round(x * 100, 2))

def assign_colors(nightlies):
    gradient = (
        '#b2a77fff',
        '#dfc47cff',
        '#e9ce77ff',
        '#ffdb6cff',
        '#ffa34eff',
        '#ff694eff',
        # '#fdffb9ff',
        # '#ffed85ff',
        # '#ffd44eff',
        # '#ffb84eff',
        # '#ff8f4eff',
        # '#ff694eff',
    )
    return (('baseline', '#888888ff', 'solid'),) + tuple(('nightly-{0}'.format(nightly), color, 'solid') for nightly, color in reversed(tuple(zip(reversed(nightlies), reversed(gradient)))))

def save_data(series):
    return ''.join('{0}:{1}\n'.format(name, ' '.join(map(str, series)))
        for name, series in series.items())

def load_data(string):
    return {name: tuple(map(float, series.split()))
        for name, series in ((name, * value.split(','))
        for name, value in (tuple(line.split(':'))
        for line in string.split('\n') if line))}

def benchmark(trials, image, save, load, prefix):
    test_image  = 'tests/compression/baseline/{0}.png'.format(image)
    level       = 8
    cache       = '{0}/historical.data'.format(prefix)
    
    nightlies   = (
        '2020-05-03-a',
        '2020-06-04-a',
        '2020-07-11-a',
        '2020-09-17-a',
        '2020-11-05-a',
        '2020-12-05-a'
    )
    if load:
        with open(cache, 'r') as file:
            series = load_data(file.read())
        
        shortest = min(map(len, series.values()))
        if shortest != trials:
            print('file \'{0}\' has {1} measurements per test case, (expected {2})'.format(cache, shortest, trials))
    else:
        baseline    = compression_benchmark('c', '.build-historical/clang')
        series      = {'baseline': baseline.collect_data(test_image, level = level, trials = trials)['series']}
        for nightly in nightlies:
            with toolchain('DEVELOPMENT-SNAPSHOT-{0}'.format(nightly)) as swift:
                series['nightly-{0}'.format(nightly)] = swift.collect_data(
                    test_image, level = level, trials = trials)['series']
        
        if save:
            with open(cache, 'w') as file:
                file.write(save_data(series))
    
    unity       = median(series['baseline'])
    legend      = (('baseline', 'libpng'),) + tuple(('nightly-{0}'.format(nightly), nightly) for nightly in nightlies)
    colors      = assign_colors(nightlies)
    plot        = densityplot({name: tuple(x / unity for x in series) 
        for name, series in series.items()}, 
        range_x     = (0, 2.5),
        range_y     = (0, 1.0),
        major       = (0.5, 0.25),
        minor       = (2, 2),
        title       = 'encoding performance by swift toolchain',
        subtitle    = 'compression level {0}, {1} trials per test image'.format(level, trials),
        label_x     = 'relative run time',
        label_y     = 'density',
        smoothing   = 0.25, 
        legend      = legend,
        colors      = colors)
    plot_detail     = densityplot({name: tuple(x / unity for x in series) 
        for name, series in series.items()}, 
        range_x     = (1.5, 2.0),
        range_y     = (0, 0.25),
        major       = (0.1, 0.05),
        minor       = (4, 2),
        title       = 'encoding performance by swift toolchain (detail)',
        subtitle    = 'compression level {0}, {1} trials per test image'.format(level, trials),
        label_x     = 'relative run time',
        label_y     = 'density',
        smoothing   = 0.6, 
        legend      = legend,
        colors      = colors)
    
    fields = {
        'plot_historical': '{0}/plot-historical.svg'.format(prefix),
        'plot_historical_detail': '{0}/plot-historical-detail.svg'.format(prefix),
        'historical_toolchains': '\n'.join('- `DEVELOPMENT-SNAPSHOT-{0}`'.format(nightly) for nightly in nightlies)
    }
    with open(fields['plot_historical'], 'w') as file:
        file.write(plot)
    with open(fields['plot_historical_detail'], 'w') as file:
        file.write(plot_detail)

    return fields
