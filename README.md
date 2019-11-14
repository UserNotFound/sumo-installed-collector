[![Docker Repository on Quay](https://quay.io/repository/usernotfound/sumo-installed-collector/status "Docker Repository on Quay")](https://quay.io/repository/usernotfound/sumo-installed-collector)

The goal here is to use the [Sumo Installed Collector](https://help.sumologic.com/03Send-Data/Installed-Collectors/01About-Installed-Collectors), running as a Deploy App, as an intermediary between our Log Drain and Sumo Logic.

We will implement a [TLS Endpoint](https://www.aptible.com/documentation/deploy/reference/apps/endpoints/tls-endpoints.html) in front of the Installed Collector, since Log Drains do not support insecure destinations.

The Collector sends data to the Sumo servers over HTTPS.

This has a number of benefits:
* Sumo is both in responsible for the service and servers that are sending and receiving data - we trust that delegating this part of the pipeline to Sumo will be more reliable and transparent to you, than our HTTPS output plugin for our Log Drain.
* Because the Installed Collector will [cache log data](https://help.sumologic.com/03Send-Data/Collector-FAQs/Configure_Limits_for_Collector_Caching) if it encounters errors communicating with the Sumo service (or you're exceeding your ingestion quota), this is absorbed and handled in the Collector, not our Log Drain

As a result, we believe this greatly reduces the risk that the Log Drain will be a source of issue, while providing more transparency to you with regards to delivery.

This is not without potential downsides, though: namely that the format of Syslog based messages is limited compared to the HTTPS formart, and the Sumo Collector running on Deploy relies on a TLS Endpoint, which cannot provide zero-downtime operations.  However, in my testing, our Log Drain is still able to tolerate interruptions, retrying any messages it is not able to push to the Collector.  Most of the risk here seems to be able to be mitigated by scaling the Collector to two containers. I didn't see any obvious issues doing so in my testing, and logs seems to be delivered even if one or the other container was "unexpectedly" stopped.

Setup Guide:

1. Create a Sumo Access Key (if needed) : https://help.sumologic.com/Manage/Security/Access-Keys#Create_an_access_key
1. You don't want the Sumo Collector to be responsible for collecting it's own logs, so create a new Environment.
1. Create a new App : `aptible apps:create sumo-installed-collector --environment ${ENVIRONMENT}`
1. Configure the `aptible config:set --app sumo-installed-collector SUMO_COLLECTOR_NAME=aptible-installed SUMO_JAVA_MEMORY_MAX=256 SUMO_ACCESS_KEY=${YOUR_KEY} SUMO_ACCESS_ID=${YOUR_ID}`
1. Deploy this App: `aptible deploy --app sumo-installed-collector --docker-image quay.io/usernotfound/sumo-installed-collector`
1. Add a TLS Endpoint: `aptible endpoints:tls:create --app sumo-installed-collector cmd --internal --default-domain` 
1. Configure a Log Drain : choose "Manual Configuration", Type: Syslog TLS TCP, Host: the above Endpoint's Hostname, Port: 514, Token: blank.
