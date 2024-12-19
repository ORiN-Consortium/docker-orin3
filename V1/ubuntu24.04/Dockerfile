FROM ubuntu:24.04

ARG TARGETARCH
ENV APT_PATH=https://d3tdvt2nrvghqz.cloudfront.net/fa/iot/apt/
ENV YQ_BINARY=yq_linux_$TARGETARCH

RUN apt update
RUN apt dist-upgrade
RUN apt install curl gpg wget -y
RUN wget https://github.com/mikefarah/yq/releases/latest/download/$YQ_BINARY -O /usr/bin/yq &&\
    chmod +x /usr/bin/yq
RUN curl -fsSL ${APT_PATH}public.key | gpg --dearmor -o /etc/apt/keyrings/dnwa.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/dnwa.gpg] $APT_PATH stable main" | tee /etc/apt/sources.list.d/dnwa.list
RUN apt update
RUN apt install aspnetcore-runtime-8.0 -y
RUN apt install orin3.remoteengine -y
RUN apt clean

COPY *.sh /bin/ 

ENTRYPOINT ["docker-entrypoint.sh"]
