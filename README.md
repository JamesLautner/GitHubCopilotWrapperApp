# GitHub Copilot App

A simple macOS application that provides a clean wrapper for GitHub Copilot's web interface.

## Screenshot

![GitHub Copilot App Screenshot](screenshot.png)

## Features

- Clean, distraction-free interface focused on the GitHub Copilot conversation
- Native macOS app experience
- Automatic UI cleanup to remove unnecessary elements
- Lightweight wrapper around the GitHub Copilot web interface

## Requirements

- macOS 15.0 or later
- Xcode 16.0 or later for development

## Installation

### Option 1: Download Pre-built App (Recommended)

1. Go to the [Releases](https://github.com/YOURUSERNAME/GitHubCopilotWrapperApp/releases) page on GitHub
2. Download the latest `.zip` file
3. Extract the zip and move `GitHub Copilot.app` to your Applications folder
4. When opening for the first time, right-click the app and select "Open" to bypass Gatekeeper

### Option 2: Build from Source

1. Clone this repository
2. Open the project in Xcode
3. Build and run the application

## Usage

After launching the app, you'll need to sign in with your GitHub account that has GitHub Copilot access. The app will automatically clean up the interface to focus on the chat experience.

## License

This project is available under the MIT License. See the LICENSE file for more information.

## Disclaimer

This is an unofficial wrapper application and is not affiliated with GitHub or Microsoft.

## Development

### Continuous Integration

This project uses GitHub Actions for continuous integration. Each push to the main branch and each release tag automatically builds the app and creates:

- Development builds for commits to main (available as build artifacts)
- Official release packages for tagged releases

To create a new release:

1. Create and push a new tag with the version number: `git tag v1.0.0 && git push --tags`
2. GitHub Actions will automatically build the app and create a new release with the app binary

See `.github/workflows/build-macos-app.yml` for the full CI workflow configuration.
