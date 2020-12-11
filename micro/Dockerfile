#FROM golang
#RUN wget -q  https://raw.githubusercontent.com/micro/micro/master/scripts/install.sh -O - | /bin/bash
#ENV PATH="/root/bin:${PATH}"
#WORKDIR /goTemp
#ENTRYPOINT ["micro"]


FROM micro/micro
ENV PATH="/:${PATH}"
WORKDIR /goTemp
ENTRYPOINT ["micro"]