FROM bestwu/wine:i386
LABEL maintainer='BoringCat <boringcat@outlook.com>'

ARG WXWORK_VERSION=3.1.2.2211

RUN set -xe && \
    apt-get update && \
    apt-get install -y apt-transport-https apt-utils

RUN set -xe && \
#  echo 'deb http://mirrors.aliyun.com/deepin/ apricot main contrib non-free'> /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends deepin.com.weixin.work wget && \
    apt-get -y autoremove && apt-get clean -y && apt-get autoclean -y && \
    find /var/lib/apt/lists -type f -delete && \
    find /var/cache -type f -delete && \
    find /var/log -type f -delete && \
    find /usr/share/doc -type f -delete && \
    find /usr/share/man -type f -delete

COPY files.7z /tmp/files.7z

RUN set -xe && \
    wget https://dldir1.qq.com/wework/work_weixin/WeCom_${WXWORK_VERSION}.exe -O /tmp/WXWork.exe && \
    mkdir -p /tmp/drive_c/Program\ Files/WXWork && \
    7z x -o/tmp/drive_c/Program\ Files/WXWork /tmp/WXWork.exe && \
    rm -r /tmp/drive_c/Program\ Files/WXWork/\$PLUGINSDIR/ && \
    cd /tmp/ && \
    7z a files.7z drive_c/ && \
    mv /tmp/files.7z /opt/deepinwine/apps/Deepin-WXWork/files.7z

ENV APP=WXWork \
    AUDIO_GID=995 \
    VIDEO_GID=986 \
    GID=1000 \
    UID=1000 \
    DPI=96 \
    DEBUG=0 \
    WAIT_FOR_SLEEP=5

RUN set -xe && \
    groupadd -o -g $GID wechat && \
    groupmod -o -g $AUDIO_GID audio && \
    groupmod -o -g $VIDEO_GID video && \
    useradd -d "/home/wechat" -m -o -u $UID -g wechat -G audio,video wechat && \
    mkdir /WXWork && \
    chown -R wechat:wechat /WXWork && \
    su wechat -c 'ln -s "/WXWork" "/home/wechat/WXWork"' && \
    INSERTLINE=$(awk '{if(match($0,/ExtractApp\(\)/)){f=1}else if(match($0,/^}\s?$/)&&f){f=0;print NR-2}}' /opt/deepinwine/tools/run_v2.sh) && \
    sed -i "${INSERTLINE}a\\\\tREGDPI=\$(printf '\"LogPixels\"=dword:%08x' \$DPI)\\n\\tsed -i \"s/\\\\\"LogPixels\\\\\"=.*$/\$REGDPI/g\" \$1/system.reg" /opt/deepinwine/tools/run_v2.sh && \
    sed -i 's/RunApp "\\$3" .*/S3=$3\\n\\t\\tshitf 4\\n\\t\\tRunAPP "$S3" "$@"/g' /opt/deepinwine/tools/run_v2.sh

VOLUME ["/WXWork", "/HostHome"]

ADD entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
