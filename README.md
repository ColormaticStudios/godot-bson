# BSON for the Godot Engine
This is a simple BSON serializer and deserializer written in GDScript that is originally designed to be compatible with [JSON for Modern C++](https://json.nlohmann.me/)'s BSON components, but it can be used with any other BSON tool.

From [bsonspec.org](https://bsonspec.org/):  
BSON, short for Bin­ary [JSON](http://json.org), is a bin­ary-en­coded seri­al­iz­a­tion of JSON-like doc­u­ments. Like JSON, BSON sup­ports the em­bed­ding of doc­u­ments and ar­rays with­in oth­er doc­u­ments and ar­rays.

This plugin is useful for server/client communication, interacting with MongoDB, reducing JSON file sizes, etc.

After enabling this plugin in your Godot project settings, you can access the BSON object with:
```gdscript
BSON.to_bson(Dictionary)
```
and
```gdscript
BSON.from_bson(PackedByteArray)
```
You can also test out this plugin with `/BSON Examples/dunk.tscn`. This example will take your JSON, serialize it to BSON, then deserialize it back to JSON.
