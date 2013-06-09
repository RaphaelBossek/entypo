#/bin/sh
set -e
tmpf=`mktemp -t font-entypo-hb.XXXXXXXX`
tmpf_download=`mktemp -t font-entypo-hb.html.XXXXXXXX`
trap "rm -f $tmpf $tmpf_download" EXIT QUIT

#dir="font-face/Entypo"
dir="font-face/Entypo"
test "$1" && dir="$1"
test -d "$dir" -a ! -d "$dir.backup" && mv "$dir" "$dir.backup"
rm -rf "$dir"
mkdir -p "$dir"

#
#  Download fonts
#
url="http://www.entypo.com/css/master.css"
echo "Download fonts defined in $url..."
curl -o "$tmpf_download" "$url"
sed -n -e '
/@font-face[[:space:]]*{/,/}/!d
# Delete everything before @font-face
s/.*@font-face/@font-face/
# Delete everything after }
s/}.*/}/
p
' "$tmpf_download" >>"$dir/stylesheet.css"
url="http://www.entypo.com/css"
for f in `sed -n -e "s/.*url('\([^&?#']\+\).*/\1/pg" "$dir/stylesheet.css"`; do
	curl -o "$dir/$f" "$url/$f"
done

if false; then
# Change download URL
sed -e "s,url(',url('./font-face/Entypo/,g" "$dir/stylesheet.css" >>"$tmpf"

#
#  Download character definitions
#
url="http://www.entypo.com/characters/"
echo "Download latest definition from $url..."
# Extract character definition from example page and create a CSS from it
curl -o "$tmpf_download" "$url"
echo "Convert defintions into CSS...."
# http://austinmatzko.com/2008/04/26/sed-multi-line-search-and-replace/
# http://www.grymoire.com/Unix/Sed.html#toc-uh-51
sed -n -e '
/<ul class="clear"/,/<\/ul>/!d
# Find next <li title as next definition of a character
/<li title="/ {
	# Remember this line and reuse it in the next operation.
	N;N
	# Save character name from the line before including its value.
	s/.*<li title="\([^+"]*\).*unicode">.*U+\([A-F0-9]*\).*/span.font-entypo.icon-\1:before\t{ content: "\\\2"; }\n.navigation-class li .font-entypo .icon-\1 > a > span:before\t{ content: "\\\2"; }/p
}' "$tmpf_download" >>"$tmpf"
sed -n -e '
/<ul id="entypo-social"/,/<\/ul>/!d
# Find next <li title as next definition of a character
/<li title="/ {
	# Remember this line and reuse it in the next operation.
	N;N
	# Save character name from the line before including its value.
	s/.*<li title="\([^+"]*\).*unicode">.*U+\([A-F0-9]*\).*/span.font-entypo-social.icon-\1:before\t{ content: "\\\2"; }\n.navigation-class li .font-entypo-social .icon-\1 > a > span:before\t{ content: "\\\2"; }/p
}' "$tmpf_download" >>"$tmpf"

out="font-entypo-hb.css"
echo "Backup our modifications between /* START HB */ /* END HB */..."
sed -n -e '/\/\* START HB \*\//,/\/\* END HB \*\//p' "$out" >"$tmpf"
test -s "$out.backup.css" || cp "$tmpf" "$out.backup.css"

echo "Apply new $out..."
mv -f "$tmpf" "$out"
fi

