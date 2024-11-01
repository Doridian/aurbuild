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
            # Below here should be in PKGBUILD but isnt \
            libxkbcommon \
            libcanberra \
            gst-plugins-bad

ENV PUID=1000
ENV PGID=1000

RUN echo '[foxdenaur]' >> /etc/pacman.conf && \
    echo 'Server = file:///home/aur/docker/repo' >> /etc/pacman.conf

RUN useradd aur && \
    echo "aur ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    mkdir -p /home/aur

COPY . /home/aur/docker
WORKDIR /home/aur/docker
ENV HOME=/home/aur

VOLUME /home/aur/docker/cache
VOLUME /home/aur/docker/repo

ENV MAKEPKG_FLAGS=""

USER root
ENTRYPOINT [ "./entrypoint.sh" ]
