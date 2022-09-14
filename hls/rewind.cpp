#include "rewind.hpp"
#include <complex>
#include <hls_math.h>

typedef std::complex<double> compd;

using namespace std::complex_literals;

void rotation(const compd raw, compd& rew, double phase){
    double c,s;
    hls::sincos(phase, &s, &c);
    
    rew = compd(raw.real()*c - raw.imag()*s, raw.real()*s + raw.imag()*c);
}


void rewind(dds_in &data_in,
            hls::stream<double> &data_out,
            dds_in &data_pipe,
            const double phase_rew[N_CH],
            const double offset_real[N_CH],
            const double offset_imag[N_CH],
            const double phi_0[N_CH])
{
    // Stream in/out.
	#pragma HLS INTERFACE axis port=data_in
	#pragma HLS INTERFACE axis port=data_out
    #pragma HLS INTERFACE axis port=data_pipe
    // Bram interface.
	#pragma HLS INTERFACE bram port=phase_rew
	#pragma HLS INTERFACE bram port=offset_real
	#pragma HLS INTERFACE bram port=offset_imag
	#pragma HLS INTERFACE bram port=phi_0
    // Ctrl interface suppression.
	#pragma HLS INTERFACE ap_ctrl_none port=return

	
	for(int i = 0; i < N_CH; i++){
		#pragma HLS pipeline II=1 rewind
	    dds_data data_tmp_dds;
		data_in.read(data_tmp_dds);

		// Data slicing.
		// Expecting Q data is put to high bits.
		ap_int<2*DDS_BW> tmp_tot = data_tmp_dds.data;
		ap_int<DDS_BW> tmp_q = tmp_tot.range(2*DDS_BW-1, DDS_BW);
		ap_int<DDS_BW> tmp_i = tmp_tot.range(DDS_BW-1, 0);

		// Cast to double.
		compd tmp_c (tmp_i.to_double(), tmp_q.to_double());

		// Cable rewinding.
		double tmp_phase_rew = -phase_rew[i];

		compd tmp_rew;
		rotation(tmp_c, tmp_rew, tmp_phase_rew);

		// Offset shifting
		double tmp_off_r = offset_real[i];
		double tmp_off_i = offset_imag[i];
		compd tmp_off(tmp_rew.real() - tmp_off_r, tmp_rew.imag() - tmp_off_i);

		// phi_0 rotation
		double tmp_phase_phi = -phi_0[i];
		compd tmp_phi_rot;
		rotation(tmp_off, tmp_phi_rot, tmp_phase_phi);

		// Invert real axis.
		// This circumvents -pi/pi chattering, making triggering easier.
		compd tmp_fin = -std::conj(tmp_phi_rot);

		// atan2 and output.
		data_out.write(hls::atan2(tmp_fin.imag(), tmp_fin.real()));
		data_pipe.write(data_tmp_dds);
	}
}
