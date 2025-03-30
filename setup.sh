#!/bin/bash

MYVIMRC=vimrc
VIMRC=$HOME/.vimrc

COMMAND=$1


setup(){


    if [ -f $VIMRC ]; then
        echo "Vim setting file alerady exists. Copying as ${VIMRC}_old and settng this as main."
        cp ${VIMRC}   ${VIMRC}_old
        cp ${MYVIMRC} $HOME/.${MYVIMRC}

    fi
}

if [ "$COMMAND" = "set" ]; then
    setup
    echo "Done!"
elif [ "$COMMAND" = "restore" ]; then
    echo "Setting back to initial status."
    cp   ${VIMRC}_old  ${VIMRC}
    rm   ${VIMRC}_old
else
    echo "Unknown or missing command: '$COMMAND'"
fi


