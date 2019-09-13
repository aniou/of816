FEATURES {
	STARTADDRESS: default = $1000;
}

MEMORY {
	RAM: start = $1000, size = $6FFFF, file = %O;
	ZP: start = $0060, size = $80;
}

FILES {
            %O: format = bin;
}

SEGMENTS {
    FStartup: load=RAM, type=rw;
    FSystem:  load=RAM, type=ro;
	FCode: load=RAM, type=ro, optional=yes;
    ZEROPAGE: load=ZP,  type=bss;
}

