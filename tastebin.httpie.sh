# export TASTEBIN_URL=

tastebin_save() {
    local URL=${TASTEBIN_URL}/tastes/
    http --check-status -p hb --pretty=all POST ${URL} | sed "s|Location\(.*\):\(.*\) |Location\1:\2 ${URL}|"
}

tastebin_save_as() {
    local URL=${TASTEBIN_URL}/tastes/${1}
    http --check-status -p hb PUT ${URL} && echo "Location: ${URL}"
}
