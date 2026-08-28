#!/usr/bin/env python3
def mode0(b,p): return ((b>>(1-p))&1)<<3|((b>>(5-p))&1)<<2|((b>>(3-p))&1)<<1|((b>>(7-p))&1)
def mode1(b,p): return ((b>>(3-p))&1)<<1|((b>>(7-p))&1)
def mode2(b,p): return (b>>(7-p))&1
def cpc_addr(ma,ra,cclk): return ((ma>>13)&1)<<15|((ma>>12)&1)<<14|(ra&7)<<11|(ma&0x3ff)<<1|cclk
assert mode0(0xB6,0)==13 and mode0(0xB6,1)==6
assert [mode1(0xFF,p) for p in range(4)]==[3,3,3,3]
assert [mode2(0x81,p) for p in range(8)]==[1,0,0,0,0,0,0,1]
assert cpc_addr(0x3000,0,0)==0xC000 and cpc_addr(0x3000,0,1)==0xC001
assert 16_000_000//4==4_000_000 and 16_000_000//16==1_000_000
fps=1_000_000/(64*312); assert 50.0<fps<50.1
print('Phase 2 reference checks passed; standard-frame rate = %.6f Hz'%fps)
