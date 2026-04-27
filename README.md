# How to do CI/CD for iOS?

This tutorial will teach you how to setup your own CI/CD based on the setup we currently have in Axel Springer in BILD team. BILD is a production app that currently has around 2M MAU.

<a href="https://www.youtube.com/watch?v=yNqCpMLmJqE"><img width="218" alt="Screenshot 2022-08-15 at 15 54 54" src="https://user-images.githubusercontent.com/35912614/184648825-eb377bb5-f400-4ace-b7be-9307075eb3bb.png"></a>


### Our Goal
We want to:
1. automatically run Unit Tests for each pull request
2. deploy a new build to TestFlight whenever pull request is merged

Here's a quick diagram of how the process in the team might look like with this CI setup:


<img width="1305" alt="Workflow process diagramm" src="https://user-images.githubusercontent.com/35912614/177534623-55d8ce27-5632-4ac8-a903-c09e78ece816.png">

Clone this repo and checkout to the `start` branch.

It contains an empty SwiftUI app and 1 Unit Test.

### Workflow initial setup
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

      - uses: ruby/setup-ruby@v1

      - name: Install Bundler
        run: gem install bundler

      - name: Install gems
        run: bundle install

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

I won't go into detail, because each platform, in our case it's Github Actions, has it's own syntax, it's more important to understand the principles and overall those config files are usually very easy to understand.

`on:`
We describe _when_ we want to run the workflow, or _what_ will trigger it.
In out case it's pull request against `develop` branch.
`workflow_dispatch` means that we want to be able to trigger the workflow manually on Github. 

`jobs`:
Now we actually start to describe what we want to do. 
We have the first and the only job called `test` (can be named anything else).
`runs-on: macos-11` - Self-explanatory.

`steps:` 
Each job can have many of them.

`actions/checkout@v2` - pull the repository code to the machine that was given us for this run. We start with a clean state.

`cancel-workflow-action` - basically if we already running the same workflow from the same branch, we want to first cancel the old one, and only then start the new execution. We discard the result of the previous workflow.

We can actually pass values or variables as a parameters to the step with `with:` keyword.

`access_token: ${{ github.token }}`

You see, `github.token` is actually a variable here. How do we now that it's available? - Documentation.

`setup-xcode@v1` - install xcode

`ruby/setup-ruby@v1` - install ruby - we will need it later. 

Please add `.ruby-version` file to the root with the following contents: `2.7.2`

`gem install bundler` and `bundle install` are needed to install [Bundler](https://bundler.io/), that's needed to manage ruby dependencies (kind of like SPM) and install all the gems (kind of like packages) that include fastlane. We will define the `Gemfile` later. But essentially all this installs `fastlane`.

`actions/cache@v2` - we want to cache SPM modules to not refetch them again and again.

That's it. Now we can push and see how it works, but the most important part is missing - the unit tests. 

### Fastlane
To run them we will use `fastlane`. Let's setup a simple fastlane project:

First of all we need to install fastlane locally, for it let's create a `Gemfile` (no extension) in the root folder:

```ruby
source 'https://rubygems.org'

gem 'fastlane'
```

Now please install ruby and Rubygems, there is a high chance that you already have them on your machine. 

```
gem install bundler
```

Now run `bundle install` - it will read the Gemfile and install or update fastlane.

Okay let's create the first fastlane file:
`Fastlane/Fastfile`
```ruby
fastlane_version '2.157'
default_platform :ios

platform :ios do
    
end
```

And now finally add unit tests lane:

```ruby
platform :ios do
    desc 'Builds project and executes unit tests'
    lane :unit_test do |options|
      scan(
        clean: options[:clean],
        skip_package_dependencies_resolution: options[:skip_package_dependencies_resolution]
      )
    end
end
```

Now, obviously it's not all it takes to run the test. We want to specify the project and the scheme among other things. Let's create `Fastlane/Scanfile`:
```ruby
# For more information about this configuration visit
# https://github.com/fastlane/scan#scanfile

workspace "AnyApp.xcodeproj/project.xcworkspace"
scheme "AnyApp"
sdk "iphonesimulator"
device "iPhone 11"
code_coverage true
xcargs '-parallelizeTargets'
prelaunch_simulator true
derived_data_path "Build/"
```

Most of it is self explanatory, everything else - just read docs if you wanna understand it.

Please create `.gitignore` to avoid committing build artefacts and cache:

```
Build

# fastlane
Fastlane/report.xml
Fastlane/test_output
```

Okay, let's test how the `fastlane` works locally. In the terminal, from the root folder of the project, run:

`fastlane unit_test`

You'll see the simulator running our tests! How exciting! Now we just have to do the same on the CI - Super easy!

Let's go back to our workflow file `pullRequest.yml` and finally add this at the end of the file:

```yaml
      - name: Run Tests
        run: bundle exec fastlane unit_test
```

Now we actually make use of the cache and check if it's there, here's how:

```yaml
      - name: Run Tests (No Cache)
        if: steps.setup.outputs.cache-hit != 'true'
        run: bundle exec fastlane unit_test
      
      - name: Run Tests (Cache)
        if: steps.setup.outputs.cache-hit == 'true'
        run: bundle exec fastlane unit_test skip_package_dependencies_resolution:true
```

Now let's actually see if it works

Push the code! 

If you'll raise a pull request from your branch

<img width="831" alt="Screenshot 2022-07-06 at 14 54 58" src="https://user-images.githubusercontent.com/35912614/177554925-e5868d7d-3608-4cf7-a005-57dcbf4995f2.png">

Warning: if you create a project from scratch on your own and the latest Xcode available on Github Actions is still 13.2.1, you have to make sure your iOS Deployment target in the project is set to `15.2` and not higher. 

After a few minutes you'll see beautiful green mark! 

#### Congrats! 🥳
