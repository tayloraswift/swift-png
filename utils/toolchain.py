#!/usr/bin/python3

import sys, os, subprocess

class toolchain:
    def __init__(self, version = None):
        # if version is None, we just use the current toolchain specified in 
        # the .swiftenv file 
        self.version = version 
    
    def __enter__(self):
        try:
            os.mkdir('.build-historical')
        except FileExistsError:
            pass 
        
        result  = subprocess.run(('swiftenv', 'local'), capture_output = True)
        if result.returncode != 0:
            print('failed to query current swift toolchain')
            sys.exit(-1)
        self.original = result.stdout.decode('utf-8').split()[0]
        print('current toolchain is \'{0}\''.format(self.original))
        
        if self.version is not None:
            result  = subprocess.run(('swiftenv', 'install', self.version))
            # will fail if snapshot is already installed, which is fine
            
            result  = subprocess.run(('swiftenv', 'local', self.version))
            if result.returncode != 0:
                print('failed to set swift toolchain \'{0}\''.format(self.version))
                sys.exit(-1)
            
            print('swift toolchain set to \'{0}\''.format(self.version))
        
        return compression_benchmark('swift', '.build-historical/{0}'.format(self.version)) 
    
    def __exit__(self, type, value, traceback):
        if self.version is None:
            return 
        result  = subprocess.run(('swiftenv', 'local', self.original))
        if result.returncode != 0:
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
        remaining   = trials 
        series      = []
        while remaining > 0:
            invocation  = self.executable, str(level), file, str(min(remaining, 10))
            
            print(' '.join(invocation))
            
            result      = subprocess.run(invocation, capture_output = True)
            
            if result.returncode == 0:
                string = result.stdout.decode('utf-8')
                print(string, end = '')
                
                times, size = string.split(',')
                series.extend(map(float, times.split()))
            else:
                print(result.stderr.decode('utf-8'), end = '')
                
            remaining -= 10
        return {'series': series, 'size': int(size)} 
