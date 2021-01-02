require 'json'
require 'active_support'
require 'ostruct'
require 'time'


#Monkey patching
class String
    def is_valid?
        return false unless self.length == 32
        true
    end
end

module Fkv

    class DStore
        attr_accessor :raw_data, :response, :status, :message

        def initialize(path: nil)
            begin
                @limit = 1000000
                Fkv::Dependencies.install unless File.exists? "Gemfile.lock"
                user_defined_path = path if path.present?
                default_path = 'tmp/store.json'
                @path = user_defined_path || default_path
                File.open(@path,File::RDWR|File::CREAT, 0644) {|file| file.write('{}')} unless File.exists? @path
                raise " Extension of file store must be .json " unless @path.split('.')[1].eql?("json") 
            rescue => e
               puts "\u{274c} " + e.message
            end
        end

        def read_thread
            check_for_ttl?
            @raw_data = ""
            thread = Thread.new {
                mutex.synchronize {
                    @raw_data << read_from_store
                }
            }
            self.raw_data = @raw_data if @raw_data.present?
            self.raw_data = '{}' if @raw_data.nil?
            thread
        end

        def read(key: )
            begin 
                read_thread.join
                json_parsed = JSON.parse(self.raw_data)
                raise "Key doesn't exists in store" unless json_parsed.key? key.to_s          
                data = json_parsed[key]
                data
            rescue => e
                puts e.message
            end
        end

        def create_thread(path,data)
            thread = Thread.new {
                mutex.synchronize {
                    @response = @response.to_i + write_to_store(path,data)
                }
            }
            thread
        end

        def create(data: , ttl: nil) 
            begin
                raise "Size of file can't be greater than 1 gb" if File.size(@path) > @limit
                raise "Data can't be nil" if data.nil? || data.empty?
                read_thread.join
                data_in_store = JSON.parse(self.raw_data)
                key = data.keys.first.to_s
                create_ttl_record(key: key, expires_at: Time.now + ttl).join if ttl.present?
                raise "#{key} key already exists in DStore" if data_in_store.key? key
                raise "Key must be 32 chars" unless key.is_valid?
                new_data = data_in_store.merge!(data.to_h)
                create_thread(@path,new_data).join
                if self.response
                    self.message = :success
                    self.status = true
                else
                    self.message = :failed
                    self.status = false
                end
                OpenStruct.new(message: message, status: status)
            rescue => e
                puts "\u{26d4} " + e.message
            end
        end

        def delete(key: )
            data = JSON.parse(read_from_store)
            data.delete(key)
            create_thread(@path, data).join
        end

        private

        def write_to_store(path,data)
            File.open(path, 'w') do |file|
                file.flock(File::LOCK_EX)
                file.write(data.to_json)
                file.flock(File::LOCK_UN)
            end
        end

        def read_from_store
            File.open(@path, 'r') do |file|
                file.flock(File::LOCK_SH)
                file.read
            end
        end

        def mutex
            @mutex ||= Mutex.new
            @mutex
        end

        def read_ttl_store
            raw_data = File.read(ttl_store_path)
            json_parsed = JSON.parse(raw_data)
        end

        def check_for_ttl?
            store_data = JSON.parse(read_from_store)
            ttl_data = read_ttl_store
            ttl_exceded_keys = ttl_data.map {|key, expires_at| key if Time.parse(expires_at) <= Time.now}
            ttl_exceded_keys.each {|key| store_data.delete(key)}
            ttl_exceded_keys.each {|key| ttl_data.delete(key)}
            create_thread(@path, store_data).join
            create_thread(ttl_store_path, ttl_data).join
        end

        def ttl_store_path
            'tmp/.ttl_store.json'
        end

        def create_ttl_record(key: , expires_at:)
            data = {}
            data[key] = expires_at
            data_in_ttl_store = read_ttl_store
            new_data = data_in_ttl_store.merge(data)
            create_thread(ttl_store_path, new_data)
        end
    end

    class Dependencies
        def self.install
            system('bundle install')
        end
    end
end