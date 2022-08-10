#include <iostream>
#include "rewind.hpp"
using namespace std;


int main()
{

    dds_in data_in;
    hls::stream<double> data_out;

    double phase_rew[N_CH];
    double offset_real[N_CH];
    double offset_imag[N_CH];
    double phi_0[N_CH];

    ap_int<48> x, y;

    for(int j = 0; j < N_CH; j++){
        phase_rew[j] = 3.1415926535/16.0*j;
        offset_real[j] = 0;
        offset_imag[j] = 0;
        phi_0[j] = 0;
    }

    for(int j = 0; j < N_CH; j++){
        dds_data tmpd;
        x = 1;
        y = 0;
        tmpd.data = y.concat(x);
        data_in.write(tmpd);
    }

    rewind(data_in, data_out, phase_rew, offset_real, offset_imag, phi_0);

    for(int j = 0; j < N_CH; j++){
        double result;
        data_out.read(result);
        cout << "result:" << result << endl;
    }

    cout << "Success: results match" << endl;
    return 0;
}
