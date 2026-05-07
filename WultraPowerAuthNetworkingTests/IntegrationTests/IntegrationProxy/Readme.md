# Integration Proxy

## What is Integration Proxy

Integration Proxy is a shared test file between iOS projects that can connect to the PowerAuth Cloud server and orchestrate the test (creating registrations etc.)

## But where is the file?

The file itself will be downloaded from a wultra-infrastructure during the build.

## Who downloads the file?

The download script can be found here:

1. Click on the scheme name (e.g. `MySDKTests`) at the top of the Xcode window.
2. Select **Edit Scheme…**
3. Expand the **Build** item on the left side of the editor.
4. Select **Pre-actions**.
5. See the script
