emerge --sync
emerge -uvDN world
emerge --depclean
mv /usr/portage/packages/s/ .
rm -Rf /usr/portage/packages/*
quickpkg --include-unmodified-config=y "*/*" | ansi2html | tail -n +1081 | head -n -7 > s/quickpkg.txt
EIX_LIMIT=0 eix --installed -F | grep -v "Available versions" | ansi2html > s/packages.html
emerge --buildpkgonly vnstat sudo openssh dnscrypt-proxy
mv s/ /usr/portage/packages/
chmod -R 755 /usr/portage/packages/
cd /usr/portage/packages/s/
php website.php
rsync -avz --delete /usr/portage/packages/ freebsd@cloveros.ga:/usr/local/www/nginx-dist/
