# Optparse
A BASH wrapper for getopts and compgen, for simple command-line argument parsing an bash completion.

### ( ! ) ATTENTION MAC USERS
Optparse requires `gnu-sed` instead of the default Mac version of sed, which you can do with the following:
```
brew install gnu-sed --with-default-names
```

## What is this?
A wrapper that provides a clean and easy way to parse arguments and create Tab completion to your BASH scripts. You could also create wrappers for linux commands. It lets you define short and long option names, handle flag variables, and set default values for optional arguments, and an optional list of posible values for options to complete, all while aiming to be as minimal as possible: *One line per argument definition*.

## Usage
##### See `sample_head.sh` for a demonstration of optparse
### 1. Define your arguments

Each argument to the script is defined with `optparse.define`, which specifies the option names, a short description, the variable it sets and the default value (if any) and a list of posible values (if any). Also you could define options as required to your script. If you use filesystem file parameters you could define the parameter as a file.

```bash
optparse.define short=f long=file desc="The input file" variable=filename
```

Flags are defined in exactly the same way, but with an extra parameter `value` that is assigned to the variable.

```bash
optparse.define short=v long=verbose desc="Set flag for verbose mode" variable=verbose_mode value=true default=false
```

Posible arguments could be defined in exactly the same way, but with an extra parameter `list` that is assigned to the variable.

```bash
optparse.define short=c long=country desc="The event country" variable=country list="USA Canada Japan Brasil England"
```

Required parameters are defined in exactly the same way, but with an extra parameter `required` that is assigned to the variable.

```bash
optparse.define short=y long=year desc="The event year" variable=year required=true
```

Another way to pass a completion list is to assign a command output to list variable as follow.

```bash
optparse.define short=y long=year desc="The event year" variable=year list="\$(my_command)"
```

File parameters are defined in exactly the same way, but with an extra parameter `file` that is assigned to the variable. See `wget_dir_generate_completion.sh` as example.

```bash
optparse.define short=x long=directory-prefix desc="Destination directory to save all files" variable=directory file=true required=true
```

### 2. Evaluate your arguments
The `optparse.build` function creates a temporary header script and a configuration file in /etc/bash_completion.d/ based on the provided argument definitions. Simply source the file the function returns, to parse the arguments.

```bash
optparse.build script_name
```

If you want to generate completion file in another location, you could path location as parameter to `optparse.build` function.

```bash
optparse.build script_name "."
```

### 3. Allow execution to the script and execute it as sudo.
##### See `sample_event_generate_completion.sh` for a demonstration. For a more complex example see `wget_dir_generate_completion.sh`.
### 4. Source profile bash completion configuration, example:

```bash
source /etc/bash_completion
```

### 5. In your command script( The script to parse arguments and generate completion ) source the optparse generated file to parse and evaluate arguments. Also you could check if there are missing options.

#### That's it!
The script can now show completion and make use of the variables. Running the script (without any arguments) should give you a neat usage description.

    usage: ./script.sh [OPTIONS]

    OPTIONS:

        -n --name  :  The event name
        -s --say-hello:  Say Hello [default:false]
        -c --country  :  The country name
        -y --year  :  The year

        -? --help  :  usage


##### See `sample_event.sh` for a demonstration. For a more complex example see `wget_dir.sh`.

### Now to use the command script we can write:
```bash
$ ./sample_event.sh [TAB][TAB]
$ --name --country --year
$ ./sample_event.sh --country [TAB][TAB]
$ USA Canada Japan Brasil
$ ./sample_event.sh --name "Football World Cup" --country Brasil --year 2014
$ The Football World Cup will be in Brasil in 2014.
$ ./sample_event.sh --sey-hello --name "Football World Cup" --country Brasil --year 2014
$ Hello!!! The Football World Cup will be in Brasil in 2014.
```

## Supported definition parameters
All definition parameters for `optparse.define` are provided as `key=value` pairs, seperated by an `=` sign.
#### `short`
a short, single-letter name for the option
#### `long`
a longer expanded option name
#### `variable`
the target variable that the argument represents
#### `value`(optional)
the value to set the variable to. If unspecified, user is expected to provide a value.
#### `desc`(optional)
a short description of the argument (to build the usage description)
#### `default`(optional)
the default value to set the variable to if argument not specified
#### `list`(optional)
the list of posible arguments for an option to autocomplete. It could be a list of strings or a command.
#### `required`(optional)
the requirement for the option

## Installation
1. Download/clone `optparse.bash`
2. Add

```bash
`source /path/to/optparse.bash`
```
to `~/.bashrc`
