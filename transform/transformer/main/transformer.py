import os

import click
import importlib

from helpers.config import Config
from helpers.helpers import print_msg, print_info, print_error, print_verbose, find_ranges


class Transformer:

    def __init__(self, input_file, plugin, output_file, config_file):
        self.input_file = click.format_filename(os.path.realpath(input_file))
        self.plugin = plugin
        self.config_file = os.path.realpath(config_file)
        self.output_file =  click.format_filename(os.path.realpath(output_file))

        self._load_config_file()
        self._print_debug_infos()

    def _print_debug_infos(self):
        click.echo('Source filename:' + self.input_file)
        click.echo('Destination filename:' + self.output_file)
        click.echo('Plugin:' + self.plugin)

    def _load_config_file(self):
        if self.config_file != '' and os.path.exists(self.config_file) :
            print_verbose(f'Actions config file: {self.config_file}')
            Config.load(self.config_file)
        else:
            print_error(f'Actions config file "${self.config_file}" not exists !')

    def _set_config_parameters(self):
        Config.setParameter('transform.input', self.input_file)
        Config.setParameter('transform.output', self.output_file)

    def run(self):
        plugin_module = importlib.import_module(f'plugins.{self.plugin.lower()}')
        PluginClass = getattr(plugin_module, self.plugin.capitalize())
        transform_plugin = PluginClass(input_file=self.input_file, output_file=self.output_file)
        transform_plugin.run()
