"""Test to check if all expected outputs were generated"""
import fnmatch
import os
from logging import Logger

import yaml

from CPAC.utils.monitoring.custom_logging import getLogger, set_up_logger


def check_outputs(output_dir, log_dir, pipe_name, unique_id):
    """Check if all expected outputs were generated

    Parameters
    ----------
    output_dir : str
        Path to the output directory

    log_dir : str
        Path to the log directory

    pipe_name : str

    unique_id : str

    Returns
    -------
    message :str
    """
    outputs_logger = getLogger(f'expected_outputs_{unique_id}')
    missing_outputs = ExpectedOutputs()
    container = os.path.join(f'cpac_{pipe_name}', unique_id)
    if isinstance(outputs_logger, Logger) and len(outputs_logger.handlers):
        outputs_log = getattr(outputs_logger.handlers[0], 'baseFilename', None)
    else:
        outputs_log = None
    if outputs_log is None:
        message = 'Could not find expected outputs log file'
    else:
        with open(outputs_log, 'r') as expected_outputs_file:
            expected_outputs = yaml.safe_load(expected_outputs_file.read())
        for subdir, filenames in expected_outputs.items():
            observed_outputs = os.listdir(
                os.path.join(output_dir, container, subdir))
            for filename in filenames:
                if not fnmatch.filter(observed_outputs,
                                      f'*{unique_id}*'
                                      f'{filename.replace(unique_id, "")}*'):
                    missing_outputs += (subdir, filename)
        if missing_outputs:
            missing_log = set_up_logger(f'missing_outputs_{unique_id}',
                                        filename='missing_outputs.yml',
                                        level='info', log_dir=log_dir)
            missing_log.info(missing_outputs)
            try:
                log_note = 'Missing outputs have been logged in ' \
                           f'{missing_log.handlers[0].baseFilename}'
            except (AttributeError, IndexError):
                log_note = ''
            message = '\n'.join([string for string in [
                'Missing expected outputs:', yaml.dump(missing_outputs),
                log_note] if string])
        else:
            message = 'All expected outputs were generated'
    for logger in [missing_log, outputs_logger]:
        logger.delete()
    return message


class ExpectedOutputs:
    '''Class to hold expected outputs for a pipeline

    Attributes
    ----------
    expected_outputs : dict
        dictionary of expected output subdirectories and files therein

    Methods
    -------
    add(subdir, output)
        Add an expected output to the expected outputs dictionary
    '''
    def __init__(self):
        self.expected_outputs = {}

    def __bool__(self):
        return bool(len(self))

    def __len__(self):
        return len([filepath for subdir, filepaths in
                    self.expected_outputs.items() for filepath in filepaths])

    def __iadd__(self, other):
        if not isinstance(other, tuple) or not len(other) == 2:
            raise TypeError(
                f'{self.__module__}.{self.__class__.__name__} requires a '
                "tuple of ('subdir', 'output') for addition")
        self.add(*other)
        return self

    def __repr__(self):
        return self.__str__()

    def __str__(self):
        return yaml.dump({subdir: sorted(list(filename)) for
                          subdir, filename in self.expected_outputs.items()})

    def add(self, subdir, output):
        '''Add an expected output to the expected outputs dictionary

        Parameters
        ----------
        subdir : str
            subdirectory of expected output

        output : str
            filename of expected output
        '''
        if subdir in self.expected_outputs:
            self.expected_outputs[subdir].add(output)
        else:
            self.expected_outputs[subdir] = {output}
