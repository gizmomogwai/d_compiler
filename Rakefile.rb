task :default => [:summon_gdc, :summon_ldc2]

def make_parallel
  sh 'make -j4'
end
def make_install
  sh 'make install'
end

GDC_DIR = Dir.pwd
GDC_BUILD_DIR=File.join(GDC_DIR, 'gdc/build')
task :summon_gdc => ["#{GDC_BUILD_DIR}/bin/gdc"]

file "#{GDC_BUILD_DIR}/bin/gdc" => ['gdc/dev/gcc-4.6.1/objdir/gcc/gdc'] do |t|
  cd 'gdc/dev/gcc-4.6.1/objdir' do
    sh 'make install'
  end
end

file "gdc/dev/gcc-4.6.1/objdir/gcc/gdc" => ['gdc/dev/gcc-4.6.1/objdir/Makefile'] do |t|
  cd 'gdc/dev/gcc-4.6.1/objdir' do
    make_parallel
  end
end

directory 'gdc/dev'
directory 'gdc/dev/gcc-4.6.1/objdir'

directory GDC_BUILD_DIR
file 'gdc/dev/gcc-4.6.1/objdir/Makefile' => ['gdc/dev/gcc-4.6.1/configure', 'gdc/dev/gcc-4.6.1/objdir', 'gdc/dev/gcc-4.6.1/gmp/ChangeLog', 'gdc/dev/gcc-4.6.1/mpfr/README', 'gdc/dev/gcc-4.6.1/mpc/INSTALL'] do |t|
  cd 'gdc/dev/gcc-4.6.1/objdir' do
    sh "../configure --enable-language=d --disable-shared --prefix=#{GDC_BUILD_DIR} --with-bugurl=\"https://bitbucket.org/goshawk/gdc/issues\" --enable-checking=release"
  end
end

file 'gdc/dev/gcc-4.6.1/configure' => ['gdc/dev/gcc-4.6.1/gcc/d/setup-gcc.sh'] do
  cd 'gdc/dev/gcc-4.6.1' do
    sh './gcc/d/setup-gcc.sh -v2'
  end
end

file 'gdc/dev/gcc-4.6.1/gcc/d/setup-gcc.sh' => ['gdc/.hgignore', 'gdc/dev/gcc-4.6.1/libstdc++-v3/Makefile.am'] do
  cd 'gdc/dev/gcc-4.6.1' do
    sh "ln -s ../../../d gcc/d"
    sh "touch gcc/d/setup-gcc.sh"
  end
end




directory 'tmp'
desc "tmp/gcc-g++-4.6.1.tar.bz2"
file "tmp/gcc-g++-4.6.1.tar.bz2" => [:tmp] do |t|
  sh "curl http://gcc.cybermirror.org/releases/gcc-4.6.1/gcc-g++-4.6.1.tar.bz2 > #{t.name}"
end
file 'gdc/dev/gcc-4.6.1/libstdc++-v3/Makefile.am' => ['tmp/gcc-g++-4.6.1.tar.bz2', 'gdc/dev/gcc-4.6.1/libgcc/Makefile.in', 'gdc/.hgignore', 'tmp'] do |t|
  p = t.prerequisites[0]
  sh "tar xf #{p} -C gdc/dev"
  sh "touch #{t.name}"
end


desc "tmp/gcc-core-4.6.1.tar.bz2"
file "tmp/gcc-core-4.6.1.tar.bz2" => [:tmp] do |t|
  sh "curl http://gcc.cybermirror.org/releases/gcc-4.6.1/gcc-core-4.6.1.tar.bz2 > #{t.name}"
end
file 'gdc/dev/gcc-4.6.1/libgcc/Makefile.in' => ['tmp/gcc-core-4.6.1.tar.bz2', 'gdc/.hgignore', 'tmp', 'gdc/dev'] do |t|
  p = t.prerequisites[0]
  sh "tar xf #{p} -C gdc/dev"
  sh "touch #{t.name}"
end


def download_and_symlink(url, output_dir, file)
  archive = File.join('tmp', File.basename(url))
  r = Regexp.new('.*/(?<name>.*?)-(?<version>\d\.\d\.?\d?)\.(?<ext>.*)')
  md = r.match(url)
  name = md[:name]
  version = md[:version]
  extension = md[:ext]

  desc "download #{archive}"
  file archive => [:tmp] do |t|
    sh "curl #{url} > #{t.name}"
  end

  name_with_version = "#{name}-#{version}"
  file_of_archive = File.join(name_with_version, file)
  if output_dir
    file_of_archive = File.join(output_dir, file_of_archive)
  end
  file file_of_archive => [archive] do |t|
    if output_dir
      sh "tar xf #{t.prerequisites[0]} -C #{output_dir}"
    else
      sh "tar xf #{t.prerequisites[0]}"
    end
    sh "touch #{t.name}"
  end

  file_in_linked_dir = File.join(name, file)
  if output_dir
    file_in_linked_dir = File.join(output_dir, file_in_linked_dir)
  end
  file file_in_linked_dir => [file_of_archive] do |t|
    cd output_dir do
      sh "ln -s #{name_with_version} #{name}"
    end
  end
end

