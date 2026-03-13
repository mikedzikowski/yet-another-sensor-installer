# Assets Directory

This directory contains media assets for the CrowdStrike Falcon Deployment Simplifier documentation.

## Files

- `falcon-deployment-demo.gif` - Demo GIF showing the deployment script in action (to be added)

## Creating the Demo GIF

To create the demo GIF, you can use tools like:

- **asciinema + gif conversion**:
  ```bash
  # Record terminal session
  asciinema rec falcon-demo.cast
  # Convert to GIF
  agg falcon-demo.cast falcon-deployment-demo.gif
  ```

- **terminalizer**:
  ```bash
  # Record session
  terminalizer record falcon-demo
  # Render as GIF
  terminalizer render falcon-demo
  ```

- **Screen recording tools**: OBS Studio, QuickTime, etc. with GIF conversion

## Demo Script Content

The demo should show:
1. Setting environment variables
2. Running the deployment script
3. Interactive version selection
4. Deployment progress
5. Successful completion with verification

Target duration: 2-3 minutes to keep file size manageable.