
local radix_tree = require('radix_tree');

function test_sample()
    local tree = radix_tree.new();

    assert(tree:is_empty(), "begin with empty")

    tree:insert('foo', 1);
    tree:insert('bar', 2);
    tree:insert('zoo', 3);

    assert(tree:get('foo') == 1, "get foo")
    assert(tree:get('bar') == 2, "get bar")
    assert(tree:get('zoo') == 3, "get zoo")

    tree:remove('foo');
    tree:remove('bar');
    tree:remove('zoo');

    assert(tree:is_empty(), "end with empty")
end


function test_share()
    local tree = radix_tree.new();

    assert(tree:is_empty(), "begin with empty")

    tree:insert('foobar', 1);
    tree:insert('foocar', 2);
    tree:insert('foozoo', 3);

    assert(tree:get('foobar') == 1, "get foo")
    assert(tree:get('foocar') == 2, "get foo")
    assert(tree:get('foozoo') == 3, "get foo")

    tree:remove('foobar');
    tree:remove('foocar');
    tree:remove('foozoo');

    assert(tree:is_empty(), "end with empty")
end


function test_insert()
    local tree = radix_tree.new();

    assert(tree:is_empty(), "begin with empty")

    n = 100000;

    for i = 1, n do
        local key = 'foo' .. i;
        tree:insert(key, i);
    end

    for i = 1, n do
        local key = 'foo' .. i;
        assert(tree:get(key) == i, "get" .. i)
    end

    for i = 1, n do
        local key = 'foo' .. i;
        tree:remove(key);
    end

    assert(tree:is_empty(), "end with empty")
end


function test_get()
    local tree = radix_tree.new();

    tree:insert('foo', 1);
    tree:insert('bar', 2);
    tree:insert('zoo', 3);
      
    assert(tree:get('bar') == 2, 'get bar');
    assert(tree:get('noop') == nil, 'get non');
end


function test_remove()
    local tree = radix_tree.new();

    tree:insert('foo', 1);
    tree:insert('bar', 2);
    tree:insert('zoo', 3);

    tree:remove('foo');
      
    assert(tree:get('foo') == nil, 'get foo');
end


function iter_table(iterator)
    local result = {};

    for key, value in iterator do
        if value == nil then
            result[#result + 1] = key;
        else
            result[key] = value;
        end
    end

    return result;
end


function test_entries()
    local tree = radix_tree.new();

    tree:insert('bar', 1);
    tree:insert('zoo', 2);
    tree:insert('foobar', 3);

    local entries = tree:entries();

    local n = 0;
    for key, value in entries do
        assert(tree:get(key) == value, 'entries');
        n = n + 1;
    end

    assert(n == 3, 'entries length');
end


function test_keys()
    local tree = radix_tree.new();

    tree:insert('foo', 1);
    tree:insert('bar', 2);
    tree:insert('zoo', 3);

    local keys = tree:keys();

    local n = 0;
    for key, value in keys do
        assert(tree:get(key) ~= nil, 'keys');
        n = n + 1;
    end

    assert(n == 3, 'keys length');
end


function test_values()
    local tree = radix_tree.new();

    tree:insert('foo', 1);
    tree:insert('bar', 2);
    tree:insert('zoo', 3);

    local values = tree:values();

    local n = 0;
    for key, value in values do
        n = n + 1;
    end

    assert(n == 3, 'values length');
end


local time_begin = os.clock();

test_sample();
test_share();
test_insert();
test_get();
test_remove();
test_entries();
test_keys();
test_values();

local time_end = os.clock();
local spend = time_end - time_begin;