download_and_symlink('ftp://ftp.gmplib.org/pub/gmp-5.0.2/gmp-5.0.2.tar.bz2', 'gdc/dev/gcc-4.6.1', 'ChangeLog')
download_and_symlink('http://www.mpfr.org/mpfr-current/mpfr-3.0.1.tar.bz2', 'gdc/dev/gcc-4.6.1', 'README')
download_and_symlink('http://www.multiprecision.org/mpc/download/mpc-0.9.tar.gz', 'gdc/dev/gcc-4.6.1', 'INSTALL')

desc 'hg clone of gdc'
file 'tmp/gdc/.hgignore' => [:tmp] do |t|
  cd 'tmp' do
    sh 'hg clone https://bitbucket.org/goshawk/gdc'
  end
end

file 'gdc/.hgignore' => ['tmp/gdc/.hgignore'] do |t|
  sh 'cp -R tmp/gdc .'
end

desc "Summon ldc2"
task :summon_ldc2 => ['ldc/bin/ldc2']

directory 'tmp/llvm-2.9/build'
file 'tmp/llvm-2.9/build/config.status' => ['tmp/llvm-2.9/configure', 'tmp/llvm-2.9/build'] do
  cd 'tmp/llvm-2.9/build' do
    sh "../configure --prefix #{GDC_DIR}/tmp/llvm --enable-optimized --enable-assertions"
  end
end

file 'tmp/llvm-2.9/build/Release+Assert/bin/llvm-config' => ['tmp/llvm-2.9/build/config.status'] do
  cd 'tmp/llvm-2.9/build' do
    make_parallel
  end
end
file 'tmp/llvm/bin/llvm-config' => ['tmp/llvm-2.9/build/Release+Assert/bin/llvm-config'] do
  cd 'tmp/llvm-2.9/build' do
    sh 'make install'
  end
end

desc 'clone ldc repo'
file 'tmp/ldc/.hgignore' => [:tmp] do
  cd 'tmp' do
    sh 'hg clone http://bitbucket.org/lindquist/ldc'
  end
end



file 'tmp/libconfig-1.4.8/Makefile' => ['tmp/libconfig-1.4.8/configure', 'tmp/libconfig-1.4.8'] do
  cd 'tmp/libconfig-1.4.8' do
    sh "./configure --prefix=#{GDC_DIR}/libconfig"
  end
end

file 'tmp/libconfig-1.4.8/lib/.libs/libconfig.so' => ['tmp/libconfig-1.4.8/Makefile'] do
  cd 'tmp/libconfig-1.4.8' do
    make_parallel
  end
end
file 'libconfig/lib/libconfig.so' => ['tmp/libconfig-1.4.8/lib/.libs/libconfig.so'] do
  cd 'tmp/libconfig-1.4.8' do
    sh 'make install'
  end
end

file 'tmp/ldc/Makefile' => ['tmp/ldc/.hgignore', 'tmp/ldc', 'tmp/llvm/bin/llvm-config', 'libconfig/lib/libconfig.so', 'libconfig/include/libconfig.h', 'tmp/ldc/druntime/.git/HEAD', 'tmp/ldc/phobos/.git/HEAD'] do
  cd 'tmp/ldc' do
    sh "cmake -DD_VERSION=2 -DLLVM_CONFIG=#{GDC_DIR}/tmp/llvm/bin/llvm-config -DCMAKE_INSTALL_PREFIX=#{GDC_DIR}/ldc -DLIBCONFIG_LDFLAGS=\"-L#{GDC_DIR}/libconfig/lib -lconfig++\" -DLIBCONFIG_CXXFLAGS=-I#{GDC_DIR}/libconfig/include -DRUNTIME_DIR=./druntime -DPHOBOS2_DIR=./phobos ."
  end
end

file 'tmp/ldc/bin/ldc2' => ['tmp/ldc/Makefile'] do
  cd 'tmp/ldc' do
    make_parallel
    sh 'make phobos2'
  end
end


file 'ldc/bin/ldc2' => ['tmp/ldc/bin/ldc2'] do
  cd 'tmp/ldc' do
    sh 'make install'
  end
end
#directory 'ldc/bin'
#directory 'ldc/lib'
#directory 'ldc/import'
#file 'ldc/bin/ldc2' => ['tmp/ldc/bin/ldc2', 'ldc/bin', 'ldc/lib', 'ldc/import'] do
#  cd 'tmp/ldc' do
#    sh 'cp bin/ldc2 bin/ldmd2 bin/ldc2.conf ../../ldc/bin'
#    sh 'cp lib/libdruntime-ldc.a lib/liblphobos2.a ../../ldc/lib'
#    sh 'cp -r druntime/ phobos/ ../../ldc/import'
#    sh 'cp -r runtime/import/ldc ../../ldc/import'
#  end
#end

file 'tmp/ldc/phobos/.git/HEAD' => ['tmp/ldc/.hgignore'] do
  cd 'tmp/ldc' do
    sh 'git clone https://github.com/AlexeyProkhin/phobos'
  end
end

file 'tmp/ldc/druntime/.git/HEAD' => ['tmp/ldc/.hgignore'] do
  cd 'tmp/ldc' do
    sh 'git clone https://github.com/AlexeyProkhin/druntime'
  end
end

download_and_symlink('http://llvm.org/releases/2.9/llvm-2.9.tgz', 'tmp', 'configure')
download_and_symlink('http://www.hyperrealm.com/libconfig/libconfig-1.4.8.tar.gz', 'tmp', 'configure')

