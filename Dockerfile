FROM alpine:latest as builder
WORKDIR /tmp
RUN apk update && apk add linux-headers g++ make autoconf libtool pkgconfig git automake python python-dev
RUN cd /tmp && git clone https://github.com/grpc/grpc && cd grpc && git submodule update --init
RUN cd grpc && make plugins -j8
ADD https://jpa.kapsi.fi/nanopb/download/nanopb-0.4.1-linux-x86.tar.gz /tmp/
RUN cd /tmp && tar xvf nanopb-0.4.1-linux-x86.tar.gz
RUN cd /tmp/nanopb-0.4.1-linux-x86/generator/proto && make

FROM uber/prototool:1.10.0 as prototool

FROM namely/prototool:1.27_0
RUN apk add g++ gcc ruby-full ruby-dev make git
ADD https://github.com/grpc/grpc-web/releases/download/1.0.7/protoc-gen-grpc-web-1.0.7-linux-x86_64 /bin/protoc-gen-grpc-web
RUN chmod +x /bin/protoc-gen-grpc-web
RUN apk --no-cache add ca-certificates wget
RUN wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub
RUN wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.29-r0/glibc-2.29-r0.apk
RUN apk add glibc-2.29-r0.apk --force
RUN apk add py-pip
RUN apk add libgcc
RUN pip install protobuf
RUN apk add nodejs npm tree libgcc
RUN npm i -g request
RUN wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub
RUN wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.31-r0/glibc-2.31-r0.apk
RUN cd /tmp && LD_LIBRARY_PATH=/usr/lib npm i grpc-tools && tree && cp node_modules/grpc-tools/bin/grpc_node_plugin /bin/grpc_tools_node_protoc_plugin
RUN gem update --system
RUN gem install grpc
RUN gem install grpc-tools
ADD https://github.com/grpc-ecosystem/grpc-gateway/releases/download/v1.16.0/protoc-gen-swagger-v1.16.0-linux-x86_64 /usr/local/bin/protoc-gen-swagger
RUN chmod +x /usr/local/bin/protoc-gen-swagger

COPY --from=builder /tmp/grpc/bins/opt/grpc_python_plugin /bin/protoc-gen-grpc_python
COPY --from=builder /tmp/nanopb-0.4.1-linux-x86/generator/protoc-gen-nanopb /bin/
COPY --from=builder /tmp/nanopb-0.4.1-linux-x86/generator/proto /bin/proto
COPY --from=builder /tmp/nanopb-0.4.1-linux-x86/generator/nanopb /bin/nanopb
COPY --from=builder /tmp/nanopb-0.4.1-linux-x86/generator/nanopb_generator.py /bin/
COPY --from=prototool /usr/local/bin/prototool /usr/local/bin/prototool
