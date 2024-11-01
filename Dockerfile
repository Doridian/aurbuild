FROM archlinux:base-devel

RUN pacman -Syu --noconfirm --needed git wget sudo rsync

RUN useradd aur && \
    echo "aur ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    mkdir -p /home/aur && \
    chown -R aur:aur /home/aur

USER aur

COPY . /home/aur/docker

WORKDIR /home/aur/docker
ENTRYPOINT [ "./entrypoint.sh" ]
