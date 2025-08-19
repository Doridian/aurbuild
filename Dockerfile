FROM archlinux:base-devel

ENV PUID=1000
ENV PGID=1000
ENV UNSHARE_MOUNT_BUILDER=

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

ENV FOXDENAUR_KEY_ID=45B097915F67C9D68C19E5747B0F7660EAEC8D49
ENV CACHYOS_KEY_ID=F3B607488DB35A47

RUN pacman-key --init && \
    gpg --export --armor "${FOXDENAUR_KEY_ID}" | pacman-key --add - && \
    pacman-key --lsign-key "${FOXDENAUR_KEY_ID}" && \
    gpg --export --armor "${CACHYOS_KEY_ID}" | pacman-key --add - && \
    pacman-key --lsign-key "${CACHYOS_KEY_ID}"

RUN pacman -Syu --noconfirm --needed \
            gpgme && \
    pacman --noconfirm -U \
            'https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-keyring-20240331-1-any.pkg.tar.zst' \
            'https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-mirrorlist-22-1-any.pkg.tar.zst' \
            'https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-v3-mirrorlist-22-1-any.pkg.tar.zst' \
            'https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-v4-mirrorlist-22-1-any.pkg.tar.zst' \
            'https://mirror.cachyos.org/repo/x86_64/cachyos/pacman-7.0.0.r7.g1f38429-1-x86_64.pkg.tar.zst'

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
            pcsclite \
            ccid \
            gocryptfs

RUN cat /aur/pacman.conf.late >> /etc/pacman.conf && \
        rm -f /etc/pacman.conf.late && \
        /aur/init.sh

VOLUME /aur/cache
VOLUME /aur/repo

ENTRYPOINT [ "/aur/entrypoint.sh" ]
