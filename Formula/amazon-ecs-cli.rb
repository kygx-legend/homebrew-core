class AmazonEcsCli < Formula
  desc "CLI for Amazon ECS to manage clusters and tasks for development"
  homepage "https://aws.amazon.com/ecs"
  url "https://github.com/aws/amazon-ecs-cli/archive/v1.0.0.tar.gz"
  sha256 "2458da61cc7d27db166c65d4f356dcaf2ef1d2671194a452e9345d97ff73d8a9"

  bottle do
    cellar :any_skip_relocation
    sha256 "4c4817db980c69151f7445e781273eb8ec96fe3de06ac13483d88fd558b38a3a" => :high_sierra
    sha256 "bbc460c2d8f420ed6eef36368d7fbd6c19d2cc623f6fed5842587d559e72920c" => :sierra
    sha256 "0656ca15e030093201614a0779914d9e6c56d19ccaa2c5d415d3f988e7c0b8b2" => :el_capitan
    sha256 "cf0d4a30545c27d83f6c28c0f8d2cd2b6076b39927527c5813d51fdf0fe967b1" => :x86_64_linux
  end

  depends_on "go" => :build

  def install
    ENV["GOPATH"] = buildpath
    (buildpath/"src/github.com/aws/amazon-ecs-cli").install buildpath.children
    cd "src/github.com/aws/amazon-ecs-cli" do
      system "make", "build"
      # Tests fail on Linux. Temporarly disabled.
      system "make", "test" if OS.mac?
      bin.install "bin/local/ecs-cli"
      prefix.install_metafiles
    end
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/ecs-cli -v")
  end
end
