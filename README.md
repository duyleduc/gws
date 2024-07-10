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

1. **Download the Script**:

   ```sh
   curl -o ~/gws.sh https://raw.githubusercontent.com/yourusername/gws/main/gws.sh
   ```

2. **Make the Script Executable**:

   ```sh
   chmod +x ~/gws.sh
   ```

3. **Create an Alias**:

   Add the following line to your `.bashrc` or `.zshrc` file to create an alias for the script:

   ```sh
   echo "alias gws='~/gws.sh'" >> ~/.bashrc
   ```

   For Zsh users:

   ```sh
   echo "alias gws='~/gws.sh'" >> ~/.zshrc
   ```

4. **Reload Your Shell Configuration**:

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

To update the `gws.sh` script, simply download the latest version and replace the existing script:

```sh
curl -o ~/gws.sh https://raw.githubusercontent.com/yourusername/gws/main/gws.sh
chmod +x ~/gws.sh
```

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.