FROM mongo:3.4
MAINTAINER Alexander Kuemmel
USER root
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install -yqq python python-pip python-setuptools \
    && pip install pydns
EXPOSE 27017
ADD tools /tools
ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
CMD [ "/entrypoint.sh" ]
