#!/bin/zsh

echo "Checking whether CocoaPods is installed…"
if [ -x "$(command -v pod)" ]; then
    echo "CocoaPods is already installed"
else
    echo "CocoaPods was not found. Installing it now…"
    brew install cocoapods --verbose
fi

echo "Installing Pods…"
pod install --deployment
