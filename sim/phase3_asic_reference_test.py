UNLOCK=[0xFF,0x77,0xB3,0x51,0xA8,0xD4,0x62,0x39,0x9C,0x46,0x2B,0x15,0x8A,0xCD,0xEE]
assert len(UNLOCK)==15 and UNLOCK[-2:]==[0xCD,0xEE]
rmr2=0xB8
assert (rmr2>>5)==0b101 and ((rmr2>>3)&3)==3 and (rmr2&7)==0
def palette_word(lo,hi): return ((lo>>4)<<8)|((hi&15)<<4)|(lo&15)
assert palette_word(0xF0,0x0F)==0xFF0 and palette_word(0x0F,0)==0x00F
def compare_line(vc,rc): return ((vc&31)<<3)|(rc&7)
assert compare_line(3,6)==30 and compare_line(31,7)==255
assert 16*256==0x1000
for w,k in [(0x03AB,'LOAD'),(0x1123,'PAUSE'),(0x2002,'REPEAT'),(0x4001,'CONTROL'),(0x4030,'CONTROL')]: assert {0:'LOAD',1:'PAUSE',2:'REPEAT',4:'CONTROL'}.get(w>>12)==k
assert 16_000_000/1024==15_625 and 27_000_000/864==31_250
print('Phase 3 ASIC reference constants: PASS')
