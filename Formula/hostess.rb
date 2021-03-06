class Hostess < Formula
  desc "Idempotent command-line utility for managing your /etc/hosts file"
  homepage "https://github.com/cbednarski/hostess"
  url "https://github.com/cbednarski/hostess/archive/v0.3.0.tar.gz"
  sha256 "9b1f72f8657dd15482a429b33fc7bdb28c7a06137330b59f0eaef956c857ed59"
  head "https://github.com/cbednarski/hostess.git"

  bottle do
    cellar :any_skip_relocation
    sha256 "d0b8140a1f3d8c97868c218626fbc935ed592abaa6be72dcca368e36b62869db" => :catalina
    sha256 "d9d5adeeb0551a9bb230b09b8463aa098abf42e2e5df4392ed7ae8236c6b4ce2" => :mojave
    sha256 "955705aca89353471ac63e07a9254ca4252546c8071eda85a8b95ac6aa0b6331" => :high_sierra
    sha256 "6a5ca47a7d0047d1595c79008ffc5d9a43ce8ef11cea5b6fc7deeaa239102216" => :sierra
    sha256 "e77cffa19bdf7feb4973d59c4aa0f1551dc74b8caaf35c8a6330e71e223e2bdf" => :el_capitan
    sha256 "2ecb13f8e1c6a8e51f7e0d4fdeacfb98397adc10440384432871f7c291397b62" => :x86_64_linux
  end

  depends_on "go" => :build

  def install
    ENV["GOPATH"] = buildpath
    dir = buildpath/"src/github.com/cbednarski/hostess"
    dir.install buildpath.children

    cd dir/"cmd/hostess" do
      system "go", "install"
    end
    bin.install "bin/hostess"
  end

  test do
    system bin/"hostess", "--help"
  end
end
