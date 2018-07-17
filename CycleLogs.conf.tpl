# configuration file template
# this is a comment followed by an empty line

# if the directory is not full qualified, we consider the current directory as the root directory
logs:weekly:archive

# environment variables are automatically expanded
$HOME/logs:monthly:purge

# this way also can work
${HOME}/logs:yearly:purge
