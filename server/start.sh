#!/bin/bash

die() {
    echo "$0 script failed, hanging forever..."
    while [ 1 ]; do sleep 10;done
    # exit 1
}

id
if [ "$(id -u)" != "1000" ];then
    echo "script must run as steam"
    die
fi

steamcmd=${STEAM_HOME}/steamcmd/steamcmd.sh

ACTUAL_PORT=8211
if [ "${PORT}" != "" ];then
    ACTUAL_PORT=${PORT}
fi
ARGS="${ARGS} -port=${ACTUAL_PORT} -publicport=${ACTUAL_PORT}"

if [ "${PLAYERS}" != "" ];then
    ARGS="${ARGS} -players=${PLAYERS}"
fi
if [ "${SERVER_NAME}" != "" ];then
    ARGS="${ARGS} -servername=${SERVER_NAME}"
fi
if [ "${SERVER_PASSWORD}" != "" ];then
    ARGS="${ARGS} -serverpassword=${SERVER_PASSWORD}"
fi
if [ "${SERVER_PASSWORD}" != "" ];then
    ARGS="${ARGS} -serverpassword=${SERVER_PASSWORD}"
fi
if [ "${NO_MULTITHREADING}" ]; then
    ARGS=${ARGS}
else
    ARGS="${ARGS} -useperfthreads -NoAsyncLoadingThread -UseMultithreadForDS"
fi 

# advertise server
ARGS="${ARGS} EpicApp=PalServer"

PalServerDir=/app/PalServer

mkdir -p ${PalServerDir}
DirPerm=$(stat -c "%u:%g:%a" ${PalServerDir})
if [ "${DirPerm}" != "1000:1000:755" ];then
    echo "${PalServerDir} has unexpected permission ${DirPerm} != 1000:1000:755"
    die
fi

set -x
$steamcmd +@sSteamCmdForcePlatformType windows +force_install_dir ${PalServerDir} +login anonymous +app_update ${APPID} validate +quit || die
set +x

PalServerExe="${PalServerDir}/Pal/Binaries/Win64/PalServer-Win64-Test.exe"
if [ ! -f ${PalServerExe} ];then
    echo "${PalServerExe} does not exist"
    die
fi

mkdir /app/palworld/tmp
wget -P /app/palworld/tmp https://github.com/UE4SS-RE/RE-UE4SS/releases/download/experimental/zDEV-UE4SS_v2.5.2-590-g013ff54.zip \
    && unzip -q /app/palworld/tmp/zDEV-UE4SS_v2.5.2-590-g013ff54.zip -d /app/palworld/tmp/ \
    && mv /app/palworld/tmp/Mods ${PalServerDir}/Pal/Binaries/Win64 \
    && mv /app/palworld/tmp/dwmapi.dll ${PalServerDir}/Pal/Binaries/Win64 \
    && mv /app/palworld/tmp/UE4SS.dll ${PalServerDir}/Pal/Binaries/Win64 \
    && mv /app/palworld/tmp/UE4SS-settings.ini ${PalServerDir}/Pal/Binaries/Win64 \
    && mv /home/steam/UE4SS_Signatures ${PalServerDir}/Pal/Binaries/Win64

# Turn off GuiConsole
sed -i 's/GuiConsoleEnabled = 1/GuiConsoleEnabled = 0/' ${PalServerDir}/Pal/Binaries/Win64/UE4SS-settings.ini
sed -i 's/GuiConsoleVisible = 1/GuiConsoleVisible = 0/' ${PalServerDir}/Pal/Binaries/Win64/UE4SS-settings.ini
mv /home/steam/DedicatedServerBuildOverlap ${PalServerDir}/Pal/Binaries/Win64/Mods




crontab /app/crontab || die

CMD="$PROTON run $PalServerExe ${ARGS}"
echo "starting server with: ${CMD}"
${CMD} || die
