function add_cmsd_headers(r) 
{
    if (r.headersOut['TCP_INFO'])
    {
        let tcp_info = r.headersOut['TCP_INFO'];
        
        let tcp_rtt = null;
        let tcp_snd_cwnd = null;
        if (/tcpinfo_rtt=([0-9]+)/.test(tcp_info))
        {
            tcp_rtt = tcp_info.match(/tcpinfo_rtt=([0-9]+)/)[1];

            if (/tcpinfo_snd_cwnd=([0-9]+)/.test(tcp_info))
            {
                tcp_snd_cwnd = tcp_info.match(/tcpinfo_snd_cwnd=([0-9]+)/)[1];
            }

        }
        if (tcp_rtt != null && tcp_snd_cwnd != null)
        {
            // Estimated throughput (etp) based on CMSD's proposal 
            let cmsd_etp = 8 * tcp_snd_cwnd/ (tcp_rtt * 1000);

            if (r.headersOut['CMSD-Dynamic']) {
                r.headersOut['CMSD-Dynamic'] = r.headersOut['CMSD-Dynamic'] +
                    `, u=\"Nginx-123\"; etp=${cmsd_etp}; rtt=${tcp_rtt}`
                // Remove TPC_INFO Header
                r.headersOut['TCP_INFO'] = null;
            }
        }
    }
}

// Set query request parameters to a env variable for logging purposes
function headers_to_json(r) {
    return JSON.stringify(r.headersIn)
  }

export default {add_cmsd_headers, headers_to_json}
