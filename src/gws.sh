#!/usr/bin/env bash

gws_props_file_name='.projects.gws'
root_directory="$(pwd)"

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

######################################################################
# Common functions #
######################################################################

# Function to display usage information
usage() {
    echo "Usage: gws {init|update|list|version|-c <git_command>|-g <git_command>}"
    echo ""
    echo "Commands:"
    echo "  init            Initialize a new Git workspace by scanning for repositories"
    echo "  update          Update the Git workspace by cloning or pulling repositories"
    echo "  list            List all repositories in the current Git workspace"
    echo "  tree            Display tree of workspaces"
    echo "  version         Display the script version"
    echo "  -c <git command>    Run a Git command in repositories in the current directory"
    echo "  -g <git command>    Run a Git command in all repositories in the Git workspace"
    exit 1
}

# Function to log messages with different levels
log() {
    local log_level="$1"
    local message="$2"
    local color="${NC}" # Default color

    case "$log_level" in
    "error")
        color="$RED"
        ;;
    "warning")
        color="$YELLOW"
        ;;
    "info")
        color="$BLUE"
        ;;
    *)
        echo "${message}"
        return 0
        ;;
    esac

    local upper_log_level=$(echo "$log_level" | tr '[:lower:]' '[:upper:]')
    echo -e "${color}[${upper_log_level}] ${message}${NC}"
}

# Function to check if a directory is a Git project
is_git_project() {
    local target_dir="$1"

    # Check if the target directory exists
    if [ ! -d "$target_dir" ]; then
        log "error" "Directory '$target_dir' not found."
        return 1
    fi

    # Log info message
    log "info" "Scanning directory: $target_dir"

    # Find all Git repositories in the target directory and its subdirectories
    find "$target_dir" -type d -name .git | while read -r git_dir; do
        project_dir=$(dirname "$git_dir")
        project_name=$(basename "$project_dir")
        git_repo=$(cd "$project_dir" && git config --get remote.origin.url)

        if [ -n "$git_repo" ]; then
            log "info" "Project at $project_dir is a Git project."
        else
            log "error" "Folder $project_dir is not properly configured as a Git project."
        fi
    done
}

# Function to check if a file exists in the parent directories
check_file_in_parents() {
    local current_dir="$1"

    while [[ "$current_dir" != "/" && "$current_dir" != "." ]]; do
        if [[ -f "$current_dir/.projects.gws" ]]; then
            projects_gws_file_location="$current_dir"
            echo "${projects_gws_file_location}"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done
    return 1
}

