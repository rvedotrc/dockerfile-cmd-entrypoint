FROM scratch
ADD var/ruby-alpine-root.tar.gz /

WORKDIR /usr/bin
COPY show-invocation ./
RUN ln -s show-invocation cmd-string
RUN ln -s show-invocation cmd-array
RUN ln -s show-invocation ep-string
RUN ln -s show-invocation ep-array
RUN ln -s show-invocation 'ep-override ep-ov1'
RUN ln -s show-invocation some
RUN ln -s show-invocation '[]'
RUN ln -s show-invocation '["foo", "bar"]'
RUN cd /bin && cp /usr/bin/show-invocation sh
WORKDIR /
