FROM centos:8

RUN set -xe \
  && sed -i -e "s|mirrorlist=|#mirrorlist=|g" /etc/yum.repos.d/CentOS-* \
  && sed -i -e "s|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g" /etc/yum.repos.d/CentOS-*

RUN set -xe \
  && dnf install -y gcc-c++ git make unzip ncurses-devel openssl-devel

WORKDIR /app

COPY .tool-versions ./

RUN set -xe \
  && version=`awk '/^erlang / { print $2 }' .tool-versions | sed 's/\.[^.]*$//'` \
  && curl -O https://erlang.org/download/otp_src_${version}.tar.gz \
  && tar -xzf otp_src_${version}.tar.gz \
  && cd otp_src_${version} \
  && export ERL_TOP=`pwd` \
  && ./configure && make && make install

RUN set -xe \
  && version=`awk '/^elixir / { sub(/-.*/, "", $2) ; print $2 }' .tool-versions` \
  && otp_version=`awk '/^erlang / { sub (/\..*/, "") ; print $2 }' .tool-versions` \
  && curl -fSL -o elixir-precompiled.zip https://github.com/elixir-lang/elixir/releases/download/v${version}/elixir-otp-${otp_version}.zip \
  && unzip -d /usr/local elixir-precompiled.zip

RUN mix local.hex --force \
  && mix local.rebar --force

ENV MIX_ENV=prod

COPY mix.exs mix.lock ./
RUN mix deps.get --only prod
RUN mix deps.compile

COPY assets assets
COPY config config
COPY lib lib
COPY priv priv
COPY VERSION VERSION
COPY rel rel

RUN mix compile

RUN mix esbuild default --minify
RUN mix phx.digest

RUN set -xe \
  && rm -rf _build/prod/rel/connect4/releases/* \
  && mix release