# Function to find all Git repositories inside a directory
find_git_repos() {
    local dir=$1
    local repos=()

    # Use find command to locate all .git directories
    find "$dir" -type d -name ".git" -print0 | while IFS= read -r -d '' repo; do
        # Remove the "/.git" suffix from the directory path
        repo=${repo%/.git}

        # Determine project_name (relative path from root_directory)
        project_name=${repo%"${repo##*[!/]}"}
        project_name=${project_name#"$dir"}
        project_name=${project_name#/}

        remote_url=$(git -C "$repo" config --get remote.origin.url)

        # Check if remote_url is empty
        if [ -n "$remote_url" ]; then
            # Add to repos array
            echo "Find ${project_name} : ${remote_url}"

            echo "${project_name} ${remote_url}" >>"${root_directory}/${gws_props_file_name}"
        else
            log "warning" "Project ${project_name} is not already created on remote"
        fi
    done
}

# Function to verify if a git command is valid
is_git_command() {
    local command="$1"
    if git help -a | awk '/^  / {print $1}' | grep -qx "$command"; then
        return 0
    else
        return 1
    fi
}

# Function to read file and save lines to an array
read_file() {
    local file=$1
    if [[ ! -f $file ]]; then
        echo "File not found: $file"
        exit 1
    fi

    local lines=()
    while IFS= read -r line; do
        # Skip empty lines and lines starting with #
        if [[ -n $line && ! $line =~ ^# ]]; then
            lines+=("$line")
        fi
    done <"$file"

    # Return the lines array
    echo "${lines[@]}"
}

# Function to check if a directory is a Git repository
is_git_repo() {
    local project_location=$1
    if [ -d "$1/.git" ]; then
        return 0
    else
        return 1
    fi
}

# Function to iterate projects and return a map
iterate_projects_and_return_map() {
    local file=$1
    local -a projects  # Declare an indexed array

    # Read the projects into the array
    IFS=' ' read -r -a projects <<<"$(read_file "$file")"

    # Check if the number of projects is even
    if (( ${#projects[@]} % 2 != 0 )); then
        echo "Error: The input file should contain an even number of entries."
        return 1
    fi

    # Create a temporary file to store project-repo pairs
    local temp_file=$(mktemp)

    # Iterate over the projects array and process each pair
    for ((i = 0; i < ${#projects[@]}; i += 2)); do
        local project="${projects[i]}"
        local repo="${projects[i + 1]}"
        
        # Store the project-repo pair in the temporary file
        echo "$project : $repo" >> "$temp_file"
    done

    echo "$temp_file"  # Output the path to the temporary file
}


# Function to clone a project if it's not already a Git repository
clone_project() {
    local project_location=$1
    local project_repo=$2
    local gws_location=$3

    is_git_repo "${gws_location}/${project_location}"
    if [[ $? -eq 1 ]]; then
        log "info" "Start cloning $project_repo at ${gws_location}/${project_location}"
        git clone "$project_repo" "${gws_location}/${project_location}"
        log "info" "Finish cloning $project_repo"
    else
        log "info" "$project_location is already a Git repository"
    fi
}

# Function to check if the Git repository is clean
is_repo_clean() {
    local dir=$1
    cd "$dir" || return 1
    if [ -z "$(git status --porcelain)" ]; then
        return 0
    else
        return 1
    fi
}

# Function to execute a Git command for projects
execute_git_command_for_projects() {
    local dir=$1
    local project=$2
    local git_command=$3

    log "info" "--------------------------------------- Project: ${project} ---------------------------------------"

    is_git_repo "${dir}/${project}"
    if [[ $? -eq 1 ]]; then
        log "error" "${dir}/${project} is not a Git repository"
        return 1
    fi

    if [[ "$git_command" != "status" ]]; then
        is_repo_clean "${dir}/${project}"
        if [[ $? -eq 1 ]]; then
            log "error" "${project} has uncommitted changes. Please commit or stash them before running the command."
            return 1
        fi
    fi

    cd "${dir}/${project}" || return 1

    eval "git $git_command"

    if [[ $? -eq 0 ]]; then
        log "info" "Command 'git $git_command' executed successfully in $project"
        echo ""
        echo ""
    else
        log "error" "Failed to execute command 'git $git_command' in $project"
    fi
}

print_indent() {
    local index=$1
    local text=$2

    local message=""
    local iteration=$((index * 4))

    local i=0

    while [ $i -le $iteration ]; do
        i=$((i + 1))
        message="$message "
    done

    echo "$message$text"
}

draw_tree() {
    local folder_list=("$@")

    # Sort the folder list
    IFS=$'\n' sorted_folders=($(sort <<<"${folder_list[*]}"))
    unset IFS

    local printed_folder_list=""

    # Draw the tree
    for folder in "${sorted_folders[@]}"; do
        local IFS='/'
        read -ra path_array <<<"$folder"
        unset IFS
        for index in "${!path_array[@]}"; do
            folder_name="${path_array[index]}"
            folder_key="${folder_name}-${index}"

            # Check if folder_key is already in printed_folder_list
            if [[ ! "$printed_folder_list" == *"$folder_key"* ]]; then
                if [[ index -eq 0 ]]; then
                    print_indent $index "$folder_name"
                else
                    print_indent $index "└──$folder_name"
                fi

                printed_folder_list="${printed_folder_list};${folder_key}"
            fi
        done
    done
}

read_keys_from_map() {
    local -n map=$1

    keys_list=("${!map[@]}")
    echo "${keys_list[@]}"
}
######################################################################
# End of common functions
######################################################################

######################################################################
# Specific git command functions
######################################################################

# Function to update the Git workspace
_update() {
    local gws_file_loc=$(check_file_in_parents "${root_directory}")
    local status=$?

    if [[ $status -eq 0 && -n "$gws_file_loc" ]]; then
        log "info" "Your current gws config is at ${gws_file_loc}"
        
        # Get the path to the temporary file with project-repo pairs
        local temp_file=$(iterate_projects_and_return_map "${gws_file_loc}/${gws_props_file_name}")

        # Check if the temporary file was created successfully
        if [[ ! -f "$temp_file" ]]; then
            log "error" "Failed to create a temporary file for project-repo pairs."
            exit 1
        fi

        cat "${temp_file}"

        # Read the project-repo pairs from the temporary file
        while IFS=' : ' read -r project repo; do
            clone_project "${gws_file_loc}/${project}" "${repo}"
        done < "$temp_file"

        # Clean up the temporary file
        rm "$temp_file"
    else
        log "error" "Not in a Git workspace"
        exit 1
    fi
}

# Function to initialize a new Git workspace
_init() {
    local gws_file_loc=$(check_file_in_parents ${root_directory})
    status=$?

    if [[ $status -eq 0 && -n "$gws_file_loc" ]]; then
        log "error" "Git workspaces already setup at ${gws_file_loc}"
        exit 1
    else
        find_git_repos "$root_directory"
    fi
}

# Function to list all repositories in the current Git workspace
_list() {
    local gws_file_loc
    gws_file_loc=$(check_file_in_parents "${root_directory}")
    local status=$?

    if [[ $status -eq 0 && -n "$gws_file_loc" ]]; then
        log "info" "Your current gws config is at ${gws_file_loc}"
        
        # Get the path to the temporary file with project-repo pairs
        local temp_file
        temp_file=$(iterate_projects_and_return_map "${gws_file_loc}/${gws_props_file_name}")

        # Check if the temporary file was created successfully
        if [[ ! -f "$temp_file" ]]; then
            log "error" "Failed to create a temporary file for project-repo pairs."
            exit 1
        fi

        # Read the project-repo pairs from the temporary file and log them
        while IFS=' : ' read -r project repo; do
            echo "${project} : ${repo}"
        done < "$temp_file"

        # Clean up the temporary file
        rm "$temp_file"
    else
        log "error" "Not in a Git workspace"
        exit 1
    fi
}


# Function to run a Git command in repositories in the current directory
_git_command_c() {
    local git_command="$@"
    
    if is_git_command "$git_command"; then
        local gws_file_loc
        gws_file_loc=$(check_file_in_parents "${root_directory}")
        local status=$?

        if [[ $status -eq 0 && -n "$gws_file_loc" ]]; then
            log "info" "Your current gws config is at ${gws_file_loc}"

            local current_dir
            current_dir="$(pwd)"
            
            # Get the path to the temporary file with project-repo pairs
            local temp_file
            temp_file=$(iterate_projects_and_return_map "${gws_file_loc}/${gws_props_file_name}")

            # Check if the temporary file was created successfully
            if [[ ! -f "$temp_file" ]]; then
                log "error" "Failed to create a temporary file for project-repo pairs."
                exit 1
            fi

            # Read the project-repo pairs from the temporary file
            while IFS=' : ' read -r project repo; do
                if [[ "${gws_file_loc}/${project}" == *"${current_dir}"* ]]; then
                    execute_git_command_for_projects "${gws_file_loc}" "${project}" "${git_command}"
                fi
            done < "$temp_file"

            # Clean up the temporary file
            rm "$temp_file"
        else
            log "error" "Not in a Git workspace"
            exit 1
        fi
    else
        log "error" "Unknown git command: $1"
        exit 1
    fi
}


# Function to run a Git command in all repositories in the Git workspace
_git_command_g() {
    local git_command="$@"

    if is_git_command "$git_command"; then
        local gws_file_loc
        gws_file_loc=$(check_file_in_parents "${root_directory}")
        local status=$?

        if [[ $status -eq 0 && -n "$gws_file_loc" ]]; then
            log "info" "Your current gws config is at ${gws_file_loc}"

            # Get the path to the temporary file with project-repo pairs
            local temp_file
            temp_file=$(iterate_projects_and_return_map "${gws_file_loc}/${gws_props_file_name}")

            # Check if the temporary file was created successfully
            if [[ ! -f "$temp_file" ]]; then
                log "error" "Failed to create a temporary file for project-repo pairs."
                exit 1
            fi

            # Read the project-repo pairs from the temporary file
            while IFS=' -> ' read -r project repo; do
                execute_git_command_for_projects "${gws_file_loc}" "${project}" "${git_command}"
            done < "$temp_file"

            # Clean up the temporary file
            rm "$temp_file"
        else
            log "error" "Not in a Git workspace"
            exit 1
        fi
    else
        log "error" "Unknown git command: $1"
        exit 1
    fi
}


# Function to display the script version
_version() {
    echo "Version 1.0.0"
}

_tree() {
    local gws_file_loc
    gws_file_loc=$(check_file_in_parents "${root_directory}")
    local status=$?

    if [[ $status -eq 0 && -n "$gws_file_loc" ]]; then
        log "info" "Your current gws config is at ${gws_file_loc}"

        # Get the path to the temporary file with project-repo pairs
        local temp_file
        temp_file=$(iterate_projects_and_return_map "${gws_file_loc}/${gws_props_file_name}")

        # Check if the temporary file was created successfully
        if [[ ! -f "$temp_file" ]]; then
            log "error" "Failed to create a temporary file for project-repo pairs."
            exit 1
        fi

        # Read project-repo pairs and extract project folders
        local folder_list=()
        while IFS=' -> ' read -r project repo; do
            folder_list+=("$project")  # Collect project names into an array
        done < "$temp_file"

        # Draw the tree using the collected folder list
        draw_tree "${folder_list[@]}"

        # Clean up the temporary file
        rm "$temp_file"
    else 
        log "error" "Not in a Git workspace"
    fi
}


if [ $# -eq 0 ]; then
    usage
fi

case $1 in
init)
    _init
    ;;
update)
    _update $2
    ;;
list)
    _list
    ;;
version)
    _version
    ;;
tree)
    _tree
    ;;
-c)
    shift
    _git_command_c "$@"
    ;;
-g)
    shift
    _git_command_g "$@"
    ;;
help)
    usage
    ;;
*)
    usage
    ;;
esac
