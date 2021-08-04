#!/bin/bash

# Source the optparse.bash file ---------------------------------------------------
source optparse.bash

# Define options
optparse.define short=n long=name desc="The event name" variable=name
optparse.define short=s long=say-hello desc="Say Hello" variable=say_hello value=true default=false
optparse.define short=c long=country desc="The event country" variable=country list="USA Canada Japan Brasil England"
optparse.define short=y long=year desc="The event year" variable=year required=true

# Generate optparse and autocompletion scripts
source $(optparse.build)

# Display event information
if [[ "$say_hello" == "true" ]]; then
    salute="Hello!!! "
fi
echo $salute "The $name event will be in $country in $year."
