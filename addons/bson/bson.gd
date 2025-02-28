# COPYRIGHT 2025 Colormatic Studios and contributors.
# This file is the BSON serializer for the Godot Engine,
# published under the MIT license. https://opensource.org/license/MIT

extends Node
# Unfortunately, this has to be a node in order to be a singleton.
# I'd rather BSON wasn't in the scenetree, but it seems like that's
# the only way to do this. Hopefully this will change in the future.


static func to_bson(data: Dictionary) -> PackedByteArray:
	var document := dictionary_to_bytes(data)
	document.append(0x00)
	var buffer := PackedByteArray()
	buffer.append_array(int32_to_bytes(document.size() + 4))
	buffer.append_array(document)
	return buffer

static func get_byte_type(value: Variant) -> int:
	match typeof(value):
		TYPE_STRING:
			return 0x02
		TYPE_INT:
			if abs(value as int) < 2147483647: # 32 bit signed integer limit
				return 0x10
			else:
				return 0x12
		TYPE_FLOAT:
			return 0x01
		TYPE_ARRAY:
			return 0x04
		TYPE_DICTIONARY:
			return 0x03
		TYPE_BOOL:
			return 0x08
		_:
			push_error("BSON serialization error: Unsupported type: ", typeof(value))
			return 0x00

static func int16_to_bytes(value: int) -> PackedByteArray:
	var buffer := PackedByteArray()
	buffer.resize(2)
	buffer.encode_s16(0, value)
	return buffer

static func int32_to_bytes(value: int) -> PackedByteArray:
	var buffer := PackedByteArray()
	buffer.resize(4)
	buffer.encode_s32(0, value)
	return buffer

static func int64_to_bytes(value: int) -> PackedByteArray:
	var buffer := PackedByteArray()
	buffer.resize(8)
	buffer.encode_s64(0, value)
	return buffer

static func float_to_bytes(value: float) -> PackedByteArray:
	var buffer := PackedByteArray()
	buffer.resize(4)
	buffer.encode_float(0, value)
	return buffer

static func double_to_bytes(value: float) -> PackedByteArray:
	var buffer := PackedByteArray()
	buffer.resize(8)
	buffer.encode_double(0, value)
	return buffer

static func dictionary_to_bytes(dict: Dictionary) -> PackedByteArray:
	var buffer := PackedByteArray()
	
	for key: String in dict.keys():
		buffer.append(get_byte_type(dict[key]))
		var key_string_bytes := key.to_utf8_buffer()
		buffer.append_array(key_string_bytes)
		buffer.append(0x00)
		buffer.append_array(serialize_variant(dict[key]))
	
	return buffer

static func array_to_bytes(array: Array[Variant]) -> PackedByteArray:
	var buffer := PackedByteArray()
	
	for index: int in range(array.size()):
		buffer.append(get_byte_type(array[index]))
		# For whatever reason, BSON wants array indexes to be strings. This makes no sense.
		var s_index := str(index)
		buffer.append_array(s_index.to_utf8_buffer())
		buffer.append(0x00)
		
		buffer.append_array(serialize_variant(array[index]))
	
	return buffer

static func serialize_variant(data: Variant) -> PackedByteArray:
	var buffer := PackedByteArray()
	match typeof(data):
		TYPE_DICTIONARY:
			var document := dictionary_to_bytes(data as Dictionary)
			buffer.append_array(int32_to_bytes(document.size()))
			buffer.append_array(document)
			buffer.append(0x00)
		TYPE_ARRAY:
			var b_array := array_to_bytes(data as Array[Variant])
			buffer.append_array(int32_to_bytes(b_array.size()))
			buffer.append_array(b_array)
			buffer.append(0x00)
		TYPE_STRING:
			var str_as_bytes := (data as String).to_utf8_buffer()
			buffer.append_array(int32_to_bytes(str_as_bytes.size() + 1))
			buffer.append_array(str_as_bytes)
			buffer.append(0x00)
		TYPE_INT:
			if abs(data as int) < 2147483647: # 32 bit signed integer limit
				buffer.append_array(int32_to_bytes(data as int))
			else:
				buffer.append_array(int64_to_bytes(data as int))
		TYPE_FLOAT:
			buffer.append_array(double_to_bytes(data as float))
		TYPE_BOOL:
			buffer.append((data as bool) if 0x01 else 0x00)
		_:
			buffer.append(0x00)
	
	return buffer


