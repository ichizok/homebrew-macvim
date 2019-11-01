class Macvim < Formula
  desc "GUI for Vim, made for macOS"
  homepage "https://github.com/macvim-dev/macvim"
  head "https://github.com/macvim-dev/macvim.git"

  option "with-properly-linked-python2-python3", "Link with properly linked Python 2 and Python 3. You will get deadly signal SEGV if you don't have them."

  depends_on "gettext" => :build
  depends_on "lua" => :build
  depends_on "python" => :build

  def install
    perl_version = Utils.popen_read("/usr/bin/perl", "-e", "print $^V")[/^v(\d+\.\d+)/, 1]
    python_version = Language::Python.major_minor_version "python3"
    ENV.append "VERSIONER_PERL_VERSION", perl_version
    ENV.append "VERSIONER_PYTHON_VERSION", "2.7"
    ENV.append "vi_cv_path_python3", Formula["python"].opt_bin/"python3"
    ENV.append "vi_cv_path_plain_lua", Formula["lua"].opt_bin/"lua"
    ENV.append "vi_cv_dll_name_perl", "/System/Library/Perl/#{perl_version}/darwin-thread-multi-2level/CORE/libperl.dylib"
    ENV.append "vi_cv_dll_name_python3", Formula["python"].opt_frameworks/"Python.framework/Versions/#{python_version}/Python"

    opts = []
    if build.with? "properly-linked-python2-python3"
      opts << "--with-properly-linked-python2-python3"
    end

    system "./configure", "--prefix=#{prefix}",
                          "--with-features=huge",
                          "--enable-multibyte",
                          "--enable-terminal",
                          "--enable-netbeans",
                          "--with-tlib=ncurses",
                          "--enable-cscope",
                          "--enable-termtruecolor",
                          "--enable-perlinterp=dynamic",
                          "--enable-pythoninterp=dynamic",
                          "--enable-python3interp=dynamic",
                          "--enable-rubyinterp=dynamic",
                          "--enable-luainterp=dynamic",
                          "--with-lua-prefix=#{Formula["lua"].opt_prefix}",
                          *opts

    system "make"

    app_path = "src/MacVim/build/Release/MacVim.app"

    gettext_bindir = Formula["gettext"].opt_bin
    system "make", "-C", "src/po", "install",
                   "PATH=#{gettext_bindir}:#{ENV["PATH"]}",
                   "MSGFMT=#{gettext_bindir}/msgfmt",
                   "INSTALL_DATA=install",
                   "FILEMOD=644",
                   "LOCALEDIR=../../#{app_path}/Contents/Resources/vim/runtime/lang"

    prefix.install app_path

    mkdir_p bin

    %w[
      vim vimdiff view
      gvim gvimdiff gview
      mvim mvimdiff mview
    ].each do |t|
      ln_s "../MacVim.app/Contents/bin/mvim", bin + t
    end
  end

  test do
    (testpath/"a").write "hai"
    (testpath/"b").write "bai"
    system bin/"vimdiff", "a", "b",
           "-c", "FormatCommand diffformat",
           "-c", "w! diff.html", "-c", "qa!"
    File.exist? "diff.html"
  end
end
