function get_profile() {
  if [ "$1" == "prod" ]; then profile="ellationc"; else profile="ellationengc"; fi
  echo "$profile"
}

function find_payments_ip() {
    aws ec2 describe-instances --profile $(get_profile "$1") --region us-west-2 --filters "Name=tag-value,Values=${1}-secure-payments" --query 'Reservations[*].Instances[*].NetworkInterfaces[*].PrivateIpAddress' --output text | head -n1
}

function find_all_secure_ips() {
    aws ec2 describe-instances --profile $(get_profile "$1") --region us-west-2 --filters "Name=tag-value,Values=${1}-secure-*" --query 'Reservations[*].Instances[*].{"Instance name": Tags[?Key==`Name`].Value | [0], "IP": NetworkInterfaces[*].PrivateIpAddress | [0]}' --output table --color off
}

function find_bastion_ip() {
    aws ec2 describe-instances --profile $(get_profile "$1") --region us-west-2 --filters "Name=tag-value,Values=${1}-bastion" --query 'Reservations[*].Instances[*].NetworkInterfaces[*].Association.PublicIp' --output text | head -n1
}

function payments-tunnel() {
    if [ "$1" == "proto0" ]; then port="3307"; elif [ "$1" == "staging" ]; then port="3308"; elif [ "$1" == "prod" ]; then port="3309"; else echo "Unknown env \"$1\": Exiting" && return 1; fi
    ssh -L ${port}:$(find_payments_ip "$1"):22 -f -N $(find_bastion_ip "$1")
    if [ "$?" == 0 ]; then echo "Tunnel successfully created on port ${port}"; fi
}

# Source local, untracked overrides
if [ -f "$HOME/.bash_profile.chime" ]; then
  source "$HOME/.bash_profile.chime"
fi
