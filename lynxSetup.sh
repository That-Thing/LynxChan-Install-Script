#!/bin/bash
echo "
##       ##    ## ##    ## ##     ##  ######  ##     ##    ###    ##    ## 
##        ##  ##  ###   ##  ##   ##  ##    ## ##     ##   ## ##   ###   ## 
##         ####   ####  ##   ## ##   ##       ##     ##  ##   ##  ####  ## 
##          ##    ## ## ##    ###    ##       ######### ##     ## ## ## ## 
##          ##    ##  ####   ## ##   ##       ##     ## ######### ##  #### 
##          ##    ##   ###  ##   ##  ##    ## ##     ## ##     ## ##   ### 
########    ##    ##    ## ##     ##  ######  ##     ## ##     ## ##    ## 

 ######  ######## ######## ##     ## ########                              
##    ## ##          ##    ##     ## ##     ##                             
##       ##          ##    ##     ## ##     ##                             
 ######  ######      ##    ##     ## ########                              
      ## ##          ##    ##     ## ##                                    
##    ## ##          ##    ##     ## ##                                    
 ######  ########    ##     #######  ##   By Sen <3                                 "


#check if user is root 
if [ `whoami` != 'root' ]
  then
    echo "Please run this script as root."
    exit
fi
#install dependencies
installDependencies () {
    apt-get update
    apt-get upgrade
    apt install curl -y
    apt install build-essential -y
    apt-get install manpages-dev -y
    apt install zlib1g -y
    apt-get install yasm -y
    apt-get install imagemagick -y
    apt-get install libmagick++-dev -y
    apt install libimage-exiftool-perl -y
    apt install git unzip file -y
    apt-get install pkg-config -y
    apt install git -y
    sudo apt-get install libcap2-bin -y
    echo
    echo "Basic dependencies installed"
}
#install node
installNode () {
    echo "Installing NodeJS"
    echo
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
    export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
    nvm install lts/erbium
    nvm use lts/erbium
    echo
    node -v
    echo "Please input node version(ex: v12.19.0)":
    read nodeVer
    ln -s ~/.nvm/versions/node/$nodeVer/bin/node /usr/bin/node
    echo
    echo "Node installed."
}
installMongoDB () {
    wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | apt-key add -
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.2 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.2.list
    apt-get update
    apt-get install -y mongodb-org
    systemctl enable mongod
    systemctl start mongod
    echo "MongoDB installed"
}
installFFMPEG () {
    cd
    git clone git://source.ffmpeg.org/ffmpeg.git 
    cd ffmpeg
    git checkout release/4.2
    ./configure --enable-shared --enable-pic
    make
    make install
    sudo echo "/usr/lib" >> /etc/ld.so.conf
    sudo echo "/usr/local/lib" >> /etc/ld.so.conf
    sudo ldconfig
}
#clones lynxchan into the home directory
cloneLynxChan () {
    cd
    git clone https://gitgud.io/LynxChan/LynxChan.git
    cd ~/LynxChan/aux
    clear
    echo "Done"
}

