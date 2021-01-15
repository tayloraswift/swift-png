#!/usr/bin/python3

import sys, os, subprocess, glob

import densityplot, differentialplot

class toolchain:
    def __init__(self, version):
        self.version = version 
    
    def __enter__(self):
        try:
            os.mkdir('.build-historical')
        except FileExistsError:
            pass 
        
        swiftenv_result  = subprocess.run(('swiftenv', 'local'), capture_output = True)
        if swiftenv_result.returncode != 0:
            print('failed to query current swift toolchain')
            sys.exit(-1)
        self.original = swiftenv_result.stdout.decode('utf-8').split()[0]
        print('current toolchain is \'{0}\''.format(self.original))
        
        swiftenv_result  = subprocess.run(('swiftenv', 'install', self.version))
        # will fail if snapshot is already installed, which is fine
        
        swiftenv_result  = subprocess.run(('swiftenv', 'local', self.version))
        if swiftenv_result.returncode != 0:
            print('failed to set swift toolchain \'{0}\''.format(self.version))
            sys.exit(-1)
        
        print('swift toolchain set to \'{0}\''.format(self.version))
        
        return compression_benchmark('swift', '.build-historical/{0}'.format(self.version)) 
    
    def __exit__(self, type, value, traceback):
        swiftenv_result  = subprocess.run(('swiftenv', 'local', self.original))
        if swiftenv_result.returncode != 0:
            print('failed to restore original swift toolchain')
            sys.exit(-1)

class compression_benchmark:
    def __init__(self, benchmark, build_directory):
        if benchmark == 'swift':
            self.executable     = "{0}/release/compression-benchmark".format(build_directory)
            
            build_invocation    = 'swift', 'build', '-c', 'release', '--product', 'compression-benchmark', '--build-path', build_directory
            print(' '.join(build_invocation))
            build               = subprocess.run(build_invocation)
            if build.returncode != 0:
                sys.exit(-1)
        
        elif benchmark == 'c':
            try:
                os.mkdir('.build-historical')
            except FileExistsError:
                pass 
            try:
                os.mkdir('.build-historical/clang')
            except FileExistsError:
                pass 
            
            self.executable = "{0}/main".format(build_directory)
            
            build_invocation    = ('clang', '-Wall', '-Wpedantic', '-lpng', 
                'benchmarks/compression/baseline/main.c', '-o', self.executable)
            print(' '.join(build_invocation))
            build               = subprocess.run(build_invocation)

            if build.returncode != 0:
                sys.exit(-1)
    
    def collect_data(self, file, level, trials):
        name, * _ = os.path.splitext(os.path.basename(file))
        
        remaining   = trials 
        series      = []
        while remaining > 0:
            invocation  = self.executable, str(level), file, str(min(remaining, 10))
            
            print(' '.join(invocation))
            
            result      = subprocess.run(invocation, capture_output = True)
            
            if result.returncode == 0:
                string = result.stdout.decode('utf-8')
                print(string, end = '')
                
                times, _ = string.split(',')
                series.extend(map(float, times.split()))
            else:
                print(result.stderr.decode('utf-8'), end = '')
                
            remaining -= 10
        return series 


def generate_test_image_table(prefix, files):
    header      =  '| Test image | Size |'
    separator   =  '| ---------- | ---- |'
    rows        = ('| `{0}` <br/> <img src="{1}"/> | {2:,} B |'.format(
            name, '{0}/{1}'.format(prefix, path), size) 
        for name, path, size in sorted((os.path.basename(path), path, os.path.getsize(path)) 
        for path in files))
    
    return '\n'.join((header, separator, * rows ))

def median(series):
    return sorted(series)[len(series) // 2]

def percent(x):
    return '{0} percent'.format(round(x * 100, 2))

def ordinal(i):
    if   i == 1:
        return '1st'
    elif i == 2:
        return '2nd'
    elif i == 3:
        return '3rd'
    else:
        return '{0}th'.format(i)

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
        series      = {'baseline': baseline.collect_data(test_image, level = level, trials = trials)}
        for nightly in nightlies:
            with toolchain('DEVELOPMENT-SNAPSHOT-{0}'.format(nightly)) as swift:
                series['nightly-{0}'.format(nightly)] = swift.collect_data(
                    test_image, level = level, trials = trials)
        
        if save:
            with open(cache, 'w') as file:
                file.write(save_data(series))
    
    unity       = median(series['baseline'])
    legend      = (('baseline', 'libpng'),) + tuple(('nightly-{0}'.format(nightly), nightly) for nightly in nightlies)
    colors      = assign_colors(nightlies)
    plot        = densityplot.plot({name: tuple(x / unity for x in series) 
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
    plot_detail     = densityplot.plot({name: tuple(x / unity for x in series) 
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
        'densityplot_historical': '{0}/densityplot-historical.svg'.format(prefix),
        'densityplot_historical_detail': '{0}/densityplot-historical-detail.svg'.format(prefix),
        'historical_toolchains': '\n'.join('- `DEVELOPMENT-SNAPSHOT-{0}`'.format(nightly) for nightly in nightlies)
    }
    with open(fields['densityplot_historical'], 'w') as file:
        file.write(plot)
    with open(fields['densityplot_historical_detail'], 'w') as file:
        file.write(plot_detail)

    return fields
