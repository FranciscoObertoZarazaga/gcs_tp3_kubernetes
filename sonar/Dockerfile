FROM curlimages/curl

COPY setup.sh /home/curl/setup.sh

USER root

RUN chmod +x /home/curl/setup.sh

USER curl_user

CMD ["/bin/sh", "-c", "/home/curl/setup.sh"]
