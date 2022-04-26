import os
import sys
import time
import datetime

import click


# Define OS Environment variables
root_dir = os.path.realpath(f'{os.path.dirname(os.path.abspath(__file__))}/../../')
config_shared_dir = os.path.realpath(f'{root_dir}/shared/config/')
app_dir = os.path.realpath(f'{os.path.dirname(os.path.abspath(__file__))}/../')
config_dir = os.path.realpath(f'{app_dir}/config/')
data_dir = os.path.realpath(f'{app_dir}/data/')

os.environ['IMPORT_PARSER.PATHES.ROOT'] = root_dir
os.environ['IMPORT_PARSER.PATHES.SHARED.CONFIG'] = config_shared_dir
os.environ['IMPORT_PARSER.PATHES.APP'] = app_dir
os.environ['IMPORT_PARSER.PATHES.APP.CONFIG'] = config_dir
os.environ['IMPORT_PARSER.PATHES.APP.DATA'] = data_dir

from helpers.config import Config
from helpers.helpers import print_msg, print_info, print_error, print_verbose, find_ranges
from main.transformer import Transformer

@click.command()
@click.argument(
    'filename',
    type=click.Path(exists=True),
)
@click.option(
    '-p',
    '--plugin',
    'plugin',
    default='ajaris',
    help='Type of transform plugin to apply on input file',
)
@click.option(
    '-c',
    '--config',
    'config_file',
    default=f'{config_dir}/settings.default.ini',
    type=click.Path(exists=True),
    help='Config file to load.',
)
@click.option(
    '-d',
    '--output-dir',
    'output_dir',
    default=f'{data_dir}/',
    type=click.Path(exists=True),
    help='Directory where the output file is stored.',
)
@click.option(
    '-o',
    '--output-file',
    'output_file',
    default='output.txt',
    help='Name of output file.',
)
def transform_file(filename, plugin, config_file, output_dir, output_file):
    """
    Transformer

    This script parse input files and apply some transformations on it.
    """
    start_time = time.time()

    transform = Transformer(
        input_file=filename,
        plugin=plugin,
        config_file=config_file,
        output_file=f'{output_dir}/{output_file}',
    )
    transform.run()

    # Script time elapsed
    time_elapsed = time.time() - start_time
    time_elapsed_for_human = str(datetime.timedelta(seconds=time_elapsed))


if __name__ == '__main__':
    transform_file()
