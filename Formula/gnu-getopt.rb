class GnuGetopt < Formula
  desc "Command-line option parsing utility"
  homepage "https://github.com/karelzak/util-linux"
  url "https://www.kernel.org/pub/linux/utils/util-linux/v2.34/util-linux-2.34.tar.xz"
  sha256 "743f9d0c7252b6db246b659c1e1ce0bd45d8d4508b4dfa427bbb4a3e9b9f62b5"

  bottle do
    cellar :any_skip_relocation
    sha256 "8e17c46ff090d4c062e18f776db6e1b3ec2123858902ac9eedf6482a3db83905" => :catalina
    sha256 "e08dc391e166d3e05ff00bd9e9fa75e34f5f9cae04a76b6d6f249374b70ab074" => :mojave
    sha256 "278a797fe2cdf1fe9c4862bc2b6a74745aa445a441d526b3c3bb50eae03a2de8" => :high_sierra
    sha256 "d1f9ded99bb4ff42fd593bf0d2b38db7fa2938859f724aa16b405181cfbb9bad" => :sierra
    sha256 "e9f377f3a387a60f64920b59ef29987350de43740cb0202b6fcba9297db9d19f" => :x86_64_linux
  end

  keg_only (OS.mac? ? :provided_by_macos : "this formula conflicts with util-linux")

  def install
    system "./configure", "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}"

    system "make", "getopt"

    bin.install "getopt"
    man1.install "misc-utils/getopt.1"
    bash_completion.install "bash-completion/getopt"
  end

  test do
    system "#{bin}/getopt", "-o", "--test"
  end
end
