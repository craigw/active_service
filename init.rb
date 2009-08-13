lib_dir = File.expand_path(File.dirname(__FILE__) + '/lib')
$:.unshift lib_dir if !$:.any? { |lib| File.expand_path(lib) == lib_dir }

require 'hpricot'
require 'digest/sha1'