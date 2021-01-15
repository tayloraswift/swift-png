import sys, os, subprocess

import densityplot, differentialplot

def build_benchmarks(prefix, suffix):
    baseline    = '{0}/baseline/main'.format(prefix)
    swift       = '.build/release/{0}'.format(suffix)
    
    build_c_invocation      = ('clang', '-Wall', '-Wpedantic', '-lpng', 
        '{0}.c'.format(baseline), '-o', baseline)
    print(' '.join(build_c_invocation))
    build_c                 = subprocess.run(build_c_invocation)

    if build_c.returncode != 0:
        sys.exit(-1)

    build_swift_invocation  = 'swift', 'build', '-c', 'release', '--product', suffix

    print(' '.join(build_swift_invocation))
    build_swift             = subprocess.run(build_swift_invocation)
    if build_swift.returncode != 0:
        sys.exit(-1)
    
    return baseline, swift 

def generate_test_image_table(images, paths):
    header      =  '| Test image | Size |'
    separator   =  '| ---------- | ---- |'
    rows        = ('| `{0}` <br/> <img src="{1}"/> | {2:,} B |'.format(
            image, '../{0}'.format(path), os.path.getsize(path)) 
        for image, path in zip(images, paths))
    
    return '\n'.join((header, separator, * rows ))

