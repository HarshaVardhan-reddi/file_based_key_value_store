# Description
### A file based key,value pair data storage with the following constraints
* The key is always a string with 32 Charectars
* The value should be always a json object

# Usage

**Add fkv.rb to your working .rb file**
``` ruby
require_relative 'path_to_fkv.rb'
```
**Provide path to your custom data store. File store must be with .json, as it is a (key, value) file store. If path is not provided then the default path to data store is tmp/store.json**
``` ruby
object = Fkv::Dstore.new(path: "path_to_your_data_store.json") # 
```
**Operations on data store**
* **read:** Provide a key to get respective value from data store
* **create:** Provide key, value pair with data keyword. time_to_live(ttl) is an optional keyword that take no of seconds a perticular record should exists in data store
* **delete:** Provide key to delete perticualr record.
```ruby
object.create(data: {key: value})
object.create(data: {key: value}, ttl: 50) #ttl is optional 
object.delete(key: key)
object.read(key: key)
```