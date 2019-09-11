FROM alpine:edge
RUN apk --no-cache add \
        libressl \
        lftp \
        bash \
        diffutils \
        git \
        openssh-client \
        zip
ADD compare.sh /bin
RUN chmod +x /bin/compare.sh