static func from_bson(data: PackedByteArray) -> Dictionary:
	return Deserializer.new(data).read_dictionary()


class Deserializer:
	var buffer: PackedByteArray
	var read_position := 0
	
	func _init(buffer: PackedByteArray):
		self.buffer = buffer
	
	func get_int8() -> int:
		var value := buffer[read_position]
		read_position += 1
		return value
	
	func get_int16() -> int:
		var value := buffer.decode_s16(read_position)
		read_position += 2
		return value
	
	func get_int32() -> int:
		var value := buffer.decode_s32(read_position)
		read_position += 4
		return value
	
	func get_int64() -> int:
		var value := buffer.decode_s64(read_position)
		read_position += 8
		return value
	
	func get_float() -> float:
		var value := buffer.decode_float(read_position)
		read_position += 4
		return value
	
	func get_double() -> float:
		var value := buffer.decode_double(read_position)
		read_position += 8
		return value
	
	func get_string() -> String:
		var expected_size = get_int32()
		var s_value: String
		var iter := 0
		while true:
			iter += 1
			var b_char := get_int8()
			if b_char == 0x00: break
			s_value += char(b_char)
		if expected_size != iter: # Check if the string is terminated with 0x00
			push_error("BSON deserialization error: String was the wrong size."
				+ " Position: "
				+ str(read_position - iter)
				+ ", stated size: "
				+ str(expected_size)
				+ ", actual size: "
				+ str(iter))
		return s_value
	
	func get_bool() -> bool:
		return (get_int8() == 1)
	
	func read_dictionary() -> Dictionary:
		var object = {}
		
		var expected_size := get_int32()
		
		var iter := 0
		while true:
			iter += 1
			var type := get_int8()
			if type == 0x00: break
			
			var key := ""
			
			while true:
				var k_char := get_int8()
				if k_char == 0x00: break
				key += char(k_char)
			
			match type:
				0x02: object[key] = get_string()
				0x10: object[key] = get_int32()
				0x12: object[key] = get_int64()
				0x01: object[key] = get_double()
				0x08: object[key] = get_bool()
				0x04: object[key] = read_array()
				0x03: object[key] = read_dictionary()
				_:
					push_error("BSON deserialization error: Unsupported type "
						+ str(type)
						+ " at byte "
						+ str(read_position - 1))
		
		if iter > expected_size:
			push_warning("BSON deserialization warning: Dictionary is the wrong length."
				+ " Expected dictionary length: "
				+ str(expected_size)
				+ ", Actual dictionary length: "
				+ str(iter))
		return object
	
	func read_array() -> Array:
		var array: Array
		
		var expected_size := get_int32()
		
		var iter := 0
		while true:
			iter += 1
			var type := get_int8()
			if type == 0x00: break
			
			var key: String
			
			while true:
				var k_char := get_int8()
				if k_char == 0x00: break
				key += char(k_char)
			
			# IMPORTANT: Since the array is being deserialized sequentially, we can
			# use the Array.append() function. It would be better to set the index
			# directly, but that is not possible. (It *could* cause null holes)
			# The BSON specification unfortunately allows for null holes, but
			# this deserializer will just remove any gaps. This could cause an
			# index desynchronization between two programs communicating with BSON,
			# but that means the other program has a buggy serializer.
			match type:
				0x02: array.append(get_string())
				0x10: array.append(get_int32())
				0x12: array.append(get_int64())
				0x01: array.append(get_double())
				0x08: array.append(get_bool())
				0x04: array.append(read_array())
				0x03: array.append(read_dictionary())
				_: push_error("BSON deserialization error: Unsupported type: " + str(type))
		if iter > expected_size:
			push_warning("BSON deserialization warning: Array is the wrong length."
				+ " Expected array length: "
				+ str(expected_size)
				+ ", Actual array length: "
				+ str(iter))
		return array
