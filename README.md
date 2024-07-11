# GWS (Git Workspace)

GWS is a shell script utility for managing multiple Git repositories within a specified root directory. It helps initialize, update, and manage repositories with ease. The script also provides functionalities to run Git commands on these repositories.

## Features

- Initialize a new Git workspace
- Update the Git workspace by cloning or pulling repositories
- List all repositories in the current Git workspace
- Run Git commands on repositories in the current directory or the entire workspace

## Installation

### Prerequisites

- [Git](https://git-scm.com/) should be installed on your system
- [Bash](https://www.gnu.org/software/bash/) shell (compatible with Zsh)

### Steps

Certainly! Here's the content for your `README.md` file without any markdown formatting:

# Project Setup

## Setup Instructions

1. Clone the Project:

   ```
   git clone https://github.com/duyleduc/gws.git
   ```

2. Navigate to the Cloned Directory:

   ```
   cd gws/src
   ```

3. Make the Script Executable:

   ```
   chmod +x gws.sh
   ```

4. Create an Alias:

   ```
   echo "alias gws='$(pwd)/gws.sh'" >> ~/.bashrc
   ```

   For Zsh users:

   ```
   echo "alias gws='$(pwd)/gws.sh'" >> ~/.zshrc
   ```

5. **Reload Your Shell Configuration**:

   For Bash users:

   ```sh
   source ~/.bashrc
   ```

   For Zsh users:

   ```sh
   source ~/.zshrc
   ```

## Usage

### Basic Commands

- **Initialize a Git Workspace**:

  ```sh
  gws init
  ```

  This command scans the current directory and its subfolders for Git repositories and creates a configuration file.

- **Update the Git Workspace**:

  ```sh
  gws update
  ```

  This command clones or updates repositories based on the configuration file in the current Git workspace.

- **List Repositories**:

  ```sh
  gws list
  ```

  This command lists all repositories and their remote URLs in the current Git workspace.

- **Run Git Commands on Repositories in the Current Directory**:

  ```sh
  gws -c <git_command>
  ```

  This command runs the specified Git command on repositories in the current directory.

- **Run Git Commands on All Repositories in the Git Workspace**:

  ```sh
  gws -g <git_command>
  ```

  This command runs the specified Git command on all repositories in the Git workspace.

- **Display Script Version**:

  ```sh
  gws version
  ```

  This command displays the version of the script.

### Example Usages

- **Initialize a Git Workspace**:

  ```sh
  gws init
  ```

- **Update a Git Workspace**:

  ```sh
  gws update
  ```

- **List Repositories**:

  ```sh
  gws list
  ```

- **Run `git status` in the Current Directory**:

  ```sh
  gws -c status
  ```

- **Run `git pull` on All Repositories in the Git Workspace**:

  ```sh
  gws -g pull
  ```

## How to Update

To update the `gws.sh` script, simply pull the latest code from git repository.
```sh
cd gws 
git pull
```

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.
