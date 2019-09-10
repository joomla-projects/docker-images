FROM alpine:edge
RUN apk --no-cache add \
        libressl \
        lftp \
        bash \
        diffutils \
        git \
        openssh-client \
        zip
ADD compare.sh .
RUN chmod +x ./compare.sh

ENTRYPOINT ./compare.sh
