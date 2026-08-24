#!/bin/bash

# Adjust your remote destination (e.g., origin or myfork)
REMOTE="origin"
BATCH_SIZE=1000  # Increased slightly for speed, but below the 2GB pack limit

# Define the array of branches you need to push
# Ensure these branches have already been created locally via git checkout -b
BRANCHES=(
    "master"
    "v6.18/standard/phyboard-pollux-imx8mp-3"
)

# Loop through each branch in the array
for BRANCH in "${BRANCHES[@]}"; do
    echo "=================================================="
    echo "Starting batch push for branch: $BRANCH"
    echo "=================================================="

    # Explicitly switch to the target branch locally
    if ! git checkout "$BRANCH"; then
        echo "ERROR: Local branch $BRANCH does not exist. Skipping."
        continue
    fi

    # Check if the branch already exists on the remote destination
    if git show-ref --quiet --verify "refs/remotes/$REMOTE/$BRANCH"; then
        # Only push commits missing from the remote
        range="$REMOTE/$BRANCH..HEAD"
    else
        # Push the full historical tree line
        range="HEAD"
    fi

    # Count the number of total commits to push in this track
    n=$(git log --first-parent --format=format:x $range | wc -l)
    echo "Found $n commits to push for $BRANCH"

    # Push each commit chunk sequentially
    for i in $(seq $n -$BATCH_SIZE 1); do
        h=$(git log --first-parent --reverse --format=format:%H --skip $i -n1)
        echo "[$BRANCH] Pushing batch commit checkpoint: $h..."
        git push $REMOTE "${h}:refs/heads/$BRANCH"
    done

    # Push the final remaining partial batch up to the branch head
    echo "[$BRANCH] Pushing final head reference..."
    git push $REMOTE "HEAD:refs/heads/$BRANCH"
    
    echo "Successfully pushed branch: $BRANCH"
done

echo "All listed branches processed!"

