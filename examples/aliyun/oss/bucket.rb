# -*- encoding: utf-8 -*-

$LOAD_PATH.unshift(File.expand_path("../../../../lib", __FILE__))
require 'yaml'
require 'aliyun/oss'

# 初始化OSS client
Aliyun::OSS::Logging.set_log_level(Logger::DEBUG)
conf_file = '~/.oss.yml'
conf = YAML.load(File.read(File.expand_path(conf_file)))
client = Aliyun::OSS::Client.new(
  :endpoint => conf['endpoint'],
  :cname => conf['cname'],
  :access_key_id => conf['id'],
  :access_key_secret => conf['key'])
bucket = client.get_bucket(conf['bucket'])

# 列出当前所有的bucket
buckets = client.list_buckets
buckets.each{ |b| puts "Bucket: #{b.name}"}

# 创建bucket
begin
  bucket_name = 't-foo-bar'
  client.create_bucket(bucket_name, :location => 'oss-cn-hangzhou')
  puts "Create bucket success: #{bucket_name}"
rescue => e
  puts "Create bucket failed: #{e.message}"
end

# 向bucket中添加5个空的object:
# foo/obj1, foo/bar/obj1, foo/bar/obj2, foo/xxx/obj1
bucket.put_object('foo/obj1') {}
bucket.put_object('foo/bar/obj1') {}
bucket.put_object('foo/bar/obj2') {}
bucket.put_object('foo/xxx/obj1') {}
bucket.put_object('中国の') {}

# list bucket下所有objects
objects = bucket.list_objects

puts "All objects:"
objects.each do |o|
  puts "Object: #{o.key}, type: #{o.type}, size: #{o.size}"
end
puts

# list bucket下所有前缀为foo/bar/的object
objects = bucket.list_objects(:prefix => 'foo/bar/')

puts "All objects begin with 'foo/bar/':"
objects.each do |o|
  puts "Object: #{o.key}, type: #{o.type}, size: #{o.size}"
end
puts

# 获取object的common prefix，common prefix是指bucket下所有object（也可
# 以指定特定的前缀）的公共前缀，这在object数量巨多的时候很有用，例如有
# 如下的object：
#     /foo/bar/obj1
#     /foo/bar/obj2
#     ...
#     /foo/bar/obj9999999
#     /foo/xx/
# 指定foo/为prefix，/为delimiter，则返回的common prefix为
# /foo/bar/, /foo/xxx/
# 这可以表示/foo/目录下的子目录。如果没有common prefix，你可能要遍历所
# 有的object来找公共的前缀

objects = bucket.list_objects(:prefix => 'foo/', :delimiter => '/')

puts "All objects begin with 'foo/':"
objects.each do |o|
  if o.is_a?(Aliyun::OSS::Object)
    puts "Object: #{o.key}, type: #{o.type}, size: #{o.size}"
  else
    puts "Common prefix: #{o}"
  end
end

# 获取/设置Bucket属性: ACL, Logging, Referer, Website, LifeCycle, CORS
puts "Bucket acl before: #{bucket.acl}"
bucket.acl = Aliyun::OSS::ACL::PUBLIC_READ
puts "Bucket acl now: #{bucket.acl}"

puts "Bucket logging before: #{bucket.logging}"
bucket.logging = {:enable => true, :target_bucket => conf['bucket'], :prefix => 'foo/'}
puts "Bucket logging now: #{bucket.logging}"

puts "Bucket referer before: #{bucket.referer}"
bucket.referer = {:allow_empty => true, :referers => ['baidu.com', 'aliyun.com']}
puts "Bucket referer now: #{bucket.referer}"

puts "Bucket website before: #{bucket.website}"
bucket.website = {:index => 'default.html', :error => 'error.html'}
puts "Bucket website now: #{bucket.website}"

puts "Bucket lifecycle before: #{bucket.lifecycle.map(&:to_s)}"
bucket.lifecycle = [
  Aliyun::OSS::LifeCycleRule.new(
    :id => 'rule1', :enabled => true, :prefix => 'foo/', :expiry => 1),
  Aliyun::OSS::LifeCycleRule.new(
    :id => 'rule2', :enabled => false, :prefix => 'bar/', :expiry => Date.new(2016, 1, 1))
]
puts "Bucket lifecycle now: #{bucket.lifecycle.map(&:to_s)}"

puts "Bucket cors before: #{bucket.cors.map(&:to_s)}"
bucket.cors = [
    Aliyun::OSS::CORSRule.new(
      :allowed_origins => ['aliyun.com', 'http://www.taobao.com'],
      :allowed_methods => ['PUT', 'POST', 'GET'],
      :allowed_headers => ['Authorization'],
      :expose_headers => ['x-oss-test'],
      :max_age_seconds => 100)
]
puts "Bucket cors now: #{bucket.cors.map(&:to_s)}"