#Run lynxchan setup. Yes, this is literally the setup.sh script. 
setupScript () {
    cd ~/LynxChan/aux
    echo "Do you wish to download the default front-end to the default location? (y,n)"
    read answerFrontEnd

    echo "Do you wish to install the libraries? Requires node.js installed. (y,n)"
    read answerLibs

    echo "Do you wish to install the default settings from the example? (0.0.0.0:8080 to listen to requests, expects a database at localhost:27017) (y,n)"
    read answerSettings

    echo "Do you wish to install the necessary data to use location flags? (y,n)"
    read answerLocation

    stable="y"

    if [ "$stable" == "n" ]; then

    echo "Do you wish to change to the latest stable version? (y,n)"
    echo "Warning: if you have already started the server and inserted data, the server might not work after you change to the latest stable version. You can fix this by dropping the db and starting it again or using a different db."
    echo "Smaller warning: this operation will try to also checkout the respective tag on the front-end for this version, this part of the operation will only work if you have installed the placeholder front-end at /src/fe, like this scripts installs it."
    read answerStable

    fi

    if [ "$answerFrontEnd" == "y" ]; then

    git clone https://gitgud.io/LynxChan/PenumbraLynx.git ../src/fe
    cd ../src/fe
    git checkout 2.4.x
    cd ../../aux

    echo "Default front-end installed."

    fi

    if [ "$answerStable" == "y" ]; then

    git checkout 2.3.x

    if [ "$answerFrontEnd" == "y" ]; then

        cd ../src/fe

        git checkout 2.3.x

        cd ../../aux

    fi

    echo "Changed to latest stable version: 2.3.x"

    fi

    if [ "$answerSettings" == "y" ]; then

    cd ../src/be

    cp -r settings.example settings

    cd ../../aux

    echo "Default settings installed. The server will listen on 0.0.0.0:8080 and expects the database to be acessible at localhost:27017.  If you wish to change the settings, look for them at src/be/settings."

    fi

    if [ "$answerLibs" == "y" ]; then

    cd ../src/be
    npm install
    cd ../../aux

    echo "Libraries installed."

    fi

    if [ "$answerLocation" == "y" ]; then

    git clone https://gitgud.io/LynxChan/LynxChan-LocationDownloader.git ../src/be/locationData
    cd ../src/be/locationData
    ./updateData

    fi
}


#creates the node user
createNode () {
    sudo adduser node
    sudo usermod -aG sudo node
}
rootSetup () {
    cd ~/LynxChan/aux
    echo "Do you wish to install the command lynxchan for all users using a soft-link? (y,n)"
    read answerCommand

    echo "Do you wish to install a init script? Requires install as a command and an user called node on the system to run the engine, so it also must have permissions on the engine files. (systemd, upstart, openrc, blank for none)"
    read answerInit

    if [ -n "$answerInit" ]; then

    if getent passwd node  > /dev/null; then

        echo "Installing lynxchan service."

        if [ $answerInit == "upstart" ]; then

        rm -rf /usr/bin/log-manager
        cp ./log-manager.sh /usr/bin/log-manager
    
        rm -rf /etc/init/lynxchan.conf
        cp ./lynxchan.conf /etc/init/lynxchan.conf

        if [ ! -d /home/node ]; then
            echo "Creating node's home folder for logs."
            mkdir /home/node
            chown node /home/node 
            chmod 700 /home/node
        fi

        echo "Upstart daemon installed at /etc/init"

        elif [ $answerInit == "openrc" ]; then

        rm -rf /etc/init.d/lynxchan
        cp ./lynxchan.rc /etc/init.d/lynxchan

        if [ ! -d /home/node ]; then
            echo "Creating node's home folder for logs."
            mkdir /home/node
            chown node /home/node 
            chmod 700 /home/node
        fi

        echo "OpenRC service installed at /etc/init.d"

        elif [ $answerInit == "systemd" ]; then

        rm -rf /etc/systemd/system/lynxchan.service
        cp ./lynxchan.systemd /etc/systemd/system/lynxchan.service
        echo "SystemD service installed at /etc/systemd/system/"
        fi 

    else
        echo "User node does not exist. Add it to the system and run this script again to be able to install a service."
    fi
    fi

    if [ "$answerCommand" == "y" ]; then
    rm -rf /usr/bin/lynxchan

    ln -s $(readlink -f ..)/src/be/boot.js /usr/bin/lynxchan
    echo "Command lynxchan installed for all users using a link to src/be/boot.js."

    fi
    sudo setcap 'cap_net_bind_service=+ep' `which node`
    sudo setcap cap_net_bind_service=+ep `readlink -f \`which node\``

}

echo "Install basic dependencies? (y/n)"
read askBasicDep

if [ "$askBasicDep" == "y" ]; then
    installDependencies
else
    :
