#include <cstring>
#include <iostream>
#include <fstream>
#include "UUT.h"
#include "defmacros.h"

#ifdef DUMP
    #include "verilated_vcd_c.h"
#endif

#ifndef DUMP_START
    const int DUMP_START=0;
#endif

#ifndef COLORW
    #define COLORW 4
#endif

using namespace std;

#ifdef JTFRAME_SDRAM_LARGE
    const int BANK_LEN = 0x100'0000;
#else
    const int BANK_LEN = 0x080'0000;
#endif

#ifndef JTFRAME_SIM_DIPS
    #define JTFRAME_SIM_DIPS 0xffffffff
#endif

class SDRAM {
    UUT& dut;
    char *banks[4];
    int dly[4];
    //int last_rd[5];
    char header[32];
    int read_offset( int region );
    int read_bank( char *bank, int addr );
    void write_bank16( char *bank,  int addr, int val, int dm /* act. low */ );
public:
    SDRAM(UUT& _dut);
    ~SDRAM();
    void update();
    void dump();
};

class Download {
    UUT& dut;
    int addr, din, ticks,len;
    char *buf;
    bool done, full_download;
    int read_buf() {
        return (buf!=nullptr && addr<len) ? buf[addr] : 0;
    }
public:
    Download(UUT& _dut) : dut(_dut) {
        done = false;
        buf = nullptr;
        ifstream fin( GAME_ROM_PATH, ios_base::binary );
        fin.seekg( 0, ios_base::end );
        len = (int)fin.tellg();
        if( len == 0 || fin.bad() ) {
            cout << "Verilator test.cpp: cannot open file " << GAME_ROM_PATH << endl;
        } else {
            buf = new char[len];
            fin.seekg(0, ios_base::beg);
            fin.read(buf,len);
            if( fin.bad() ) {
                cout << "Verilator test.cpp: problem while reading " << GAME_ROM_PATH << endl;
            } else {
                cout << "Read " << len << " bytes from " << GAME_ROM_PATH << endl;
            }
        }
    };
    ~Download() {
        delete []buf;
        buf=nullptr;
    };
    bool FullDownload() { return full_download; }
    void start( bool download ) {
        full_download = download; // At least the first 32 bytes will always be downloaded
        //if( !full_download && len>32 ) len=32;
        ticks = 0;
        done = false;
        dut.downloading = 1;
        dut.ioctl_addr = 0;
        dut.ioctl_dout = read_buf();
        dut.ioctl_wr   = 0;
        addr = -1;
    }
    void update() {
        dut.ioctl_wr = 0;
        if( !done && dut.downloading ) {
            switch( ticks&31 ) {
                case 0:
                    addr++;
                    dut.ioctl_addr = addr;
                    dut.ioctl_dout = read_buf();
                    break;
                case 1:
                    if( addr < len ) {
                        dut.ioctl_wr = 1;
                    } else {
                        dut.downloading = 0;
                        done = true;
                        cout << "ROM load finished\n";
                    }
                    break;
            }
            ticks++;
        } else {
            ticks=0;
            addr = -1;
        }
    }
};

const int VIDEO_BUFLEN = 256;

class JTSim {
    vluint64_t simtime;
#ifdef JTFRAME_CLK96
    const vluint64_t semi_period=10416/2;
#else
    const vluint64_t semi_period=10416; // 48 MHz
#endif

    void parse_args( int argc, char *argv[] );
    void video_dump();
    bool trace;   // trace enable or not
    bool dump_ok; // can we dump? (provided trace is enabled)
    bool download;
    VerilatedVcdC* tracer;
    SDRAM sdram;
    Download dwn;
    int frame_cnt, last_VS;
    // Video dump
    struct {
        ofstream fout;
        int ptr;
        int32_t buffer[VIDEO_BUFLEN];
    } dump;
    int color8(int c) {
        switch(COLORW) {
            case 8: return c;
            case 4: return (c<<4) | c;
            default: return c;
        }
    }
    void reset(int r);
public:
    int finish_time, finish_frame;
    bool done() {
        return (finish_frame>0 ? frame_cnt > finish_frame :
                simtime/1000'000'000 >= finish_time ) && !game.downloading;
    };
    UUT& game;
    int get_frame() { return frame_cnt; }
    JTSim( UUT& g, int argc, char *argv[] );
    ~JTSim();
    void redownload() { dwn.start(download); }
    void clock(int n);
};

