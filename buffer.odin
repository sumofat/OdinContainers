package containers;

import "core:fmt"
import "core:c"
import "core:mem"
import "core:runtime"

Buffer :: struct (type : typeid)
{
    buffer : [dynamic]type,
    current_id : u64,
    borrow_count : u64,
	is_init : bool,
}

buf_init :: proc(capacity : u64,$type : typeid) -> (Buffer(type))
{
    result : Buffer(type);
    result.buffer = make([dynamic]type,0,capacity);
	result.is_init = true
    return result;
}

buf_push :: proc(buffer : ^Buffer($element_type),element : element_type) -> u64
{
    assert(buffer != nil);
    assert(buffer.borrow_count == 0);
	assert(buffer.is_init == true)
    if buf_len(buffer^) <= buffer.current_id
    {
	   append_nothing(&buffer.buffer);
       //assert(false)
    }
    
    buffer.buffer[buffer.current_id] = element;
    index := buffer.current_id;
    buffer.current_id = index + 1;
    return index;
}

buf_insert :: proc(buffer : ^Buffer($element_type),at : u64,element : element_type) -> bool{
    assert(buffer != nil)
    assert(buffer.borrow_count == 0)
	assert(buffer.is_init == true)
    ok : bool
    if ok = insert_at(&buffer.buffer,int(at),element);ok{
        buffer.current_id += 1
    }
    return ok
}

buf_get :: proc(buffer : ^Buffer($element_type),index : u64) -> (element_type)
{
    assert(buffer != nil);
	assert(buffer.is_init == true)
    return buffer.buffer[index];
}

buf_get_nb :: proc(buffer : ^Buffer($element_type),index : u64,$type : typeid) -> (type)// #no_bounds_check
{
    assert(buffer != nil);
	assert(buffer.is_init == true)
    return buffer.buffer[index];
}

buf_peek :: proc(buffer : ^Buffer($element_type)) -> (element_type){
	assert(buffer.is_init == true)
	result : element_type
	result = buf_get(buffer,buf_len(buffer^) - 1)
	return result
}

buf_pop :: proc(buffer : ^Buffer($element_type)) -> (element_type)
{
    assert(buffer != nil);
	assert(buffer.is_init == true)
    //should reduce length by 1 and remove the top element
    return pop(&buffer.buffer);
}

//NOTE(Ray):If somone tries to push an element while a ptr is checked out should assert
buf_chk_out :: proc(buffer : ^Buffer($element_type),index : u64) -> (^element_type)
{
    assert(buffer != nil);
	assert(buffer.is_init == true)
    if (len(buffer.buffer) == 0)
    { 
        return nil;   
    }
    else
    {
        buffer.borrow_count += 1;
        return &buffer.buffer[index];
    }
}

buf_ptr :: proc(buffer : ^Buffer($element_type),index : u64) -> (^element_type)
{
    assert(buffer != nil);
	assert(buffer.is_init == true)
    if (len(buffer.buffer) == 0)
    { 
        return nil;   
    }
    return &buffer.buffer[index];    
}

buf_len :: proc(buf : Buffer($element_type)) -> u64
{
	assert(buf.is_init == true)
    return cast(u64)len(buf.buffer)
}

//NOTE(Ray):If somone tries to push an element while a ptr is checked out should assert
//Call this when your done with checkout ptr.
buf_chk_in :: proc(buffer : ^Buffer($element_type))
{
	assert(buffer.is_init == true)
    if buffer.borrow_count > 0
    {
	   buffer.borrow_count -= 1;	
    }
}

buf_swap :: proc(buffer : ^Buffer($element_type), a_idx : u64,b_idx : u64)-> bool{
    assert(buffer != nil)
    assert(buffer.borrow_count == 0);
	assert(buffer.is_init == true)

    if (len(buffer.buffer) == 0){ 
        return false
    }else if buf_len(buffer^) <= a_idx || buf_len(buffer^) <= b_idx{
        return false
    }

    a := buf_ptr(buffer,a_idx)
    b := buf_ptr(buffer,b_idx)
    c := a^
    a^ = b^
    b^ = c

    return true
}

buf_del :: proc(buffer : ^Buffer($element_type),idx : u64) -> bool{
    assert(buffer != nil)
    assert(buffer.borrow_count == 0)
	assert(buffer.is_init == true)

    if (len(buffer.buffer) == 0){ 
        return false
    }else if buf_len(buffer^) <= idx{
        return false
    }
    runtime.unordered_remove(&buffer.buffer,int(idx))
	buffer.is_init = false
    buffer.current_id -= 1
    return true
}

buf_clear :: proc(b : ^Buffer($element_type))
{
	assert(b.is_init == true)
    assert(b != nil);
    clear(&b.buffer);
    b.current_id = 0;
    b.borrow_count = 0;
}

buf_free :: proc(b : ^Buffer($element_type))
{
	assert(b.is_init == true)
    assert(b != nil);
    delete(b.buffer);
    b.borrow_count = 0;
	b.is_init = false
}

buf_copy :: proc(buf : ^Buffer($element_type),copy_contents : bool  = false) -> Buffer(element_type)
{
	assert(buf.is_init == true)
    assert(buf != nil);
    result : Buffer(element_type);
	result.is_init = true
    result.current_id = buf.current_id;
    result.borrow_count = buf.borrow_count;
    //    result.buffer = clone_dynamic_array(buf.buffer);
    resize(&result.buffer,len(buf.buffer));
    copy(result.buffer[:],buf.buffer[:]);        
    return result;
}

buf_copy_slice :: proc(s : []$element_type)-> Buffer(element_type){
    result : Buffer(element_type);
	result.is_init = true
    result.current_id = 0
    result.borrow_count = 0
    resize(&result.buffer,len(s));
    copy(result.buffer[:],s[:]);        
    return result;
}

buf_get_slice :: proc(buf : ^Buffer($element_type))-> []element_type{
	assert(buf.is_init == true)
	return buf.buffer[:]
}

buf_get_slice_of_type :: proc(buf : ^Buffer($element_type),$new_type : typeid )-> []new_type{
	assert(buf.is_init == true)
	return mem.slice_data_cast([]new_type,buf.buffer[:])
}

clone_dynamic_array :: proc(x: $T/[dynamic]$E) -> T
{
    res := make(T, len(x));
    copy(res[:], x[:]);
    return res;
}

