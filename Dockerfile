FROM archlinux:base-devel

WORKDIR /aur
COPY docker/init.sh /aur/init.sh
COPY docker/repo-add.sh /aur/repo-add.sh
RUN /aur/init.sh
WORKDIR /

COPY docker/pacman.conf /etc/pacman.conf

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
            mkinitcpio

RUN echo '# DISABLED' > /etc/mkinitcpio.d/linux-zen-dori.preset
RUN echo '# DISABLED' > /etc/mkinitcpio.d/linux-zen.preset
RUN echo '# DISABLED' > /etc/mkinitcpio.d/linux-lts.preset
RUN echo '# DISABLED' > /etc/mkinitcpio.d/linux.preset

ENV PUID=1000
ENV PGID=1000

RUN useradd aur && \
    echo "aur ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    mkdir -p /home/aur /aur /home/aur/.gnupg && \
    chown aur:aur /home/aur /aur /home/aur/.gnupg && \
    chmod 700 /home/aur/.gnupg /home/aur

COPY docker/ /aur
ENV HOME=/home/aur
WORKDIR /aur/keys/pgp
RUN find -type f -exec gpg --import {} \;
WORKDIR /aur

VOLUME /aur/cache
VOLUME /aur/repo

ENTRYPOINT [ "./entrypoint.sh" ]
