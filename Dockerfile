FROM archlinux:base-devel

RUN pacman -Syu --noconfirm --needed \
            cmake \
            make \
            gcc \
            pkgconfig \
            git \
            wget \
            sudo \
            rsync \
            coreutils \
            pcsclite \
            ccid

COPY docker/pacman.conf /etc/pacman.conf

ENV PUID=1000
ENV PGID=1000

RUN useradd aur && \
    echo "aur ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    mkdir -p /home/aur /aur /home/aur/.gnupg && \
    chown aur:aur /home/aur /aur /home/aur/.gnupg && \
    chmod 700 /home/aur/.gnupg /home/aur

COPY --chown=aur:aur docker/scdaemon.conf /home/aur/.gnupg/scdaemon.conf

COPY docker/ /aur
ENV HOME=/home/aur
WORKDIR /aur/keys/pgp
RUN find -type f -exec gpg --import {} \;
WORKDIR /aur

RUN /aur/init.sh

VOLUME /aur/cache
VOLUME /aur/repo

ENTRYPOINT [ "/aur/entrypoint.sh" ]
