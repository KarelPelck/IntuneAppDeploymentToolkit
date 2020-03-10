# IntuneAppDeploymentToolkit

A toolset to help you package your win32 applications and deploy them to Intune!

## Why this repository

I was looking for script to help me manage and speed up my deployment workflow. 
I got some good inspiration from various sources and adapted this to suite my needs: 
- https://github.com/tabs-not-spaces/Intune-App-Deploy
- Various articles from Oliver Kieselbach's blog: https://oliverkieselbach.com/

This repo can be used as is with no guarantees. 
Feel free to adapt for your own usecase & credit my sources as well if 

## The basic setup

- Clone the repository
- For chocolatey based deployments you just need to create a yaml file per app deployment. Copy an existing example and adjust for your app is the easiest way.
- For a custom app you need a seperate folder per app containing: 
    + A yaml config file for build and deployment parameters
    + A Source folder that will hold all the deployment files needed in your package

## What's in it and how to use it

### Initialize Environment

To set up your deployment environment, run the Prepare-Environmant script with admin privileges. It will install modules Yaml-Powershell (you need this for reading the Yaml configuration files) & AzureAD, downloading the intunewin packaging tool.

### Building a package

Before you can publish your package in Microsoft Endpoint Manager (Intune), you need to create your .intunewin package. You can create a package by creating the needed application configuration files as descibed above. and for custom packages you need to create a seperate application folder containing this configuration file and the source folder containing the source files for your package. To build your package run the Build-Package script with the -appConfig parameter-value containing the path to your yaml-config file. 

Running the script will create an intunewin-folder in your application folder containing your intunewin package

### Publish a package

To publish your application package, run the Publish-Package script with the -appConfig parameter as you did for building the package and add the -user parameter specifying a user that has the rights to upload packages into your MEM (Intune) environment. 

You will be asked to authenticate to your Azure Tenant. Multi-factor Authentication is supported. 

## The Yaml-file

Below is a sample to use as a reference point.
You can also copy any of the sample yaml files in the repository

``` yaml
application:
  appName: "NameOfApplication"
  publisher: "Shellblazer"
  description: 'Description goes here'
  appUrl: "" # URL of your application package (storage blob, dropbox, whatever)
  appFile: "" # whats the file name inclusing extension
  unpack: false # true / false (if you need to unpack the remote media set to true, otherwise set to false)
  installFile: "InstallerGoesHere.exe" # The name of this file will define the name of the intunewin-package, usually the file that wil trigger the install (setup.exe, setup.msi, setup.ps1 etc)
  installCmdLine: "InstallerGoesHere.exe -installArgs"
  uninstallCmdLine: "InstallerGoesHere.exe -uninstallArgs"

requirements:
  runAs32: false # true / false
  minOSArch: "v10_1809" # set this to your minimum allowed win10 build

detection:
  detectionType: "file" # file / msi / registry - what you pick here is what detection method will be bundled into your application.
  file: # File or folder detection.
    path: "C:/path/to/application"
    fileOrFolderName: "filename.ext"
    fileDetectionType: "exists"
    check32BitRegOn64System: false # true / false
  
  registry: # Registry detection
    registryKeyPath: "HKLM:/software/path/application"
    registryDetectionType: "exists"
    check32BitRegOn64System: false # true / false
  
  msi: # MSI installation detection (application GUID)
    msiProductCode: "{F16BDC7C-960E-4F21-A44A-41E996D5356C}"
```