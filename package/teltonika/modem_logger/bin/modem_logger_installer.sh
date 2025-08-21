#!/bin/sh

########### DEFINES FOR LOGGER FILES ###########
QLOG_LOGGER="qlog"
QC_LOGGER="qc_trace_collector"
################################################

checkIfLoggerExists() {
        local LOGGER_PATH=$1
        [ -f $LOGGER_PATH ] && {
                echo "Logger file exists"
                return 0
        }
        echo "Logger does not exist, Downloading..."
        opkg update

        # Check if LOGGER_PATH contains QLOG_LOGGER or QC_LOGGER in path using regex
        # This is done by checking the logger in path because we have the function
        # To force a particular logger, so it might be different than the default one
        [[ $LOGGER_PATH =~ $QLOG_LOGGER ]] && {
                opkg install qlog
                return 0
        } || [[ $LOGGER_PATH =~ $QC_LOGGER ]] && {
                opkg install qc_trace_collector
                return 0
        } || {
                echo "Specified Logger not found $LOGGER_PATH"
        }

        return 1
}
