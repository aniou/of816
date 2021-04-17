FEATURES {
	STARTADDRESS: default = $010000;
}

MEMORY {
	RAM: start = $010000, size = $ffff, file = %O;
	ZP: start  = $8000,   size = $2000;
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

