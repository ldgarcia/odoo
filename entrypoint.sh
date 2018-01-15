#!/bin/bash
set -e

case "$1" in
    -- | odoo)
        shift
        if [[ "$1" == "scaffold" ]] ; then
            exec odoo "$@"
        else
            dockerize -template /etc/odoo/odoo.conf.tmpl:/etc/odoo/odoo.conf odoo "$@"
        fi
        ;;
    -*)
        dockerize -template /etc/odoo/odoo.conf.tmpl:/etc/odoo/odoo.conf odoo "$@"
        ;;
    *)
        exec "$@"
esac

exit 1
