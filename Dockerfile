FROM store/oracle/database-enterprise:12.1.0.2

MAINTAINER patrick.bleek@docker.com

RUN yum install -y patch

COPY setupDB.sh.patch /home/oracle/setup/
COPY dockerInit.sh.patch /home/oracle/setup/

RUN patch /home/oracle/setup/setupDB.sh /home/oracle/setup/setupDB.sh.patch && \
    patch /home/oracle/setup/dockerInit.sh /home/oracle/setup/dockerInit.sh.patch
