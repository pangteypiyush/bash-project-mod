# Maintainer: Piyush Pangtey <me at pangtey dot co dot in>

pkgname=bash-project-mod
pkgver=3.0.0
pkgrel=1
pkgdesc="Lightweight bash/zsh project manager - switch projects and navigate quickly"
arch=('any')
url="https://github.com/pangteypiyush/bash-project-mod"
license=('GPL3')
depends=('bash>=4.0' 'fzf' 'bat')
install=bash-project-mod.install
_pm=pm.sh
_completion=pm-completion.bash
_zsh_completion=pm-completion.zsh
_test=test.sh
source=(
    "$_pm"
    "$_completion"
    "$_zsh_completion"
    "$_test"
    'LICENSE'
)
sha256sums=(
    'SKIP'
    'SKIP'
    'SKIP'
    'SKIP'
    'SKIP'
)

check() {
    bash "$_test"
}

package() {
    install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
    install -Dm755 "$srcdir/$_pm" "$pkgdir/usr/share/pm/$_pm"
    install -Dm644 "$srcdir/$_completion" "$pkgdir/usr/share/bash-completion/completions/pm"
    install -Dm644 "$srcdir/$_zsh_completion" "$pkgdir/usr/share/zsh/site-functions/_pm"
}

