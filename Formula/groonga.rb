class Groonga < Formula
  desc "Fulltext search engine and column store"
  homepage "http://groonga.org/"
  url "http://packages.groonga.org/source/groonga/groonga-6.1.5.tar.gz"
  sha256 "bd404dca8860b4bb7af72d77020c95b32926f8976fecfe3ae2b9f8792e26105e"

  bottle do
    sha256 "3d0724639c516f89b1351e7ff8024728bbe03a15f858800be88f937dd9527bff" => :sierra
    sha256 "5a936914a4d9a0bd44737a4541f7f6baa930f21acf79ef6cbfb961304c136e79" => :el_capitan
    sha256 "105ba3a4c9b465e13cbf25744c707d66dd7e6bd90f36879d6553aef6f279158a" => :yosemite
  end

  head do
    url "https://github.com/groonga/groonga.git"
    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  option "with-glib", "With benchmark program for developer use"
  option "with-zeromq", "With suggest plugin for suggesting"

  deprecated_option "enable-benchmark" => "with-glib"
  deprecated_option "with-benchmark" => "with-glib"
  deprecated_option "with-suggest-plugin" => "with-zeromq"

  depends_on "pkg-config" => :build
  depends_on "pcre"
  depends_on "msgpack"
  depends_on "openssl"
  depends_on "glib" => :optional
  depends_on "lz4" => :optional
  depends_on "mecab" => :optional
  depends_on "mecab-ipadic" if build.with? "mecab"
  depends_on "zeromq" => :optional
  depends_on "libevent" if build.with? "zeromq"
  depends_on "zstd" => :optional

  resource "groonga-normalizer-mysql" do
    url "http://packages.groonga.org/source/groonga-normalizer-mysql/groonga-normalizer-mysql-1.1.1.tar.gz"
    sha256 "bc83d1e5e0f32d4b95e219cb940a7e3f61f0f743abd3bd47c2d436a34e503870"
  end

  link_overwrite "lib/groonga/plugins/normalizers/"
  link_overwrite "share/doc/groonga-normalizer-mysql/"
  link_overwrite "lib/pkgconfig/groonga-normalizer-mysql.pc"

  def install
    args = %W[
      --prefix=#{prefix}
      --with-zlib
      --with-ssl
      --enable-mruby
      --without-libstemmer
    ]

    if build.with? "zeromq"
      args << "--enable-zeromq"
    else
      args << "--disable-zeromq"
    end

    args << "--enable-benchmark" if build.with? "glib"
    args << "--with-mecab" if build.with? "mecab"
    args << "--with-lz4" if build.with? "lz4"
    args << "--with-zstd" if build.with? "zstd"

    if build.head?
      args << "--with-ruby"
      system "./autogen.sh"
    end

    system "./configure", *args
    system "make", "install"

    resource("groonga-normalizer-mysql").stage do
      ENV.prepend_path "PATH", bin
      ENV.prepend_path "PKG_CONFIG_PATH", lib/"pkgconfig"
      system "./configure", "--prefix=#{prefix}"
      system "make"
      system "make", "install"
    end
  end

  test do
    IO.popen("#{bin}/groonga -n #{testpath}/test.db", "r+") do |io|
      io.puts("table_create --name TestTable --flags TABLE_HASH_KEY --key_type ShortText")
      sleep 2
      io.puts("shutdown")
      # expected returned result is like this:
      # [[0,1447502555.38667,0.000824928283691406],true]\n
      assert_match(/\[\[0,\d+.\d+,\d+.\d+\],true\]/, io.read)
    end

    IO.popen("#{bin}/groonga -n #{testpath}/test-normalizer-mysql.db", "r+") do |io|
      io.puts "register normalizers/mysql"
      sleep 2
      io.puts("shutdown")
      # expected returned result is like this:
      # [[0,1447502555.38667,0.000824928283691406],true]\n
      assert_match(/\[\[0,\d+.\d+,\d+.\d+\],true\]/, io.read)
    end
  end
end
