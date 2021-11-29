FROM debian:11

RUN apt-get update; \
    apt-get install -y git build-essential libpq-dev libssl-dev libz-dev libexpat1-dev cpanminus liblocal-lib-perl \
        postgresql-client postgresql-contrib postgresql python3-psycopg2; \
    useradd -U -s /bin/bash -m app;

USER app
RUN eval $(perl -Mlocal::lib); \
    echo 'eval $(perl -Mlocal::lib)' >> /home/app/.bashrc; \
    cpanm Dist::Zilla Archive::Zip Minion Mojolicious::Plugin::XslateRenderer Mojolicious::Plugin::RenderFile Mojo::Pg \
        DateTime::Format::Pg WebService::WsScreenshot LWP::UserAgent XML::RSS Test::Postgresql58 Test::More Test::Deep \
        DBIx::Class::InflateColumn::Serializer DBIx::Class::Schema::Config DBIx::Class::DeploymentHandler Data::GUID   \
        MooseX::AttributeShortcuts MooseX::Getopt DBD::Pg; \
    cpanm Dist::Zilla Archive::Zip Minion Mojolicious::Plugin::XslateRenderer Mojolicious::Plugin::RenderFile Mojo::Pg \
        DateTime::Format::Pg WebService::WsScreenshot LWP::UserAgent XML::RSS Test::Postgresql58 Test::More Test::Deep \
        DBIx::Class::InflateColumn::Serializer DBIx::Class::Schema::Config DBIx::Class::DeploymentHandler Data::GUID   \
        MooseX::AttributeShortcuts MooseX::Getopt DBD::Pg; \
    cpanm Dist::Zilla Archive::Zip Minion Mojolicious::Plugin::XslateRenderer Mojolicious::Plugin::RenderFile Mojo::Pg \
        DateTime::Format::Pg WebService::WsScreenshot LWP::UserAgent XML::RSS Test::Postgresql58 Test::More Test::Deep \
        DBIx::Class::InflateColumn::Serializer DBIx::Class::Schema::Config DBIx::Class::DeploymentHandler Data::GUID   \
        MooseX::AttributeShortcuts MooseX::Getopt DBD::Pg; \
    cpanm Dist::Zilla Archive::Zip Minion Mojolicious::Plugin::XslateRenderer Mojolicious::Plugin::RenderFile Mojo::Pg \
        DateTime::Format::Pg WebService::WsScreenshot LWP::UserAgent XML::RSS Test::Postgresql58 Test::More Test::Deep \
        DBIx::Class::InflateColumn::Serializer DBIx::Class::Schema::Config DBIx::Class::DeploymentHandler Data::GUID   \
        MooseX::AttributeShortcuts MooseX::Getopt DBD::Pg; \
    cpanm Dist::Zilla Archive::Zip Minion Mojolicious::Plugin::XslateRenderer Mojolicious::Plugin::RenderFile Mojo::Pg \
        DateTime::Format::Pg WebService::WsScreenshot LWP::UserAgent XML::RSS Test::Postgresql58 Test::More Test::Deep \
        DBIx::Class::InflateColumn::Serializer DBIx::Class::Schema::Config DBIx::Class::DeploymentHandler Data::GUID   \
        MooseX::AttributeShortcuts MooseX::Getopt DBD::Pg;
