# Description
### A file based key,value pair data storage with the following constraints
* The key is always a string capped at 32 characters
* The value should be always a json object
# Depenencies
```ruby
ruby: 2.7.2
bundler_version: 2.2.3
```
# Usage

**Add fkv.rb to your working .rb file**
``` ruby
require_relative 'path_to_fkv.rb'
```
**Provide path to your custom data store. File store must be with .json extension, as it is a (key, value) file store. If path is not provided then the default path to data store is tmp/store.json**
``` ruby
object = Fkv::DStore.new(path: "path_to_your_data_store.json") # path is optional
#object = Fkv::Dstore.new
```
**Operations on data store**
* **Read:** Provide a key to get respective value from data store
* **Create:** Provide key, value pair with data keyword. time_to_live(ttl) is an optional keyword that take no of seconds a perticular record should exists in data store. Create returns message and status. 
* **Delete:** Provide key to delete particular record.
```ruby
object.create(data: {key: value})
object.create(data: {key: value}).message #success
object.create(data: {key: value}).status #true
object.create(data: {key: value}, ttl: 50) #ttl is optional 
object.delete(key: key)
object.read(key: key)
```