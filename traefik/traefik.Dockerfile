FROM traefik:latest as treafik 
CMD ["--configFile=/etc/treafik/treafik.yml"]
# LABEL [ \
# traefik.enable: true\
# traefik.http.routers.dokap_treafik.entrypoints: websecure\
# traefik.http.routers.dokap_treafik.service: api@internal\
# traefik.http.routers.dokap_treafik.tls: true\
# traefik.http.routers.dokap_treafik.tls.certresolver: le\
# traefik.http.routers.api.rule: Host(`localhost`)\
# traefik.http.routers.api.middlewares=auth\
# traefik.http.middlewares.auth.basicauth.users:"test:$$apr1$$H6uskkkW$$IgXLP6ewTrSuBkTrqE8wj/"\
# traefik.http.middlewares.hstsx.headers.stspreload: true\
# traefik.http.middlewares.hstsx.headers.stsseconds: 31536000\
# traefik.http.middlewares.hstsx.headers.forcestsheader: true\
# traefik.http.middlewares.hstsx.headers.customframeoptionsvalue: sameorigin\
# traefik.http.middlewares.hstsx.headers.browserxssfilter: true\
# traefik.http.middlewares.hstsx.headers.sslredirect: true\
# traefik.http.middlewares.hstsx.headers.contenttypenosniff: true\
# ]