def median(series):
    return sorted(series)[len(series) // 2]

def percent(x):
    return '{0} percent'.format(round(x * 100, 2))

def assign_colors(images):
    solid   = [('swift', '#ff694eff'), ('baseline', '#888888ff')]
    dashed  = []
    for name in images:
        name_baseline           = 'baseline-{0}'.format(name)
        name_swift              = 'swift-{0}'.format(name)
        
        solid.append((name_baseline, '#dddddd80'))
        if name == 'rgb8-color-photographic':
            dashed.append((name_swift, '#ff694eff'))
        else:
            solid.append((name_swift, '#ffbf9d80'))
    
    return tuple((name, color, 'dashed') for name, color in dashed) + tuple((name, color, 'solid') for name, color in solid)
    
def compression_collect_data_for_level(level, images, paths, baseline, swift, trials):
    series  = {'baseline': [], 'swift': []}
    sizes   = {}
    for image, path in zip(images, paths):
        name_baseline           = 'baseline-{0}'.format(image)
        name_swift              = 'swift-{0}'.format(image)
        
        remaining       = trials 
        series_baseline = []
        series_swift    = []
        while remaining > 0:
            count               = min(remaining, 10)
            baseline_invocation = baseline, str(level), path, str(count)
            swift_invocation    = swift,    str(level), path, str(count)
            
            print(' '.join(baseline_invocation))
            baseline_result     = subprocess.run(baseline_invocation, capture_output = True)
            
            if baseline_result.returncode == 0:
                string = baseline_result.stdout.decode('utf-8')
                print(string, end = '')
                
                times, size             = string.split(',')
                sizes[name_baseline]    = int(size)
                series_baseline.extend(map(float, times.split()))
            else:
                print(baseline_result.stderr.decode('utf-8'), end = '')
            
            print(' '.join(swift_invocation))
            swift_result        = subprocess.run(swift_invocation, capture_output = True)
            
            if swift_result.returncode == 0:
                string = swift_result.stdout.decode('utf-8')
                print(string, end = '')
                
                times, size             = string.split(',')
                sizes[name_swift]       = int(size)
                series_swift.extend(map(float, times.split()))
            else:
                print(swift_result.stderr.decode('utf-8'), end = '')
                
            remaining -= 10
        
        # normalize to median of the baseline series         
        median                  = sorted(series_baseline)[len(series_baseline) // 2]
        series[name_baseline]   = tuple(x / median for x in series_baseline)
        series[name_swift]      = tuple(x / median for x in series_swift)
        
        series['baseline'].extend(series[name_baseline])
        series['swift'].extend(   series[name_swift])
            
    return {key: (series, sizes[key] if key in sizes else None) 
        for key, series in series.items()}

def compression_collect_data(images, paths, baseline, swift, trials):
    return tuple(compression_collect_data_for_level(level, images, paths, baseline, swift, trials) 
        for level in range(10))

def compression_save_data(series):
    return ''.join('{0}:{1}:{2}{3}\n'.format(
            level, 
            name, 
            ' '.join(map(str, series)), 
            '' if size is None else ', {0}'.format(size)) 
        for level, series in enumerate(series) 
        for name, (series, size) in series.items())

def compression_load_data(string):
    combined = {(int(level), name): (tuple(map(float, series.split())), int(tail[0]) if tail else None)
        for level, name, series, * tail in ((level, name, * value.split(','))
        for level, name, value in (tuple(line.split(':'))
        for line in string.split('\n') if line))}
    return tuple({name: series for (level, name), series in combined.items() if level == i} 
        for i in range(10))

def compression_benchmark(trials, images, paths, cache_destination, cache_source):
    prefix      = 'benchmarks/compression' 
    suffix      = 'compression-benchmark'
    
    baseline, swift = build_benchmarks(prefix, suffix)
    colors          = assign_colors(images)
    
    if cache_source is None:
        series      = compression_collect_data(images, paths, baseline, swift, trials)
        if cache_destination is not None:
            with open(cache_destination, 'w') as file:
                file.write(compression_save_data(series))
    else:
        with open(cache_source, 'r') as file:
            series  = compression_load_data(file.read())
        
        shortest    = min(len(series) for series in series for series, size in series.values())
        if trials  != shortest:
            print('file \'{0}\' has only {1} measurements per test case (expected {2})'.format(
                cache_source, shortest, trials))
            sys.exit(-1)
    
    # associates file sizes for swift benchmarks with corresponding libpng benchmarks 
    def compare_filesizes(series):
        baseline    = {'-'.join(name.split('-')[1:]): size 
            for name, (series, size) in series.items() if size is not None and name.startswith('baseline')}
        swift       = {'-'.join(name.split('-')[1:]): size 
            for name, (series, size) in series.items() if size is not None and name.startswith('swift')}
        return {common: swift[common] / baseline[common] for common in swift.keys() | baseline.keys()}
    
    return tuple((
            densityplot.plot({name: series for name, (series, size) in series.items()}, 
                range_x     = (0, 5.0),
                range_y     = (0, 0.6),
                major       = (0.5, 0.1),
                minor       = (2, 2),
                title       = 'encoding performance (level {0})'.format(level),
                subtitle    = '{0} trials per test image'.format(trials),
                label_x     = 'relative run time',
                label_y     = 'density',
                smoothing   = 0.6, 
                legend      = (('baseline', 'libpng'), ('swift', 'swift png')),
                colors      = tuple(reversed(colors))), 
            
            differentialplot.plot(size_ratios, 
                range_x     = (0, 1.8),
                major       = 0.2, 
                minor       = 4,
                title       = 'relative file size (level {0})'.format(level),
                subtitle    = 'swift png size / libpng size ',
                colors      = {
                    'color_fill_worse':     '#888888ff',
                    'color_fill_better':    '#ff694eff',
                    'color_worse':          '#666666ff',
                    'color_better':         '#ff694eff',
                }),
            
            median(series['swift'][0]), 
            median(series['swift-rgb8-color-photographic'][0]) if 'swift-rgb8-color-photographic' in series else None,
            size_ratios['rgb8-color-photographic'])
        for level, series, size_ratios in ((level, series, compare_filesizes(series))
        for level, series in enumerate(series)))
    

def decompression_collect_data(images, paths, baseline, swift, trials):
    series = {'baseline': [], 'swift': []}
    for image, path in zip(images, paths):
        name_baseline           = 'baseline-{0}'.format(image)
        name_swift              = 'swift-{0}'.format(image)
        
        remaining       = trials 
        series_baseline = []
        series_swift    = []
        while remaining > 0:
            count               = min(remaining, 10)
            baseline_invocation = baseline, path, str(count)
            swift_invocation    = swift,    path, str(count)
            
            print(' '.join(baseline_invocation))
            baseline_result     = subprocess.run(baseline_invocation, capture_output = True)
            
            if baseline_result.returncode == 0:
                string = baseline_result.stdout.decode('utf-8')
                print(string, end = '')
                series_baseline.extend(map(float, string.split()))
            else:
                print(baseline_result.stderr.decode('utf-8'), end = '')
            
            print(' '.join(swift_invocation))
            swift_result        = subprocess.run(swift_invocation, capture_output = True)
            
            if swift_result.returncode == 0:
                string = swift_result.stdout.decode('utf-8')
                print(string, end = '')
                series_swift.extend(map(float, string.split()))
            else:
                print(swift_result.stderr.decode('utf-8'), end = '')
                
            remaining -= 10
        
        # normalize to median of the baseline series         
        median                  = sorted(series_baseline)[len(series_baseline) // 2]
        series[name_baseline]   = tuple(x / median for x in series_baseline)
        series[name_swift]      = tuple(x / median for x in series_swift)
        
        series['baseline'].extend(series[name_baseline])
        series['swift'].extend(   series[name_swift])
            
    return series
    
def decompression_save_data(series):
    return ''.join('{0}:{1}\n'.format(name, ' '.join(map(str,series)))
        for name, series in series.items())

def decompression_load_data(string):
    return {name: tuple(map(float, series.split()))
        for name, series in (tuple(line.split(':')) 
        for line in string.split('\n') if line)} 

def decompression_benchmark(trials, images, paths, cache_destination, cache_source):
    prefix      = 'benchmarks/decompression' 
    suffix      = 'decompression-benchmark'
    
    baseline, swift = build_benchmarks(prefix, suffix)
    colors          = assign_colors(images)
    
    if cache_source is None:
        series      = decompression_collect_data(images, paths, baseline, swift, trials)
        if cache_destination is not None:
            with open(cache_destination, 'w') as file:
                file.write(decompression_save_data(series))
    else:
        with open(cache_source, 'r') as file:
            series  = decompression_load_data(file.read())
    
    shortest    = min(map(len, series.values()))
    if trials  != shortest:
        print('file \'{0}\' has {1} measurements per test case (expected {2})'.format(
            cache_source, shortest, trials))
        sys.exit(-1)
    
    plot    = densityplot.plot(series, 
        range_x     = (0, 2.0),
        range_y     = (0, 0.6),
        major       = (0.2, 0.1),
        minor       = (2, 2),
        title       = 'decoding performance',
        subtitle    = '{0} trials per test image'.format(trials),
        label_x     = 'relative run time',
        label_y     = 'density',
        smoothing   = 0.6, 
        legend      = (('baseline', 'libpng'), ('swift', 'swift png')),
        colors      = tuple(reversed(colors)))
    
    median_ratio    = median(series['swift'])
    rgb8_ratio      = median(series['swift-rgb8-color-photographic']) if 'swift-rgb8-color-photographic' in series else None
    
    return plot, median_ratio, rgb8_ratio
            
def benchmark(trials, images, save, load, prefix):
    paths = tuple('tests/compression/baseline/{0}.png'.format(image) for image in images)
    
    plot, median_ratio, rgb8_ratio  = decompression_benchmark(trials[0], images, paths, 
        cache_destination   = '{0}/decompression.data'.format(prefix) if save else None,
        cache_source        = '{0}/decompression.data'.format(prefix) if load else None)
    levels                          =   compression_benchmark(trials[1], images, paths, 
        cache_destination   = '{0}/compression.data'.format(prefix) if save else None,
        cache_source        = '{0}/compression.data'.format(prefix) if load else None)
    
    fields = {
        'images'        : len(images), 
        'image_table'   : generate_test_image_table(images, paths), 
    }
    
    fields['median_decompression_speed']    = percent(median_ratio)
    fields['rgb8_decompression_speed']      = percent(rgb8_ratio)
    fields['plot_decompression_speed']      = '{0}/decompression-speed.svg'.format(prefix)
    with open(fields['plot_decompression_speed'], 'w') as file:
        file.write(plot)
    
    for i, (plot_speed, plot_size, median_ratio, rgb8_ratio_speed, rgb8_ratio_size) in enumerate(levels):
        plot_compression_speed  = '{0}/compression-speed@{1}.svg'.format(prefix, i)
        plot_compression_size   = '{0}/compression-size@{1}.svg'.format(prefix, i)
        fields['median_compression_speed@{0}'.format(i)]    = percent(median_ratio)
        fields['rgb8_compression_speed@{0}'.format(i)]      = percent(rgb8_ratio_speed)
        fields['rgb8_compression_ratio@{0}'.format(i)]      = percent(rgb8_ratio_size)
        fields['plot_compression_speed@{0}'.format(i)]      = plot_compression_speed 
        fields['plot_compression_ratio@{0}'.format(i)]      = plot_compression_size
        with open(plot_compression_speed, 'w') as file:
            file.write(plot_speed)
        with open(plot_compression_size, 'w') as file:
            file.write(plot_size)
    
    return fields
