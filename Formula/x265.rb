class X265 < Formula
  desc "H.265/HEVC encoder"
  homepage "http://x265.org"
  url "https://bitbucket.org/multicoreware/x265/downloads/x265_2.5.tar.gz"
  sha256 "2e53259b504a7edb9b21b9800163b1ff4c90e60c74e23e7001d423c69c5d3d17"
  revision 1
  head "https://bitbucket.org/multicoreware/x265", :using => :hg

  bottle do
    cellar :any
    sha256 "e09e6c6d0e51d956e6b1ab5396db3a8fa8201cd1efdb35d11391d29c294fe263" => :high_sierra
    sha256 "541de69ba422c79fd0782833b5edb941d42b97dd6ae1d1a767688270dad4bfb5" => :sierra
    sha256 "2ef0de7bef2e973a695f6839472b5be6ba4ff87c098e6199b2b2589bfc68618d" => :el_capitan
    sha256 "c0e823407c654081c6aebf7a2abbc177aa012c897e158ce3487f47ffd7991f09" => :x86_64_linux
  end

  depends_on "cmake" => :build
  depends_on "yasm" => :build
  depends_on :macos => :lion

  def install
    # Build based off the script at ./build/linux/multilib.sh
    args = std_cmake_args + %w[
      -DLINKED_10BIT=ON
      -DLINKED_12BIT=ON
      -DEXTRA_LINK_FLAGS=-L.
      -DEXTRA_LIB=x265_main10.a;x265_main12.a
    ]
    high_bit_depth_args = std_cmake_args + %w[
      -DHIGH_BIT_DEPTH=ON -DEXPORT_C_API=OFF
      -DENABLE_SHARED=OFF -DENABLE_CLI=OFF
    ]
    (buildpath/"8bit").mkpath

    mkdir "10bit" do
      system "cmake", buildpath/"source", *high_bit_depth_args
      system "make"
      mv "libx265.a", buildpath/"8bit/libx265_main10.a"
    end

    mkdir "12bit" do
      system "cmake", buildpath/"source", "-DMAIN12=ON", *high_bit_depth_args
      system "make"
      mv "libx265.a", buildpath/"8bit/libx265_main12.a"
    end

    cd "8bit" do
      system "cmake", buildpath/"source", *args
      system "make"
      mv "libx265.a", "libx265_main.a"
      if OS.mac?
        system "libtool", "-static", "-o", "libx265.a", "libx265_main.a",
                          "libx265_main10.a", "libx265_main12.a"
      else
        system "ar", "cr", "libx265.a", "libx265_main.a", "libx265_main10.a",
                           "libx265_main12.a"
        system "ranlib", "libx265.a"
      end
      system "make", "install"
    end
  end

  test do
    yuv_path = testpath/"raw.yuv"
    x265_path = testpath/"x265.265"
    yuv_path.binwrite "\xCO\xFF\xEE" * 3200
    system bin/"x265", "--input-res", "80x80", "--fps", "1", yuv_path, x265_path
    header = "AAAAAUABDAH//w=="
    assert_equal header.unpack("m"), [x265_path.read(10)]
  end
end
