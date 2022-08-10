#include "ap_axi_sdata.h"
#include "ap_int.h"
#include "hls_stream.h"

#define N_CH 16
#define DDS_BW 48

typedef ap_axis<DDS_BW*2,0,0,0> dds_data;

typedef struct dds_iq {
	ap_int<DDS_BW> i;
    ap_int<DDS_BW> q;
} dds_iq;

typedef hls::stream<dds_data> dds_in;

void rewind(dds_in &data_in,
            hls::stream<double> &data_out,
            const double phase_rew[N_CH],
            const double offset_real[N_CH],
            const double offset_imag[N_CH],
            const double phi_0[N_CH]);
