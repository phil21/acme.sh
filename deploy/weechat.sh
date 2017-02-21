#!/usr/bin/env bash

# Simple script to deploy certificates for Weechat relay servers
# 
# Configuration:
# export WEECHAT_PEM (or set in access.conf) to the PEM file you have your weechat client
# set to load.
# Optionally configure WEECHAT_HOME if you would like to attempt to reload the certificate
# on a successful deploy.  
# This deploy script attempts to guess sane defaults in the absence of either

# If you would like this script to automatically reload this certificate, you must ensure
# weechat is configured with plugins.var.fifo.fifo = on

# Usage Example: acme.sh --renew --deploy --deploy-hook weechat -d weechat.example.com --force

#returns 0 means success, otherwise error.

########  Public functions #####################

#domain keyfile certfile cafile fullchain
weechat_deploy() {
  _cdomain="$1"
  _ckey="$2"
  _ccert="$3"
  _cca="$4"
  _cfullchain="$5"

  _debug _cdomain "$_cdomain"
  _debug _ckey "$_ckey"
  _debug _ccert "$_ccert"
  _debug _cca "$_cca"
  _debug _cfullchain "$_cfullchain"

  _info "Deploying $_cdomain to weechat"
  if [ -z "$WEECHAT_HOME" ]; then
    _info "WEECHAT_HOME not set, defaulting to ${HOME}/.weechat"
    WEECHAT_HOME="${HOME}/.weechat"
  fi
  if [ -z "$WEECHAT_PEM" ]; then
    _info "WEECHAT_PEM not set, defaulting to ${HOME}/.weechat/ssl/relay.pem"
    WEECHAT_PEM="${HOME}/.weechat/ssl/relay.pem"
  fi
  if [ -w "$WEECHAT_PEM" ]; then
    _info "$WEECHAT_PEM exists and is writable, backing up and overwriting"
    cp "$WEECHAT_PEM" "$WEECHAT_PEM.bak"
    cat "$_ckey" "$_cfullchain" >"$WEECHAT_PEM"
    _info "Deployed $_cdomain to weechat"
    _debug "Attempting to issue /relay sslcertky to weechat via fifo"
    for fifo in $WEECHAT_HOME/weechat_fifo_*; do
      _info "Issuing reload to weechat via $fifo"
      printf '%b' '*/relay sslcertkey\n' >"$fifo"
    done
    exit 0
  else
    _err "$WEECHAT_PEM does not exist or is not writable.  If this is a first run \
please issue \'touch $WEECHAT_PEM\' and retry."
    exit 1
  fi
}
