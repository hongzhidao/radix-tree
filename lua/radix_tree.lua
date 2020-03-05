-- copyright (C) hongzhidao

local _M = {};

function _M.new()
    local self = {
        root = {},
        size = 0
    };

    return setmetatable(self, {__index = _M});
end


function _find_node(parent, label)
    local closest_child = nil;
    local exact_match = false;
    local match_length = 0;
    local first_index = 1;

    if (parent.children) then

        local last_index = #parent.children + 1;

        while (first_index < last_index) do
            local middle_index = first_index + math.floor((last_index - first_index) / 2)
            local node = parent.children[middle_index];
            local min_length = math.min(#label, #node.label);

            local i = 0;
            while ((i < min_length)
                   and (label:byte(i + 1) == node.label:byte(i + 1)))
            do
                i = i + 1;
            end

            if i > 0 then
                closest_child = node;
                exact_match = (i == #node.label);
                match_length = i;
                first_index = middle_index;
                break;
            end

            if (node.label < label) then
                first_index = middle_index + 1;
            else
                last_index = middle_index;
            end 
        end
    end

    return closest_child, exact_match, match_length, first_index;
end


function _M.match_node(self, prefix)
    if not prefix or #prefix == 0 then
        return self.root, true, nil, 0, 0, 1;
    end

    local ancestor_length = 0;
    local parent = self.root;

    while true do
        local label = prefix:sub(ancestor_length + 1);
        local child, exact_match, match_length, index = _find_node(parent, label);

        if ((not exact_match)
            or (ancestor_length + #child.label >= #prefix))
        then
            return child, exact_match, parent, ancestor_length, match_length, index;
        end

        parent = child;
        ancestor_length = ancestor_length + #child.label;
    end
end


function _M.insert(self, key, value)
    local closest_node, exact_match, parent_node,
          ancestor_length, match_length, closest_index = self:match_node(key); 

    local label = key:sub(ancestor_length + 1);

    if (not closest_node) then
        if (not parent_node.children) then
            parent_node.children = {};
        end

        local new_node = {
            label = label,
            value = value
        };

        table.insert(parent_node.children, closest_index, new_node);
        self.size = self.size + 1;
        return
    end

    if (exact_match) then
        local old = closest_node.value;
        closest_node.value = value;

        if (not old) then
            self.size = self.size + 1;
        end

        return old;
    end

    local shared_prefix = label:sub(1, match_length);
    local key_suffix = label:sub(match_length + 1);
    local node_suffix = closest_node.label:sub(match_length + 1);

    parent_node.children[closest_index] = {
        label = shared_prefix,
        value = value,
        children = {
            {
                label = node_suffix,
                value = closest_node.value,
                children = closest_node.children
            }
        },
    };
    
    if (#key_suffix > 0) then
        parent_node.children[closest_index].value = nil;

        local insert_node = {
            label = key_suffix,
            value = value
        };
    
        table.insert(parent_node.children[closest_index].children,
                     (node_suffix < key_suffix) and 2 or 1, 
                     insert_node);
    end

    self.size = self.size + 1;
end


function _M.get(self, key)
    local node, exact_match = self:match_node(key);

    return exact_match and node.value or nil;
end


function _merge_nodes(parent, child)
    parent.label = parent.label .. child.label;
    parent.value = child.value;
    parent.children = child.children;
end


function _M.remove(self, key)
    local closest_node, exact_match, parent_node, _, _, closest_index = 
            self:match_node(key);

    if (not exact_match) then
        return;
    end

    local old = closest_node.value;

    if (closest_node.children ~= nil) then
        if (#closest_node.children == 1) then
            _merge_nodes(closest_node, closest_node.children[1]);

        else
            closest_node.value = nil;
        end

    else
        table.remove(parent_node.children, closest_index);

        if (parent_node ~= self.root
            and #parent_node.children == 1
            and not parent_node.value)
        then
            _merge_nodes(parent_node, parent_node.children[1]);
        end
    end

    self.size = self.size - 1;

    return old;
end


function _M.len(self)
    return self.size;
end


function _M.is_empty(self)
    return self.size == 0;
end


function _rescure_node(node, transform, prefixes)
    if (not node) then
        return;
    end

    if (not prefixes) then
        prefixes = {};
    end

    prefixes[#prefixes + 1] = node.label;

    if (node.value ~= nil) then
        coroutine.yield(transform(node, prefixes));
    end

    if (node.children ~= nil) then
        for index in ipairs(node.children) do
            local child = node.children[index];
            _rescure_node(child, transform, prefixes);
        end
    end

    prefixes[#prefixes] = nil;
end


function _M.wrap_rescure(self, prefix, type)
    return coroutine.wrap(function()
        local node, _, _, ancestor_length, _, _ = self:match_node(prefix);
        local ancestor = prefix and prefix:sub(1, ancestor_length) or '';

        _rescure_node(node, function(node, prefixes)
            local key = ancestor .. table.concat(prefixes);

            if (type == 1) then -- entries
                return key, node.value;

            elseif (type == 2) then -- keys
                return key;

            else -- values
                return node.value;
            end
        end)
    end)
end


function _M.entries(self, prefix)
    return self:wrap_rescure(prefix, 1);
end


function _M.keys(self, prefix)
    return self:wrap_rescure(prefix, 2);
end


function _M.values(self, prefix)
    return self:wrap_rescure(prefix, 3);
end


return _M;
