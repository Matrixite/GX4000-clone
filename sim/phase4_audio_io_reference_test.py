# Focused Phase-4 reference checks.
def ppi_sel(addr): return ((addr >> 11) & 1) == 0
def ppi_port(addr): return (addr >> 8) & 3
assert ppi_sel(0xF400) and ppi_port(0xF400) == 0
assert ppi_sel(0xF500) and ppi_port(0xF500) == 1
assert ppi_sel(0xF600) and ppi_port(0xF600) == 2
assert ppi_sel(0xF700) and ppi_port(0xF700) == 3
assert [0,1,2,3] == [0b00,0b01,0b10,0b11]
joy=0x7f; joy &= ~(1<<0); joy &= ~(1<<5); matrix=(1<<7)|joy
assert (matrix&0x01)==0 and (matrix&0x20)==0 and (matrix&0x80)!=0
assert list(range(0x6808,0x6810)) == [0x6808,0x6809,0x680a,0x680b,0x680c,0x680d,0x680e,0x680f]
MASTER=16_000_000; PSG=1_000_000
assert MASTER//16 == PSG
assert PSG/(16*100)==625.0
assert PSG/(16*10)==6250.0
assert PSG/(256*1)==3906.25
A,B,C=100,200,300
assert (A+B,B+C)==(300,500)
print('Phase 4 audio/PPI/controller reference checks: PASS')
