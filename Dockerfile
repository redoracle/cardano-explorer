# Dockerfile to create an environment that contains:
# Alpine +  Nix package manager + nodejs + Cardano SL (Explorer + Wallet + mallet scripts) 

FROM redoracle/nixos
MAINTAINER RedOracle

# Metadata params
ARG BUILD_DATE
ARG VERSION
ARG VCS_URL
ARG VCS_REF

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-url=$VCS_URL \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.version=$VERSION \
      org.label-schema.name='Cardano Explorer' \
      org.label-schema.description='Cardano Explorer + Nixos' \
      org.label-schema.usage='https://www.katango.eu/docker' \
      org.label-schema.url='https://www.katango.eu/' \
      org.label-schema.vendor='Blockchain Security' \
      org.label-schema.schema-version='2.1' \
      org.label-schema.docker.cmd='docker run --rm redoracle/cardano-explorer' \
      org.label-schema.docker.cmd.devel='docker run --rm -ti redoracle/cardano-explorer' \
      org.label-schema.docker.debug='docker logs $CONTAINER' \
      io.github.offensive-security.docker.dockerfile="Dockerfile" \
      io.github.offensive-security.license="GPLv3" \
      MAINTAINER="RedOracle <info@redoracle.com>"

WORKDIR /root/

# Download additional packages and Enable HTTPS support in wget
RUN cd \
&& curl -sSL https://get.haskellstack.org/ | sh \
&& mkdir /root/blockscripts \
&& echo http:"//dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
&& apk update && apk --no-cache upgrade && apk add --no-cache --update bash make tmux curl gtk+2.0 g++ \
&& nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs \
&& nix-shell -p nix-info --run "nix-info -m" \
&& nix-channel --update \
&& nix-env -iaPA nixpkgs.purescript nixos.nodePackages nixpkgs.wget nixpkgs.ghc nixpkgs.perl nixpkgs.sudo nixpkgs.gcc nixpkgs.gmp nixpkgs.xz nixpkgs.git nixpkgs.rustc nixpkgs.yarn nixpkgs.openssl nixpkgs.ncurses nixpkgs.haskell-ci nixpkgs.python nixpkgs.npm2nix \
&& npm install -f -g --unsafe-perm=true --allow-root --no-optional --toolset=musl node-musl n wscat mobx react react-dom fsevents pulp bower \
&& yarn install && yarn upgrade \
&& git clone https://github.com/input-output-hk/cardano-byron-proxy \
&& cd cardano-byron-proxy \
&& nix-build -A scripts.mainnet.proxy -o mainnet-byron-proxy \
&& cd && git clone https://github.com/input-output-hk/cardano-node \
&& cd cardano-node \
&& nix-build -A scripts.mainnet.node -o mainnet-node-local --arg customConfig '{ useProxy = true; }' \
&& cd && git clone https://github.com/input-output-hk/cardano-explorer \
&& cd cardano-explorer \
&& nix-build -A cardano-explorer-node -o explorer-node \
&& cd \
&& git clone https://github.com/input-output-hk/daedalus.git \
&& git clone https://github.com/input-output-hk/mallet.git \
&& git clone https://github.com/input-output-hk/cardano-cli.git --recursive \
&& cd /root/mallet \
&& npm install -g --engine-strict @iohk/mallet --unsafe-perm=true --allow-root \
&& npm audit fix --force \
&& cd /root/cardano-cli  \
#&& res=$(find /nix/store/ -name cargo | head -1 ) \
#&& echo "RES = $res" && $res install \
&& cd && source . /etc/profile && echo ". /etc/profile;" >> /root/.profile \
&& echo "if [ \"$BASH\" ]; then   if [ -f ~/.bashrc ]; then     . ~/.bashrc;   fi; fi" >> /root/.profile \
&& nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs \
&& nix-shell -p nix-info --run "nix-info -m" \
&& nix-channel --update \
&& nix-env -u --always \
&& nix-collect-garbage -d \
&& rm -rf /root/.cache \
&& rm -rf /tmp/* \
&& rm -rf /root/state-wallet-mainnet/* \
&& rm -rf /var/cache/apk/* 

COPY Cardano_updated.sh /root/blockscripts/
VOLUME /root/state-wallet-mainnet 
VOLUME /root/state-explorer-mainnet
    
ONBUILD ENV \
    ENV=/etc/profile \
    USER=root \
    PATH=~/.nix-profile/bin:/usr/local/bin:/root/.cargo/bin:/root/blockscripts/:~/.local/bin:/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:/bin:/sbin:/usr/bin:/usr/sbin \
    NIX_PATH=/nix/var/nix/profiles/per-user/root/channels
    

ENV \
    ENV=/etc/profile \
    USER=root \
    PATH=~/.nix-profile/bin:/usr/local/bin:/root/.cargo/bin:/root/blockscripts/:~/.local/bin:/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:/bin:/sbin:/usr/bin:/usr/sbin \
    NIX_PATH=/nix/var/nix/profiles/per-user/root/channels
    
CMD ["/bin/bash"]
#ENTRYPOINT ["./blockscripts/connect-to-mainnet"]
EXPOSE 8101
