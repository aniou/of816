FEATURES {
	STARTADDRESS: default = $3a0000;
}

MEMORY {
	RAM: start = $3a0000, size = $ffff, file = %O;
	ZP: start  = $9000,   size = $2000;
}

FILES {
    %O: format = bin;
}

SEGMENTS {
    FStartup: load=RAM, type=ro;
    FSystem:  load=RAM, type=ro;
	FCode:    load=RAM, type=ro, optional=yes;
    ZEROPAGE: load=ZP,  type=bss;
}

