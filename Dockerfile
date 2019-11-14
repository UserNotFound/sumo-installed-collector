FROM sumologic/collector:latest-syslog

ADD log-wrapper.sh .

ENTRYPOINT ["/bin/bash", "/log-wrapper.sh"]