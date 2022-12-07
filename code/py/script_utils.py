import os
from datetime import datetime as dt
from yaml import CLoader as Loader, load


ansii_colors = {
    "magenta": "[1;35;2m",
    "green": "[1;9;2m",
    "red": "[1;31;1m",
    "cyan": "[1;36;1m",
    "gray": "[1;30;1m",
    "black": "[0m",
}

colors = {
    "process": ansii_colors["green"],
    "time": ansii_colors["magenta"],
    "normal": ansii_colors["gray"],
    "warning": ansii_colors["red"],
    "success": ansii_colors["cyan"],
}


def show_output(text, color="normal", multi=False, time=False, **kwargs):
    """
    get colored output to the terminal
    """
    time = (
        f"\033{colors['time']}{dt.now().strftime('%H:%M:%S')}\033[0m : " if time else ""
    )
    proc = f"\033{colors['process']}Process {os.getpid()}\033[0m : " if multi else ""
    text = f"\033{colors[color]}{text}\033[0m"
    print(time + proc + text, **kwargs)


def load_config_file(config_file):
    '''
    loads a yaml_config
    '''

    with open(config_file, "r") as stream:
        return load(stream, Loader=Loader)


def load_config(config_file="", *, config_path="", **kwargs):
    '''
    passes configs to inner functions
    directly passed arguments overwrite config
    '''

    if config_path and not config_file.startswith("/"):
        config_file = os.path.join(config_path, config_file)
    if not os.path.splitext(config_file) in [".yml", "yaml"]:
        config_file = config_file + ".yml"
    try:
        config = load_config_file(config_file)
    except:
        show_output(f"config file {config_file} could not be loaded", color="warning")
        return {}

    path_config = config['paths']
    if not path_config['base_path'].startswith("/"):
        path_config['base_path'] = os.path.join(os.environ['HOME'], path_config['base_path'])
    for path in ['data', 'output', 'info', 'img', 'tables']:
        key = f"{path}_path"
        if not path_config[key].startswith("/"):
            path_config[key] = os.path.join(path_config['base_path'], path_config[key])

    # load in the kwargs to overwrite config
    config.update(kwargs)
    show_output(f"config file {config_file} successfully loaded", color="success")
    
    # build the output paths
    pc = config['paths']
    for folder in ['output_path', 'img_path', 'tables_path']:
        if not os.path.isdir(pc[folder]):
            show_output(f"Creating folder {pc[folder].replace(pc['base_folder'], '')} in base folder")
            os.makedirs(pc[folder])

    return config