////////////////////////////////////////////////////////////////////////
//////////////////////// SDRAM /////////////////////////////////////////


int SDRAM::read_bank( char *bank, int addr ) {
    const int mask = (BANK_LEN>>1)-1; // 8/16MB in 16-bit words
    addr &= mask;
    int16_t *b16 =(int16_t*)bank;
    int v = b16[addr]&0xffff;
    return v;
}

void SDRAM::write_bank16( char *bank, int addr, int val, int dm /* act. low */ ) {
    const int mask = (BANK_LEN>>1)-1; // 8/16MB in 16-bit words
    addr &= mask;
    int16_t *b16 =(int16_t*)bank;
    int v = (int)b16[addr];
    if( (dm&1) == 0 ) {
        v &= 0xff00;
        v |= val&0xff;
    }
    if( (dm&2) == 0 ) {
        v &= 0xff;
        v |= val&0xff00;
    }
    v &= 0xffff;
    b16[addr] = (int16_t)v;
    //if(verbose) printf("%04X written to %X\n", v,addr);
}

void SDRAM::dump() {
    char *aux=new char[BANK_LEN];
    for( int k=0; k<4; k++ ) {
        char fname[32];
        sprintf(fname,"sdram_bank%d.bin",k);
        ofstream fout(fname,ios_base::binary);
        if( !fout.good() ) {
            cout << "Error creating " << fname << '\n';
        }
        // reverse bytes because 16-bit access operation
        // use the wrong endianness in intel machines
        for( int j=0;j<BANK_LEN;j++) {
            aux[j^1] = banks[k][j];
        }
        fout.write(aux,BANK_LEN);
        if( !fout.good() ) {
            cout << "Error saving to " << fname << '\n';
        }
        cout << fname << " dumped\n";
#ifndef JTFRAME_SDRAM_BANKS
        break;
#endif
    }
    delete[] aux;
}

    void SDRAM::update() {
#ifdef JTFRAME_SDRAM_BANKS
        CData *ba_ack   = &dut.ba_ack;
        CData *ba_rdy   = &dut.ba_rdy;
        CData *ba_dst   = &dut.ba_dst;
        unsigned ba_rd  = dut.ba_rd;
        unsigned ba_add[4] = { dut.ba0_addr, dut.ba1_addr, dut.ba2_addr, dut.ba3_addr };
        dut.prog_ack = 0;

        if( dut.prog_we ) {
            write_bank16( banks[dut.prog_ba], dut.prog_addr, dut.prog_data, dut.prog_mask );
            dut.prog_ack = 1;
            return;
        }

        if( dut.rst ) {
            *ba_ack = 0;
            *ba_rdy = 0;
            for( int k=0; k<4; k++ ) {
                //last_rd[k] = 0;
                dly[k] = -1;
            }
            return;
        }

        bool dout=false;
        *ba_dst = 0;
        *ba_rdy = 0;
        for( int k=0; k<4; k++) {
            // Data output at dly==1 and dly==0
            if( dly[k] == 1 && !dout ) { // do not emit ba_dst for write operations
                dut.data_read = read_bank( banks[k], ba_add[k] );
                *ba_dst |= 1<<k;
                dout=true;
            }
            if( dly[k] == 0 && !dout) {
                dut.data_read = read_bank( banks[k], ba_add[k]+1 );
                *ba_rdy |= 1<<k;
                dly[k] = -1;
                dout=true;
                continue;
            }
            // Process read/write requests
            if( ( (ba_rd &(1<<k)) || (k==0 && dut.ba_wr) ) // read or write
                && dly[k]<0) {
                dly[k]    = 8;
                unsigned aux = *ba_rdy & ~(1<<k);
                *ba_rdy = aux;
                aux = *ba_ack | (1<<k);
                *ba_ack = aux;
                if( k==0 && dut.ba_wr ) {
                    write_bank16( banks[0], dut.ba0_addr, dut.ba0_din, dut.ba0_din_m );
                }
            } else {
                if( dly[k]==7) *ba_ack = 0;
                if( dly[k]>0 ) --dly[k];
            }
        }
    }
