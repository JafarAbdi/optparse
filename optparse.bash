# Optparse - a BASH wrapper for getopts
# https://github.com/nk412/optparse

# Copyright (c) 2015 Nagarjuna Kumarappan
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Author: Nagarjuna Kumarappan <nagarjuna.412@gmail.com>

optparse_usage=""
optparse_contractions=""
optparse_defaults=""
optparse_process=""
optparse_arguments_string=""
optparse_process_completion=""
short_options=""
long_options=""
required_short_options=""
required_long_options=""
declare -A hash_options

# -----------------------------------------------------------------------------------------------------------------------------
function optparse.throw_error(){
  local message="$1"
        echo "OPTPARSE: ERROR: $message"
        exit 1
}

# -----------------------------------------------------------------------------------------------------------------------------
function optparse.define(){
        if [ $# -lt 3 ]; then
                optparse.throw_error "optparse.define <short> <long> <variable> [<desc>] [<default>] [<value>]"
        fi
        for option_id in $( seq 1 $# ) ; do
                local option="$( eval "echo \$$option_id")"
                local key="$( echo $option | awk -F "=" '{print $1}' )";
                local value="$( echo $option | awk -F "=" '{print $2}' )";

                #essentials: shortname, longname, description
                if [ "$key" = "short" ]; then
                        local shortname="$value"
                        if [ ${#shortname} -ne 1 ]; then
                                optparse.throw_error "short name expected to be one character long"
                        fi
                        local short="-${shortname}"
                elif [ "$key" = "long" ]; then
                        local longname="$value"
                        if [ ${#longname} -lt 2 ]; then
                                optparse.throw_error "long name expected to be atleast one character long"
                        fi
                        local long="--${longname}"
                elif [ "$key" = "desc" ]; then
                        local desc="$value"
                elif [ "$key" = "default" ]; then
                        local default="$value"
                elif [ "$key" = "variable" ]; then
                        local variable="$value"
                elif [ "$key" = "value" ]; then
                        local val="$value"
                elif [ "$key" = "list" ]; then
                        local list="$value"
				elif [ "$key" = "required" ]; then
                        local required="$value"
                fi
        done

        if [ "$variable" = "" ]; then
                optparse.throw_error "You must give a variable for option: ($short/$long)"
        fi

        if [ "$val" = "" ]; then
                val="\$OPTARG"
        fi

        # build OPTIONS and help
        optparse_usage="${optparse_usage}#NL#TB${short} $(printf "%-25s %s" "${long}:" "${desc}")"
        if [ "$default" != "" ]; then
                optparse_usage="${optparse_usage} [default:$default]"
        fi
        optparse_contractions="${optparse_contractions}#NL#TB#TB${long})#NL#TB#TB#TBparams=\"\$params ${short}\";;"
        optparse_contractions="${optparse_contractions}#NL#TB#TB${long}=*)#NL#TB#TB#TBparams=\"\$params ${short}=\${param#*=}\";;"
        if [ "$default" != "" ]; then
                optparse_defaults="${optparse_defaults}#NL${variable}=${default}"
        fi
        optparse_arguments_string="${optparse_arguments_string}${shortname}"
        if [ "$val" = "\$OPTARG" ]; then
                optparse_arguments_string="${optparse_arguments_string}:"
        fi
        optparse_process="${optparse_process}#NL#TB#TB${shortname})#NL#TB#TB#TB${variable}=\"$val\""
        optparse_process="${optparse_process}#NL#TB#TB#TB\$(grep -q '^=' <<< \"\$OPTARG\") && hash_options[-${shortname}\"\$OPTARG\"]=${long}\"\$OPTARG\";;"
        # Complete options
        long_options="${long_options} ${long}"
        short_options="${short_options} ${short}"
        # Complete command arguments
        if [ "$list" != "" ]; then
                optparse_process_completion="${optparse_process_completion}#NL#TB#TB${long})#NL#TB#TB#TB${variable}_list=\"$list\"#NL#TB#TB#TBCOMPREPLY=( \$(compgen -W \"\${${variable}_list}\" -- \${cur}) )#NL#TB#TB#TBreturn 0;;"
        fi
        # Take obligatory parameters
        if [ "$required" == "true" ]; then
            required_short_options="${required_short_options} ${short}"
            required_long_options="${required_long_options} ${long}"
	    fi
       hash_options["${short}"]="${long}"
}

# -----------------------------------------------------------------------------------------------------------------------------
function optparse.build(){
        local script=${1:?}
        local build_file="$(mktemp -t "optparse-XXXXXX.tmp")"
        local completion_dir="/etc/bash_completion.d/"
        local completion_file="${completion_dir}${script}"

        # Building getopts header here

        # Function usage
        cat << EOF > $build_file
function usage(){
cat << XXX
usage: \$0 [OPTIONS]

OPTIONS:
        $optparse_usage

        -? --help  :  usage

XXX
}

# Contract long options into short options
params=""
while [ \$# -ne 0 ]; do
        param="\$1"
        shift

        case "\$param" in
                $optparse_contractions
                "-?"|--help)
                        usage
                        exit 0;;
                *)
                        if [[ "\$param" == --* ]]; then
                                echo -e "Unrecognized long option: \$param"
                                usage
                                exit 1
                        fi
                        params="\$params \"\$param\"";;
        esac
done

eval set -- "\$params"

# Set default variable values
$optparse_defaults

# Get required options and parameters
required_short_options="$( sed 's/^ //' <<< "$required_short_options")"
required_long_options="$( sed 's/^ //' <<< "$required_long_options")"

# Create an associative array with with short options as keys and long options as values
declare -A hash_options=(\
$(for option in ${short_options}
do
echo -n "[$option]=${hash_options[$option]} "
done))

# Process using getopts
while getopts "$optparse_arguments_string" option; do
        # Return error when argument is an option of type Ex: --option or --option=xxxxx
        [[ -n "\$OPTARG" ]] && [[ "\${required_short_options}" == *"\${OPTARG/=*/}"* ]] && echo "Invalid parameter: \${hash_options["\${OPTARG/=*/}"]}"=\${OPTARG#*=} && usage
        case \$option in
                # Substitute actions for different variables
                $optparse_process
                :)
                        echo "Option - \$OPTARG requires an argument"
                        exit 1;;
                *)
                        echo "Unknown option: \$option"
                        usage
                        exit 1;;
        esac
done

# Clean up after self
rm $build_file

EOF

# Create completion script
mkdir -p $completion_dir
        cat << EOF > $completion_file
_$script(){
        local cur prev options
        COMPREPLY=()
        cur=\${COMP_WORDS[COMP_CWORD]}
        prev=\${COMP_WORDS[COMP_CWORD-1]}

        # The basic options we'll complete.
        options="${long_options}"

        # Complete the arguments to some of the basic commands.
        case \$prev in
                $optparse_process_completion
                *)
        esac
        COMPREPLY=(\$(compgen -W "\${options}" -- \${cur}))
        return 0
}
complete -F _$script $script
EOF

        local -A o=( ['#NL']='\n' ['#TB']='\t' )

        for i in "${!o[@]}"; do
                sed -i "s/${i}/${o[$i]}/g" $build_file
                sed -i "s/${i}/${o[$i]}/g" $completion_file
        done

        # Unset global variables
        unset optparse_usage
        unset optparse_process
        unset optparse_arguments_string
        unset optparse_defaults
        unset optparse_contractions
        unset long_options

        # Return file name to parent
        echo "$build_file"
}
# -----------------------------------------------------------------------------------------------------------------------------
