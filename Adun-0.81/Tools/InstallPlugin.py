#! /usr/bin/env python
'''InstallPlugin - Python script for installing Adun plugins

Usage: InstallPlugin.py -t [type]

Arguments:
    -t  Plugin type. Must be one of the following -
        Controllers, Analysis, Configurations

Note: Script must be run in the plugin source directory.'''

import os, sys, getopt, shutil
    
def GetPluginName():

    '''Gets the plugin name by reading the bundles Info.plist

    Calls sys.exit() if the plist doesnt exist'''

    contents = os.listdir(".")
    name = None
    for filename in contents:
	components = os.path.splitext(filename)
	if components[1] == ".plist":
		name = components[0]
		#There could be both a Mac and GNUstep plist.
		#These differ in that one has a hydpen before 'Info'.
		if name[-5] == '-':
			name = name[:-5]
		else:
			name = name[:-4]

    if name == None:
        print "Unable to read Info.plist for this plugin"
        print "Cannot determine plugin name"
        sys.exit(1)
   
    return name    

def CheckBuild(name):

    '''Returns true if a build is needed. False otherwise'''

    x = os.listdir(".")
    return not x.count(name)

if __name__ == "__main__":

    try:
        opt = getopt.getopt(sys.argv[1:], "t:")
        opt = dict(opt[0])
    except getopt.GetoptError, data:
        print "Error - %s" % data
        print __doc__
        sys.exit(1)

    allowedType = ["Controllers", "Analysis", "Configurations"]

    #Parse options
    if opt.has_key("-t"):
        pluginType = opt["-t"]
        if allowedType.count(pluginType) == 0:
            print "Type %s is not known" % pluginType
            print __doc__
            sys.exit(1)
    else:
        print "Must define plugin type"
        print __doc__
        sys.exit(1)

    name = GetPluginName()
    print "Plugin is %s" % name
    build = CheckBuild(name)

    #If build was requested execute make
    if build:
        print "Build required ..."
        os.system("make")

    #Check installation dir exists
    pluginDir = os.path.expandvars("$HOME/adun/Plugins/" + pluginType)
    if not os.path.exists(pluginDir):
        print 'Required plugin directory %s does not exist' % pluginDir
        print __doc__
        sys.exit(1)

    destinationDir = os.path.join(pluginDir, name)
    #Check if a previous plugin version was installed
    if os.path.exists(destinationDir):
        print "Detected previous copy of %s - Removing" % name
        try:
            shutil.rmtree(destinationDir)
        except OSError, data:
            print "Remove failed"
            print "%s - %s" % (data.strerror, data.filename)
            sys.exit(1)

    #Install the plugin            
    print "Installing %s into %s" % (name, pluginDir)
    shutil.copytree(name, destinationDir, symlinks=True)
    try:
        shutil.rmtree(name)
    except OSError, data:
        print "Remove failed"
        print "%s - %s" % (data.strerror, data.filename)
    
    

        

    

  
