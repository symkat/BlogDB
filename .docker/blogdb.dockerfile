FROM symkat/mojo:latest

USER root

ADD . /home/app/src
RUN chown -R app:app /home/app/src;

USER app 

RUN eval $(perl -Mlocal::lib); \
    cd /home/app/src/DB; \
    dzil build; \
    cpanm BlogDB-DB-*.tar.gz ; \
    cd /home/app/src/Web; \
    cpanm --installdeps .; \
    cpanm --installdeps .; \
    cpanm --installdeps .;
