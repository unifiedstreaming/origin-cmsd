# This is an example VCL file for Varnish.
#
# It does not do anything by default, delegating control to the
# builtin VCL. The builtin VCL is called when there is no explicit
# return statement.
#
# See the VCL chapters in the Users Guide for a comprehensive documentation
# at https://www.varnish-cache.org/docs/.

# Marker to tell the VCL compiler that this VCL has been written with the
# 4.0 or 4.1 syntax.
vcl 4.1;
import std;
import header;
import tcp;


# Default backend definition. Set this to point to your content server.
backend default {
    .host = "{{TARGET_HOST}}";
    .port = "{{TARGET_PORT}}";
}

sub vcl_recv {
    # Happens before we check if we have this in cache already.
    #
    # Typically you clean up the request here, removing cookies you don't need,
    # rewriting the request, etc.

    # We first set TTLs valid for most of the content we need to cache
    set req.ttl = 1h;
    set req.grace = 2s;  

    set req.http.X-Request-ID = std.real2integer(std.random(1,999999999), 0);
    // Set Request ID (rid) if does not exist
    if(req.http.CMSD-Static !~ ".*rid="){
        if (req.http.CMSD-Static ~ ".*"){
            # No value has been appended to header `CMSD-Static`
            set req.http.CMSD-Static = regsub(req.http.CMSD-Static,  "^(.*)$", ("\1 rid=" + req.http.X-Request-ID + "")); 
        }
        else {
            set req.http.CMSD-Static = regsub(req.http.CMSD-Static,  "^(.*)$", ("\1; rid=" + req.http.X-Request-ID + "")); 
        }
    }

}
sub vcl_backend_response {
    # Happens after we have read the response headers from the backend.
    #
    # Here you clean the response headers, removing silly Set-Cookie headers
    # and other mistakes your backend does.

    # This block will make sure that if the upstream returns a 5xx, but we have the response in the cache (even if it's expired),
    # we fall back to the cached value (until the grace period is over).
    if (beresp.status == 500 || beresp.status == 502 || beresp.status == 503 || beresp.status == 504)
    {
        # This check is important. If is_bgfetch is true, it means that we've found and returned the cached object to the client,
        # and triggered an asynchoronus background update. In that case, if it was a 5xx, we have to abandon, otherwise the previously cached object
        # would be erased from the cache (even if we set uncacheable to true).
        if (bereq.is_bgfetch)
        {
            return (abandon);
        }

        # We should never cache a 5xx response.
        set beresp.uncacheable = true;
    }


}

sub vcl_deliver {
    # Happens when we have all the pieces we need, and are about to send the
    # response to the client.
    #
    # You can do accounting or modifying the final object here.
    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT";
    } else {
        set resp.http.X-Cache = "MISS";
    }
    set resp.http.X-Request-ID = req.http.X-Request-ID;

    // Set Request ID (rid) if does not exist
    if(resp.http.CMSD-Static !~ ".*rid="){
        set resp.http.CMSD-Static = regsub(resp.http.CMSD-Static,  "^(.+)$", ("\1; rid=" + req.http.X-Request-ID + ""));    
    }
    # Example on how to append a key and value using regsub
    # In this cases it appends n, etp, and rtt ot CMSD-Dynamic header
    if(resp.http.CMSD-Dynamic){
        set resp.http.CMSD-Dynamic = regsub(resp.http.CMSD-Dynamic, "^(.+)$", {"\1, n="Varnish-123"; etp=XXXX"});
        ## Added estimated RTT provided by VMOD tcp measured in milliseconds
        set resp.http.CMSD-Dynamic = regsub(resp.http.CMSD-Dynamic, "^(.+)$", ("\1; rtt=" + tcp.get_estimated_rtt() + ""));   
    }
    ## Set the correct format for CPU load. Specifically `busy` time variable
    ## from Header X-Origin-Load
    ##           x <= 30%   ----> low: l
    ##  30 % <=  x < 60%    ----> medium: m
    ##  60 % =<  x <= 100% ----> high: h
    if(resp.http.X-Origin-Load  ~ ".*b="){
        set resp.http.CMSD-busy = regsub(resp.http.X-Origin-Load, "^.*\sbusy=b=([0-9]+)%$", "\1");

        if(std.integer(resp.http.CMSD-busy, 0) < 30 )
        {
            set resp.http.CMSD-busy = "l";
        }
        elseif(std.integer(resp.http.CMSD-busy, 0) >= 30 && std.integer(resp.http.CMSD-busy, 0) < 60 )
        {
            set resp.http.CMSD-busy = "m";
        }
        else
        {
            set resp.http.CMSD-busy = "h";
        }
        
        ## Set at the begining of CMSD-Dynamic the value Orign's CPU usage
        # set resp.http.CMSD-Dynamic = regsub(resp.http.CMSD-Dynamic,  "^(.+)$", ("cpu=" + resp.http.CMSD-busy + "; \1"));  
        set resp.http.CMSD-Dynamic = regsub(resp.http.CMSD-Dynamic,  "^(.+)(,)(.+)$", ("\1; cpu=" + resp.http.CMSD-busy + ",\3"));    
  
        unset resp.http.CMSD-busy;
        # Remove Response header (X-Origin-Load) to caclcuate backend server (Origin) utilization
        unset resp.http.X-Origin-Load;

    }
}
