#!/bin/bash

CELL1X=0
CELL1Y=0

CELL2X=1
CELL2Y=0

CELL3X=1
CELL3Y=1

CELL4X=0
CELL4Y=-1

CELL5X=-1
CELL5Y=1

#deploy cells
GREP_STR1="Address:"
GREP_STR2="(calculated from TVC and signer public)"

everdev contract info Cell --data "xcoord:$CELL1X,ycoord:$CELL1Y" --signer keys1 | tee cell1_address.log
export CELL1_ADDRESS=`grep "$GREP_STR1" cell1_address.log | sed -e "s/ *$GREP_STR1  *//" |  sed -e "s/$GREP_STR2//" | tr -d ' '`

everdev contract info Cell --data "xcoord:$CELL2X,ycoord:$CELL2Y" --signer keys1 | tee cell2_address.log
export CELL2_ADDRESS=`grep "$GREP_STR1" cell2_address.log | sed -e "s/ *$GREP_STR1  *//" |  sed -e "s/$GREP_STR2//" | tr -d ' '`

everdev contract info Cell --data "xcoord:$CELL3X,ycoord:$CELL3Y" --signer keys1 | tee cell3_address.log
export CELL3_ADDRESS=`grep "$GREP_STR1" cell3_address.log | sed -e "s/ *$GREP_STR1  *//" |  sed -e "s/$GREP_STR2//" | tr -d ' '`

everdev contract info Cell --data "xcoord:$CELL4X,ycoord:$CELL4Y" --signer keys1 | tee cell4_address.log
export CELL4_ADDRESS=`grep "$GREP_STR1" cell4_address.log | sed -e "s/ *$GREP_STR1  *//" |  sed -e "s/$GREP_STR2//" | tr -d ' '`

everdev contract info Cell --data "xcoord:$CELL5X,ycoord:$CELL5Y" --signer keys1 | tee cell5_address.log
export CELL5_ADDRESS=`grep "$GREP_STR1" cell5_address.log | sed -e "s/ *$GREP_STR1  *//" |  sed -e "s/$GREP_STR2//" | tr -d ' '`


everdev contract deploy Cell --data "xcoord:$CELL1X,ycoord:$CELL1Y" --signer keys1 --input "pc:\"$CELL5_ADDRESS\",nc:\"$CELL2_ADDRESS\",ch:\"$CELL1_ADDRESS\"" --signer keys1 -v 100000000000
everdev contract deploy Cell --data "xcoord:$CELL2X,ycoord:$CELL2Y" --signer keys1 --input "pc:\"$CELL1_ADDRESS\",nc:\"$CELL3_ADDRESS\",ch:\"$CELL1_ADDRESS\"" --signer keys1 -v 10000000000
everdev contract deploy Cell --data "xcoord:$CELL3X,ycoord:$CELL3Y" --signer keys1 --input "pc:\"$CELL2_ADDRESS\",nc:\"$CELL4_ADDRESS\",ch:\"$CELL1_ADDRESS\"" --signer keys1 -v 10000000000
everdev contract deploy Cell --data "xcoord:$CELL4X,ycoord:$CELL4Y" --signer keys1 --input "pc:\"$CELL3_ADDRESS\",nc:\"$CELL5_ADDRESS\",ch:\"$CELL1_ADDRESS\"" --signer keys1 -v 10000000000
everdev contract deploy Cell --data "xcoord:$CELL5X,ycoord:$CELL5Y" --signer keys1 --input "pc:\"$CELL4_ADDRESS\",nc:\"$CELL1_ADDRESS\",ch:\"$CELL1_ADDRESS\"" --signer keys1 -v 10000000000


everdev contract run Cell processGeneration -a $CELL1_ADDRESS --input "generation:1,head:\"$CELL1_ADDRESS\"" --signer keys1
