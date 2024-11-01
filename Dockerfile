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
            coreutils

ENV PUID=1000
ENV PGID=1000

RUN useradd aur && \
    echo "aur ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    mkdir -p /home/aur /aur

COPY docker/ /aur
WORKDIR /aur
ENV HOME=/home/aur

VOLUME /aur/cache
VOLUME /aur/repo

ENV MAKEPKG_FLAGS=""

ENTRYPOINT [ "./entrypoint.sh" ]