fi
clear
#ask user if they want to install Node
echo "                  
###       #     
# # ### ### ### 
# # # # # # ##  
# # ### ### ### 
# #        "
echo
echo "Install Node? (y/n)"
read askNode
if [ "$askNode" == "y" ]; then
    installNode
else
    :
fi
clear
#aks user if they want to install mongoDB
echo "                   
# #                 ##  ##  
### ### ##  ### ### # # # # 
### # # # # # # # # # # ##  
# # ### # #  ## ### # # # # 
# #         ###     ##  ##  "
echo
echo "Install MongoDB? (y/n)"
read askMongo
if [ "$askMongo" == "y" ]; then
    installMongoDB
else
    :
fi
clear
#asks user if they want to install ffmpeg (compiles from source)
echo "                     
### ### # # ##  ###  ## 
#   #   ### # # #   #   
##  ##  ### ##  ##  # # 
#   #   # # #   #   # # 
#   #   # # #   ###  ## "
echo
echo "Install FFMPEG? (y/n)"
read askFFMPEG
if [ "$askFFMPEG" == "y" ]; then
    installFFMPEG
else
    :
fi
clear
echo "                               
##               #            # 
# # ### # # ##   #  ###  ## ### 
# # # # ### # #  #  # # # # # # 
# # ### ### # #  ## ### ### ### 
##                              
                                
#                ## #           
#   # # ##  # # #   ###  ## ##  
#   ### # #  #  #   # # # # # # 
#     # # # # # #   # # ### # # 
### ###          ##             "
echo
echo "Clone LynxChan? (y/n)"
read askLynxChan
if [ "$askLynxChan" == "y" ]; then
    cloneLynxChan
else
    :
fi
clear
echo "                                     
 #    #   #     ###       #         # #             
# # ### ###     # # ### ### ###     # #  ## ### ### 
### # # # #     # # # # # # ##      # #  #  ##  #   
# # ### ###     # # ### ### ###     # # ##  ### #   
# #             # #                 ###             "
echo
echo "Add Node user? (y/n)"
read askNodeUser
if [ "$askNodeUser" == "y" ]; then
    createNode
else
    :
fi
clear
echo "                         
#                ## #           
#   # # ##  # # #   ###  ## ##  
#   ### # #  #  #   # # # # # # 
#     # # # # # #   # # ### # # 
### ###          ##             
                                
 ##      #                      
#   ### ### # # ###             
 #  ##   #  # # # #             
  # ###  ## ### ###             
##              #               "
echo
echo "Run LynxChan setup? (y/n)"
read askLynxSetup
if [ "$askLynxSetup" == "y" ]; then
    setupScript
else
    :
fi
clear
echo "                   
##           #      
# # ### ### ###     
##  # # # #  #      
# # ### ###  ##     
# #                 
                    
 ##      #          
#   ### ### # # ### 
 #  ##   #  # # # # 
  # ###  ## ### ### 
##              #   "
echo
echo "Run Root setup? (y/n)"
read askLynxRootSetup
if [ "$askLynxRootSetup" == "y" ]; then
    rootSetup
else
    :
fi
clear
echo "
   ###    ##       ##          ########   #######  ##    ## ######## #### 
  ## ##   ##       ##          ##     ## ##     ## ###   ## ##       #### 
 ##   ##  ##       ##          ##     ## ##     ## ####  ## ##       #### 
##     ## ##       ##          ##     ## ##     ## ## ## ## ######    ##  
######### ##       ##          ##     ## ##     ## ##  #### ##            
##     ## ##       ##          ##     ## ##     ## ##   ### ##       #### 
##     ## ######## ########    ########   #######  ##    ## ######## #### "
echo
echo "LynxChan installed and set up"
echo "Run this to create a new user (Don't forget to replace username and password with the correct information):"
echo "lynxchan -ca -l username -p password -gr 0"
echo "                change ^    change ^"
echo "Your imageboard will be available at http://127.0.0.1:8080"
exit