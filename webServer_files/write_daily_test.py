# python/python-3.6.7

import os
import logging
import shutil
import datetime

if __name__ == '__main__':
        from sys import argv

        import argparse
        parser = argparse.ArgumentParser()
        parser.add_argument('path',
                            help='A path to a folder in which the sweeps analysis will be written.',
                            type=lambda path: path if os.path.exists(path) else parser.error(f'{path} does not exist!'))
        parser.add_argument('server', type=str,
                            help='server name')
        parser.add_argument('results_url', type=str, 
                            help='A url to results html.')
                            #type=lambda path: path if os.path.exists(path) else parser.error(f'{path} does not exist!'))
        parser.add_argument('final_pass_file', type=str,
                            help='pass file to be checked')
                            
        args = parser.parse_args()
        
        date = datetime.datetime.today().strftime('%d%m%Y')
        if os.path.exists(args.final_pass_file): 
            status = 'PASS'
        else:
            status = 'FAIL'
        with open(os.path.join(args.path, f'{args.server}_{date}.txt'), "w") as f:
            f.write(f'{status},{args.results_url}')
        f.close()
        
        

        
       

