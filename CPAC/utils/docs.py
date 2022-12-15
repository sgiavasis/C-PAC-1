# Copyright (C) 2022  C-PAC Developers

# This file is part of C-PAC.

# C-PAC is free software: you can redistribute it and/or modify it under
# the terms of the GNU Lesser General Public License as published by the
# Free Software Foundation, either version 3 of the License, or (at your
# option) any later version.

# C-PAC is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public
# License for more details.

# You should have received a copy of the GNU Lesser General Public
# License along with C-PAC. If not, see <https://www.gnu.org/licenses/>.
"""Utilties for documentation."""
import ast
from urllib import request
from urllib.error import ContentTooShortError, HTTPError, URLError
from CPAC import __version__
from CPAC.utils import versioning


def docstring_parameter(*args, **kwargs):
    """Decorator to parameterize docstrings.

    Examples
    --------
    >>> @docstring_parameter('test', answer='Yes it does.')
    ... def do_nothing():
    ...     '''Does this {} do anything? {answer}'''
    ...     pass
    >>> print(do_nothing.__doc__)
    Does this test do anything? Yes it does.
    """
    def dec(obj):
        if obj.__doc__ is None:
            obj.__doc__ = ''
        obj.__doc__ = obj.__doc__.format(*args, **kwargs)
        return obj
    return dec


def _docs_url_prefix():
    """Function to determine the URL prefix for this version of C-PAC"""
    def _url(url_version):
        return f'https://fcp-indi.github.io/docs/{url_version}'
    url_version = f'v{__version__}'
    try:
        request.urlopen(  # pylint: disable=consider-using-with
                        _url(url_version))
    except (ContentTooShortError, HTTPError, URLError):
        if 'dev' in url_version:
            url_version = 'nightly'
        else:
            url_version = 'latest'
    return _url(url_version)


def grab_docstring_dct(fn):
    """Function to grab a NodeBlock dictionary from a docstring.

    Parameters
    ----------
    fn : function
        The NodeBlock function with the docstring to be parsed.

    Returns
    -------
    dct : dict
        A NodeBlock configuration dictionary.
    """
    fn_docstring = fn.__doc__
    init_dct_schema = ['name', 'config', 'switch', 'option_key',
                       'option_val', 'inputs', 'outputs']
    if 'Node Block:' in fn_docstring:
        fn_docstring = fn_docstring.split('Node Block:')[1]
    fn_docstring = fn_docstring.lstrip().replace('\n', '')
    dct = ast.literal_eval(fn_docstring)
    for key in init_dct_schema:
        if key not in dct.keys():
            raise Exception('\n[!] Developer info: At least one of the '
                            'required docstring keys in your node block '
                            'is missing.\n\nNode block docstring keys:\n'
                            f'{init_dct_schema}\n\nYou provided:\n'
                            f'{dct.keys()}\n\nDocstring:\n{fn_docstring}\n\n')
    return dct


def version_report() -> str:
    """A formatted block of versions included in CPAC's environment"""
    version_list = []
    for pkg, version in versioning.REPORTED.items():
        version_list.append(f'{pkg}: {version}')
        if pkg == 'Python':
            version_list.append('  Python packages')
            version_list.append('  ---------------')
            for ppkg, pversion in versioning.PYTHON_PACKAGES.items():
                version_list.append(f'  {ppkg}: {pversion}')
    return '\n'.join(version_list)


DOCS_URL_PREFIX = _docs_url_prefix()
