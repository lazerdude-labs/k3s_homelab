#!/bin/bash
set -o errexit
set -o pipefail

SHEEP1='
________________🐑'

SHEEP2='
_______🐑_________'

SHEEP3='
_🐑______________'

ID="rocky"
ID_LIKE="rhel centos fedora"


animate_sheep() {
    case $1 in
        1) echo -e "$SHEEP1" ;;
        2) echo -e "$SHEEP2" ;;
        3) echo -e "$SHEEP3" ;;
    esac
}


deploy_infrustructure_main() {
    export VAULT_TOKEN=$(cat /etc/vault.d/agent-token-k3s)
    cd terraform

    frame=1

    # Start terraform init in the background
    terraform init -reconfigure > /tmp/tf.log 2>&1 &
    TF_PID=$!

    (
        # INIT PHASE
        while kill -0 $TF_PID 2>/dev/null; do
            progress=5
            if grep -q "Initializing the backend" /tmp/tf.log; then progress=10; fi
            if grep -q "Initializing provider plugins" /tmp/tf.log; then progress=20; fi

            echo "XXX"
            echo "$progress"
            echo "Initializing Terraform..."
            animate_sheep $frame
            echo "XXX"

            frame=$((frame % 3 + 1))
            sleep 1
        done

        echo "XXX"
        echo "25"
        echo "Terraform init complete"
        animate_sheep $frame
        echo "XXX"
        sleep 0.5

        # PLAN PHASE
        terraform plan > /tmp/tf.log 2>&1 &
        TF_PID=$!

        while kill -0 $TF_PID 2>/dev/null; do
            progress=30
            if grep -q "Refreshing state" /tmp/tf.log; then progress=35; fi
            if grep -q "Plan:" /tmp/tf.log; then progress=45; fi

            echo "XXX"
            echo "$progress"
            echo "Planning infrastructure..."
            animate_sheep $frame
            echo "XXX"

            frame=$((frame % 3 + 1))
            sleep 1
        done

        echo "XXX"
        echo "50"
        echo "Terraform plan complete"
        animate_sheep $frame
        echo "XXX"
        sleep 0.5

        # APPLY PHASE
        terraform apply -auto-approve > /tmp/tf.log 2>&1 &
        TF_PID=$!

        while kill -0 $TF_PID 2>/dev/null; do
            progress=60
            if grep -q "Creating..." /tmp/tf.log; then progress=70; fi
            if grep -q "Provisioning" /tmp/tf.log; then progress=85; fi
            if grep -q "Apply complete" /tmp/tf.log; then progress=100; fi

            echo "XXX"
            echo "$progress"
            echo "Deploying infrastructure..."
            animate_sheep $frame
            echo "XXX"

            frame=$((frame % 3 + 1))
            sleep 1
        done

        echo "XXX"
        echo "100"
        echo "Infrustructure Deployment complete!"
        animate_sheep $frame
        echo "XXX"

    ) | dialog --gauge "" 25 70 0
    return 0
}

deploy_infrustructure_main "$@"