task :default => [:summon_gdc, :summon_ldc2]

GDC_DIR = Dir.pwd
GDC_BUILD_DIR=File.join(GDC_DIR, 'gdc/build')
task :summon_gdc => ["#{GDC_BUILD_DIR}/bin/gdc"]

file "#{GDC_BUILD_DIR}/bin/gdc" => ['gdc/dev/gcc-4.6.1/objdir/Makefile'] do |t|
  cd 'gdc/dev/gcc-4.6.1/objdir' do
    sh 'make -j4'
  end
end

directory 'gdc/dev'
directory 'gdc/dev/gcc-4.6.1/objdir'

directory GDC_BUILD_DIR
file 'gdc/dev/gcc-4.6.1/objdir/Makefile' => ['gdc/dev/gcc-4.6.1/configure', 'gdc/dev/gcc-4.6.1/objdir', 'gdc/dev/gcc-4.6.1/gmp', 'gdc/dev/gcc-4.6.1/mpfr/README', 'gdc/dev/gcc-4.6.1/mpc'] do |t|
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
  r = Regexp.new('.*/(?<name>.*?)-(?<version>.*).tar.bz2')
  md = r.match(url)
  name = md[:name]
  version = md[:version]

  desc "download #{archive}"
  file archive => [:tmp] do |t|
    sh "curl #{url} > #{t.name}"
  end

  file_of_archive = File.join(output_dir, file)
  file file_of_archive => [archive] do |t|
    sh "tar xf #{t.prerequisites[0]} -C #{output_dir}"
    sh "touch #{t.name}"
  end

  name_with_version = "#{name}-#{version}"
  file File.join(output_dir, "#{name}") => [file_of_archive] do |t|
    cd output_dir do
      sh "ln -s #{name_with_version} #{name}"
    end
  end
end

download_and_symlink('ftp://ftp.gmplib.org/pub/gmp-5.0.2/gmp-5.0.2.tar.bz2', 'gdc/dev/gcc-4.6.1', 'gmp-5.0.2/ChangeLog')

#desc "tmp/gmp-5.0.2.tar.bz2"
#file "tmp/gmp-5.0.2.tar.bz2" => [:tmp] do |t|
#  sh "curl ftp://ftp.gmplib.org/pub/gmp-5.0.2/gmp-5.0.2.tar.bz2 > #{t.name}"
#end
#file 'gdc/dev/gcc-4.6.1/gmp' => ['gdc/dev/gcc-4.6.1/gmp-5.0.2/ChangeLog'] do |t|
#  cd 'gdc/dev/gcc-4.6.1' do
#    sh "ln -s gmp-5.0.2 gmp"
#  end
#end
#file 'gdc/dev/gcc-4.6.1/gmp-5.0.2/ChangeLog' => ['tmp/gmp-5.0.2.tar.bz2'] do |t|
#  sh "tar xf #{t.prerequisites[0]} -C gdc/dev/gcc-4.6.1"
#  sh "touch #{t.name}"
#end

desc "tmp/mpfr-3.0.1.tar.bz2"
file "tmp/mpfr-3.0.1.tar.bz2" => [:tmp] do |t|
  sh "curl http://www.mpfr.org/mpfr-current/mpfr-3.0.1.tar.bz2 > #{t.name}"
end
file 'gdc/dev/gcc-4.6.1/mpfr/README' => ['gdc/dev/gcc-4.6.1/mpfr-3.0.1/README'] do |t|
  cd 'gdc/dev/gcc-4.6.1' do
    sh 'ln -s mpfr-3.0.1 mpfr'
  end
end
file 'gdc/dev/gcc-4.6.1/mpfr-3.0.1/README' => ['tmp/mpfr-3.0.1.tar.bz2'] do |t|
  sh "tar xf #{t.prerequisites[0]} -C gdc/dev/gcc-4.6.1"
  sh "touch #{t.name}"
end

desc "tmp/mpc-0.9.tar.gz"
file "tmp/mpc-0.9.tar.gz" => [:tmp] do |t|
  sh "curl http://www.multiprecision.org/mpc/download/mpc-0.9.tar.gz > #{t.name}"
end
file 'gdc/dev/gcc-4.6.1/mpc-0.9/INSTALL' => ['tmp/mpc-0.9.tar.gz'] do |t|
  sh "tar xf #{t.prerequisites[0]} -C gdc/dev/gcc-4.6.1"
  sh "touch #{t.name}"
end
file 'gdc/dev/gcc-4.6.1/mpc' => ['gdc/dev/gcc-4.6.1/mpc-0.9/INSTALL'] do |t|
  cd 'gdc/dev/gcc-4.6.1' do
    sh "ln -s mpc-0.9 mpc"
  end
end

desc 'hg clone of gdc'
file 'tmp/gdc/.hgignore' => [:tmp] do |t|
  cd 'tmp' do
    sh 'hg clone https://bitbucket.org/goshawk/gdc'
  end
end

file 'gdc/.hgignore' => ['tmp/gdc/.hgignore'] do |t|
  sh 'cp -R tmp/gdc .'
end

task :summon_ldc2 do |t|

end
