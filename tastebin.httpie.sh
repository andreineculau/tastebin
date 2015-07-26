# export TASTEBIN_URL=

tastebin_list() {
    local URL=${TASTEBIN_URL}/tastes/
    http --check-status --pretty=all GET ${URL} | sed "s|\([^ ]\+\) \([^ ]\+\) |\1 \2 ${URL}|"
}

tastebin_get() {
    local URL=${TASTEBIN_URL}/tastes/${1}
    http --check-status --pretty=all GET ${URL}
}

tastebin_save() {
    local URL=${TASTEBIN_URL}/tastes/
    http --check-status -p hb --pretty=all POST ${URL} | sed "s|Location\(.*\):\(.*\) |Location\1:\2 ${URL}|"
}

tastebin_save_as() {
    local URL=${TASTEBIN_URL}/tastes/${1}
    http --check-status -p hb PUT ${URL} && echo "Location: ${URL}"
}
