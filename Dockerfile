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
            ccid \
            gocryptfs

ENV FOXDENAUR_KEY_ID=723AB072D36DF76677DA5ACF41ADC5FF876838A8

COPY docker/pacman.conf /etc/pacman.conf

ENV PUID=1000
ENV PGID=1000

RUN useradd aur && \
    echo "aur ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    mkdir -p /home/aur /aur /aur/tmp /home/aur/.gnupg && \
    chown aur:aur /home/aur /aur /aur/tmp /home/aur/.gnupg && \
    chmod 700 /home/aur/.gnupg /home/aur /aur/tmp

COPY --chown=aur:aur docker/scdaemon.conf /home/aur/.gnupg/scdaemon.conf

COPY docker/ /aur
ENV HOME=/home/aur
WORKDIR /aur/keys/pgp
RUN find -type f -exec gpg --import {} \;
WORKDIR /aur

RUN pacman-key --init && \
    gpg --export --armor "${FOXDENAUR_KEY_ID}" | pacman-key --add - && \
    pacman-key --lsign-key "${FOXDENAUR_KEY_ID}"
RUN /aur/init.sh

VOLUME /aur/cache
VOLUME /aur/repo

ENTRYPOINT [ "/aur/entrypoint.sh" ]
