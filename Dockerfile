FROM store/oracle/database-enterprise:12.1.0.2

MAINTAINER patrick.bleek@docker.com

RUN yum install -y patch && \
    yum clean all

COPY *.patch /home/oracle/setup/

RUN patch /home/oracle/setup/setupDB.sh /home/oracle/setup/setupDB.sh.patch && \
    patch /home/oracle/setup/startupDB.sh /home/oracle/setup/startupDB.sh.patch && \
    patch /home/oracle/setup/dockerInit.sh /home/oracle/setup/dockerInit.sh.patch && \
    patch /home/oracle/setup/configDBora.sh /home/oracle/setup/configDBora.sh.patch
    
