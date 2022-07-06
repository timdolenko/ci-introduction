# ci-introduction

This tutorial will teach you how to setup your own CI/CD based on the setup we currently have in Axel Springer in BILD team. BILD is a production app that currently has around 2M MAU.

### Our Goal
We want to:
1. automatically run Unit Tests for each pull request
2. deploy a new build to TestFlight whenever pull request is merged

Here's a quick diagram of how the process in the team might look like with this CI setup:


<img width="1305" alt="Workflow process diagramm" src="https://user-images.githubusercontent.com/35912614/177534623-55d8ce27-5632-4ac8-a903-c09e78ece816.png">

Clone this repo and checkout to `start` branch.

It contains an empty SwiftUI app and 1 Unit Test.

Now, let's go to Visual Studio Code and create our first workflow yaml file:

Create `.github/workflows/pullRequest.yml` file. I will just copy and paste the following to save time, but we'll go over everything:

```yaml
name: Pull Request

on:
  pull_request:
    branches:
      - develop
  workflow_dispatch:

jobs:
  test:
    runs-on: macos-11
    steps:
      - uses: actions/checkout@v2

      - name: Cancel Previous Runs
        uses: styfle/cancel-workflow-action@0.9.1
        with:
          access_token: ${{ github.token }}

      - uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: latest-stable

      - name: Setup SSH
        uses: webfactory/ssh-agent@v0.4.1
        with:
          ssh-private-key: ${{ inputs.ssh-key }}

      - uses: ruby/setup-ruby@v1

      - name: Swift Packages Cache
        uses: actions/cache@v2
        id: cache
        with:
          path: |
            Build/SourcePackages
            Build/Build/Products
          key: ${{ runner.os }}-deps-v1-${{ hashFiles('BILDsolid.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved') }}
          restore-keys: ${{ runner.os }}-deps-v1-
```
