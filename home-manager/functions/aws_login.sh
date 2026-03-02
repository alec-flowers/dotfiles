function aws_login() {
  export AWS_PAGER=""

  echo "Checking AWS credentials..."

  # 1) Check if current AWS creds are already valid
  if timeout 3 aws sts get-caller-identity &>/dev/null; then
    echo "AWS credentials are valid:"
    aws sts get-caller-identity --output json --no-cli-pager | python3 -c "
import sys,json
d=json.load(sys.stdin)
print(f\"  Account:  {d['Account']}\")
print(f\"  Arn:      {d['Arn']}\")
print(f\"  UserId:   {d['UserId']}\")
"
    echo ""
    echo -n "Already authenticated. Re-login anyway? [y/N] "
    read reply </dev/tty
    [[ "$reply" != [yY]* ]] && return 0
  fi

  # 2) Check if nvsec auth is still cached, authenticate if not
  echo "Checking nvsec session..."
  if timeout 3 nvsec aws list &>/dev/null; then
    echo "nvsec session is active (cached)"
  else
    echo "nvsec session expired, authenticating..."
    nvsec aws auth --no-browser
  fi

  # 3) Show available roles and ask which one
  echo ""
  nvsec aws list 2>&1 | cat
  echo ""
  echo -n "Enter role number to configure (default: 3): "
  read role_num </dev/tty
  role_num="${role_num:-3}"

  # 4) Configure AWS credentials for selected role
  local nvsec_opts=(--profile default --no-refresh)
  [[ -n "$SSH_CONNECTION" ]] && nvsec_opts+=(--no-browser)
  nvsec aws configure "$role_num" "${nvsec_opts[@]}" 2>&1 | cat
  if [[ ${pipestatus[1]} -ne 0 ]]; then
    echo "Failed to configure AWS credentials"
    return 1
  fi

  # 5) Export credentials from file into current shell
  local creds_file="$HOME/.aws/credentials"
  if [[ -r "$creds_file" ]]; then
    while IFS='=' read -r key value; do
      key=$(echo "$key" | xargs | tr '[:lower:]' '[:upper:]')
      value=$(echo "$value" | xargs)
      [[ -n "$key" && -n "$value" && "$key" != \[* ]] && export "$key"="$value"
    done < "$creds_file"
    echo ""
    echo "Exported AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN"
  else
    echo "Credentials file not found: $creds_file"
    return 1
  fi

  # 6) Verify
  echo ""
  aws sts get-caller-identity --output json --no-cli-pager | python3 -c "
import sys,json
d=json.load(sys.stdin)
print(f\"  Account:  {d['Account']}\")
print(f\"  Arn:      {d['Arn']}\")
print(f\"  UserId:   {d['UserId']}\")
"

  # 7) Login to ECR for the selected account
  local acct_id
  acct_id=$(aws sts get-caller-identity --output json --no-cli-pager | python3 -c "import sys,json; print(json.load(sys.stdin)['Account'])")
  if [[ -n "$acct_id" ]]; then
    echo ""
    echo "Logging into ECR for account $acct_id..."
    aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin "${acct_id}.dkr.ecr.us-west-2.amazonaws.com"
  fi
}