#else
        dut.sdram_ack = 0;
        dut.data_dst  = 0;  // dst = data start
        dut.data_rdy  = 0;

        if( dut.rst ) {
            dut.data_read = 0;
            dly[0] = -1;
            return;
        }

        if( dut.prog_we ) {
            write_bank16( banks[0], dut.prog_addr, dut.prog_data, dut.prog_mask );
            dut.sdram_ack = 1;
            return;
        }

        if( dut.prog_rd ) {
            cout << "Verilator test.cpp: unsupported prog_rd operation\n";
        }

        if( !dut.downloading ) {
            // Regular access
            // Data output at dly==1 and dly==0
            if( dly[0] == 1 ) {
                dut.data_read = read_bank( banks[0], dut.sdram_addr );
                dut.data_dst = 1;
            }
            if( dly[0] == 0 ) {
                dut.data_read = read_bank( banks[0], dut.sdram_addr+1 );
                dut.data_rdy  = 1;
                dly[0] = -1;
                return;
            }

            if( dut.sdram_req && dly[0]<0) {
                dly[0] = 8;
                dut.data_rdy = 0;
                dut.sdram_ack = 1;
            } else {
                if( dly[0]>0 ) --dly[0];
            }
        }
    }
#endif

int SDRAM::read_offset( int region ) {
    if( region>=32 ) {
        region = 0;
        printf("ERROR: tried to read past the header\n");
        return 0;
    }
    int offset = (((int)header[region]<<8) | ((int)header[region+1]&0xff)) & 0xffff;
    return offset<<8;
}

SDRAM::SDRAM(UUT& _dut) : dut(_dut) {
#ifdef JTFRAME_SDRAM_BANKS
    cout << "Multibank SDRAM enabled\n";
#endif
    banks[0] = nullptr;
    for( int k=0; k<4; k++ ) {
        banks[k] = new char[BANK_LEN];
        dly[k]=-1;
        // delete the content
        memset( banks[k], 0, BANK_LEN );
        // Try to load a file for it
        char fname[32];
        sprintf(fname,"sdram_bank%d.bin",k);
        ifstream fin( fname, ios_base::binary );
        if( fin ) {
            fin.seekg( 0, fin.end );
            auto len = fin.tellg();
            fin.seekg( 0, fin.beg );
            if( len>BANK_LEN ) len=BANK_LEN;
            fin.read( banks[k], len );
            auto pos = fin.tellg();
            cout << "Read " << hex << pos << " from " << fname << '\n';
            // Reset the rest of the SDRAM bank
            if( pos<BANK_LEN )
                memset( (void*)&banks[k][pos], 0, BANK_LEN-pos);
        } else {
            cout << "Skipped " << fname << "\n";
        }
    }
}

SDRAM::~SDRAM() {
    for( int k=0; k<4; k++ ) {
        delete [] banks[k];
        banks[k] = nullptr;
    }
}

////////////////////////////////////////////////////////////////////////
//////////////////////// JTSIM /////////////////////////////////////////

void JTSim::reset( int v ) {
    game.rst = v;
#ifdef JTFRAME_CLK96
    game.rst96 = v;
#endif
#ifdef JTFRAME_CLK24
    game.rst24 = v;
#endif
}

JTSim::JTSim( UUT& g, int argc, char *argv[]) : game(g), sdram(g), dwn(g) {
    simtime=0;
    frame_cnt=0;
    last_VS = 0;
#ifdef LOADROM
    download = true;
#else
    download = false;
#endif
    // Video dump
    dump.fout.open("video.pipe", ios_base::binary );
    dump.ptr = 0;

    parse_args( argc, argv );
#ifdef DUMP
    if( trace ) {
        Verilated::traceEverOn(true);
        tracer = new VerilatedVcdC;
        game.trace( tracer, 99 );
        tracer->open("test.vcd");
        cout << "Verilator will dump to test.vcd\n";
    } else {
        tracer = nullptr;
    }
#endif
#ifdef JTFRAME_SIM_GFXEN
    game.gfx_en=JTFRAME_SIM_GFXEN;    // enable selected layers
#else
    game.gfx_en=0xf;    // enable all layers
#endif
    game.dip_pause=1;
#ifdef JTFRAME_MRA_DIP
    game.dipsw=JTFRAME_SIM_DIPS;
#endif
    game.joystick1 = 0xff;
    game.joystick2 = 0xff;
    game.start_button = 0xf;
    game.coin_input   = 0xf;
    game.service      = 1;
    game.dip_test     = 1;
    reset(0);
    clock(48);
    reset(1);
    clock(48);
#ifdef JTFRAME_CLK96
    game.rst96 = 0;
#endif
    clock(10);
    dwn.start(download);
}

