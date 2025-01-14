pkgname=seto
pkgver=0.1.0
pkgrel=1
pkgdesc="Hardware accelerated keyboard driven screen selection tool"
arch=('x86_64')
url="https://github.com/unixpariah/seto"
license=('GPL3')
depends=(
	'freetype2'
	'fontconfig'
	'libgl'
	'wayland'
	'libxkbcommon'
)
makedepends=(
	'zig'
	'pkg-config'
	'scdoc'
	'wayland-protocols'
)
source=("$pkgname::git+https://github.com/unixpariah/seto.git")
sha256sums=('SKIP')

prepare() {
	mkdir -p zig-global-cache/p/
}

build() {
	export ZIG_GLOBAL_CACHE_DIR="${srcdir}/zig-global-cache"
	cd "$srcdir/$pkgname"
	zig build \
		--cache-dir "$(pwd)/.zig-cache" \
		--global-cache-dir "$(pwd)/.cache" \
		-Dcpu=baseline \
		-Doptimize=ReleaseSafe
}

package() {
	cd "$srcdir/$pkgname"

	# Install binary
	install -Dm755 zig-out/bin/$pkgname -t "$pkgdir/usr/bin"

	# Install man pages
	for f in doc/*.scd; do
		page="doc/$(basename "$f" .scd)"
		scdoc <"$f" >"$page"
		install -Dm644 "$page" "$pkgdir/usr/share/man/man1/$(basename "$page").1"
	done

	# Install shell completions
	install -Dm644 "completions/$pkgname.bash" "$pkgdir/usr/share/bash-completion/completions/$pkgname"
	install -Dm644 "completions/$pkgname.fish" "$pkgdir/usr/share/fish/vendor_completions.d/$pkgname.fish"
	install -Dm644 "completions/_$pkgname" "$pkgdir/usr/share/zsh/site-functions/_$pkgname"
}
