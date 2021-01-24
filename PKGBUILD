# Maintainer: Piyush Pangtey <me at pangtey dot co dot in>

pkgname=bash-project-mod
pkgver=0.1
pkgrel=1
pkgdesc="Bash Project mod"
arch=('any')
url="https://github.com/pangteypiyush/bash-project-mod"
license=('GPL')
depends=( 'rofi' 'bash-completion' )
_mod=project-mod
_completion=project-completion
source=(
    "$_mod"
    "$_completion"
    'LICENSE'
)
sha256sums=(
    'SKIP'
    'SKIP'
    'SKIP'
)

pkgver() {
    git describe --tags --always | sed -e 's;-;.;g'
}

package() {
    install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
    install -Dm644 "$srcdir/$_mod" "$pkgdir/usr/share/${pkgname}/$_mod"
    install -Dm644 "$srcdir/$_completion" "$pkgdir/usr/share/bash-completion/completions/lsp"
    for f in cdp chproject; do
        ln -s lsp "$pkgdir/usr/share/bash-completion/completions/$f"
    done
}