JTSim::~JTSim() {
    dump.fout.write( (char*) dump.buffer, dump.ptr*4 ); // flushes the buffer
#ifdef DUMP
    delete tracer;
#endif
}

void JTSim::clock(int n) {
    static int ticks=0;
    static int last_dwnd=0;
    while( n-- > 0 ) {
        game.clk = 1;
#ifdef JTFRAME_CLK24    // not supported together with JTFRAME_CLK96
        switch( ticks&3 ) {
            case 0: game.clk24 = 1; break;
            case 2: game.clk24 = 0; break;
        }
#endif
#ifdef JTFRAME_CLK48
        game.clk48 = 1-game.clk48;
#endif
#ifdef JTFRAME_CLK96
        game.clk96 = game.clk;
#endif
        game.eval();
        sdram.update();
        dwn.update();
        int cur_dwn = game.downloading | game.dwnld_busy;
        if( !cur_dwn && last_dwnd ) {
            // Download finished
            if( finish_time>0 ) finish_time += simtime/1000'000'000;
            if( finish_frame>0 ) finish_frame += frame_cnt;
            if ( dwn.FullDownload() ) sdram.dump();
            reset(0);
        }
        last_dwnd = cur_dwn;
        simtime += semi_period;
#ifdef DUMP
        if( tracer && dump_ok ) tracer->dump(simtime);
#endif
        game.clk = 0;
#ifdef JTFRAME_CLK96
        game.clk96 = game.clk;
#endif
        game.eval();
        simtime += semi_period;
        ticks++;

#ifdef DUMP
        if( tracer && dump_ok ) tracer->dump(simtime);
#endif
        // frame counter
        if( game.VS && !last_VS ) {
            frame_cnt++;
            if( frame_cnt == DUMP_START && !dump_ok ) {
                dump_ok = 1;
                cout << "\nDump starts " << dec << frame_cnt << '\n';
            }
            cout << ".";
            if( !(frame_cnt & 0x3f) ) cout << '\n';
            cout.flush();
        }
        last_VS = game.VS;

        // Video dump
        video_dump();
    }
}

void JTSim::video_dump() {
    if( game.pxl_cen && game.LHBL_dly && game.LVBL_dly && frame_cnt>0 ) {
        const int MASK = (1<<COLORW)-1;
        int red   = game.red   & MASK;
        int green = game.green & MASK;
        int blue  = game.blue  & MASK;
        int mix = 0xFF000000 |
            ( color8(blue ) << 16 ) |
            ( color8(green) <<  8 ) |
            ( color8(red  )       );
        dump.buffer[dump.ptr++] = mix;
        if( dump.ptr==256 ) {
            dump.fout.write( (char*)dump.buffer, VIDEO_BUFLEN*4 );
            dump.ptr=0;
        }
    }
}

void JTSim::parse_args( int argc, char *argv[] ) {
    trace = false;
    finish_frame = -1;
    finish_time  = 10;
    for( int k=1; k<argc; k++ ) {
        if( strcmp( argv[k], "--trace")==0 ) {
            trace=true;
            dump_ok = DUMP_START==0;
            continue;
        }
        if( strcmp( argv[k], "-time")==0 ) {
            if( ++k >= argc ) {
                cout << "ERROR: expecting time after -time argument\n";
            } else {
                finish_time = atol(argv[k]);
            }
            continue;
        }
        if( strcmp( argv[k], "-frame")==0 ) {
            if( ++k >= argc ) {
                cout << "ERROR: expecting frame count after -frame argument\n";
            } else {
                finish_frame = atol(argv[k]);
            }
            continue;
        }
    }
    #ifdef MAXFRAME
    finish_frame = MAXFRAME;
    #endif
}

////////////////////////////////////////////////////
// Main

int main(int argc, char *argv[]) {
    Verilated::commandArgs(argc, argv);

    UUT game;
    JTSim sim(game, argc, argv);

    int loops=1;

    while( !sim.done() ) {
        sim.clock(9'000);
        if( sim.game.dwnld_busy==0 ) {
            sim.redownload();
            if( loops-- < 0 ) break;
        }
        sim.clock(1'000);
    }
    if( sim.get_frame()>1 ) cout << endl;
    return 0;
}