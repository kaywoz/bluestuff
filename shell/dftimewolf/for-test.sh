#!/bin/bash

# Function to run a command and handle success/error output
run_step() {
    step_name="$1"
    shift
    if "$@"; then  # Remove redirection to show all outputs
        echo -e "\033[32mThis step \"$step_name\" was successful.\033[0m"  # Green for success
    else
        echo -e "\033[31mError during \"$step_name\":\033[0m"  # Red for error
        "$@"
        exit 1
    fi
}

# Function to wait for rclone to be available
wait_for_rclone() {
    echo "Waiting for rclone to complete installation..."
    for i in {1..10}; do
        if command -v rclone &>/dev/null; then
            echo -e "\033[32mRclone is installed and ready.\033[0m"  # Green for success
            return 0
        fi
        echo "Rclone not available yet. Retrying in 2 seconds... (Attempt $i/10)"
        sleep 2
    done
    echo -e "\033[31mRclone installation timed out. Please check the installation process.\033[0m"  # Red for error
    exit 1
}

# Function to wait for Timesketch service to become available
wait_for_timesketch() {
    local endpoint="http://localhost:80"
    echo "Waiting for Timesketch service to become available at $endpoint..."
    for i in {1..10}; do
        status_code=$(curl -s -o /dev/null -w "%{http_code}" "$endpoint")
        if [[ "$status_code" =~ ^[23][0-9]{2}$ ]]; then
            echo -e "\033[32mTimesketch service is available (HTTP $status_code).\033[0m"  # Green for success
            return 0
        fi
        echo "Timesketch service not ready yet (HTTP $status_code). Retrying in 5 seconds... (Attempt $i/10)"
        sleep 5
    done
    echo -e "\033[31mTimesketch service did not become available. Please check the deployment.\033[0m"  # Red for error
    exit 1
}

# Start monitoring plaso with `top` in the background
(pgrep -x plaso >/dev/null && top -p $(pgrep -d ',' plaso)) &
TOP_PID=$!

# Ensure cleanup of background `top` process on exit
trap "kill $TOP_PID 2>/dev/null" EXIT

# Script Steps

# Prep directories
run_step "Create directories" mkdir -p /workspace/dftimewolf /workspace/timesketch /workspace/workfiles
run_step "Set permissions" chown root /workspace
cd /workspace || exit 1

# System updates
run_step "Update system" apt update && apt upgrade -y
run_step "Install dependencies" apt install -y python3 python3-pip python3-venv git unzip nano

# Configure environment
run_step "Set PATH" export PATH="$HOME/.local/bin:$PATH"

# Check Python and pip versions
run_step "Check Python version" python3 --version
run_step "Check pip version" pip --version

# Rclone setup
run_step "Install rclone" curl https://rclone.org/install.sh | sudo bash
wait_for_rclone  # Wait for rclone to become available
run_step "Create rclone config directory" mkdir -p /root/.config/rclone/
rclone_conf_path="$HOME/.config/rclone/rclone.conf"

# Write the rclone configuration to the file
cat <<EOF > "$rclone_conf_path"
[source]
type = sftp
host = ftp.example.com
user = auser
pass = FBnjPvheUk7ggBOXcRYkuhNhRHiKSg6qrEovpJpS1iPwkBmQmuxkzy9fYDIt5nQ4
shell_type = unix
EOF

# Notify user
echo "rclone configuration file created at $rclone_conf_path"

#run_step "Configure rclone" curl -o /root/.config/rclone/rclone.conf https://raw.githubusercontent.com/kaywoz/bluestuff/refs/heads/main/other/samples/rclone/rclone.conf

# Docker setup
run_step "Install Docker" curl -sSL https://get.docker.com/ | sh

# Plaso setup
run_step "Check Plaso image" docker run log2timeline/plaso log2timeline.py --version

# Dftimewolf setup
run_step "Clone dftimewolf repo" git clone https://github.com/log2timeline/dftimewolf.git /workspace/dftimewolf
cd /workspace/dftimewolf || exit 1
run_step "Set up Python virtual environment" python3 -m venv venv
run_step "Install Poetry" source venv/bin/activate && venv/bin/pip install poetry
run_step "Install dftimewolf" venv/bin/poetry install
run_step "Verify dftimewolf" venv/bin/poetry run dftimewolf -h

# Timesketch setup
cd /workspace/timesketch || exit 1
run_step "Download Timesketch deployment script" curl -s -O https://raw.githubusercontent.com/google/timesketch/master/contrib/deploy_timesketch.sh
run_step "Make script executable" chmod 755 deploy_timesketch.sh
run_step "Run Timesketch deployment script" ./deploy_timesketch.sh --start-container --skip-create-user

# Wait for Timesketch service to become available
wait_for_timesketch

cd timesketch || exit 1
run_step "Create Timesketch user" docker compose exec timesketch-web tsctl create-user user --password password
run_step "Restart Timesketch" docker compose restart

# Copy workfiles
run_step "Copy workfiles" rclone copy /tmp/work/ /workspace/workfiles/ -P --include="**/file**"

# Extract hostname for sketch ID
work_folder=$(basename "$(find /workspace/workfiles -mindepth 1 -maxdepth 1 -type d | head -n 1)")
hostname=$(echo "$work_folder" | awk -F'-' '{print $4}' | awk -F '.' '{print $1}')

if [ -z "$hostname" ]; then
    echo -e "\033[31mError: Could not determine hostname from work folder name.\033[0m"  # Red for error
    exit 1
fi

# Run dftimewolf job with --sketch_id set to hostname
cd /workspace/dftimewolf || exit 1
source venv/bin/activate
run_step "Run dftimewolf job" venv/bin/poetry run dftimewolf plaso_ts \
    --timesketch_endpoint http://localhost/ \
    --timesketch_username user \
    --timesketch_password password \
    --incident_id "$hostname" \
    /workspace/workfiles/