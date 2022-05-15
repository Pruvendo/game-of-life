pragma ton-solidity >=0.58.0;
pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;


contract LifeCell {

string constant version = "0.6"; 

int static public xcoord;
int static public ycoord;

mapping (uint16 => bool) public liveness;

uint8  public askedNeighbours;
uint8  public askedLive;
uint8  public sentLive;
bool   public cellInserted;
uint16 public nextGeneration;

LifeCell public prevCell;
LifeCell public nextCell;
LifeCell public currentHead;


constructor(address pc, address nc, address ch) public
{
    tvm.accept();
    if (msg.pubkey()!=0)
    {
        liveness[1] = true;
        prevCell = LifeCell(pc);
        nextCell = LifeCell(nc);
        currentHead = LifeCell(ch);
        cellInserted = true;
    }
}


//intialize can be called only by living cells in generation
function initialize (uint16 generation, LifeCell head) public 
{
    //living at asked generation
    tvm.rawReserve(address(this).balance - msg.value, 0);
    currentHead = head;

    if (liveness.exists(generation))
        LifeCell(msg.sender).onGetState {value:0, flag: 128} (liveness[generation]);
    else
    {
        sentLive ++;
        if (nextGeneration != generation + 1){
            nextGeneration = generation + 1;
            sentLive = 1;
        }
        if ((!cellInserted) && (sentLive == 3)) {
            nextCell = head;
            cellInserted = true;
            nextCell.insertCellBefore {value:0.15 ton, flag: 0} (this, LifeCell(msg.sender));
            LifeCell(msg.sender).onGetState {value:0, flag: 128} (false);
        }
        else
            LifeCell(msg.sender).onGetState {value:0, flag: 128} (false);
    }
}

//inserting cell

function insertCellBefore(LifeCell c, LifeCell caller) public
{
    prevCell.setNextCellToPrevHead {value:0, flag: 64} (c, caller);
    prevCell = c;
}

function setNextCellToPrevHead (LifeCell c, LifeCell caller) public
{
    nextCell = c;
    c.setPrevCellFromHead {value:0, flag: 64} (this, caller);
    //LifeCell(msg.sender).onPrevNextCellUpdated {value:0, flag: 64} (pc, c, caller);
}

/* function onPrevNextCellUpdated(LifeCell pc, LifeCell c, LifeCell caller) public
{
    c.setPrevCellFromHead {value:0, flag: 64} (pc, caller);
} */

function setPrevCellFromHead (LifeCell c, LifeCell caller) public
{
    prevCell = c;
    //cellInserted = true;
    address(caller).transfer(0, true, 64);
    //caller.onGetState {value:0, flag: 64} (false); 
}

///////////////////////////////////////////////////////////////////////////

// removing cell

function removeFromCircle() internal
{   
    cellInserted = false;

    if (nextCell == this) return; //end of game

    prevCell.setNextCellWhileRemoving { value: 0.2 ton } (nextCell);

    if (currentHead == this)
    {
        currentHead = nextCell;
    }

    tvm.rawReserve(0.1 ton, 0);

    nextCell.setPrevCellAndContinue { value: 0, flag: 128 } (prevCell, getLastGeneration(), currentHead);
}

function setNextCellWhileRemoving (LifeCell c) public
{
    nextCell = c;
    msg.sender.transfer(0, true, 64);
    //LifeCell(msg.sender).onPrevNextCellUpdatedWhileRemoving {value:0, flag: 64} ();
}

function getLastGeneration() public view returns(uint16 m)
{
    optional (uint16, bool) om = liveness.max();
    if (om.hasValue())
    {
        (m, ) = om.get();
    }
}


function setPrevCellAndContinue (LifeCell c, uint16 gen, LifeCell head) public
{
    prevCell = c;
    processGeneration(gen, head);
}


function transformGeneration(uint8 liveNeighbours) internal
{
    if ((liveNeighbours == 2) || (liveNeighbours == 3))
    {
        uint16 m = getLastGeneration();
        liveness[ m + 1] = true;
        tvm.rawReserve(0.1 ton, 0);
        nextCell.processGeneration {value:0, flag: 128} (m, currentHead);
    }
    else
    {
        sentLive = 0;
        removeFromCircle();
    }
}

function onGetState (bool state) public
{
    askedNeighbours --;
    if (state)
        askedLive ++;

    if (askedNeighbours == 0)
        transformGeneration(askedLive);    
}


function askNeighbours() internal
{
    askedNeighbours = 0;
    askedLive = 0;
    for (int i=-1 ; i <= 1; i++)
    for (int j=-1 ; j <= 1; j++)
    {
        if ((i!=0) || (j!=0))
        {
            TvmCell _dataCell = tvm.buildDataInit ( {contr: LifeCell,
                                                     pubkey: tvm.pubkey(),
                                                     varInit: { xcoord: xcoord + i,
                                                                ycoord: ycoord + j } } );
            TvmCell _stateInit = tvm.buildStateInit(tvm.code(), _dataCell);

            LifeCell newCell = new LifeCell { value: 0.2 ton,
                                              stateInit: _stateInit } 
                               (address.makeAddrStd(0,0), address.makeAddrStd(0,0), address.makeAddrStd(0,0));
            newCell.initialize { value: 0.3 ton }(getLastGeneration(), currentHead);                          
            askedNeighbours ++;                                
        }
    }
}

function processGeneration(uint16 generation, LifeCell head) public
{
    if (msg.pubkey() == tvm.pubkey())   
        tvm.accept();

    currentHead = head;   

    //if (generation == 2) return; 
    
    if (liveness.exists(generation) || liveness.exists(generation + 1)) // == true
    {
        askNeighbours();
    }
    else
    {
        if ((sentLive == 3) && (nextGeneration == generation + 1))
        {
            sentLive = 0;
            liveness[nextGeneration] = true;
            tvm.rawReserve(0.1 ton, 0);
            nextCell.processGeneration {value:0, flag: 128} (generation, currentHead);
        }
        else
        {
            sentLive = 0;
            liveness[generation] = false;
            removeFromCircle();
        }
    }
}

function getVersion() pure public returns(string)
{
    return version;
}

} 
